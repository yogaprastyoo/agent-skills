#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# setup-repo.sh — Initialize a GitHub repository with best practices
#
# Usage:
#   bash scripts/setup-repo.sh --name <repo-name> --stack <stack> [options]
#
# Required:
#   --name          Repository name
#   --stack         Project stack: node, python, go, multi
#
# Optional:
#   --visibility    Repository visibility: public, private (default: private)
#   --org           GitHub organization (default: personal account)
#   --description   Repository description
#   --license       License type: mit, apache-2.0, gpl-3.0 (default: mit)
#   --dry-run       Print commands without executing
#
# Examples:
#   bash scripts/setup-repo.sh --name my-api --stack node
#   bash scripts/setup-repo.sh --name ml-service --stack python --org my-company --visibility public
# =============================================================================

# --- Defaults ----------------------------------------------------------------
VISIBILITY="private"
ORG=""
DESCRIPTION=""
LICENSE="mit"
DRY_RUN=false
NAME=""
STACK=""
SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"

# --- Parse arguments ---------------------------------------------------------
while [[ $# -gt 0 ]]; do
  case "$1" in
    --name)         NAME="$2"; shift 2 ;;
    --stack)        STACK="$2"; shift 2 ;;
    --visibility)   VISIBILITY="$2"; shift 2 ;;
    --org)          ORG="$2"; shift 2 ;;
    --description)  DESCRIPTION="$2"; shift 2 ;;
    --license)      LICENSE="$2"; shift 2 ;;
    --dry-run)      DRY_RUN=true; shift ;;
    --help)
      sed -n '3,/^# ====/p' "$0" | head -n -1 | sed 's/^# \?//'
      exit 0
      ;;
    *)
      echo "Error: Unknown argument '$1'"
      echo "Usage: bash scripts/setup-repo.sh --help"
      exit 1
      ;;
  esac
done

# --- Validate ----------------------------------------------------------------
if [[ -z "$NAME" ]]; then
  echo "Error: --name is required."
  exit 1
fi

if [[ -z "$STACK" ]]; then
  echo "Error: --stack is required. Options: node, python, go, multi"
  exit 1
fi

VALID_STACKS="node python go multi"
if ! echo "$VALID_STACKS" | grep -qw "$STACK"; then
  echo "Error: Invalid stack '$STACK'. Options: $VALID_STACKS"
  exit 1
fi

if ! gh auth status &>/dev/null; then
  echo "Error: GitHub CLI is not authenticated. Run 'gh auth login' first."
  exit 1
fi

# --- Helper: run or dry-run --------------------------------------------------
run() {
  if [[ "$DRY_RUN" == true ]]; then
    echo "[dry-run] $*"
  else
    eval "$@"
  fi
}

# --- Step 1: Create repository -----------------------------------------------
echo "=== Step 1: Creating repository ==="

REPO_PATH="$NAME"
if [[ -n "$ORG" ]]; then
  REPO_PATH="${ORG}/${NAME}"
fi

CMD="gh repo create $REPO_PATH --$VISIBILITY --clone"
if [[ -n "$DESCRIPTION" ]]; then
  CMD="$CMD --description \"$DESCRIPTION\""
fi
run "$CMD"

if [[ "$DRY_RUN" == false ]]; then
  cd "$NAME"
fi

# --- Step 2: Set up develop branch -------------------------------------------
echo ""
echo "=== Step 2: Setting up develop branch ==="

run "git checkout -b develop"
run "git push -u origin develop"
run "gh repo edit --default-branch develop"

# --- Step 3: Generate .gitignore ---------------------------------------------
echo ""
echo "=== Step 3: Generating .gitignore ==="

generate_gitignore() {
  case "$1" in
    node)
      cat << 'GITIGNORE'
# Dependencies
node_modules/

# Build output
dist/
build/
.next/
out/

# Environment & Secrets
.env
.env.local
.env.*.local

# Logs
*.log
npm-debug.log*
yarn-debug.log*

# Testing
coverage/

# IDE & Editor
.vscode/
.idea/
*.swp
*.swo

# OS files
.DS_Store
Thumbs.db

# Cache
.cache/
.turbo/
.eslintcache
GITIGNORE
      ;;
    python)
      cat << 'GITIGNORE'
# Virtual environments
venv/
.venv/
env/

# Byte-compiled files
__pycache__/
*.py[cod]
*$py.class

# Distribution
dist/
build/
*.egg-info/

# Environment & Secrets
.env
.env.local

# Testing
.pytest_cache/
.coverage
htmlcov/

# IDE & Editor
.vscode/
.idea/
*.swp
*.swo

# OS files
.DS_Store
Thumbs.db
GITIGNORE
      ;;
    go)
      cat << 'GITIGNORE'
# Binary output
bin/
*.exe
*.dll
*.so
*.dylib

# Test binary
*.test

# Environment & Secrets
.env

# IDE & Editor
.vscode/
.idea/
*.swp

# OS files
.DS_Store
Thumbs.db
GITIGNORE
      ;;
    multi)
      cat << 'GITIGNORE'
# === Node.js ===
node_modules/
dist/

# === Python ===
__pycache__/
venv/

# === Shared ===
.env
.env.local
.DS_Store
Thumbs.db
.vscode/
.idea/
*.log
GITIGNORE
      ;;
  esac
}

if [[ "$DRY_RUN" == false ]]; then
  generate_gitignore "$STACK" > .gitignore
  echo "Generated .gitignore for $STACK"
else
  echo "[dry-run] Would generate .gitignore for $STACK"
fi

# --- Step 4: Create README.md -----------------------------------------------
echo ""
echo "=== Step 4: Creating README.md ==="

if [[ "$DRY_RUN" == false ]]; then
  if [[ -f "$SKILL_DIR/assets/readme-template.md" ]]; then
    cp "$SKILL_DIR/assets/readme-template.md" README.md
    sed -i "s/# Project Name/# $NAME/" README.md
    echo "Created README.md from template"
  else
    echo "# $NAME" > README.md
    echo "" >> README.md
    echo "<!-- Add project description here -->" >> README.md
    echo "Created basic README.md"
  fi
else
  echo "[dry-run] Would create README.md"
fi

# --- Step 5: Create .github directory ----------------------------------------
echo ""
echo "=== Step 5: Setting up .github templates ==="

if [[ "$DRY_RUN" == false ]]; then
  mkdir -p .github/ISSUE_TEMPLATE

  if [[ -f "$SKILL_DIR/assets/pr-template.md" ]]; then
    cp "$SKILL_DIR/assets/pr-template.md" .github/pull_request_template.md
    echo "Created PR template"
  fi

  if [[ -f "$SKILL_DIR/assets/issue-template-feature.md" ]]; then
    cp "$SKILL_DIR/assets/issue-template-feature.md" .github/ISSUE_TEMPLATE/feature.md
    echo "Created feature issue template"
  fi

  if [[ -f "$SKILL_DIR/assets/issue-template-bug.md" ]]; then
    cp "$SKILL_DIR/assets/issue-template-bug.md" .github/ISSUE_TEMPLATE/bug.md
    echo "Created bug issue template"
  fi
else
  echo "[dry-run] Would create .github templates"
fi

# --- Step 6: Initial commit --------------------------------------------------
echo ""
echo "=== Step 6: Initial commit ==="

run "git add ."
run "git commit -m 'chore: initial project setup

- Add .gitignore for $STACK
- Add README.md
- Add PR template
- Add issue templates'"

run "git push -u origin develop"

# --- Summary -----------------------------------------------------------------
echo ""
echo "=== Setup complete ==="
echo "Repository: $REPO_PATH"
echo "Default branch: develop"
echo "Stack: $STACK"
echo "Visibility: $VISIBILITY"
echo ""
echo "Next steps:"
echo "  1. Configure branch protection rules"
echo "  2. Add CODEOWNERS (if team project)"
echo "  3. Set up CI/CD (see references/actions.md)"
echo "  4. Create your first issue and start coding"
