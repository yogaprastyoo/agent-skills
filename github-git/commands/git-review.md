---
description: Review a pull request using the team's checklist (correctness, security, performance, tests) and post inline feedback
argument-hint: <PR number or URL>
---

# /git-review

Review a pull request systematically using the github-git review checklist. Reads the PR + linked issue, walks through every applicable check, and posts findings as inline comments on GitHub.

## What this command does

1. Resolves `$ARGUMENTS` to a PR number (accepts URL, number, or "current" for the PR of the current branch)
2. Fetches the PR metadata and the linked issue
3. Reads the full diff
4. Walks through the review checklist from `references/code-review.md`
5. Drafts comments with the correct prefix (`blocker:`, `suggestion:`, `question:`, `nitpick:`, `praise:`)
6. Asks the user to confirm the verdict (approve / request changes / comment)
7. Posts the review via `gh pr review`

## Workflow

When invoked:

### Step 1 — Resolve PR identifier

`$ARGUMENTS` can be:
- `42` → PR number 42 in current repo
- `https://github.com/owner/repo/pull/42` → extract owner/repo/42
- `current` or empty when on a branch with an open PR → use `gh pr view --json number --jq '.number'`
- empty without an open PR → stop and ask user

### Step 2 — Verify prerequisites

```bash
gh auth status
gh pr view <pr-number> --json number,title,baseRefName,headRefName,author,body
```

If PR not found, stop with a clear error.

### Step 3 — Fetch context

```bash
# PR details
gh pr view <pr-number>

# Diff
gh pr diff <pr-number>

# Changed files (for scope assessment)
gh pr diff <pr-number> --stat

# Linked issue
ISSUE_NUM=$(gh pr view <pr-number> --json body --jq '.body' | grep -oE 'Closes #[0-9]+' | head -1 | grep -oE '[0-9]+')
gh issue view "$ISSUE_NUM"
```

If no linked issue → flag as `blocker:` ("PR must link an issue via `Closes #N`"). Do not skip the review.

### Step 4 — Assess scope

If diff > 400 lines changed, warn: PR is too large for thorough review. Recommend splitting. Continue review but mention size in the verdict.

### Step 5 — Read in review order

Per `references/code-review.md`:
1. Schema/model changes (migrations, type definitions, interfaces)
2. Core logic (services, business logic, algorithms)
3. API layer (controllers, routes, handlers)
4. Tests
5. Configuration (env, CI, package changes)
6. Documentation

### Step 6 — Walk the checklist

For each section in `references/code-review.md`, evaluate applicable items:

- **Correctness** — does it match the PR description and acceptance criteria? Edge cases handled?
- **Security** — secrets, input validation, SQL injection, auth/authz, sensitive logging
- **Performance** — N+1, blocking ops, pagination, caching, memory leaks
- **Maintainability** — naming, duplication, comments, dead code, consistency
- **Tests** — coverage, edge cases, independence, naming, no flakiness

### Step 7 — Draft comments

For each finding, use the right prefix:

| Prefix | Use when |
|--------|----------|
| `blocker:` | Must fix before merge (security, correctness, missing acceptance criteria) |
| `suggestion:` | Recommended improvement — author decides |
| `question:` | Need clarification — author must respond |
| `nitpick:` | Minor style/preference — take or leave |
| `praise:` | Positive reinforcement for something done well |

Be specific: cite file, line, and explain WHY. Offer alternatives.

### Step 8 — Compose review

Group findings into:
- Summary (1–2 sentences on overall quality)
- Blockers (must-fix list)
- Suggestions
- Questions
- Praise

Show the user the full draft. Ask for confirmation and verdict:

| Verdict | When to use |
|---------|-------------|
| `--approve` | No blockers, acceptance criteria met |
| `--request-changes` | One or more `blocker:` findings |
| `--comment` | Only `suggestion:` / `question:` / `nitpick:` |

### Step 9 — Post the review

```bash
gh pr review <pr-number> \
  --<verdict> \
  --body "$(cat <<'EOF'
## Summary

...

## Blockers

...

## Suggestions

...

## Praise

...
EOF
)"
```

For inline comments on specific lines, use `gh api` with the review endpoint, or paste them into the review body with `path:line` references.

### Step 10 — Report

Print confirmation:

```
Review posted on PR #42 (request-changes): https://github.com/.../pull/42#pullrequestreview-...
```

## Constraints

- MUST read the linked issue before reviewing the diff — acceptance criteria drive correctness checks
- MUST use the prefix system (`blocker:`, `suggestion:`, etc.)
- MUST be specific — never "this is wrong"; always cite line and explain
- MUST NOT include `Co-Authored-By: Claude`, AI mentions, or "Generated with Claude" in the review body
- MUST NOT request changes on stylistic preferences alone — use `nitpick:` instead
- MUST NOT approve a PR with `blocker:` findings open
- If reviewing your own PR (self-review), still walk the full checklist — write findings in the PR body or as comments, do not submit a self-approval

## Example invocations

```
/git-review 42
/git-review https://github.com/yogaprastyoo/agent-skills/pull/12
/git-review current
```

## See also

- `references/code-review.md` — full checklist, comment patterns, verdict guidelines
- `references/pull-requests.md` — self-review process (use this before requesting reviews from others)
