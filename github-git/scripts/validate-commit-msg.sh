#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# validate-commit-msg.sh — Validate conventional commit message format
#
# Usage:
#   bash scripts/validate-commit-msg.sh <commit-message>
#   bash scripts/validate-commit-msg.sh --file <path-to-commit-msg-file>
#   bash scripts/validate-commit-msg.sh --last
#
# Options:
#   <commit-message>   Commit message string to validate
#   --file <path>      Read commit message from file
#   --last             Validate the last commit in the current branch
#   --help             Show this help message
#
# Examples:
#   bash scripts/validate-commit-msg.sh "feat(auth): add JWT refresh token"
#   bash scripts/validate-commit-msg.sh --last
#   bash scripts/validate-commit-msg.sh --file .git/COMMIT_EDITMSG
#
# Exit codes:
#   0 — Valid commit message
#   1 — Invalid commit message
# =============================================================================

# --- Valid types -------------------------------------------------------------
VALID_TYPES="feat|fix|docs|style|refactor|test|chore|ci|perf"

# --- Parse input -------------------------------------------------------------
MSG=""

if [[ $# -eq 0 ]]; then
  echo "Error: No commit message provided."
  echo "Usage: bash scripts/validate-commit-msg.sh \"<commit-message>\""
  echo "       bash scripts/validate-commit-msg.sh --last"
  echo "       bash scripts/validate-commit-msg.sh --help"
  exit 1
fi

case "$1" in
  --help)
    sed -n '3,/^# ====/p' "$0" | head -n -1 | sed 's/^# \?//'
    exit 0
    ;;
  --file)
    if [[ -z "${2:-}" ]]; then
      echo "Error: --file requires a path argument."
      exit 1
    fi
    if [[ ! -f "$2" ]]; then
      echo "Error: File not found: $2"
      exit 1
    fi
    MSG=$(head -n 1 "$2")
    ;;
  --last)
    if ! git rev-parse HEAD &>/dev/null; then
      echo "Error: Not in a git repository or no commits found."
      exit 1
    fi
    MSG=$(git log -1 --format="%s")
    ;;
  *)
    MSG="$1"
    ;;
esac

# --- Get first line only -----------------------------------------------------
FIRST_LINE=$(echo "$MSG" | head -n 1)
ERRORS=()

# --- Check 1: Format matches conventional commit pattern --------------------
# Pattern: type(scope)!: description  OR  type!: description  OR  type(scope): description  OR  type: description
PATTERN="^(${VALID_TYPES})(\(.+\))?\!?: .+$"

if ! echo "$FIRST_LINE" | grep -qE "$PATTERN"; then
  ERRORS+=("Format must be: <type>(<scope>): <description>")
  ERRORS+=("  Valid types: feat, fix, docs, style, refactor, test, chore, ci, perf")
  ERRORS+=("  Example: feat(auth): add JWT refresh token")
fi

# --- Check 2: First line length ---------------------------------------------
LINE_LENGTH=${#FIRST_LINE}
if [[ $LINE_LENGTH -gt 72 ]]; then
  ERRORS+=("First line is $LINE_LENGTH characters (max 72).")
fi

# --- Check 3: Description should not start with uppercase --------------------
DESCRIPTION=$(echo "$FIRST_LINE" | sed -E "s/^(${VALID_TYPES})(\(.+\))?\!?: //")
if echo "$DESCRIPTION" | grep -qE "^[A-Z]"; then
  ERRORS+=("Description should not start with uppercase: '$DESCRIPTION'")
  ERRORS+=("  Use: '$(echo "$DESCRIPTION" | sed 's/^./\L&/')'")
fi

# --- Check 4: Description should not end with a period -----------------------
if echo "$DESCRIPTION" | grep -qE '\.$'; then
  ERRORS+=("Description should not end with a period.")
fi

# --- Check 5: Description should use imperative mood hints -------------------
if echo "$DESCRIPTION" | grep -qE "^(added|fixed|updated|removed|changed|created|deleted) "; then
  WORD=$(echo "$DESCRIPTION" | awk '{print $1}')
  ERRORS+=("Use imperative mood: '$WORD' should be '$(echo "$WORD" | sed 's/ed$//' | sed 's/d$//')'")
  ERRORS+=("  Example: 'add' not 'added', 'fix' not 'fixed'")
fi

# --- Output results ----------------------------------------------------------
if [[ ${#ERRORS[@]} -eq 0 ]]; then
  echo "✓ Valid commit message: $FIRST_LINE"
  exit 0
else
  echo "✗ Invalid commit message: $FIRST_LINE"
  echo ""
  for ERROR in "${ERRORS[@]}"; do
    echo "  $ERROR"
  done
  exit 1
fi
