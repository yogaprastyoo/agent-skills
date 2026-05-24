# github-git cheatsheet

One-page reference. Print and stick to your monitor.

---

## Branch naming
```
{prefix}/{issue#}-{slug}

feature/42-jwt-refresh-token
bugfix/15-fix-uppercase-email-login
hotfix/78-patch-payment-crash
refactor/33-extract-payment-service
docs/50-update-api-docs
ci/55-add-docker-build-step
release/1.2.0
```

## Branch source → target
| Prefix | From | To |
|---|---|---|
| `feature/`, `bugfix/`, `refactor/`, `docs/`, `ci/` | `develop` | `develop` |
| `hotfix/` | `main` | `main` AND `develop` |
| `release/` | `develop` | `main` AND `develop` |

---

## Conventional commit
```
<type>(<scope>): <description>

[optional body explaining WHY]

Closes #N
```

| Type | Use for |
|---|---|
| `feat` | New feature / functionality |
| `fix` | Bug fix |
| `docs` | Docs/comments only |
| `style` | Format, lint, whitespace |
| `refactor` | Same behavior, cleaner code |
| `test` | Tests added/changed |
| `chore` | Deps, config, maintenance |
| `ci` | Workflows, Dockerfile |
| `perf` | Performance improvement |
| `revert` | Reverts an earlier commit |

**Rules**: imperative ("add", not "added") · lowercase first letter · no period · ≤72 chars subject

---

## Slash commands
```
/git-issue   [type:] <title>     Create issue following team template
/git-commit  [scope]             Auto-detect type, conventional commit
/git-pr      [--draft]           PR with auto base/title/labels
/git-review  <pr-number>         Checklist-driven review + comments
/git-setup   <repo-name>         Bootstrap repo with team defaults
```

---

## Daily git
```bash
# Refresh from develop
git checkout develop && git pull

# New branch
git checkout -b feature/<N>-<slug>

# Stage and check
git status
git diff --cached

# Sync your branch with develop
git fetch origin && git rebase origin/develop

# Push after rebase
git push --force-with-lease

# Push first time (sets upstream)
git push -u origin <branch>
```

---

## Daily gh
```bash
gh auth login                    # Authenticate once
gh auth status                   # Verify

gh issue create                  # Interactive issue
gh issue view <N>                # View issue
gh issue list --search "key"     # Search before creating duplicate

gh pr create --base develop      # Open PR
gh pr view [<N>]                 # View PR (current branch if omitted)
gh pr diff <N>                   # Inspect diff
gh pr checks                     # CI status
gh pr review <N> --approve|--request-changes|--comment --body "..."
gh pr merge <N> --squash --delete-branch
```

---

## Common fixes
| Symptom | Fix |
|---|---|
| `gh: command not found` | `brew install gh` / `apt install gh` |
| `gh not logged in` | `gh auth login` |
| `Permission denied (publickey)` | Switch remote to HTTPS: `git remote set-url origin https://...` |
| `rejected (non-fast-forward)` | `git fetch && git rebase origin/<base> && git push --force-with-lease` |
| `package-lock.json conflict` | `rm package-lock.json && npm install && git add . && git rebase --continue` |
| `commit-msg hook BLOCKED` | Rewrite message in conventional format: `git commit -m "feat(x): real description"` |
| Committed to wrong branch | `git branch new-branch && git reset --hard origin/<correct-branch> && git checkout new-branch` |
| Lost a commit | `git reflog` → `git checkout <sha>` → `git checkout -b recovery` |
| Need to undo last commit (not pushed) | `git reset --soft HEAD~1` (keep changes) or `--hard` (discard) |
| Need to undo last commit (pushed) | `git revert HEAD && git push` |
| Bypass hook (emergency) | `git commit --no-verify` / `git push --no-verify` (document why) |

---

## Hooks
**Claude Code hooks** (wired in `~/.claude/settings.json`):
- `guard-push-to-main` — blocks `git push origin main`
- `commit-msg-validator` — enforces Conventional Commits format

**Git hooks** (per repo, install with):
```bash
bash ~/.agents/skills/github-git/scripts/install-git-hooks.sh
```
- `commit-msg` — catches heredoc/`-F file` commits
- `pre-push` — blocks pushes to `refs/heads/main`

**Verify everything is set up**:
```bash
bash ~/.agents/skills/github-git/scripts/verify-install.sh
```

---

## Merge strategy
| Branch | Strategy |
|---|---|
| `feature/`, `bugfix/`, `refactor/`, `docs/`, `ci/` | `--squash` (clean commit on develop) |
| `hotfix/`, `release/` | `--merge` (preserve history) |

Always add `--delete-branch` to clean up after merge.

---

## PR title format
```
[Type] Short description

[Feature] Add JWT refresh token mechanism
[Bug] Fix login crash when email contains uppercase
[Hotfix] Handle null response from payment gateway
[Refactor] Extract payment logic into dedicated service
[Docs] Add API authentication guide
[Release] v1.2.0
```

---

## Review comment prefixes
| Prefix | Required action |
|---|---|
| `blocker:` | Must fix — PR can't merge |
| `suggestion:` | Optional — author decides |
| `question:` | Author must respond |
| `nitpick:` | Take it or leave it |
| `praise:` | Positive reinforcement |

---

## Forbidden in any Git/GitHub output
- `Co-Authored-By: Claude`
- `🤖 Generated with Claude Code`
- Any mention of AI/automation tools

Applies to: commit messages, PR titles, PR bodies, issue bodies, comments, release notes.

---

**See also**: `SKILL.md` · `references/troubleshooting.md` · `references/advanced-operations.md` · `examples/` · `hooks/README.md`
