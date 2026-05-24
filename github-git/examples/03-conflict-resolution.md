# Example 03 — Merge conflict resolution

The most common cause of "I'm stuck and don't know what to do." This walkthrough resolves a realistic conflict step-by-step.

**Scenario**: you've been working on `feature/42-jwt-refresh-rotation` for three days. Meanwhile, two PRs landed on `develop` that also touched `src/services/auth.ts`. You try to push and:

```
$ git push -u origin feature/42-jwt-refresh-rotation
! [rejected]   feature/42-jwt-refresh-rotation -> feature/42-jwt-refresh-rotation (non-fast-forward)
```

Or your PR shows "This branch has conflicts that must be resolved."

---

## Step 0 — Don't panic, don't use the GitHub UI

Resolving in the GitHub web UI works for trivial conflicts but gives you no test feedback. Resolve locally so you can run tests on the resolution before pushing.

```bash
# Make sure you're on your branch
git checkout feature/42-jwt-refresh-rotation

# Fetch the latest from origin (don't pull — fetch only)
git fetch origin
```

---

## Step 1 — Choose: rebase vs merge

Two ways to incorporate `develop`'s changes:

**Rebase** (preferred for your own feature branches):
```bash
git rebase origin/develop
```
- Pros: clean linear history
- Cons: replays each of your commits onto develop, so conflicts surface one commit at a time

**Merge** (preferred when rebase is going badly):
```bash
git merge origin/develop
```
- Pros: conflicts surface once at the merge boundary
- Cons: creates a merge commit, slightly messier history

For first-time conflict resolvers, **start with rebase**. If it gets ugly, abort and switch to merge.

```bash
git rebase origin/develop
```

---

## Step 2 — Read the conflict announcement

Git pauses with output like:

```
Auto-merging src/services/auth.ts
CONFLICT (content): Merge conflict in src/services/auth.ts
error: could not apply abc1234... feat(auth): add rotateRefreshToken

When you have resolved this conflict run "git rebase --continue".
If you prefer to skip this patch, run "git rebase --skip" instead.
To check out the original branch and stop rebasing run "git rebase --abort".
```

Now you know:
- `src/services/auth.ts` has a conflict
- The commit being applied is your `abc1234 feat(auth): add rotateRefreshToken`
- Your options are: continue (after resolving), skip this commit (rare), or abort

```bash
git status
```

```
interactive rebase in progress; onto def5678
Last command done (1 command done):
   pick abc1234 feat(auth): add rotateRefreshToken
Next commands to do (2 remaining commands):
   pick ghi9012 feat(auth): add blacklist middleware
   pick jkl3456 test(auth): refresh rotation tests
You are currently rebasing branch 'feature/42-jwt-refresh-rotation' on 'def5678'.
  (fix conflicts and then run "git rebase --continue")
  (use "git rebase --skip" to skip this patch)
  (use "git rebase --abort" to check out the original branch)

Unmerged paths:
  (use "git add <file>..." to mark resolution)
        both modified:   src/services/auth.ts

no changes added to commit (use "git add" and/or "git commit -a")
```

---

## Step 3 — Open the conflicted file

```bash
# In your editor
code src/services/auth.ts
# or
vim src/services/auth.ts
```

You'll see conflict markers:

```typescript
export class AuthService {
  async issueRefreshToken(userId: string): Promise<string> {
    const token = generateToken();

<<<<<<< HEAD
    // From develop (someone else's change)
    await this.redis.set(`refresh:${userId}`, token, 'EX', 86400);
    this.metrics.increment('auth.refresh.issued');
=======
    // Your change (from feature/42-jwt-refresh-rotation)
    await this.repository.saveRefreshToken(userId, token);
    await this.invalidatePreviousRefreshTokens(userId);
>>>>>>> abc1234 (feat(auth): add rotateRefreshToken)

    return token;
  }
}
```

Read carefully:
- Code between `<<<<<<< HEAD` and `=======` = what `develop` looks like now (NOT your change — `HEAD` during rebase is the base branch)
- Code between `=======` and `>>>>>>> abc1234` = your change
- `abc1234` is the SHA of YOUR commit (the one git is trying to replay)

---

## Step 4 — Understand both sides

**Before you delete anything**, understand what each side is trying to do:

- **develop's change**: storing refresh tokens in Redis with 24-hour expiry, plus a metrics counter
- **your change**: storing refresh tokens in the database via the repository, plus invalidating previous tokens

Neither is "wrong." They serve different requirements. The right resolution depends on context:

- Did the team decide to switch from Redis to DB? If yes — your change wins, drop the Redis call.
- Did the team add Redis for performance? If yes — keep both: store in DB AND cache in Redis. Your invalidation logic still applies.
- Are you supposed to coordinate with whoever added the Redis change? Probably.

When in doubt: `git log --oneline origin/develop | head -5` shows recent develop commits. Find the one that added the Redis call. Read its PR. Then decide.

---

## Step 5 — Resolve

For our scenario, assume the team decided to keep BOTH (DB as source of truth, Redis as cache). The resolution:

```typescript
export class AuthService {
  async issueRefreshToken(userId: string): Promise<string> {
    const token = generateToken();

    // Source of truth: database
    await this.repository.saveRefreshToken(userId, token);
    await this.invalidatePreviousRefreshTokens(userId);

    // Cache layer: Redis with 24h expiry
    await this.redis.set(`refresh:${userId}`, token, 'EX', 86400);
    this.metrics.increment('auth.refresh.issued');

    return token;
  }
}
```

Delete the conflict markers (`<<<<<<<`, `=======`, `>>>>>>>`). Keep what you want from each side. Save.

---

## Step 6 — Verify the resolution

```bash
# Re-check that no markers are left
grep -n '<<<<<<<\|=======\|>>>>>>>' src/services/auth.ts
# (no output = clean)

# Make sure it compiles
npm run build       # or tsc, or your project's equivalent

# Run the tests
npm test src/services/auth.test.ts
```

If tests fail, you have more work — the integration of both sides revealed a bug. Fix it now.

---

## Step 7 — Stage and continue

```bash
git add src/services/auth.ts
git rebase --continue
```

Git applies the next commit. If there's another conflict, repeat from Step 2.

If everything applies cleanly:

```
Successfully rebased and updated refs/heads/feature/42-jwt-refresh-rotation.
```

---

## Step 8 — Force-push (carefully)

Rebase rewrote your commits' SHAs. The remote still has the old SHAs. You need:

```bash
git push --force-with-lease
```

**Why `--force-with-lease` not `--force`**: `--force` overwrites unconditionally. `--force-with-lease` only succeeds if the remote tip matches what you last fetched — protecting you if a teammate pushed to your branch while you were rebasing.

---

## When to abort

If after 10+ minutes of rebasing you've hit 5+ conflicts and aren't making progress:

```bash
git rebase --abort
```

This restores your branch to exactly where it was before you started. No changes lost.

Then try merge instead:

```bash
git merge origin/develop
```

Merge surfaces conflicts once (at the merge boundary) instead of per-commit. Easier when conflicts are in the same lines repeatedly.

After merge resolution:

```bash
git add <resolved-files>
git commit            # let git use the default merge message
git push              # no force needed — merge is additive
```

---

## When you're really stuck

If even merge is going badly, the conflict is symptomatic of something larger — your branch has diverged so far from develop that combining the changes manually doesn't make sense.

Options:

1. **Pair with the person who made the conflicting changes.** They have context you don't.
2. **Cherry-pick your commits onto a fresh branch.**
   ```bash
   git checkout develop
   git pull origin develop
   git checkout -b feature/42-jwt-refresh-rotation-v2
   # Cherry-pick the commits that still make sense
   git cherry-pick <sha1> <sha2> <sha3>
   # Drop the ones that don't
   ```
3. **Split the feature into multiple smaller PRs.** Merge the parts that don't conflict first.

---

## Prevention

You won't always avoid conflicts — but you can reduce them:

- **Keep branches short-lived.** A 3-day branch conflicts less than a 3-week branch.
- **Rebase frequently.** Run `git fetch && git rebase origin/develop` daily, not at the end. Small conflicts are easier than big ones.
- **Coordinate on hot files.** If two people are about to touch `auth.ts`, talk first.
- **Split large changes.** A PR touching 20 files is more likely to conflict than four PRs of 5 files each.

The skill's "MUST keep PRs small" rule isn't just about review quality — it's also about reducing conflict surface.
