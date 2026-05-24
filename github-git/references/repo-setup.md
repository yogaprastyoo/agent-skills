# Repository Setup

Complete guide for initializing a new GitHub repository with best practices.

---

## Workflow

1. Create repository on GitHub
2. Set default branch to `develop`
3. Generate `.gitignore` based on project stack
4. Create README.md from template
5. Add LICENSE
6. Configure branch protection rules
7. Set up CODEOWNERS (if team project)

---

## Step 1: Create Repository

### Via GitHub CLI

```bash
gh repo create <repo-name> --public --clone
# or for private repo
gh repo create <repo-name> --private --clone
```

### Via GitHub CLI (with org)

```bash
gh repo create <org-name>/<repo-name> --private --clone
```

After creation, immediately set default branch to `develop`:

```bash
cd <repo-name>
git checkout -b develop
git push -u origin develop
gh repo edit --default-branch develop
```

---

## Step 2: Generate .gitignore

Detect the project stack first, then generate the appropriate `.gitignore`.

### Node.js / TypeScript

```gitignore
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
yarn-error.log*

# Testing
coverage/

# IDE & Editor
.vscode/
.idea/
*.swp
*.swo
*~

# OS files
.DS_Store
Thumbs.db

# Cache
.cache/
.turbo/
.eslintcache
```

### Python

```gitignore
# Virtual environments
venv/
.venv/
env/

# Byte-compiled files
__pycache__/
*.py[cod]
*$py.class
*.pyo

# Distribution
dist/
build/
*.egg-info/
*.egg

# Environment & Secrets
.env
.env.local

# Testing
.pytest_cache/
.coverage
htmlcov/
.tox/

# IDE & Editor
.vscode/
.idea/
*.swp
*.swo

# OS files
.DS_Store
Thumbs.db

# Jupyter
.ipynb_checkpoints/
```

### Go

```gitignore
# Binary output
bin/
*.exe
*.exe~
*.dll
*.so
*.dylib

# Test binary
*.test

# Go workspace
go.work

# Environment & Secrets
.env

# IDE & Editor
.vscode/
.idea/
*.swp

# OS files
.DS_Store
Thumbs.db

# Vendor (if not committing dependencies)
# vendor/
```

### Multi-stack projects

Combine relevant sections and add a comment header for each stack:

```gitignore
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
```

---

## Step 3: Create README.md

Use the template from `assets/readme-template.md`. At minimum, a README must include:

- Project name and short description
- Prerequisites
- Installation steps
- Usage examples
- License

For detailed README template, copy from `assets/readme-template.md`:

```bash
cp assets/readme-template.md README.md
```

Then fill in the project-specific details.

---

## Step 4: Add LICENSE

Choose a license based on project intent:

| License | Use When |
|---------|----------|
| MIT | Maximum freedom, minimal restrictions |
| Apache 2.0 | Need patent protection |
| GPL 3.0 | Want derivatives to remain open source |
| Proprietary | Internal/commercial project |

Generate via GitHub CLI:

```bash
gh repo edit --enable-wiki=false
# License is typically selected during repo creation on GitHub
# Or create manually:
# Visit https://choosealicense.com/ for full license text
```

---

## Step 5: Configure Branch Protection

**IMPORTANT — Ask the user before applying any protection.**

Before running any branch protection commands, present the list below and ask the user (Indonesian — user-facing prompt):

> "Berikut daftar branch protection yang tersedia. Mana saja yang ingin diaktifkan?"

Present each option with its explanation, then wait for user confirmation. Only apply what the user approves.

---

### Available Protection Options

| # | Option | Description | When to Use |
|---|--------|-------------|-------------|
| 1 | **Require PR review (1 approver)** | Every change must be reviewed by at least one person before merge. Prevents code from landing without verification. | Solo project with self-review, or small teams |
| 2 | **Require PR review (2 approvers)** | Same as above but requires 2 reviewers. Stricter, suited for production branches. | Teams with more than 2 developers |
| 3 | **Require status checks (CI must pass)** | Merge only allowed if CI/CD (tests, linting, build) succeeds. Prevents broken code on the main branch. | Projects with an existing CI pipeline (GitHub Actions) |
| 4 | **Require branch up-to-date** | Branch must be in sync with the target branch before merge. Prevents hidden conflicts. | Enable together with option #3 |
| 5 | **Block force push** | Prohibits `git push --force` to this branch. Protects history from accidental deletion. | Almost always recommended |
| 6 | **Block branch deletion** | Branch cannot be deleted via GitHub. Protects main branches from accidental deletion. | Almost always recommended |
| 7 | **Enforce admins** | Admins must also follow these protection rules (no bypass). | Teams requiring strict compliance |
| 8 | **Restrict who can merge** | Only specific users/teams may merge into this branch. | Teams with a clear maintainer hierarchy |
| 9 | **Require conversation resolution** | All PR comments must be resolved before merge. | Teams that want all feedback addressed |
| 10 | **Dismiss stale reviews** | Pushing new commits after approval dismisses it and requires re-review. | Teams that need reviews always up-to-date |

---

### After user confirmation, apply only the selected options:

```bash
# Example: apply options 1, 3, 4, 5, 6
gh api repos/{owner}/{repo}/branches/{branch}/protection \
  --method PUT \
  --field "required_pull_request_reviews[required_approving_review_count]=1" \
  --field "required_status_checks[strict]=true" \
  --field "required_status_checks[contexts][]=ci" \
  --field "enforce_admins=false" \
  --field "restrictions=null"
```

### Field mapping per option:

| Option | Field |
|--------|-------|
| PR review (1) | `required_pull_request_reviews[required_approving_review_count]=1` |
| PR review (2) | `required_pull_request_reviews[required_approving_review_count]=2` |
| Status checks | `required_status_checks[contexts][]=ci` |
| Branch up-to-date | `required_status_checks[strict]=true` |
| Block force push | automatically active when protection is created |
| Block deletion | `allow_deletions=false` |
| Enforce admins | `enforce_admins=true` |
| Dismiss stale reviews | `required_pull_request_reviews[dismiss_stale_reviews]=true` |
| Conversation resolution | `required_conversation_resolution=true` |

---

## Step 6: Set Up CODEOWNERS

Create `.github/CODEOWNERS` to auto-assign reviewers:

```bash
mkdir -p .github
```

Example CODEOWNERS file:

```
# Default owner for everything
* @team-lead

# Frontend code
/src/frontend/ @frontend-team
*.tsx @frontend-team
*.css @frontend-team

# Backend code
/src/api/ @backend-team
/src/services/ @backend-team

# Infrastructure
/docker/ @devops-team
/.github/workflows/ @devops-team
Dockerfile @devops-team

# Documentation
/docs/ @tech-writer
*.md @tech-writer
```

---

## Step 7: Initial Commit and Push

After all setup is complete:

```bash
git add .
git commit -m "chore: initial project setup

- Add .gitignore for [stack]
- Add README.md
- Add LICENSE
- Configure branch protection
- Add CODEOWNERS"

git push -u origin develop
```

---

## Validation Checklist

Before considering setup complete, verify:

- [ ] Repository created on GitHub
- [ ] Default branch set to `develop`
- [ ] `.gitignore` matches project stack
- [ ] `README.md` has project name, install steps, and usage
- [ ] `LICENSE` file present
- [ ] Branch protection enabled on `develop` and `main`
- [ ] `CODEOWNERS` configured (if team project)
- [ ] Initial commit pushed to `develop`

---

## Gotchas

- **Default branch**: GitHub defaults to `main`. Always change default to `develop` immediately after repo creation with `gh repo edit --default-branch develop`.
- **Empty repo push**: You cannot set branch protection on a branch that does not exist yet. Push at least one commit to `develop` before configuring protection.
- **.gitignore after commit**: If you forgot to add `.gitignore` before the first commit, tracked files will remain tracked. Clean up with `git rm -r --cached .` then re-add and commit.
- **CODEOWNERS location**: GitHub looks for CODEOWNERS in `.github/`, `docs/`, or root. Prefer `.github/` for consistency.
- **License selection**: Adding a license after initial commit requires a new commit. It is easier to select the license during repo creation.
