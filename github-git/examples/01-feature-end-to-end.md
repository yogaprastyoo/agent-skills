# Example 01 — Feature end-to-end

A complete walkthrough from "I have an idea" to "merged on develop." Use this when you're new to the skill and want to see every step in context.

**Scenario**: a teammate asks you to add JWT refresh token rotation to the auth service.

---

## Step 0 — Start clean

```bash
cd ~/projects/our-backend
git checkout develop
git pull origin develop
```

Always start from an up-to-date `develop`. If you skip this, your branch will rebase onto stale code.

---

## Step 1 — File the issue

In Claude Code:

```
/git-issue feat: add JWT refresh token rotation
```

Claude (with the `github-git` skill loaded) will ask follow-up questions:

> "Saya butuh info berikut untuk bikin issue yang lengkap:
> 1. Description — apa motivasi/dampaknya? (security, UX, etc.)
> 2. Context — file mana yang relevant? Bagaimana code sekarang bekerja?
> 3. API Response — endpoint apa yang affected? Request/success/error contoh?
> 4. Acceptance criteria — 3-5 hal verifiable
> ..."

You answer. Claude assembles the body and runs:

```bash
gh issue create --title "feat: add JWT refresh token rotation" --body "$(cat <<'EOF'
## Description
Refresh tokens are currently issued once and never rotated...

## Context
- `src/services/auth.ts` lines 80-95 — issues refresh tokens
- `src/middleware/auth.ts` — validates them
...

## API Response
### POST /api/auth/refresh
**Request**
{ "refreshToken": "..." }
**Success — 200**
{ "success": true, "message": "...", "data": { "accessToken": "...", "refreshToken": "..." } }
**Error — 401**
{ "success": false, "message": "Invalid refresh token", "errors": null }

## Acceptance Criteria
- [ ] POST /api/auth/refresh rotates the refresh token on every use
- [ ] Previous refresh token is invalidated after rotation
- [ ] Unit tests cover happy path + 3 error cases
- [ ] Integration test verifies rotation across two consecutive refreshes

## Technical Notes
...
EOF
)" --label "enhancement"
```

Output:

```
https://github.com/our-org/our-backend/issues/42
```

Note the issue number — you'll need it for the branch.

---

## Step 2 — Create the branch

```bash
git checkout -b feature/42-jwt-refresh-rotation
```

Branch naming follows `{prefix}/{issue-number}-{slug}`. The prefix `feature/` is auto-detected by `/git-pr` later.

---

## Step 3 — Implement

Do the actual work. Edit files, run tests locally as you go.

For this example, you'd add:
- `src/services/auth.ts` — `rotateRefreshToken()` function
- `src/middleware/auth.ts` — invalidate old token on refresh
- `src/controllers/auth.ts` — new POST `/api/auth/refresh` endpoint
- `tests/unit/auth.test.ts` — happy path + error cases
- `tests/integration/auth-refresh.test.ts` — rotation across two refreshes

Commit progress as you go (not at the end):

```
/git-commit
```

Claude reads your diff, infers `feat`, scope `auth`, drafts:

```
feat(auth): add rotateRefreshToken to auth service

Implements token rotation per RFC 6749 §6. Previous token is added
to the blacklist when a new one is issued.

Closes #42
```

Asks "commit pakai pesan ini?" → you say yes → commit lands.

Continue with the controller, then tests. Each logical chunk = one commit.

---

## Step 4 — Push and open PR

When the feature is ready:

```
/git-pr
```

Claude:
1. Checks you're not on `develop`/`main` (you're on `feature/42-jwt-refresh-rotation` ✓)
2. Auto-detects base branch from prefix → `develop`
3. Extracts issue #42 from branch name, fetches its title
4. Runs `git fetch && git rebase origin/develop` (you resolve any conflicts)
5. Pushes the branch
6. Generates PR body using your commits + the issue
7. Runs:

```bash
gh pr create --base develop \
  --title "[Feature] Add JWT refresh token rotation" \
  --body "$(cat <<'EOF'
## Description
Implements JWT refresh token rotation. Each refresh issues a new token
and invalidates the previous one.

## Changes
- Added `rotateRefreshToken()` in `src/services/auth.ts`
- Added blacklist check in `src/middleware/auth.ts`
- New POST `/api/auth/refresh` endpoint
- 4 unit tests, 1 integration test

## Related Issues
Closes #42

## Type of Change
- [x] New feature

## Testing Performed
- [x] Unit tests pass — `npm test src/services/auth.test.ts`
- [x] Integration test passes
- [x] Manual: refreshed via Postman, old token rejected on subsequent use

## Self-Review Checklist
- [x] Self-review performed
- [x] No secrets committed
- [x] Tests added
EOF
)" --label "enhancement" --assignee "@me"
```

Output:

```
https://github.com/our-org/our-backend/pull/87
```

---

## Step 5 — Wait for CI

CI runs. If it fails, fix and push more commits (do NOT amend after pushing).

While waiting, you can do a self-review:

```
/git-review 87
```

Claude (via the `pr-reviewer` agent) walks the checklist and returns findings. You address them with more commits.

---

## Step 6 — Request review

Once CI passes and self-review is clean:

```bash
gh pr edit 87 --add-reviewer @teammate
```

Or ping in Slack. Wait for approval.

---

## Step 7 — Address review feedback

Reviewer leaves blocker comments. You fix:

```bash
# Edit files
/git-commit
# Push
git push
```

Re-request review:

```bash
gh pr edit 87 --add-reviewer @teammate
```

---

## Step 8 — Merge

Once approved:

```bash
gh pr merge 87 --squash --delete-branch
```

Squash is the default for `feature/*` branches — combines all your commits into a single commit on `develop` with a clean conventional message.

Locally:

```bash
git checkout develop
git pull origin develop
git branch -d feature/42-jwt-refresh-rotation
```

Done. Issue #42 auto-closes because the PR body said `Closes #42`.

---

## What just happened

You went from "idea" to "merged" in 8 explicit steps. Every artifact is traceable:

- Issue #42 has the requirements (acceptance criteria)
- Branch `feature/42-jwt-refresh-rotation` has the work
- PR #87 links them and shows the diff + reviews
- Commit on `develop` references both

If a bug shows up next month, anyone can `git blame` the line, find the commit, find the PR, find the issue, and understand WHY the code is the way it is.

---

## Variations

- **No issue yet** — `/git-issue` first, then continue from Step 2.
- **Existing branch** — skip Step 0 and 2, go to Step 3.
- **Bug fix** — same flow, but title prefix is `fix:`, branch prefix is `bugfix/`, label is `bug`.
- **Hotfix** — see `examples/02-hotfix-production.md`.
- **Conflict during rebase** — see `examples/03-conflict-resolution.md`.
