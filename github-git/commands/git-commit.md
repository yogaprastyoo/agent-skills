---
description: Analyze the current diff, auto-detect the commit type, and create a conventional commit
argument-hint: [scope] or [type:scope:description]
---

# /git-commit

Stage and commit current changes with an auto-generated conventional commit message. The skill enforces format, scope, and message rules — no `chore: wip` or `fix stuff` slips through.

## What this command does

1. Checks current branch (refuses commit on `develop` or `main`)
2. Inspects staged and unstaged changes
3. Auto-detects commit type from the diff using the table in `references/branching-commits.md`
4. Auto-derives scope from the changed files (e.g., `auth`, `api`, `ui`)
5. Generates a conventional commit message (subject + optional body)
6. Shows the user the proposed message and asks for confirmation
7. Runs `git commit`

## Workflow

When invoked:

### Step 1 — Refuse on protected branches

```bash
git branch --show-current
```

If on `develop`, `main`, or any other protected branch, STOP and warn (Indonesian — user-facing prompt):

> "Kamu sedang di branch `<branch>`. Commit langsung ke branch ini melanggar workflow. Buat feature/bugfix branch dulu sebelum commit."

Only proceed if the user explicitly overrides (rare — e.g., emergency hotfix initial setup).

### Step 2 — Inspect diff

```bash
git status --short
git diff --cached --stat       # staged changes
git diff --stat                # unstaged changes
git diff --cached               # staged diff (read carefully)
git diff                        # unstaged diff (read if nothing staged)
```

If nothing is staged AND nothing modified → nothing to commit. Stop.

If nothing is staged but there are unstaged changes → ask user what to stage. Do NOT auto `git add .` — that can sweep in unintended files.

### Step 3 — Auto-detect commit type

Use this matrix (mirrors `references/branching-commits.md`):

| Diff signals | Type |
|--------------|------|
| New endpoint, new component, new function with new behavior | `feat` |
| Modified existing code to fix incorrect behavior, error handling added | `fix` |
| `.md` files changed, comments updated, JSDoc/docstring added | `docs` |
| Indentation, formatting, linting fixes, no logic change | `style` |
| Code restructured, extracted, renamed — same behavior | `refactor` |
| Test files added or modified (`*.test.*`, `*.spec.*`, `__tests__/`) | `test` |
| `package.json`/`pubspec.yaml`/`requirements.txt` deps changed, config updated, `.gitignore` modified | `chore` |
| Workflow files (`.github/workflows/`), Dockerfile, CI config changed | `ci` |
| Query optimization, caching added, algorithm improved for speed | `perf` |

If `$ARGUMENTS` starts with `feat:`, `fix:`, etc. → respect the override.

### Step 4 — Auto-derive scope

From the changed file paths, infer the most common module/feature area:

| Path pattern | Scope |
|--------------|-------|
| `**/auth/**`, `**/login/**` | `auth` |
| `**/api/**`, `**/routes/**`, `**/controllers/**` | `api` |
| `**/components/**`, `**/widgets/**`, `**/ui/**` | `ui` |
| `**/models/**`, `**/db/**`, `**/migrations/**` | `db` |
| `**/.github/**`, `**/Dockerfile`, `**/*.yml` (CI) | `ci` |
| `package.json`, `pubspec.yaml`, `requirements.txt`, `go.mod` | `deps` |
| Multiple unrelated areas | omit scope |

If `$ARGUMENTS` provides an explicit scope, use it.

### Step 5 — Generate subject line

Format: `<type>(<scope>): <description>`

Description rules:
- Imperative mood ("add", not "added")
- Lowercase first letter
- No period at end
- Max 72 chars total (type + scope + description)
- Be specific — never `update X`, `fix Y`, `change Z`

### Step 6 — Generate body (optional)

Include a body when the change is non-trivial:
- Explain WHY (not WHAT — the diff shows what)
- Reference related issue: `Closes #<number>` (extract from branch name)
- For breaking changes: include `BREAKING CHANGE:` footer

Skip body for trivial commits (typo fix, format-only).

### Step 7 — Confirm and commit

Show the user the proposed message:

```
feat(auth): add JWT refresh token rotation

Previously refresh tokens were issued once and never rotated, allowing
indefinite session extension if leaked. This change rotates the refresh
token on every use.

Closes #42
```

Ask: "Commit pakai pesan ini? (y/n)"

If yes → run:

```bash
git commit -m "$(cat <<'EOF'
<subject>

<body>

Closes #<n>
EOF
)"
```

If no → ask user what to change.

## Constraints

- MUST refuse commits on `develop`, `main`, or any protected branch
- MUST use conventional commits format
- MUST use single-quoted `'EOF'` heredoc for multi-line messages
- MUST NOT include `Co-Authored-By: Claude`, AI mentions, or "Generated with Claude"
- MUST NOT auto-stage with `git add .` — ask the user
- MUST NOT amend an existing commit unless user explicitly asks
- MUST reject vague descriptions ("fix stuff", "update", "wip")
- If pre-commit hook fails: investigate root cause, fix, and create a NEW commit (do NOT amend)

## Example invocations

```
/git-commit
/git-commit auth
/git-commit feat:auth:add OAuth2 login
```

## See also

- `references/branching-commits.md` — full conventional commits guide, types, scopes
- `scripts/validate-commit-msg.sh` — standalone validator for commit messages
