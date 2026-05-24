#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# create-issue.sh — Create a GitHub issue with auto-detected labels
#
# Usage:
#   bash scripts/create-issue.sh --title "..." --body-file <path> --type <type> [options]
#
# Required:
#   --title         Issue title
#   --body-file     Path to markdown file containing the issue body
#   --type          Issue type: feature, bug, refactor, chore, docs
#
# Optional:
#   --priority      Priority level: critical, high, medium, low (default: medium)
#   --assignee      GitHub username to assign (default: @me)
#   --milestone     Milestone name to assign
#   --dry-run       Print the command without executing
#
# Examples:
#   bash scripts/create-issue.sh \
#     --title "[Feature] Add JWT refresh token" \
#     --body-file /tmp/issue.md \
#     --type feature \
#     --priority high
#
#   bash scripts/create-issue.sh \
#     --title "[Bug] Login crash on uppercase email" \
#     --body-file /tmp/issue.md \
#     --type bug \
#     --priority critical \
#     --assignee "john-doe"
# =============================================================================

# --- Defaults ----------------------------------------------------------------
PRIORITY="medium"
ASSIGNEE="@me"
MILESTONE=""
DRY_RUN=false
TITLE=""
BODY_FILE=""
TYPE=""

# --- Parse arguments ---------------------------------------------------------
while [[ $# -gt 0 ]]; do
  case "$1" in
    --title)      TITLE="$2"; shift 2 ;;
    --body-file)  BODY_FILE="$2"; shift 2 ;;
    --type)       TYPE="$2"; shift 2 ;;
    --priority)   PRIORITY="$2"; shift 2 ;;
    --assignee)   ASSIGNEE="$2"; shift 2 ;;
    --milestone)  MILESTONE="$2"; shift 2 ;;
    --dry-run)    DRY_RUN=true; shift ;;
    --help)
      sed -n '3,/^# ====/p' "$0" | head -n -1 | sed 's/^# \?//'
      exit 0
      ;;
    *)
      echo "Error: Unknown argument '$1'"
      echo "Usage: bash scripts/create-issue.sh --help"
      exit 1
      ;;
  esac
done

# --- Validate required arguments ---------------------------------------------
if [[ -z "$TITLE" ]]; then
  echo "Error: --title is required."
  echo "Usage: bash scripts/create-issue.sh --title \"...\" --body-file <path> --type <type>"
  exit 1
fi

if [[ -z "$BODY_FILE" ]]; then
  echo "Error: --body-file is required."
  echo "Usage: bash scripts/create-issue.sh --title \"...\" --body-file <path> --type <type>"
  exit 1
fi

if [[ ! -f "$BODY_FILE" ]]; then
  echo "Error: Body file not found: $BODY_FILE"
  exit 1
fi

if [[ -z "$TYPE" ]]; then
  echo "Error: --type is required. Options: feature, bug, refactor, chore, docs"
  exit 1
fi

# --- Validate type -----------------------------------------------------------
VALID_TYPES="feature bug refactor chore docs"
if ! echo "$VALID_TYPES" | grep -qw "$TYPE"; then
  echo "Error: Invalid type '$TYPE'. Options: $VALID_TYPES"
  exit 1
fi

# --- Validate priority -------------------------------------------------------
VALID_PRIORITIES="critical high medium low"
if ! echo "$VALID_PRIORITIES" | grep -qw "$PRIORITY"; then
  echo "Error: Invalid priority '$PRIORITY'. Options: $VALID_PRIORITIES"
  exit 1
fi

# --- Check gh auth -----------------------------------------------------------
if ! gh auth status &>/dev/null; then
  echo "Error: GitHub CLI is not authenticated. Run 'gh auth login' first."
  exit 1
fi

# --- Build labels ------------------------------------------------------------
LABELS="${TYPE},priority:${PRIORITY},status:ready"

# --- Build command -----------------------------------------------------------
CMD=(gh issue create --title "$TITLE" --body-file "$BODY_FILE" --label "$LABELS" --assignee "$ASSIGNEE")

if [[ -n "$MILESTONE" ]]; then
  CMD+=(--milestone "$MILESTONE")
fi

# --- Execute or dry-run ------------------------------------------------------
if [[ "$DRY_RUN" == true ]]; then
  echo "[dry-run] Would execute:"
  echo "  ${CMD[*]}"
  exit 0
fi

echo "Creating issue..."
ISSUE_URL=$("${CMD[@]}")

if [[ -n "$ISSUE_URL" ]]; then
  echo "Issue created successfully: $ISSUE_URL"

  # Extract issue number from URL
  ISSUE_NUMBER=$(echo "$ISSUE_URL" | grep -oE '[0-9]+$')
  echo ""
  echo "Next steps:"
  echo "  1. Create branch: git checkout develop && git pull origin develop"

  # Determine branch prefix
  case "$TYPE" in
    feature) PREFIX="feature" ;;
    bug)     PREFIX="bugfix" ;;
    refactor) PREFIX="refactor" ;;
    chore)   PREFIX="chore" ;;
    docs)    PREFIX="docs" ;;
  esac

  # Generate slug from title (lowercase, remove prefix tag, replace spaces with hyphens)
  SLUG=$(echo "$TITLE" | sed 's/\[.*\] *//' | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd 'a-z0-9-' | head -c 40)

  echo "  2. Create branch: git checkout -b ${PREFIX}/${ISSUE_NUMBER}-${SLUG}"
  echo "  3. Start implementation"
else
  echo "Error: Failed to create issue."
  exit 1
fi
