---
description: Create a pull request from the current branch with auto-detected base, title, and labels
argument-hint: [--draft]
---

# /git-pr

Create a pull request from the current branch, auto-detecting the base branch, deriving the title from the linked issue, and filling the template from `references/pull-requests.md`.

## What this command does

1. Verifies the current branch is not `develop`, `main`, or detached HEAD
2. Auto-detects base branch from the branch prefix (`feature/*` → `develop`, `hotfix/*` → `main`, etc.)
3. Extracts the issue number from the branch name and fetches its title for the PR title
4. Pushes the branch if not yet on remote
5. Runs the pre-PR checklist (tests, lint, rebase)
6. Generates a PR body filling all required sections from the template
7. Creates the PR with `gh pr create`
8. Reports the PR URL

## Workflow

When invoked:

### Step 1 — Verify prerequisites

```bash
gh auth status
git status
git branch --show-current
```

Stop if:
- `gh` is not authenticated
- Current branch is `develop`, `main`, or detached HEAD → instruct user to create a proper branch first
- Working tree has uncommitted changes → ask user to commit or stash first

### Step 2 — Detect base branch

Branch prefix → base branch map:

| Prefix | Base |
|--------|------|
| `feature/*` | `develop` |
| `bugfix/*` | `develop` |
| `refactor/*` | `develop` |
| `docs/*` | `develop` |
| `ci/*` | `develop` |
| `hotfix/*` | `main` |
| `release/*` | `main` |

If the prefix is unrecognized, ask the user.

### Step 3 — Extract issue number

Branch name format: `{prefix}/{issue-number}-{slug}`. Extract `{issue-number}` and fetch:

```bash
gh issue view <number> --json title,body --jq '.title'
```

If the branch lacks an issue number, ask the user to either:
- Cancel and create an issue first (recommended — enforces traceability)
- Provide a manual PR title

### Step 4 — Pre-PR checklist

```bash
# Ensure branch is up-to-date with base
git fetch origin
git rebase origin/<base-branch>

# Push branch
git push -u origin <current-branch>

# Run project tests if a test script is detected (npm test, pytest, flutter test, dotnet test, etc.)
```

If rebase produces conflicts, stop and ask the user to resolve.

### Step 5 — Generate PR body

Read `~/.claude/skills/github-git/references/pull-requests.md` for the full template. Fill at minimum:

- **Description** — derive from issue body if available, else ask user
- **Changes** — bullet list summarizing the diff (`git log <base>..HEAD --oneline` + diff summary)
- **Related Issues** — `Closes #<number>`
- **Type of Change** — check the box matching branch prefix
- **Self-Review Checklist** — leave unchecked for the user to verify

### Step 6 — Create the PR

```bash
gh pr create \
  --base <detected-base> \
  --title "[Type] <issue title>" \
  --body "$(cat <<'EOF'
...body...
EOF
)" \
  --label "<detected-label>" \
  --assignee "@me"
```

Add `--draft` if `$ARGUMENTS` contains `--draft`.

### Step 7 — Report

Print the PR URL. Suggest next steps:

```
PR created: https://github.com/.../pull/42
Next: wait for CI, then request reviewers via `gh pr edit 42 --add-reviewer <user>`
```

## Constraints

- MUST link PR to an issue via `Closes #N` — refuse to create PR-without-issue unless the user explicitly overrides
- MUST use heredoc with single-quoted `'EOF'`
- MUST NOT include `Co-Authored-By: Claude`, `Co-Authored-By: Antigravity`, AI mentions, or "Generated with Claude" / "Generated with Antigravity" anywhere
- MUST detect and apply correct base branch — never default to `main` for feature work
- MUST use `--force-with-lease`, not `--force`, if a rebase requires force-push
- Use only default labels (`bug`, `enhancement`, `documentation`) unless custom labels exist
- Title format: `[Type] description` matching `references/pull-requests.md`

## Example invocations

```
/git-pr
/git-pr --draft
```

## See also

- `references/pull-requests.md` — full PR template, merge strategy, self-review
- `references/branching-commits.md` — branch naming convention (which the auto-detection relies on)
- `references/code-review.md` — for reviewing PRs created by others
