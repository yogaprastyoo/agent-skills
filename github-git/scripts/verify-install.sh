#!/usr/bin/env bash
# verify-install.sh
#
# Sanity-checks that the github-git skill is installed correctly and the
# environment has everything it needs to operate.
#
# Usage:
#   bash ~/.agents/skills/github-git/scripts/verify-install.sh
#   bash ~/.agents/skills/github-git/scripts/verify-install.sh --quiet
#
# Exit codes:
#   0 — all checks passed
#   1 — one or more checks failed
#
# Checks performed:
#   - git is installed and usable
#   - gh CLI is installed and authenticated
#   - jq is installed (optional — hooks degrade gracefully without it)
#   - github-git skill is accessible at ~/.claude/skills/github-git/
#   - SKILL.md, references/, commands/, hooks/ all present
#   - Slash commands symlinked into ~/.claude/commands/ (warn only — not required)
#   - Claude Code hooks wired in ~/.claude/settings.json (warn only — not required)

set -uo pipefail

QUIET=0
if [ "${1:-}" = "--quiet" ]; then
  QUIET=1
fi

PASS=0
FAIL=0
WARN=0

# --- helpers -----------------------------------------------------------------
green() { [ "$QUIET" -eq 0 ] && printf '\033[32m%s\033[0m\n' "$1"; }
red()   { printf '\033[31m%s\033[0m\n' "$1" >&2; }
amber() { [ "$QUIET" -eq 0 ] && printf '\033[33m%s\033[0m\n' "$1"; }
note()  { [ "$QUIET" -eq 0 ] && printf '   %s\n' "$1"; }

ok()   { PASS=$((PASS + 1)); green   "[OK]    $1"; }
fail() { FAIL=$((FAIL + 1)); red     "[FAIL]  $1"; }
warn() { WARN=$((WARN + 1)); amber   "[WARN]  $1"; }

# --- 1. git ------------------------------------------------------------------
if command -v git >/dev/null 2>&1; then
  ok "git installed ($(git --version))"
else
  fail "git not installed"
  note "Install via your package manager (apt install git / brew install git)"
fi

# --- 2. gh -------------------------------------------------------------------
if command -v gh >/dev/null 2>&1; then
  ok "gh CLI installed ($(gh --version | head -1))"
  if gh auth status >/dev/null 2>&1; then
    ACTIVE=$(gh auth status 2>&1 | grep -oE 'account [^[:space:]]+' | head -1 | sed 's/^account //')
    ok "gh authenticated (${ACTIVE:-unknown account})"
  else
    fail "gh not authenticated"
    note "Run: gh auth login"
  fi
else
  fail "gh CLI not installed"
  note "Install from https://cli.github.com/"
fi

# --- 3. jq (optional) --------------------------------------------------------
if command -v jq >/dev/null 2>&1; then
  ok "jq installed (used by hooks for clean JSON parsing)"
else
  warn "jq not installed"
  note "Hooks fall back to a regex parser, but jq is more reliable"
  note "Install: apt install jq  /  brew install jq"
fi

# --- 4. Skill location -------------------------------------------------------
SKILL_DIR=""
for candidate in \
  "$HOME/.claude/skills/github-git" \
  "$HOME/.agents/skills/github-git"; do
  if [ -d "$candidate" ]; then
    SKILL_DIR="$candidate"
    break
  fi
done

if [ -n "$SKILL_DIR" ]; then
  ok "skill directory found: $SKILL_DIR"
else
  fail "skill directory not found"
  note "Expected at ~/.claude/skills/github-git/ or ~/.agents/skills/github-git/"
  note "See https://github.com/yogaprastyoo/agent-skills for install"
fi

# --- 5. Required files -------------------------------------------------------
if [ -n "$SKILL_DIR" ]; then
  REQUIRED=(
    "SKILL.md"
    "references/issues.md"
    "references/branching-commits.md"
    "references/pull-requests.md"
    "references/code-review.md"
    "references/repo-setup.md"
    "commands/git-issue.md"
    "commands/git-commit.md"
    "commands/git-pr.md"
    "commands/git-review.md"
    "commands/git-setup.md"
    "hooks/guard-push-to-main.sh"
    "hooks/commit-msg-validator.sh"
    "hooks/git-hooks/commit-msg"
    "hooks/git-hooks/pre-push"
    "scripts/validate-commit-msg.sh"
    "scripts/install-git-hooks.sh"
  )

  MISSING=()
  for f in "${REQUIRED[@]}"; do
    [ -f "$SKILL_DIR/$f" ] || MISSING+=("$f")
  done

  if [ "${#MISSING[@]}" -eq 0 ]; then
    ok "all required skill files present (${#REQUIRED[@]} files)"
  else
    fail "${#MISSING[@]} required file(s) missing in skill directory"
    for f in "${MISSING[@]}"; do
      note "missing: $f"
    done
  fi

  # --- 6. Hook executable bits ----------------------------------------------
  for hook in hooks/guard-push-to-main.sh hooks/commit-msg-validator.sh hooks/git-hooks/commit-msg hooks/git-hooks/pre-push; do
    path="$SKILL_DIR/$hook"
    if [ -f "$path" ] && [ ! -x "$path" ]; then
      warn "$hook is not executable"
      note "Fix: chmod +x $path"
    fi
  done
fi

# --- 7. Slash commands symlinked --------------------------------------------
if [ -d "$HOME/.claude/commands" ]; then
  CMD_COUNT=$(find "$HOME/.claude/commands" -maxdepth 1 -name 'git-*.md' 2>/dev/null | wc -l | tr -d ' ')
  if [ "$CMD_COUNT" -ge 5 ]; then
    ok "slash commands symlinked in ~/.claude/commands ($CMD_COUNT files)"
  else
    warn "only $CMD_COUNT of 5 expected slash commands in ~/.claude/commands"
    note "Install with:"
    note "  for cmd in $SKILL_DIR/commands/*.md; do ln -sf \"\$cmd\" ~/.claude/commands/; done"
  fi
else
  warn "~/.claude/commands does not exist"
  note "Create and symlink commands:"
  note "  mkdir -p ~/.claude/commands"
  note "  for cmd in $SKILL_DIR/commands/*.md; do ln -sf \"\$cmd\" ~/.claude/commands/; done"
fi

# --- 8. Claude Code hooks in settings.json (optional) ------------------------
SETTINGS="$HOME/.claude/settings.json"
if [ -f "$SETTINGS" ]; then
  if grep -q "guard-push-to-main.sh" "$SETTINGS" 2>/dev/null; then
    ok "guard-push-to-main hook wired in ~/.claude/settings.json"
  else
    warn "guard-push-to-main hook NOT wired in ~/.claude/settings.json"
    note "See $SKILL_DIR/hooks/settings.example.json for the snippet"
  fi
  if grep -q "commit-msg-validator.sh" "$SETTINGS" 2>/dev/null; then
    ok "commit-msg-validator hook wired in ~/.claude/settings.json"
  else
    warn "commit-msg-validator hook NOT wired in ~/.claude/settings.json"
    note "See $SKILL_DIR/hooks/settings.example.json for the snippet"
  fi
else
  warn "~/.claude/settings.json does not exist"
  note "Create it and add the hooks snippet from $SKILL_DIR/hooks/settings.example.json"
fi

# --- summary -----------------------------------------------------------------
echo
echo "============================================================"
printf '  %s passed, %s failed, %s warnings\n' "$PASS" "$FAIL" "$WARN"
echo "============================================================"

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
exit 0
