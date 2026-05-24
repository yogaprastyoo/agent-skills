# Troubleshooting

Common errors encountered when using this skill, with concrete fixes. Each entry follows the same structure: **Symptom**, **Cause**, **Fix**, **Prevention**.

For workflow gotchas (rebase vs merge, `.gitignore` timing, etc.), see the relevant reference file:
- Branching/commits → `branching-commits.md`
- Issues → `issues.md`
- PRs → `pull-requests.md`
- Code review → `code-review.md`
- Repo setup → `repo-setup.md`

---

## Tool installation

### `gh: command not found`

**Symptom**
```
$ gh issue create ...
bash: gh: command not found
```

**Cause**
The GitHub CLI is not installed, or it is installed but not on `PATH`.

**Fix**
- macOS: `brew install gh`
- Ubuntu/Debian: `sudo apt install gh` (or follow https://cli.github.com/ for the official APT repo)
- Windows (WSL): use the Linux instructions above
- Verify: `gh --version`

**Prevention**
Run `bash ~/.agents/skills/github-git/scripts/verify-install.sh` after install — it explicitly checks for `gh`.

---

### `git: command not found`

**Symptom**
```
$ git status
bash: git: command not found
```

**Cause**
Git is not installed, or shell `PATH` is missing the directory containing `git`.

**Fix**
- macOS: install Xcode Command Line Tools (`xcode-select --install`) or `brew install git`
- Ubuntu/Debian: `sudo apt install git`
- Verify: `git --version`

**Prevention**
`verify-install.sh` checks this. Run after every shell-config change.

---

## Authentication

### `gh auth: not logged in to any GitHub hosts`

**Symptom**
```
$ gh pr create ...
You are not logged into any GitHub hosts. Run gh auth login to authenticate.
```

**Cause**
The GitHub CLI has no active auth token.

**Fix**
```bash
gh auth login
# Choose: GitHub.com → HTTPS → "Login with a web browser" → follow the prompt
gh auth status   # verify
```

**Prevention**
Slash commands like `/git-issue` check `gh auth status` before any state-changing action. If you bypass them (use `gh` directly), keep this in mind.

---

### `Permission denied (publickey)`

**Symptom**
```
$ git push origin develop
git@github.com: Permission denied (publickey).
fatal: Could not read from remote repository.
```

**Cause**
You are pushing over SSH but the SSH key is not registered with GitHub (or `ssh-agent` is not loaded).

**Fix**
Either:
- Switch the remote to HTTPS (recommended — matches `gh` defaults):
  ```bash
  git remote set-url origin https://github.com/<owner>/<repo>.git
  ```
- Or register the SSH key:
  ```bash
  cat ~/.ssh/id_ed25519.pub        # or id_rsa.pub
  # Paste into https://github.com/settings/keys → New SSH key
  ssh -T git@github.com            # verify
  ```

**Prevention**
`gh repo create` defaults to HTTPS, so following the skill's setup workflow avoids this entirely.

---

### `error: GH001: Large files detected. You may want to try Git Large File Storage`

**Symptom**
GitHub rejects a push because a file exceeds 100 MB.

**Cause**
You committed a large binary (build artifact, video, dataset, etc.) and tried to push it.

**Fix**
```bash
# Remove the file from the latest commit
git reset HEAD~1
echo "<large-file>" >> .gitignore
git add .gitignore
git commit -m "chore: ignore large artifact"

# If the file is already in history, removal requires history rewriting
# (use git-filter-repo or bfg-repo-cleaner; coordinate with the team before doing this)
```

For files you DO need to track:
```bash
git lfs install
git lfs track "*.psd"
git add .gitattributes
git commit -m "chore: track psd files with Git LFS"
```

**Prevention**
Add large-file patterns to `.gitignore` before the first commit. See `repo-setup.md` stack-specific gitignores.

---

## Pushing & syncing

### `rejected (non-fast-forward)`

**Symptom**
```
$ git push origin feature/42-foo
! [rejected]   feature/42-foo -> feature/42-foo (non-fast-forward)
hint: Updates were rejected because the tip of your current branch is behind
```

**Cause**
Someone else (or another machine of yours) pushed commits to this branch after you last fetched. Your local branch is behind the remote.

**Fix**
```bash
git fetch origin
git rebase origin/feature/42-foo
# Resolve any conflicts, then:
git push --force-with-lease
```

`--force-with-lease` will fail if the remote moved again since your fetch — that is intentional, it prevents overwriting someone else's work.

**Prevention**
- Treat branches as "owned by one person at a time" — coordinate before sharing
- Always `git fetch` before starting work on an existing branch

---

### `error: failed to push some refs` (after rebase)

**Symptom**
After a rebase, `git push` fails with a non-fast-forward error.

**Cause**
Rebase rewrote the commit history; the remote no longer matches your local.

**Fix**
```bash
git push --force-with-lease
```

Never `git push --force` — it overwrites without checking, which can erase teammates' commits. `--force-with-lease` only succeeds if the remote tip matches your last `git fetch`.

**Prevention**
Rebase only branches you own. Never rebase a branch that others are pushing to.

---

### `fatal: refusing to merge unrelated histories`

**Symptom**
```
$ git pull origin develop
fatal: refusing to merge unrelated histories
```

**Cause**
The local and remote branches were created independently (no common ancestor commit). Usually happens when you `git init` a directory that already has commits, then add a remote that has its own commits.

**Fix**
Decide which side you want to keep:
```bash
# Keep the remote, discard local
git fetch origin
git reset --hard origin/develop

# OR merge anyway (creates a weird-looking history)
git pull origin develop --allow-unrelated-histories
```

**Prevention**
- Always `git clone` an existing repo instead of `git init` + add remote
- If you must init a new repo, push the empty repo first, then add files

---

## Merging & conflicts

### `package-lock.json` conflict

**Symptom**
After `git rebase` or `git merge`, `package-lock.json` shows hundreds of conflict markers.

**Cause**
Two branches changed dependencies independently. Lockfile conflicts cannot be meaningfully merged line-by-line.

**Fix**
Regenerate the lockfile from `package.json`:
```bash
# Take whichever package.json you want as source of truth, then:
rm package-lock.json
npm install
git add package-lock.json
git rebase --continue   # or git merge --continue
```

For `pnpm` / `yarn` / `bun`, swap the install command.

**Prevention**
Coordinate dependency upgrades with the team. If multiple PRs touch deps, merge them sequentially and rebase the second on the first before opening it.

---

### Conflict in a file you do not understand

**Symptom**
Rebase paused on a file you did not write and do not understand.

**Fix**
```bash
# Inspect what both sides changed
git log --merge --oneline -p -- <conflicted-file>

# Talk to the original author before guessing
gh pr view <pr-number>   # or git blame <file>

# When in doubt, abort and ask:
git rebase --abort
```

**Prevention**
Keep branches short-lived. The longer a branch lives, the more likely it conflicts with code touched by others.

---

## Commits

### Pre-commit / commit-msg hook rejected my commit

**Symptom**
```
$ git commit -m "fix stuff"
[commit-msg-validator] BLOCKED
The commit message does not follow Conventional Commits format.
```

**Cause**
The `commit-msg-validator` hook (Claude Code) or the `.git/hooks/commit-msg` hook (git-level) rejected the message.

**Fix**
Rewrite the message in Conventional Commits format:
```bash
git commit -m "fix(auth): handle null user response from oauth callback"
```

For multi-line messages, use heredoc:
```bash
git commit -m "$(cat <<'EOF'
fix(auth): handle null user response from oauth callback

OAuth providers sometimes return 200 with an empty user object when
the user denies scope. We treated that as success and crashed downstream.

Closes #42
EOF
)"
```

**Prevention**
Use `/git-commit` — it auto-generates Conventional Commits format from the diff.

---

### `git commit --amend` after push

**Symptom**
```
$ git commit --amend
$ git push
! [rejected] non-fast-forward
```

**Cause**
`--amend` rewrites the last commit (new SHA). The remote still has the old one.

**Fix**
```bash
git push --force-with-lease
```

**Prevention**
Do not amend commits that have been pushed and pulled by others. If you need to fix a commit on a shared branch, create a new commit:
```bash
git commit -m "fix(auth): correct previous typo in error message"
```

---

### Accidentally committed to `develop` / `main`

**Symptom**
You realize you committed to the wrong branch (e.g., `develop`) instead of a feature branch.

**Fix**
```bash
# Move the commit to a new branch
git branch feature/<n>-<slug>
# Reset develop back to remote
git fetch origin
git reset --hard origin/develop
# Switch to the new branch — the commit is preserved there
git checkout feature/<n>-<slug>
```

**Prevention**
Install the git `pre-push` hook (`scripts/install-git-hooks.sh`) — it refuses pushes to `main`/`master`. For `develop`, rely on the Claude Code hook `guard-push-to-main` (which does not currently block `develop` — adjust the regex in the hook if you want it to).

---

## `.gitignore`

### `.gitignore` added but the file is still tracked

**Symptom**
You added a file to `.gitignore` but it still shows up in `git status` and gets pushed.

**Cause**
`.gitignore` only affects **untracked** files. Once a file is tracked, Git ignores `.gitignore` for that path.

**Fix**
```bash
git rm --cached <file>           # untrack, keep on disk
git add .gitignore
git commit -m "chore: stop tracking <file>"
git push
```

For an entire ignored directory:
```bash
git rm -r --cached <directory>
```

**Prevention**
Set up `.gitignore` **before** the first commit. See `repo-setup.md` for stack-specific templates.

---

## Repository state

### `fatal: not a git repository`

**Symptom**
```
$ git status
fatal: not a git repository (or any of the parent directories): .git
```

**Cause**
You are not inside a git repository.

**Fix**
- If this is a new project: `git init`
- If you meant to be in an existing repo: `cd <correct-directory>` or `git clone <url>`

**Prevention**
Always check `git rev-parse --show-toplevel` before running git commands in scripts.

---

### Detached HEAD

**Symptom**
```
$ git status
HEAD detached at abc1234
```

**Cause**
You ran `git checkout <commit-sha>` or `git checkout <tag>` instead of a branch name. You are now editing a snapshot in time, not a branch.

**Fix**
```bash
# If you want to keep changes you made here:
git checkout -b temp-branch-name

# If you do not want any changes — return to develop:
git checkout develop
```

**Prevention**
Always use branch names with `git checkout`. If you need to inspect an old commit, use `git show <sha>` or `git log -p <sha>` instead of checking it out.

---

## GitHub-specific

### `gh: command 'pr' takes no positional arguments`

**Symptom**
```
$ gh pr 42
unknown command "42" for "gh pr"
```

**Cause**
You wrote `gh pr <number>` thinking it would show the PR. The correct subcommand is `view`.

**Fix**
```bash
gh pr view 42
```

**Prevention**
`/git-review 42` handles this for you. For direct CLI use, `gh pr --help` lists the subcommands.

---

### `Label not found`

**Symptom**
```
$ gh issue create --label "needs-triage"
HTTP 422: Validation Failed (label 'needs-triage' not found)
```

**Cause**
Custom labels must be created before they can be applied. New repos have only three default labels: `bug`, `enhancement`, `documentation`.

**Fix**
```bash
gh label create needs-triage --color FFA500 --description "Needs initial assessment"
# Then retry:
gh issue create --label "needs-triage" ...
```

**Prevention**
Slash commands like `/git-issue` default to using only `bug`, `enhancement`, `documentation` unless you explicitly request otherwise.

---

## Hook-related

### Hook never fires

**Symptom**
You configured `guard-push-to-main` in `~/.claude/settings.json` but it never seems to run.

**Cause**
One of:
- Script is not executable: `chmod +x ~/.agents/skills/github-git/hooks/guard-push-to-main.sh`
- Claude Code session started before the settings change — restart Claude Code
- Wrong matcher — must be `"matcher": "Bash"`, not `"bash"` or `"Bash.*"`

**Fix**
Run `bash ~/.agents/skills/github-git/scripts/verify-install.sh` and address any warnings.

**Prevention**
Always restart Claude Code after editing `~/.claude/settings.json`.

---

### Hook blocked a legitimate command

**Symptom**
A hook rejected a command that you really did need to run (e.g., emergency `git push origin main` during an outage).

**Fix**
- For git-level hooks: `git commit --no-verify` / `git push --no-verify`
- For Claude Code hooks: temporarily comment out the entry in `~/.claude/settings.json`, restart Claude Code, do the operation, re-enable

**Prevention**
If you find yourself bypassing a hook regularly, the rule probably needs adjusting — open an issue against the skill.

---

## Last resort

When nothing here matches, in order of preference:

1. **Read the actual error message.** Git and `gh` errors usually name the failing operation and suggest a fix.
2. **Check the relevant reference file** in this skill — `branching-commits.md`, `pull-requests.md`, etc. — for the workflow context.
3. **Ask `gh` for help**: `gh <command> --help`.
4. **Search the error message verbatim** (in quotes). The first Stack Overflow result is usually correct for common errors.
5. **Open an issue against the skill** if you found a workflow gap.
