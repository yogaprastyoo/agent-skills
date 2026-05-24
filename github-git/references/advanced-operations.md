# Advanced Operations

Operations that the slash commands intentionally do not automate — they require human judgment about which path is right for the situation. Each section walks the steps end-to-end.

For day-to-day workflow (issue → branch → commit → PR), see the other reference files. For common errors, see `troubleshooting.md`.

---

## Revert a merged PR

You merged a PR and now want to undo it on the target branch.

### When to use

- Bug discovered after merge that is bigger than a quick follow-up fix
- Wrong PR merged (accidentally clicked the wrong button)
- Production incident traced to a specific PR

### Steps

```bash
# 1. Find the merge commit
git checkout develop
git pull origin develop
git log --merges --oneline -5

# 2. Revert it. The -m 1 flag tells git to keep the develop side as
#    the "mainline" parent of the merge.
git revert -m 1 <merge-sha>

# This opens an editor for the revert commit message. Conventional format:
#   revert: <original PR title> (#<pr-number>)
```

Push the revert directly to `develop` via PR (do NOT push straight to `develop`):

```bash
git checkout -b revert/<pr-number>-<slug>
git push -u origin revert/<pr-number>-<slug>
gh pr create --base develop \
  --title "[Revert] <original PR title> (#<pr-number>)" \
  --body "Reverts #<pr-number>. Reason: <one paragraph>."
```

### Gotchas

- A revert creates a new commit; it does NOT erase history. The reverted code is still in the log.
- To re-introduce the same changes later, you must revert the revert (or cherry-pick the original commit).
- For PRs squash-merged: the merge SHA you want is the single squash commit, not the original commits on the feature branch.

---

## Undo the last commit

Three scenarios, three different fixes.

### A. Undo locally, before pushing — keep the changes staged

```bash
git reset --soft HEAD~1
```

Now your changes are staged but uncommitted. Edit what you want, then commit again.

### B. Undo locally, before pushing — discard the changes entirely

```bash
git reset --hard HEAD~1
```

DANGER: This drops the commit AND all its file changes from your working tree. Make sure you do not need them.

### C. Undo a commit that has already been pushed

You cannot truly "undo" a pushed commit — that would rewrite shared history. Instead, revert it:

```bash
git revert HEAD
git push
```

This creates a new commit that inverts the changes. Safe for shared branches.

### Gotcha

If the commit you want to undo is buried under newer commits, the steps change. For local-only history, use `git reset --hard <sha-before-bad-commit>` and `git push --force-with-lease` (only on YOUR branch). For pushed-and-merged history, `git revert <sha>` is the only safe option.

---

## Resolve a merge conflict

### Workflow

```bash
# 1. Refresh and start the rebase (or merge — preference varies)
git fetch origin
git rebase origin/<base-branch>

# Git pauses at the first conflict:
#   CONFLICT (content): Merge conflict in src/foo.ts
#   error: could not apply abc1234... feat(foo): ...

# 2. Inspect the conflicted file
git status                              # lists conflicted files
git diff --cc src/foo.ts                # combined diff showing both sides
```

Conflict markers in the file:

```
<<<<<<< HEAD                          ← what is on the BASE branch
const FOO = "production-default";
=======                               ← divider
const FOO = "your-new-value";
>>>>>>> abc1234 (your commit message) ← what is on YOUR branch
```

### Resolution

1. Decide which side is correct (or write a combined version)
2. Delete the conflict markers
3. Stage the resolved file
4. Continue the rebase

```bash
# After editing src/foo.ts:
git add src/foo.ts
git rebase --continue
```

If more conflicts appear, repeat. Once the rebase finishes:

```bash
git push --force-with-lease
```

### When to abort

If the rebase is going badly (10+ conflicts, none obvious how to resolve), abort and try a merge instead:

```bash
git rebase --abort
git merge origin/<base-branch>
```

Merge conflicts are easier to resolve because git only confronts you with the final state, not each commit replayed.

### Gotcha

Resolving in the GitHub web UI works for tiny conflicts but provides no test feedback. Always resolve locally so you can run tests before pushing the resolution.

---

## Sync a fork with upstream

You forked someone else's repo and want to pull in their latest changes.

### One-time setup

```bash
# Inside your fork's local clone:
git remote add upstream https://github.com/<original-owner>/<repo>.git
git remote -v   # verify both origin (your fork) and upstream are listed
```

### Sync

```bash
git fetch upstream
git checkout main                       # or develop
git merge upstream/main
git push origin main
```

For active feature branches based on `develop`:

```bash
git checkout feature/<n>-<slug>
git rebase upstream/develop
git push --force-with-lease
```

### Gotcha

GitHub also has a "Sync fork" button in the web UI that runs the equivalent of the above. Either works.

---

## Split one commit into several

You realize a single commit mixed two unrelated changes. Conventional commits prefer one logical change per commit.

### Steps

```bash
# 1. Start an interactive rebase that includes the commit to split.
#    HEAD~3 means "the last 3 commits".
git rebase -i HEAD~3

# 2. In the editor, change `pick` to `edit` for the commit to split.
#    Save and exit.

# 3. The rebase pauses at that commit. Undo it but keep the files:
git reset HEAD^

# 4. Now stage and commit each logical chunk separately:
git add src/auth/
git commit -m "feat(auth): add JWT refresh"

git add src/ui/
git commit -m "refactor(ui): extract login form"

# 5. Continue the rebase
git rebase --continue
```

### Gotcha

If the commit you split was already pushed, you need `git push --force-with-lease` after. This rewrites history, so do not do it on branches others are pushing to.

---

## Cherry-pick a commit from another branch

You want one specific commit from branch A applied to branch B, without merging the rest of A.

### Steps

```bash
# 1. Find the commit SHA on the source branch
git log <source-branch> --oneline | head -10

# 2. Switch to the target branch
git checkout <target-branch>
git pull

# 3. Cherry-pick
git cherry-pick <sha>
```

If the cherry-pick produces conflicts, resolve them like a merge conflict, then `git cherry-pick --continue`.

### Use cases

- Backport a bugfix from `develop` to a `release/*` branch
- Apply a hotfix to an old maintenance branch
- Pull a single commit out of an abandoned branch

### Gotcha

Cherry-picking creates a new commit with the same content but a different SHA. The original commit still exists on the source branch — if you later merge that branch in, git will be smart enough not to double-apply the change (usually).

---

## Interactive rebase

Reorder, squash, or rewrite commits before opening a PR. Useful for cleaning up a branch with messy "wip" commits.

### Workflow

```bash
# Rebase the last N commits
git rebase -i HEAD~5
```

Editor opens with a list:

```
pick a1b2c3d wip
pick e4f5g6h wip
pick i7j8k9l fix tests
pick m0n1o2p actual feature
pick q3r4s5t typo
```

Change the verb on the left to control what happens:

| Verb | Action |
|------|--------|
| `pick` | Keep the commit as-is (default) |
| `reword` | Keep the commit, but edit the message |
| `edit` | Pause at this commit so you can amend or split it |
| `squash` | Combine into the previous commit, keep both messages |
| `fixup` | Combine into the previous commit, discard this message |
| `drop` | Remove the commit entirely |

Save and exit. Git replays the commits according to your instructions.

### Common patterns

**Squash all the wip commits into one clean commit:**

```
pick a1b2c3d wip                  ← keep
fixup e4f5g6h wip                 ← merge into a1b2c3d, drop message
fixup i7j8k9l fix tests           ← merge into a1b2c3d, drop message
fixup m0n1o2p actual feature      ← merge into a1b2c3d
fixup q3r4s5t typo                ← merge into a1b2c3d
```

Then `reword` to give it a proper conventional commit message at the end.

**Drop a commit you no longer want:**

```
drop a1b2c3d experiment that didn't work
pick e4f5g6h ...
```

### Gotcha

Never rebase commits that others have pulled. If your branch is shared, talk to the team before rewriting history. If you must, communicate the new SHA so others can reset their local copy.

---

## Recover a "lost" commit

You ran `git reset --hard` and your changes are "gone." They probably aren't.

### Steps

```bash
git reflog
```

`reflog` shows every move HEAD has made. You'll see entries like:

```
abc1234 HEAD@{0}: reset: moving to develop
def5678 HEAD@{1}: commit: feat(foo): the work you thought you lost
```

Recover by checking out that SHA:

```bash
git checkout def5678
# Create a new branch from it
git checkout -b recovery/lost-work
```

### Gotcha

`reflog` entries expire (default 90 days). Recover as soon as you realize the loss — do not wait.

---

## Find when a bug was introduced

Use `git bisect` to binary-search through history for the commit that introduced a bug.

### Workflow

```bash
git bisect start
git bisect bad                       # current state is broken
git bisect good <known-good-sha>     # this older commit worked

# Git checks out the midpoint commit. Test it.
# Tell git the result:
git bisect good   # ... or git bisect bad

# Git narrows the range. Repeat until git identifies the offender.

git bisect reset                     # return to your original branch
```

For automated bisect (when you have a script that returns 0 on good, non-zero on bad):

```bash
git bisect start HEAD <known-good-sha>
git bisect run ./test-script.sh
```

### Gotcha

Bisect assumes commits are independent — won't work well on branches with broken merge commits. Squashed history is easier to bisect than full merge history.

---

## Delete a branch (local + remote)

```bash
# Local
git branch -d feature/42-foo           # safe — refuses if unmerged
git branch -D feature/42-foo           # force — discards unmerged work

# Remote
git push origin --delete feature/42-foo

# Or via gh
gh pr close <pr-number> --delete-branch
```

`/git-pr` and `gh pr merge --delete-branch` handle this automatically on merge. Manual deletion is only needed for branches you abandon without merging.

---

## Last resort

When you're truly stuck and the working tree is in an unrecoverable state:

```bash
# 1. Stash everything (saves uncommitted work)
git stash push -m "before nuclear option"

# 2. Reset to a known-good state
git fetch origin
git checkout develop
git reset --hard origin/develop

# 3. Recover stashed work if needed
git stash list
git stash pop
```

If `git status` is incomprehensible, sometimes the easiest fix is:

```bash
cd ..
mv <repo> <repo>.broken
git clone <url> <repo>
cd <repo>
# Restore any specific work from <repo>.broken/ as needed
```

This loses no information (the broken copy is preserved) and gets you back to a clean state immediately.
