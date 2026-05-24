#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# generate-changelog.sh — Generate changelog from conventional commits
#
# Usage:
#   bash scripts/generate-changelog.sh [options]
#
# Options:
#   --from <tag>     Start tag (default: latest tag or first commit)
#   --to <ref>       End reference (default: HEAD)
#   --version <ver>  Version for the new section (default: Unreleased)
#   --output <file>  Output file (default: stdout)
#   --help           Show this help message
#
# Examples:
#   bash scripts/generate-changelog.sh
#   bash scripts/generate-changelog.sh --from v1.0.0 --version v1.1.0
#   bash scripts/generate-changelog.sh --from v1.0.0 --to v1.1.0 --output CHANGELOG.md
# =============================================================================

# --- Defaults ----------------------------------------------------------------
FROM=""
TO="HEAD"
VERSION="Unreleased"
OUTPUT=""

# --- Parse arguments ---------------------------------------------------------
while [[ $# -gt 0 ]]; do
  case "$1" in
    --from)     FROM="$2"; shift 2 ;;
    --to)       TO="$2"; shift 2 ;;
    --version)  VERSION="$2"; shift 2 ;;
    --output)   OUTPUT="$2"; shift 2 ;;
    --help)
      sed -n '3,/^# ====/p' "$0" | head -n -1 | sed 's/^# \?//'
      exit 0
      ;;
    *)
      echo "Error: Unknown argument '$1'"
      echo "Usage: bash scripts/generate-changelog.sh --help"
      exit 1
      ;;
  esac
done

# --- Validate git repo -------------------------------------------------------
if ! git rev-parse HEAD &>/dev/null; then
  echo "Error: Not in a git repository."
  exit 1
fi

# --- Determine range ---------------------------------------------------------
if [[ -z "$FROM" ]]; then
  FROM=$(git describe --tags --abbrev=0 2>/dev/null || git rev-list --max-parents=0 HEAD)
fi

RANGE="${FROM}..${TO}"
DATE=$(date +%Y-%m-%d)

# --- Collect commits by type -------------------------------------------------
declare -A SECTIONS
SECTIONS=(
  ["feat"]=""
  ["fix"]=""
  ["docs"]=""
  ["refactor"]=""
  ["perf"]=""
  ["test"]=""
  ["chore"]=""
  ["ci"]=""
  ["style"]=""
)

SECTION_TITLES=(
  ["feat"]="Features"
  ["fix"]="Bug Fixes"
  ["docs"]="Documentation"
  ["refactor"]="Refactoring"
  ["perf"]="Performance"
  ["test"]="Tests"
  ["chore"]="Chores"
  ["ci"]="CI/CD"
  ["style"]="Style"
)

BREAKING=""

while IFS= read -r COMMIT_LINE; do
  [[ -z "$COMMIT_LINE" ]] && continue

  HASH=$(echo "$COMMIT_LINE" | awk '{print $1}')
  MESSAGE=$(echo "$COMMIT_LINE" | cut -d' ' -f2-)
  SHORT_HASH="${HASH:0:7}"

  # Check for breaking change marker
  if echo "$MESSAGE" | grep -qE "^[a-z]+(\(.+\))?\!:"; then
    BREAKING+="- $MESSAGE ($SHORT_HASH)\n"
  fi

  # Extract type
  TYPE=$(echo "$MESSAGE" | grep -oE "^[a-z]+" || true)

  if [[ -n "$TYPE" && -n "${SECTIONS[$TYPE]+x}" ]]; then
    # Extract scope and description
    SCOPE=$(echo "$MESSAGE" | grep -oE "\(.+\)" | tr -d '()' || true)
    DESC=$(echo "$MESSAGE" | sed -E 's/^[a-z]+(\(.+\))?\!?: //')

    if [[ -n "$SCOPE" ]]; then
      SECTIONS[$TYPE]+="- **$SCOPE**: $DESC ($SHORT_HASH)\n"
    else
      SECTIONS[$TYPE]+="- $DESC ($SHORT_HASH)\n"
    fi
  fi
done < <(git log "$RANGE" --oneline --no-merges 2>/dev/null)

# --- Build changelog ---------------------------------------------------------
CHANGELOG=""
CHANGELOG+="## [$VERSION] - $DATE\n\n"

# Breaking changes first
if [[ -n "$BREAKING" ]]; then
  CHANGELOG+="### ⚠ Breaking Changes\n\n"
  CHANGELOG+="$BREAKING\n"
fi

# Sections in display order
DISPLAY_ORDER=("feat" "fix" "perf" "refactor" "docs" "test" "ci" "chore" "style")

for TYPE in "${DISPLAY_ORDER[@]}"; do
  if [[ -n "${SECTIONS[$TYPE]}" ]]; then
    CHANGELOG+="### ${SECTION_TITLES[$TYPE]}\n\n"
    CHANGELOG+="${SECTIONS[$TYPE]}\n"
  fi
done

# --- Output ------------------------------------------------------------------
if [[ -n "$OUTPUT" ]]; then
  if [[ -f "$OUTPUT" ]]; then
    # Prepend to existing changelog (after the first line if it's a header)
    EXISTING=$(cat "$OUTPUT")
    HEADER="# Changelog\n\n"

    if echo "$EXISTING" | head -n 1 | grep -q "^# "; then
      # File has a header, insert after it
      echo -e "${HEADER}$(echo -e "$CHANGELOG")$(echo "$EXISTING" | tail -n +2)" > "$OUTPUT"
    else
      echo -e "${HEADER}$(echo -e "$CHANGELOG")\n${EXISTING}" > "$OUTPUT"
    fi

    echo "Changelog updated: $OUTPUT"
  else
    echo -e "# Changelog\n\n$(echo -e "$CHANGELOG")" > "$OUTPUT"
    echo "Changelog created: $OUTPUT"
  fi
else
  echo -e "$CHANGELOG"
fi
