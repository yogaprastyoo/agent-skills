# Pull Requests

Complete guide for creating, managing, and merging pull requests.

---

## Workflow

1. Ensure all commits are pushed to the remote branch
2. Create PR into `develop` (or `main` for hotfixes/releases)
3. Fill in the PR template
4. Auto-assign labels and reviewers
5. Run self-review checklist
6. Wait for CI checks to pass
7. Address review feedback
8. Merge and clean up

---

## Step 1: Pre-PR Checklist

Before creating a PR, verify these conditions are met:

```bash
# Ensure you are on your feature branch
git branch --show-current

# Ensure branch is up-to-date with develop
git fetch origin
git rebase origin/develop

# Ensure all changes are committed
git status

# Ensure tests pass locally
npm test  # or your project's test command

# Ensure linter passes
npm run lint  # or your project's lint command
```

If any of the above fail, fix them before creating the PR.

---

## Step 2: Create PR via GitHub CLI

Always use heredoc — no temp files. Only use default GitHub labels (`bug`, `enhancement`, `documentation`) unless custom labels have been created first with `gh label create`.

### Standard feature/bugfix PR (into develop)

```bash
gh pr create \
  --base develop \
  --title "[Feature] Add JWT refresh token mechanism" \
  --body "$(cat <<'EOF'
## Description

...

## Changes

- Change 1
- Change 2

## Related Issues

Closes #42

## Type of Change

- [x] New feature

## Self-Review Checklist

- [ ] Self-review performed
- [ ] No secrets committed
- [ ] No debug statements left
EOF
)" \
  --assignee "@me"
```

### Hotfix PR (into main)

```bash
gh pr create \
  --base main \
  --title "[Hotfix] Handle null payment response" \
  --body "$(cat <<'EOF'
## Description

...

## Related Issues

Closes #78

## Type of Change

- [x] Bug fix

## Self-Review Checklist

- [ ] Self-review performed
- [ ] No secrets committed
EOF
)" \
  --assignee "@me"
```

### Release PR (into main)

```bash
gh pr create \
  --base main \
  --title "[Release] v1.2.0" \
  --body "$(cat <<'EOF'
## Description

Release v1.2.0 — see CHANGELOG.md for details.

## Type of Change

- [x] Refactoring

## Self-Review Checklist

- [ ] CHANGELOG updated
- [ ] Version bumped
EOF
)" \
  --assignee "@me"
```

---

## Step 3: PR Title Format

Use the same type prefix as the issue:

```
[Type] Short description of the change
```

**Good examples:**

```
[Feature] Add JWT refresh token mechanism
[Bug] Fix login crash when email contains uppercase
[Hotfix] Handle null response from payment gateway
[Refactor] Extract payment logic into dedicated service
[Docs] Add API authentication guide
[Release] v1.2.0
```

**Bad examples:**

```
Update code
Fix
PR for issue #42
WIP
Changes
```

---

## Step 4: PR Body Structure

Every PR MUST include these sections. Use the template from `assets/pr-template.md` or follow this structure:

```markdown
## Description

Brief explanation of what this PR does and why.

## Changes

- Added refresh token generation in auth service
- Added refresh endpoint in auth controller
- Added token rotation logic
- Added HTTP-only cookie handling

## Related Issues

Closes #42

## Type of Change

- [ ] Bug fix (non-breaking change that fixes an issue)
- [ ] New feature (non-breaking change that adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to change)
- [ ] Refactoring (no functional changes)
- [ ] Documentation update
- [ ] CI/CD changes

## Screenshots (if applicable)

Include before/after screenshots for UI changes.

## Self-Review Checklist

- [ ] Code follows the project's style guidelines
- [ ] Self-review of the code has been performed
- [ ] Comments added for complex logic
- [ ] Tests added or updated for the changes
- [ ] All existing tests pass
- [ ] Documentation updated (if applicable)
- [ ] No secrets or credentials committed
- [ ] No unnecessary console.log or debug statements
```

---

## Step 5: Auto-Detection for PR

Claude MUST automatically determine the following when creating a PR. The user should NOT need to specify these manually.

### Base branch detection

| Context | Base Branch |
|---------|------------|
| Feature, bugfix, refactor, docs, ci branches | `develop` |
| Hotfix branches (`hotfix/*`) | `main` |
| Release branches (`release/*`) | `main` |

### Title detection

Derive the PR title from the branch name and issue title:

| Branch | Resulting PR Title |
|--------|--------------------|
| `feature/42-jwt-refresh-token` | `[Feature] Add JWT refresh token mechanism` (from issue #42 title) |
| `bugfix/15-fix-uppercase-email` | `[Bug] Fix uppercase email login issue` (from issue #15 title) |
| `hotfix/78-patch-payment-crash` | `[Hotfix] Handle payment crash` (from issue #78 title) |

If issue title is available, use it. Otherwise, derive from the branch slug.

### Label detection

Only use default GitHub labels — do NOT use custom labels unless they have been created first with `gh label create`. Default labels available in every repo: `bug`, `enhancement`, `documentation`.

| Branch Prefix | Label |
|--------------|-------|
| `feature/*` | `enhancement` |
| `bugfix/*` | `bug` |
| `hotfix/*` | `bug` |
| `docs/*` | `documentation` |
| `refactor/*`, `ci/*`, `release/*` | *(no label — these don't map to default labels)* |

If the project has custom labels set up, use them. Otherwise, omit `--label` rather than using a non-existent label.

### Reviewer detection

If CODEOWNERS is configured, GitHub auto-assigns reviewers. Otherwise, Claude should prompt the user for reviewer assignment.

---

## Step 6: Self-Review

Before requesting reviews from others, the PR author MUST perform a self-review.

### Self-review process

```bash
# View the full diff of your PR
gh pr diff

# Or view in browser
gh pr view --web
```

### What to check during self-review

**Code quality:**
- No leftover debug statements (`console.log`, `print`, `debugger`)
- No commented-out code blocks
- No hardcoded values that should be configuration
- No TODO comments without a linked issue
- Variable and function names are clear and consistent

**Logic:**
- Edge cases are handled (null, empty, boundary values)
- Error handling is in place
- No off-by-one errors
- No race conditions in async code
- No unintended side effects

**Security:**
- No secrets, API keys, or credentials in the code
- User input is validated and sanitized
- SQL queries use parameterized statements
- Authentication and authorization checks are present where needed

**Tests:**
- New code has corresponding tests
- Edge cases are tested
- Tests are not fragile or dependent on external state
- Test names clearly describe what they verify

**Documentation:**
- Complex logic has comments explaining WHY
- Public API has documentation (JSDoc, docstring, etc.)
- README updated if behavior changed
- CHANGELOG updated if user-facing change

---

## Step 7: Address Review Feedback

When reviewers leave feedback:

### Responding to comments

- Address every comment — either make the change or explain why not
- Use "resolved" to mark addressed comments
- Do not dismiss reviews without discussion

### Making changes after review

```bash
# Make the requested changes
# ... edit files ...

# Commit with descriptive message
git add .
git commit -m "refactor(auth): address PR review feedback

- Rename token variable for clarity
- Add error handling for edge case
- Update test assertions"

# Push to the same branch
git push
```

Do NOT force push after receiving reviews — it makes it harder for reviewers to see what changed. Use additional commits instead. Squash will happen at merge time.

### Re-requesting review

```bash
gh pr edit <pr-number> --add-reviewer "reviewer-username"
```

---

## Step 8: Merge Strategies

### Squash and merge (recommended for feature/bugfix branches)

Combines all commits into a single commit on `develop`. Keeps the history clean.

```bash
gh pr merge <pr-number> --squash --delete-branch
```

Use this for: `feature/*`, `bugfix/*`, `refactor/*`, `docs/*`, `ci/*`

### Merge commit (for release/hotfix branches)

Preserves the full commit history with a merge commit.

```bash
gh pr merge <pr-number> --merge --delete-branch
```

Use this for: `release/*`, `hotfix/*`

### Auto-detection

Claude MUST automatically select the merge strategy based on branch prefix:

| Branch Prefix | Merge Strategy |
|--------------|----------------|
| `feature/*` | Squash and merge |
| `bugfix/*` | Squash and merge |
| `refactor/*` | Squash and merge |
| `docs/*` | Squash and merge |
| `ci/*` | Squash and merge |
| `hotfix/*` | Merge commit |
| `release/*` | Merge commit |

### Post-merge cleanup

After merge, verify the branch is deleted:

```bash
# Delete local branch
git branch -d feature/42-jwt-refresh-token

# Switch back to develop and pull latest
git checkout develop
git pull origin develop
```

---

## PR Size Guidelines

Keep PRs small and focused for faster, more effective reviews.

| PR Size | Lines Changed | Review Time | Quality |
|---------|--------------|-------------|---------|
| Small | < 200 | Quick, thorough | Best |
| Medium | 200-400 | Reasonable | Good |
| Large | 400-800 | Slow, less thorough | Risky |
| Monster | 800+ | Very slow, likely superficial | Avoid |

If a PR exceeds 400 lines:
- Consider splitting into smaller, sequential PRs
- Each PR should be independently mergeable
- Use stacked PRs if changes depend on each other

---

## Guidelines

- Every PR must reference an issue with `Closes #N`
- Every PR must pass CI before merge
- Every PR must have at least one review (self-review for solo projects)
- PR title and body must be written in English
- Do not merge your own PR without at least one approval (if team project)
- Do not leave PRs open for more than 3 days — if blocked, communicate in the PR comments
- Use draft PRs for work in progress that needs early feedback

### Draft PRs

Create a draft PR when you want early feedback before the code is complete:

```bash
gh pr create \
  --base develop \
  --title "[WIP] Add JWT refresh token mechanism" \
  --body "Early draft for feedback. Not ready for merge." \
  --draft
```

Mark as ready when complete:

```bash
gh pr ready <pr-number>
```

---

## Gotchas

- **PR base branch**: Claude auto-detects the base branch, but always verify. A feature PR targeting `main` instead of `develop` will include unrelated diffs.
- **Squash commit message**: When squashing, GitHub uses the PR title as the commit message by default. Ensure the PR title follows conventional commit format for a clean history.
- **Review dismissal**: If you push new commits to a PR that was already approved, some branch protection rules will dismiss the previous approval. The reviewer will need to re-approve.
- **Merge conflicts in PR**: If GitHub shows merge conflicts, do NOT resolve them in the GitHub UI. Instead, rebase locally and push:
  ```bash
  git fetch origin
  git rebase origin/develop
  # resolve conflicts
  git push --force-with-lease
  ```
- **Auto-delete branches**: Enable "Automatically delete head branches" in repository settings to avoid stale branches accumulating.
- **CI on draft PRs**: Some CI configurations skip draft PRs. Ensure your workflow includes `types: [opened, synchronize, reopened, ready_for_review]` in the PR trigger.
