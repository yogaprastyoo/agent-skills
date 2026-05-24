# Branching Strategy & Commits

Complete guide for branch management and commit conventions.

---

## Branch Architecture

```
main          ← Production only. Receives merges from develop during release.
  └── develop ← Default branch. All feature/bugfix branches start and end here.
        ├── feature/42-user-auth
        ├── bugfix/15-fix-login
        └── hotfix/78-patch-payment   ← Hotfixes branch from main, merge to both main AND develop
```

### Branch Roles

| Branch | Purpose | Created From | Merges Into |
|--------|---------|-------------|-------------|
| `main` | Production-ready code | — | — |
| `develop` | Integration branch for next release | `main` (once, at setup) | `main` (at release) |
| `feature/*` | New features or enhancements | `develop` | `develop` |
| `bugfix/*` | Non-urgent bug fixes | `develop` | `develop` |
| `hotfix/*` | Urgent production fixes | `main` | `main` AND `develop` |
| `release/*` | Release preparation (freeze, final fixes) | `develop` | `main` AND `develop` |
| `refactor/*` | Code refactoring without behavior change | `develop` | `develop` |
| `docs/*` | Documentation changes only | `develop` | `develop` |
| `ci/*` | CI/CD pipeline changes | `develop` | `develop` |

---

## Branch Naming Convention

Format:

```
{prefix}/{issue-number}-{slug}
```

Rules:
- Use lowercase only
- Separate words with hyphens (`-`)
- Keep the slug short but descriptive (3-5 words max)
- Always include the issue number

**Good examples:**

```
feature/42-jwt-refresh-token
bugfix/15-fix-uppercase-email-login
hotfix/78-patch-payment-null-response
release/1.2.0
refactor/33-extract-payment-service
docs/50-update-api-documentation
ci/55-add-docker-build-step
```

**Bad examples:**

```
feature/new-stuff              # No issue number, vague slug
fix                            # No prefix format, no issue number
Feature/42-JWT-Refresh-Token   # Uppercase not allowed
feature/42                     # No descriptive slug
my-branch                      # No prefix, no issue number
```

---

## Branch Lifecycle

### Creating a Branch

Always branch from **`origin/develop`**, not local `develop`. This prevents silently absorbing unpushed local commits into your feature branch (see Gotcha: "Silent absorption of unpushed local commits" below).

Recommended one-liner:

```bash
git fetch origin && git checkout -b feature/<issue-number>-<slug> origin/develop
```

Or in two steps if you prefer:

```bash
git fetch origin
git checkout develop
git pull --ff-only origin develop      # fail loudly if local develop has its own commits
git checkout -b feature/<issue-number>-<slug>
```

The `--ff-only` is the key safety net — it refuses a non-fast-forward pull, which is the signal that you have unpushed local commits on `develop` that need to be handled (pushed via PR) before creating a new branch.

Verify you are on the correct branch:

```bash
git branch --show-current
```

And verify the branch base matches `origin/develop`:

```bash
git rev-parse HEAD == git rev-parse origin/develop
# (or: git log origin/develop..HEAD — should be empty before you make any commits)
```

### Working on a Branch

Keep your branch up-to-date with `develop` by rebasing regularly:

```bash
git fetch origin
git rebase origin/develop
```

If conflicts arise during rebase, resolve them file by file:

```bash
# Fix conflicts in the reported files
git add <resolved-file>
git rebase --continue
```

If rebase becomes too complex, abort and use merge instead:

```bash
git rebase --abort
git merge origin/develop
```

### Pushing a Branch

First push (set upstream):

```bash
git push -u origin feature/42-jwt-refresh-token
```

Subsequent pushes:

```bash
git push
```

After rebase (force push your own branch only):

```bash
git push --force-with-lease
```

Use `--force-with-lease` instead of `--force` — it prevents overwriting changes that someone else pushed to your branch.

### Deleting a Branch

After PR is merged, delete the branch:

```bash
# Delete remote branch
git push origin --delete feature/42-jwt-refresh-token

# Delete local branch
git branch -d feature/42-jwt-refresh-token
```

GitHub can auto-delete branches after PR merge. Enable in repository settings under "Automatically delete head branches".

---

## Hotfix Workflow

Hotfixes are the only branches created from `main` instead of `develop`.

```bash
# 1. Branch from main
git checkout main
git pull origin main
git checkout -b hotfix/78-patch-payment-null-response

# 2. Fix the issue
# ... make changes ...

# 3. Commit
git add .
git commit -m "fix(payment): handle null response from gateway

Closes #78"

# 4. Create PR to main
gh pr create \
  --base main \
  --title "[Hotfix] Handle null payment response" \
  --body "Closes #78"

# 5. After merge to main, also merge hotfix into develop
git checkout develop
git pull origin develop
git merge hotfix/78-patch-payment-null-response
git push origin develop
```

The double-merge (into `main` AND `develop`) ensures the fix exists in both production and the development branch.

---

## Release Workflow

When `develop` is ready for a new release:

```bash
# 1. Create release branch from develop
git checkout develop
git pull origin develop
git checkout -b release/1.2.0

# 2. Final adjustments (version bump, changelog, last-minute fixes)
# ... make changes ...
git commit -m "chore(release): prepare v1.2.0"

# 3. Create PR to main
gh pr create \
  --base main \
  --title "[Release] v1.2.0" \
  --body "Release v1.2.0 — see CHANGELOG.md for details"

# 4. After merge to main, tag the release
git checkout main
git pull origin main
git tag -a v1.2.0 -m "Release v1.2.0"
git push origin v1.2.0

# 5. Merge release branch back into develop
git checkout develop
git merge release/1.2.0
git push origin develop

# 6. Clean up
git branch -d release/1.2.0
git push origin --delete release/1.2.0
```

---

## Conventional Commits

All commits MUST follow the Conventional Commits specification.

### Format

```
<type>(<scope>): <description>

[optional body]

[optional footer]
```

### Types

| Type | When to Use | Example |
|------|------------|---------|
| `feat` | New feature or functionality | `feat(auth): add OAuth2 login` |
| `fix` | Bug fix | `fix(api): handle timeout on slow networks` |
| `docs` | Documentation changes only | `docs(readme): add deployment instructions` |
| `style` | Formatting, whitespace, no logic change | `style(lint): fix eslint warnings` |
| `refactor` | Code change without fixing bug or adding feature | `refactor(user): extract validation logic` |
| `test` | Adding or updating tests | `test(auth): add login edge case tests` |
| `chore` | Maintenance, deps, config changes | `chore(deps): bump express to 4.19.0` |
| `ci` | CI/CD pipeline changes | `ci(github): add Node 22 to test matrix` |
| `perf` | Performance improvement | `perf(query): add index for user lookup` |

### Auto-Detection

Claude MUST automatically determine the commit type based on the changes made. The user should NOT need to specify the type manually.

| Change Signals | Commit Type |
|---------------|-------------|
| New file added, new endpoint, new component, new function with new behavior | `feat` |
| Modified existing code to fix incorrect behavior, error handling added | `fix` |
| `.md` files changed, comments updated, JSDoc/docstring added | `docs` |
| Indentation, formatting, linting fixes, no logic change | `style` |
| Code restructured, extracted, renamed — same behavior | `refactor` |
| Test files added or modified (`*.test.*`, `*.spec.*`, `__tests__/`) | `test` |
| `package.json` deps changed, config files updated, `.gitignore` modified | `chore` |
| Workflow files (`.github/workflows/`), Dockerfile, CI config changed | `ci` |
| Query optimization, caching added, algorithm improved for speed | `perf` |

### Scope

Scope is optional but recommended. Use the module, feature area, or component name:

```
feat(auth): add JWT refresh token
fix(cart): prevent duplicate item addition
refactor(payment): extract gateway adapter
test(user): add registration validation tests
```

Common scopes: `auth`, `api`, `ui`, `db`, `config`, `deps`, `docker`, `ci`

### Description Rules

- Use imperative mood: "add", not "added" or "adds"
- Do not capitalize the first letter
- Do not end with a period
- Maximum 72 characters for the entire first line
- Be specific: "add user email validation" not "update user module"

### Body

The body explains WHY the change was made, not WHAT changed (the diff shows that).

```
fix(auth): prevent token reuse after logout

Previously, JWT tokens remained valid after logout because the
token blacklist was only checked on refresh, not on every request.
This allowed stolen tokens to be used until natural expiration.

Added middleware to check the blacklist on every authenticated request.

Closes #42
```

### Breaking Changes

Use `!` after the type/scope and add `BREAKING CHANGE` in the footer:

```
feat(api)!: change authentication endpoint response format

BREAKING CHANGE: The /auth/login endpoint now returns
{ accessToken, refreshToken } instead of { token }.
All clients must update their token handling logic.
```

### Multi-file Commits

When a single logical change spans multiple files, use one commit that describes the overall change:

```
feat(auth): add JWT refresh token mechanism

- Add refresh token generation in auth service
- Add refresh endpoint in auth controller
- Add token rotation logic
- Add HTTP-only cookie handling
- Add unit tests for all token scenarios

Closes #42
```

Do NOT create separate commits for each file unless they represent independent changes.

---

## Guidelines

- Always branch from **`origin/develop`** (not local `develop`) — except hotfixes which branch from `origin/main`
- Keep branches short-lived — merge within a few days, not weeks
- Rebase regularly to stay up-to-date with `develop`
- Use `--force-with-lease` instead of `--force` when pushing after rebase
- One issue = one branch = one PR — do not mix concerns
- Delete branches after merge to keep the repository clean
- Write commits that tell a story — a reviewer should understand the progression

---

## Gotchas

- **Rebase vs Merge**: Use rebase to keep your feature branch up-to-date with `develop`. Use merge only when rebase produces too many conflicts. Never rebase a branch that others are also working on.
- **Force push safety**: `--force-with-lease` will fail if someone else pushed to your branch since your last fetch. This is intentional — check what they pushed before overwriting.
- **Hotfix double-merge**: Forgetting to merge a hotfix back into `develop` means the fix will be lost on the next release. Always merge hotfixes into both `main` and `develop`.
- **Branch from wrong base**: If you accidentally branch from `main` instead of `develop`, your PR will show all the diff between `main` and `develop`. Recreate the branch from `develop`.
- **Commit amend after push**: `git commit --amend` followed by `git push` will fail because history changed. Use `git push --force-with-lease` after amending, but only on your own branch.
- **Empty commits**: If you need to re-trigger CI without code changes, use `git commit --allow-empty -m "ci: re-trigger pipeline"`.
- **Silent absorption of unpushed local commits**: If you branch from local `develop` (instead of `origin/develop`) while local has commits that haven't been pushed yet, those commits get inherited by your new feature branch. When the PR is squash-merged, GitHub's combined diff includes BOTH your intended changes AND the inherited local-only changes — silently absorbing them under your PR's title. Symptoms: you open a "small" PR that suddenly contains code you don't recognize; or another person's recent work appears as part of your PR. Prevention: always `git fetch && git checkout -b <branch> origin/<base>` (or use `git pull --ff-only` which fails loudly if local is ahead). To check before pushing: `git log origin/<base>..<your-branch> --not <your-commits-only>` should be empty. This is enforced as a pre-PR check in `/git-pr`.
