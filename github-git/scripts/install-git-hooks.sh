#!/usr/bin/env bash
# install-git-hooks.sh
#
# Installs the github-git skill's git hooks into the current repository's
# .git/hooks/ directory. Run this once per repo where you want commit-msg
# and pre-push protection.
#
# Usage:
#   bash ~/.agents/skills/github-git/scripts/install-git-hooks.sh
#   bash ~/.agents/skills/github-git/scripts/install-git-hooks.sh --copy
#   bash ~/.agents/skills/github-git/scripts/install-git-hooks.sh --uninstall
#
# Options:
#   (default)     Symlink hooks from the skill into .git/hooks/. Updates to
#                 the skill take effect immediately.
#   --copy        Copy hooks instead of symlinking. Use when the skill
#                 directory might not be available at hook execution time.
#   --uninstall   Remove any hooks that point to (or match) the skill hooks.

set -euo pipefail

MODE="symlink"
case "${1:-}" in
  --copy) MODE="copy" ;;
  --uninstall) MODE="uninstall" ;;
  --help|-h)
    sed -n '3,/^set -euo/p' "$0" | head -n -1 | sed 's/^# \?//'
    exit 0
    ;;
  "") ;;
  *)
    printf 'Unknown option: %s\n' "$1" >&2
    exit 1
    ;;
esac

# --- Resolve skill location --------------------------------------------------
SKILL_DIR=""
for candidate in \
  "$HOME/.claude/skills/github-git" \
  "$HOME/.agents/skills/github-git"; do
  if [ -d "$candidate/hooks/git-hooks" ]; then
    SKILL_DIR="$candidate"
    break
  fi
done

if [ -z "$SKILL_DIR" ]; then
  cat >&2 <<'EOF'
ERROR: github-git skill not found.

Looked for:
  ~/.claude/skills/github-git/hooks/git-hooks/
  ~/.agents/skills/github-git/hooks/git-hooks/

Install the skill first (see https://github.com/yogaprastyoo/agent-skills).
EOF
  exit 1
fi

SOURCE_DIR="$SKILL_DIR/hooks/git-hooks"

# --- Locate target .git/hooks ------------------------------------------------
if ! GIT_DIR=$(git rev-parse --git-dir 2>/dev/null); then
  cat >&2 <<'EOF'
ERROR: not inside a git repository.

Run this script from the root of the repository where you want the hooks
installed. For example:

  cd /path/to/your/repo
  bash ~/.agents/skills/github-git/scripts/install-git-hooks.sh
EOF
  exit 1
fi

HOOKS_DIR="$GIT_DIR/hooks"
mkdir -p "$HOOKS_DIR"

# --- Hook list ---------------------------------------------------------------
HOOKS=(commit-msg pre-push)

# --- Execute action ----------------------------------------------------------
case "$MODE" in
  symlink|copy)
    for hook in "${HOOKS[@]}"; do
      src="$SOURCE_DIR/$hook"
      dest="$HOOKS_DIR/$hook"

      if [ ! -f "$src" ]; then
        printf 'WARNING: source hook missing, skipping: %s\n' "$src" >&2
        continue
      fi

      # Back up any existing hook that isn't already ours.
      if [ -e "$dest" ] && [ ! -L "$dest" ]; then
        backup="$dest.bak-$(date +%Y%m%d-%H%M%S)"
        mv "$dest" "$backup"
        printf 'Backed up existing %s -> %s\n' "$dest" "$backup"
      elif [ -L "$dest" ]; then
        rm "$dest"
      fi

      if [ "$MODE" = "symlink" ]; then
        ln -s "$src" "$dest"
        printf 'Symlinked %-15s -> %s\n' "$hook" "$src"
      else
        cp "$src" "$dest"
        printf 'Copied    %-15s (from %s)\n' "$hook" "$src"
      fi

      chmod +x "$dest"
    done
    printf '\nDone. Hooks installed in %s\n' "$HOOKS_DIR"
    printf 'Test commit-msg:  git commit --allow-empty -m "bad message" (should fail)\n'
    printf 'Test pre-push:    git push origin main (should fail; use --no-verify only in emergencies)\n'
    ;;

  uninstall)
    removed=0
    for hook in "${HOOKS[@]}"; do
      dest="$HOOKS_DIR/$hook"
      if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$SOURCE_DIR/$hook" ]; then
        rm "$dest"
        printf 'Removed symlink %s\n' "$dest"
        removed=$((removed + 1))
      elif [ -f "$dest" ] && cmp -s "$dest" "$SOURCE_DIR/$hook" 2>/dev/null; then
        rm "$dest"
        printf 'Removed copy   %s\n' "$dest"
        removed=$((removed + 1))
      elif [ -e "$dest" ]; then
        printf 'Skipped (not a skill hook): %s\n' "$dest"
      fi
    done
    printf '\nUninstall complete. %d hook(s) removed.\n' "$removed"
    ;;
esac
