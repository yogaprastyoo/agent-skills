#!/usr/bin/env bash
# guard-push-to-main.sh
#
# Claude Code PreToolUse hook (matcher: Bash).
# Blocks `git push` commands that target main/master directly,
# enforcing the team's PR-via-develop workflow.
#
# Hook contract:
#   - Reads JSON from stdin describing the tool call
#   - Exit 0  => allow the tool call to proceed
#   - Exit 2  => block the tool call; stderr is shown to the user/Claude
#
# Wiring example (in ~/.claude/settings.json):
#   {
#     "hooks": {
#       "PreToolUse": [
#         {
#           "matcher": "Bash",
#           "hooks": [
#             { "type": "command", "command": "$HOME/.agents/skills/github-git/hooks/guard-push-to-main.sh" }
#           ]
#         }
#       ]
#     }
#   }

set -euo pipefail

# Read the entire JSON payload from stdin
INPUT=$(cat)

# Extract the command string. Use jq if available, else a minimal fallback.
if command -v jq >/dev/null 2>&1; then
  CMD=$(printf '%s' "$INPUT" | jq -r '.tool_input.command // ""')
else
  # Minimal fallback parser — extracts the first "command" string value.
  CMD=$(printf '%s' "$INPUT" | grep -oE '"command"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed -E 's/^"command"[[:space:]]*:[[:space:]]*"//;s/"$//')
fi

# If no command (or this isn't a Bash tool call), allow.
[ -z "$CMD" ] && exit 0

# Normalize whitespace for the match.
NORMALIZED=$(printf '%s' "$CMD" | tr '\n' ' ' | tr -s ' ')

# Match patterns that push directly to main/master:
#   git push origin main
#   git push origin master
#   git push <remote> main
#   git push -u origin main
#   git push --force origin main         (extra dangerous)
#   git push origin HEAD:main            (sneaky)
if printf '%s' "$NORMALIZED" | grep -qE '\bgit[[:space:]]+push\b[^|&;]*\b(main|master)\b'; then
  cat >&2 <<'EOF'
[guard-push-to-main] BLOCKED

This command would push directly to `main`/`master`, which violates the
github-git skill's workflow. Production branches receive changes through
a PR from `develop` (or hotfix/release branches) — never a direct push.

Correct path:
  1. Make sure you are on a feature/bugfix/hotfix branch
  2. Push that branch:    git push -u origin <branch-name>
  3. Open a PR:           /git-pr   (or `gh pr create --base develop`)

If this is a release and you really need to push to main, perform the
release via a PR (release branch → main) rather than a direct push.

To bypass this hook for a specific session (e.g. emergency hotfix when
GitHub is down), temporarily disable it in ~/.claude/settings.json.
EOF
  exit 2
fi

exit 0
