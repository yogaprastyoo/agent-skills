---
name: github-git
description: >
  Manages complete GitHub development workflow — from repository setup to release.
  Use this skill when working with Git or GitHub in any capacity: creating repositories,
  managing issues, branching, writing commits, creating pull requests, reviewing code,
  setting up GitHub Actions CI/CD, or managing releases. Trigger on any mention of
  'git', 'github', 'commit', 'branch', 'merge', 'pull request', 'PR', 'issue',
  'CI/CD', 'actions', 'workflow', '.gitignore', 'README', 'release', 'tag',
  'code review', 'changelog', or 'gh cli'. Also trigger when starting new features,
  fixing bugs, or refactoring code in a Git-managed project.
---

# GitHub Git Workflow Skill

## Goal

Standardize the complete GitHub development lifecycle:

**Setup → Issue → Branch → Implement → Commit → PR → Review → Merge → Release**

Every piece of work must be traceable — from issue to branch to PR to release.

---

## When To Use

Use this skill when:

- Setting up a new repository
- Starting a new feature or module
- Fixing a bug
- Refactoring code
- Creating or reviewing pull requests
- Any task involving Git or GitHub

---

## Prerequisites

- Git installed and configured (`git config --global user.name` / `user.email`)
- GitHub CLI installed and authenticated (`gh auth login`)
- Repository initialized or cloned

Verify setup before any workflow:

```bash
git --version && gh auth status
```

If `gh` is not authenticated, run `gh auth login` first. Everything else will fail without this.

---

## Core Workflow

Default branch is `develop`. All feature/bugfix branches are created from `develop` and merged back to `develop`. The `main` branch is reserved for production releases only — `develop` is merged into `main` when releasing.

```
┌─────────────┐
│  New Task    │
└──────┬──────┘
       ▼
┌─────────────┐
│ Create Issue │ ← Every task starts here
└──────┬──────┘
       ▼
┌──────────────┐
│ Create Branch│ ← Branch from develop
└──────┬───────┘
       ▼
┌──────────────┐
│  Implement   │ ← Follow acceptance criteria
└──────┬───────┘
       ▼
┌──────────────┐
│   Commit     │ ← Conventional commits
└──────┬───────┘
       ▼
┌──────────────┐
│  Create PR   │ ← PR into develop
└──────┬───────┘
       ▼
┌──────────────┐
│ Code Review  │ ← Review checklist
└──────┬───────┘
       ▼
┌──────────────┐
│    Merge     │ ← Merge into develop
└──────┬───────┘
       ▼
┌──────────────┐
│   Release    │ ← Merge develop → main, tag + changelog
└──────────────┘
```

---

## Core Rules

1. MUST create a GitHub issue before starting any work
2. MUST create a dedicated branch per issue
3. MUST use conventional commit format
4. MUST open a PR into `develop` — never push directly to `develop` or `main`
5. MUST link PR to its issue (`Closes #N`)
6. MUST pass CI checks before merging

---

## Available Commands

For explicit, repeatable workflows, prefer the slash commands shipped with this skill:

| Command | Purpose |
|---------|---------|
| `/git-issue` | Create a GitHub issue following the team template (Description, Context, API Response, Acceptance Criteria) |
| `/git-commit` | Analyze the current diff, auto-detect the commit type, and create a conventional commit |
| `/git-pr` | Open a PR from the current branch with auto-detected base, title, and labels |
| `/git-review` | Review a PR by number or URL using the checklist (correctness, security, performance, tests) |
| `/git-setup` | Initialize a new repository with `develop` default, stack-appropriate `.gitignore`, README, LICENSE, branch protection |

Each command is a self-contained playbook in `commands/` that reads the relevant reference file on demand. The commands enforce the same conventions as keyword-triggered usage — they're just more discoverable for the team.

---

## Decision Tree

### User wants to start a new project

→ Use `/git-setup` (or read `references/repo-setup.md` for full detail)

### User wants to create an issue

→ Use `/git-issue` (or read `references/issues.md` for the template)

### User wants to start a new feature

→ `/git-issue` to file the issue
→ Create branch from issue (read `references/branching-commits.md`)
→ Implement feature
→ `/git-commit` to commit with conventional format
→ `/git-pr` to open a PR

### User wants to fix a bug

→ `/git-issue` (type: `fix`) → branch `bugfix/<n>-<slug>` → fix → `/git-commit` → `/git-pr`

### User wants to commit current changes

→ Use `/git-commit` (auto-detects type, generates conventional message)

### User wants to open a PR

→ Use `/git-pr` (auto-detects base branch, derives title from linked issue)

### User wants to review a PR

→ Use `/git-review <pr-number>` (or read `references/code-review.md`)

### User asks about branching strategy

→ Read `references/branching-commits.md`
→ Recommend based on team size and deploy frequency

---

## Branch Naming Convention

Format:

```
{prefix}/{issue-number}-{slug}
```

Prefixes:
- `feature/` — new features or enhancements
- `bugfix/` — bug fixes
- `hotfix/` — urgent production fixes
- `refactor/` — code refactoring
- `docs/` — documentation only
- `ci/` — CI/CD changes

Examples:

```
feature/42-user-authentication
bugfix/15-fix-null-pointer-login
hotfix/78-patch-payment-crash
```

---

## Commit Message Format

Use **Conventional Commits**:

```
<type>(<scope>): <description>

[optional body]

[optional footer]
```

Types: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`, `ci`, `perf`

Quick examples:

```
feat(auth): add JWT refresh token mechanism
fix(api): handle null response from payment gateway
docs(readme): add installation instructions
chore(deps): bump express to 4.19.0
```

Rules:
- Imperative mood ("add", not "added")
- First line max 72 characters
- Body explains WHY, not WHAT (the diff shows what changed)
- Reference issue number in footer: `Closes #42`

---

## Gotchas

These are things that frequently go wrong — read before starting:

- **`gh` auth**: `gh issue create` and `gh pr create` silently fail or error if not authenticated. Always verify with `gh auth status` first.
- **package-lock.json conflicts**: Never resolve manually. Run `npm install` on the target branch after resolving other conflicts, then commit the regenerated lockfile.
- **Force push to protected branches**: This destroys history for everyone. Branch protection should block this, but if it's not set up yet, never run `git push --force` on `develop` or `main`.
- **Large files**: Git is not designed for large binary files. If you need to track them, set up Git LFS before committing. Removing large files after commit requires history rewriting (`git filter-branch` or `bfg`).
- **Secrets in commits**: If credentials are accidentally committed, rotating the secret is the only safe fix. Removing the file in a new commit does NOT remove it from history.
- **.gitignore timing**: `.gitignore` only affects untracked files. If a file is already tracked, adding it to `.gitignore` won't remove it. Run `git rm --cached <file>` first.
- **Detached HEAD**: If `git checkout` puts you in detached HEAD, you're on a commit, not a branch. Create a branch with `git checkout -b <branch-name>` before making changes.
- **Merge vs Rebase**: Use merge for shared branches (preserves history). Use rebase for local cleanup before PR (cleaner history). Never rebase commits that others have pulled.

---

## Constraints

- Do NOT implement without creating an issue first
- Do NOT skip branch creation — never commit directly on `develop` or `main`
- Do NOT mix multiple features in one branch
- Do NOT ignore acceptance criteria in the issue
- Do NOT merge without CI passing
- Do NOT force push to shared branches

## API Response in Issues — Mandatory

When creating an issue for a backend endpoint (one that returns a response body), the issue body MUST include an `## API Response` section with request and full response examples (success + every relevant error).

The detailed rules — envelope shape, per-endpoint structure, pagination, project-specific overrides — live in [`references/issues-api-response.md`](references/issues-api-response.md). Read that file before generating any issue for a backend endpoint.

Summary of the envelope (full spec in the reference):

```json
{ "success": true,  "message": "...", "data":   {} }    // success
{ "success": false, "message": "...", "errors": null }  // error
```

Place the `## API Response` section between `## Context` and `## Acceptance Criteria` in the issue body.

## PR and Issue Descriptions — Strict Rules

NEVER include any of the following in PR body, issue body, commit messages, or any GitHub content:
- `🤖 Generated with Claude Code`
- `Co-Authored-By: Claude`
- Any mention of Claude, AI, or automation tools

This applies to **all** Git and GitHub output: commit messages, PR titles, PR bodies, issue bodies, comments, and release notes.

Only use the template from `assets/pr-template.md` and `assets/issue-template-*.md`. No additions outside the template.

---

## Push to Main — Mandatory Warning

If the user is on branch `main` and about to push (or asks to push to `main`), STOP and ask the user (in Indonesian — user-facing prompt):

> "Kamu sedang di branch `main`. Push langsung ke `main` melanggar workflow — perubahan seharusnya masuk lewat PR dari `develop`.
>
> Apakah kamu yakin ingin push langsung ke `main`? (ini hanya boleh dilakukan saat release)"

Only proceed if the user explicitly confirms. After confirmation, remind them:

> - Branch protection mungkin menolak push ini jika `enforce_admins` aktif
> - Untuk private repo gratisan, branch protection tidak tersedia — lebih penting untuk disiplin manual
> - Cara yang benar: push ke `develop` atau buat PR

---

## Anti-Patterns

### Direct Implementation (no issue)

```
# BAD: started coding without creating an issue
git checkout -b feature/something
# start coding...
```

→ Always create an issue first for traceability.

### Committing on Develop/Main

```
# BAD: committing directly on develop or main
git add . && git commit -m "add feature"
git push origin develop
```

→ Always work on a feature branch and open a PR into `develop`.

### Vague Commits

```
# BAD
git commit -m "fix stuff"
git commit -m "update"
git commit -m "wip"
```

→ Use conventional commit format with clear scope and description.

### Monster PR

```
# BAD: PR with 50 files changed, 3000+ lines
```

→ Keep PRs small and focused. One issue = one branch = one PR.

### Skipping Review

```
# BAD: merging without any review
gh pr merge --auto
```

→ Every PR should be reviewed, even in solo projects (self-review).

---

## Slash Command Playbooks

The 5 commands above are defined as self-contained playbooks in `commands/`. Read the playbook to understand exactly what each command will do:

| Command | Playbook |
|---------|----------|
| `/git-issue` | `commands/git-issue.md` |
| `/git-commit` | `commands/git-commit.md` |
| `/git-pr` | `commands/git-pr.md` |
| `/git-review` | `commands/git-review.md` |
| `/git-setup` | `commands/git-setup.md` |

---

## Subagents (focused, on-demand)

Three single-purpose agents shipped in `agents/`. Use them via the Agent tool when you want a focused tool-restricted helper without loading the full skill into the conversation. They mirror the slash commands but skip the interactive steps — they take inputs, do the work, return outputs.

| Agent | Use when | Returns |
|-------|----------|---------|
| `commit-writer` | You need a Conventional Commits message from a diff | Subject + body (does NOT commit) |
| `pr-reviewer`   | You need a checklist-driven PR review | Structured findings + recommended verdict (does NOT submit) |
| `issue-writer`  | You need to turn a short description into a complete issue | Title + label + body (does NOT create) |

Pattern: caller invokes the agent, agent returns content, caller decides what to do with it. Keeps destructive Git actions in the caller's hands.

---

## Examples (end-to-end walkthroughs)

Real-world scenario playbooks in `examples/`. Use these when onboarding teammates or when you want to see the full flow before stitching commands together yourself.

| File | Scenario |
|------|----------|
| `examples/01-feature-end-to-end.md` | Full flow: issue → branch → commit → PR → review → merge |
| `examples/02-hotfix-production.md`  | Emergency hotfix to `main` + backport to `develop` |
| `examples/03-conflict-resolution.md` | Step-by-step merge conflict walkthrough |

---

## Hooks (defense-in-depth)

Two layers of automation enforce the workflow even when Claude (or a human) tries to take a shortcut:

| Layer | Where | What it catches |
|-------|-------|-----------------|
| **Claude Code hooks** (in `hooks/`) | PreToolUse on Bash | Direct push to `main`/`master`, malformed commit messages from `git commit -m` |
| **Git hooks** (in `hooks/git-hooks/`) | `commit-msg`, `pre-push` per repo | Any commit/push via plain `git` (terminal, IDE, other tools) |

Both layers are optional but recommended. See [`hooks/README.md`](hooks/README.md) for install steps and the exact rules each hook enforces.

When the user (or Claude) hits a hook block, the hook prints the reason to stderr and explains how to fix it. Do not suggest `--no-verify` unless the situation truly warrants it.

---

## Reference Files

Read the appropriate reference file based on the task:

| Task | Reference File |
|------|---------------|
| Setting up a new repository | `references/repo-setup.md` |
| Creating and managing issues | `references/issues.md` |
| API Response section for backend endpoint issues | `references/issues-api-response.md` |
| Branching strategy & commits | `references/branching-commits.md` |
| Creating pull requests | `references/pull-requests.md` |
| Reviewing code | `references/code-review.md` |
| Common errors (symptom → fix) | `references/troubleshooting.md` |
| Advanced ops (revert, undo, conflict, cherry-pick, bisect) | `references/advanced-operations.md` |

## Asset Templates

Ready-to-use templates are available in `assets/`:

| Template | File |
|----------|------|
| Feature issue template | `assets/issue-template-feature.md` |
| Bug report template | `assets/issue-template-bug.md` |
| Pull request template | `assets/pr-template.md` |
| README template | `assets/readme-template.md` |

## Available Scripts

Automation scripts in `scripts/`:

| Script | Purpose |
|--------|---------|
| `scripts/create-issue.sh` | Create GitHub issue via gh CLI |
| `scripts/setup-repo.sh` | Initialize repo with best practices |
| `scripts/validate-commit-msg.sh` | Validate conventional commit format |
| `scripts/install-git-hooks.sh` | Install `commit-msg` + `pre-push` hooks into the current repo |
| `scripts/verify-install.sh` | Sanity-check that the skill and its dependencies are installed |
