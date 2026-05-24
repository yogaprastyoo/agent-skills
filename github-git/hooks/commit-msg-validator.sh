#!/usr/bin/env bash
# commit-msg-validator.sh
#
# Claude Code PreToolUse hook (matcher: Bash).
# Validates that any `git commit -m "<message>"` invocation uses the
# Conventional Commits format. Rejects messages like "fix stuff",
# "wip", "update", or anything missing a proper type prefix.
#
# Hook contract:
#   - Reads JSON from stdin describing the tool call
#   - Exit 0  => allow
#   - Exit 2  => block; stderr is shown to the user/Claude
#
# Limitations:
#   - Only validates the inline `-m "<message>"` form. Commits via heredoc
#     or `-F <file>` pass through unchecked at this layer (the git-level
#     `commit-msg` hook covers those — install via scripts/install-git-hooks.sh).
#
# Wiring example (in ~/.claude/settings.json):
#   {
#     "hooks": {
#       "PreToolUse": [
#         {
#           "matcher": "Bash",
#           "hooks": [
#             { "type": "command", "command": "$HOME/.agents/skills/github-git/hooks/commit-msg-validator.sh" }
#           ]
#         }
#       ]
#     }
#   }

set -euo pipefail

INPUT=$(cat)

if command -v jq >/dev/null 2>&1; then
  CMD=$(printf '%s' "$INPUT" | jq -r '.tool_input.command // ""')
else
  CMD=$(printf '%s' "$INPUT" | grep -oE '"command"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed -E 's/^"command"[[:space:]]*:[[:space:]]*"//;s/"$//')
fi

[ -z "$CMD" ] && exit 0

NORMALIZED=$(printf '%s' "$CMD" | tr '\n' ' ' | tr -s ' ')

# Only inspect commands that look like `git commit ... -m ...`
if ! printf '%s' "$NORMALIZED" | grep -qE '\bgit[[:space:]]+commit\b'; then
  exit 0
fi

# Heredoc-based commit messages can't be inspected from the command string
# alone. Pass through and let the git-level commit-msg hook handle them.
if printf '%s' "$NORMALIZED" | grep -qE '<<-?[[:space:]]*'\''?EOF'\''?'; then
  exit 0
fi

# `-F <file>` form also defers to the git-level hook.
if printf '%s' "$NORMALIZED" | grep -qE '\b-F[[:space:]]+'; then
  exit 0
fi

# Extract the message after `-m`. Support both '...' and "..." quoting.
MSG=$(printf '%s' "$CMD" | perl -ne '
  if (/\bgit\s+commit\b.*?-m\s+("(?:[^"\\]|\\.)*"|'"'"'(?:[^'"'"'\\]|\\.)*'"'"')/) {
    my $m = $1;
    $m =~ s/^["'"'"']//;
    $m =~ s/["'"'"']$//;
    print $m;
  }
')

# If we could not parse out a message, allow (better to let git itself complain
# than to false-positive block).
[ -z "$MSG" ] && exit 0

# Validate the FIRST LINE only against Conventional Commits.
FIRST_LINE=$(printf '%s' "$MSG" | head -n 1)

# Conventional Commits regex:
#   <type>(<scope>)?!?: <description>
# Allowed types from references/branching-commits.md
CC_REGEX='^(feat|fix|docs|style|refactor|test|chore|ci|perf|revert)(\([a-z0-9._-]+\))?!?:[[:space:]].+'

if ! printf '%s' "$FIRST_LINE" | grep -qE "$CC_REGEX"; then
  cat >&2 <<EOF
[commit-msg-validator] BLOCKED

The commit message does not follow Conventional Commits format.

Expected:  <type>(<scope>): <description>
Got:       $FIRST_LINE

Valid types: feat, fix, docs, style, refactor, test, chore, ci, perf, revert
Optional scope:  feat(auth): ...
Breaking change: feat(api)!: ...

Examples:
  feat(auth): add JWT refresh token mechanism
  fix(api): handle null response from payment gateway
  refactor(payment): extract gateway adapter
  chore(deps): bump express to 4.19.0

See references/branching-commits.md for the full rules.

To bypass this hook for one commit (rare): temporarily disable it in
~/.claude/settings.json, then re-enable.
EOF
  exit 2
fi

# Enforce 72-character soft limit on the subject line.
SUBJECT_LEN=${#FIRST_LINE}
if [ "$SUBJECT_LEN" -gt 72 ]; then
  cat >&2 <<EOF
[commit-msg-validator] BLOCKED

The commit subject line is $SUBJECT_LEN characters — the limit is 72.

Subject:  $FIRST_LINE

Move detail into the commit body (separate from the subject by a blank line)
instead of cramming it into the first line.
EOF
  exit 2
fi

# Reject vague descriptions that pass the regex but are useless.
DESCRIPTION=$(printf '%s' "$FIRST_LINE" | sed -E 's/^[a-z]+(\([^)]+\))?!?:[[:space:]]+//')
if printf '%s' "$DESCRIPTION" | grep -qiE '^(stuff|things|update|updates|changes|wip|fix|work|misc)$'; then
  cat >&2 <<EOF
[commit-msg-validator] BLOCKED

The commit description is too vague: "$DESCRIPTION"

A commit message should answer "what does this change do?" specifically.
Examples of vague vs specific:

  BAD:   fix: stuff
  GOOD:  fix(auth): handle null user response from oauth callback

  BAD:   chore: update
  GOOD:  chore(deps): bump express from 4.18.2 to 4.19.0

  BAD:   refactor: changes
  GOOD:  refactor(payment): extract gateway adapter into its own module
EOF
  exit 2
fi

exit 0
