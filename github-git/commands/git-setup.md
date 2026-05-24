---
description: Initialize a new repository following the team's conventions — gitignore, README, LICENSE, branch protection
argument-hint: <repo-name> [--private]
---

# /git-setup

Bootstrap a new GitHub repository with the team's defaults: `develop` as the default branch, stack-appropriate `.gitignore`, README template, MIT license, and interactive branch protection setup.

## What this command does

1. Parses `$ARGUMENTS` for the repo name and optional `--private` flag
2. Detects or asks about the project stack (Node, Python, Go, Flutter, .NET, etc.)
3. Creates the GitHub repo with `gh repo create`
4. Generates `.gitignore`, `README.md`, `LICENSE` from templates
5. Configures `develop` as the default branch
6. Interactively offers branch protection options
7. Makes the initial commit and push

## Workflow

When invoked:

### Step 1 — Parse arguments

`$ARGUMENTS` parsing:
- First word → repo name (kebab-case, required)
- `--private` flag → repo is private (default: public)
- `--org <name>` flag → create under an organization

If repo name is missing, ask the user.

Validate repo name: lowercase, alphanumeric + hyphens only, no spaces.

### Step 2 — Verify prerequisites

```bash
gh auth status
git --version
```

Stop if either fails.

Check repo doesn't already exist:

```bash
gh repo view <owner>/<name> 2>&1 | head -1
```

If it does, ask: continue with different name, or clone existing?

### Step 3 — Detect or ask stack

Detect from current directory if invoked inside a project:

| File present | Stack |
|--------------|-------|
| `package.json` | Node.js / TypeScript |
| `requirements.txt`, `pyproject.toml`, `setup.py` | Python |
| `go.mod` | Go |
| `pubspec.yaml` | Flutter / Dart |
| `*.csproj`, `*.sln` | .NET |
| `Gemfile` | Ruby |
| `pom.xml`, `build.gradle` | Java |
| `Cargo.toml` | Rust |

If invoked in an empty directory, ask the user:

> "Stack apa untuk repo ini? (node / python / go / flutter / dotnet / lainnya)"

### Step 4 — Create the repo

```bash
gh repo create <owner>/<name> \
  --<public|private> \
  --description "<description from user>" \
  --clone
cd <name>
```

Or if the user is already in an existing local directory:

```bash
gh repo create <owner>/<name> \
  --<public|private> \
  --description "<description>" \
  --source . \
  --remote origin
```

### Step 5 — Set up develop branch

```bash
git checkout -b develop
git push -u origin develop
gh repo edit --default-branch develop
```

### Step 6 — Generate .gitignore

Read `~/.claude/skills/github-git/references/repo-setup.md` for stack-specific templates. Write `.gitignore` matching the detected stack. For multi-stack projects, combine the relevant sections with `# === <Stack> ===` headers.

### Step 7 — Generate README.md

Copy from `~/.claude/skills/github-git/assets/readme-template.md`. Ask the user to fill:
- Project name and tagline
- Short description
- Prerequisites
- Install steps
- Usage example

Do not invent project-specific content.

### Step 8 — Add LICENSE

Default: MIT (unless user specifies otherwise). Generate the file with the user's name and current year.

For non-MIT licenses, ask:

| License | When |
|---------|------|
| MIT | Maximum freedom, minimal restrictions (default) |
| Apache 2.0 | Need patent protection |
| GPL 3.0 | Want derivatives to remain open source |
| Proprietary | Internal/commercial — no LICENSE file |

### Step 9 — Configure branch protection (interactive)

Read `~/.claude/skills/github-git/references/repo-setup.md` — "Configure Branch Protection" section.

Present the full options table (in Indonesian — user-facing prompt). Wait for the user's selection. Only apply what they approve.

Skip this step if the repo is private and the user lacks GitHub Pro (free private repos don't support branch protection).

### Step 10 — Initial commit and push

```bash
git add .gitignore README.md LICENSE
git commit -m "chore: initial project setup

- Add .gitignore for <stack>
- Add README.md
- Add LICENSE (<license>)
- Configure default branch as develop"
git push origin develop
```

### Step 11 — Report

```
Repository ready: https://github.com/<owner>/<name>
Default branch: develop
Branch protection: <list of applied options or "skipped">

Next steps:
1. Create your first issue: /git-issue
2. Branch from develop: git checkout -b feature/1-<slug>
3. Implement and commit: /git-commit
4. Open a PR: /git-pr
```

## Constraints

- MUST set `develop` as the default branch
- MUST NOT skip the branch protection question (just don't apply if user opts out)
- MUST use the assets templates — do not invent README/LICENSE content
- MUST NOT include `Co-Authored-By: Claude`, `Co-Authored-By: Antigravity`, AI mentions, or "Generated with Claude" / "Generated with Antigravity" in any generated file
- MUST verify repo doesn't exist before creating
- MUST use HTTPS remote, not SSH, unless the user explicitly asks (matches the gh CLI default)
- Initial commit message follows conventional commits (`chore: initial project setup`)

## Example invocations

```
/git-setup my-new-app
/git-setup my-internal-tool --private
/git-setup team-utils --org pens-pbl
```

## See also

- `references/repo-setup.md` — full setup checklist, stack-specific gitignore, branch protection options
- `assets/readme-template.md` — README template
- `scripts/setup-repo.sh` — non-interactive setup script (alternative)
