# Code Review

Complete guide for reviewing pull requests effectively and providing constructive feedback.

---

## Workflow

1. Understand the context (read the issue and PR description)
2. Review the diff systematically
3. Run the code locally (if needed)
4. Leave feedback using the appropriate comment type
5. Submit review with a clear verdict

---

## Step 1: Understand the Context

Before reading any code, understand WHAT the PR is doing and WHY.

```bash
# View PR details
gh pr view <pr-number>

# View the linked issue
gh issue view <issue-number>
```

Read in this order:
1. The linked issue — understand the problem and acceptance criteria
2. The PR description — understand the approach taken
3. The list of changed files — get a high-level picture of scope

If the PR lacks a description or linked issue, request it before reviewing.

---

## Step 2: Review the Diff

### Via CLI

```bash
# View the full diff
gh pr diff <pr-number>

# View changed files list
gh pr diff <pr-number> --name-only
```

### Via browser

```bash
gh pr view <pr-number> --web
```

### Review order

Review files in this order for maximum effectiveness:

1. **Schema/model changes** — database migrations, type definitions, interfaces. These are the foundation that everything else depends on.
2. **Core logic** — services, business logic, algorithms. This is where most bugs hide.
3. **API layer** — controllers, routes, handlers. Check that inputs are validated and outputs match the contract.
4. **Tests** — verify they cover the changes and edge cases. Tests also serve as documentation for intended behavior.
5. **Configuration** — environment files, CI config, package changes. Easy to overlook but can cause production issues.
6. **Documentation** — README updates, comments, JSDoc. Check accuracy against the actual implementation.

---

## Step 3: Review Checklist

Use this checklist when reviewing every PR. Not all items apply to every PR — focus on the ones relevant to the changes.

### Correctness

- [ ] Code does what the PR description claims
- [ ] All acceptance criteria from the linked issue are met
- [ ] Edge cases are handled (null, empty, boundary values, invalid input)
- [ ] Error handling is appropriate and consistent
- [ ] No off-by-one errors in loops or array operations
- [ ] Async operations are properly awaited
- [ ] No race conditions in concurrent code

### Security

- [ ] No secrets, API keys, or credentials in the code
- [ ] User input is validated and sanitized
- [ ] SQL queries use parameterized statements (no string concatenation)
- [ ] Authentication and authorization checks are present
- [ ] Sensitive data is not logged or exposed in error messages
- [ ] Dependencies added are from trusted sources

### Performance

- [ ] No unnecessary database queries (N+1 problem)
- [ ] No blocking operations on the main thread
- [ ] Large data sets are paginated or streamed
- [ ] Expensive operations are cached where appropriate
- [ ] No memory leaks (event listeners removed, subscriptions cleaned up)

### Maintainability

- [ ] Code is readable without needing the author to explain it
- [ ] Functions and variables have clear, descriptive names
- [ ] No duplicated logic that should be extracted
- [ ] Complex logic has comments explaining WHY (not WHAT)
- [ ] No dead code or commented-out blocks
- [ ] Consistent with existing codebase patterns

### Tests

- [ ] New code has corresponding tests
- [ ] Edge cases and error paths are tested
- [ ] Tests are independent and do not rely on execution order
- [ ] Test names clearly describe the scenario being tested
- [ ] No flaky tests (random failures, timing dependencies)
- [ ] Mocks and stubs are appropriate (not over-mocking)

---

## Step 4: Leaving Feedback

### Comment types

Use prefixes to make the intent of each comment clear:

| Prefix | Meaning | Action Required |
|--------|---------|----------------|
| `blocker:` | Must fix before merge | Yes — PR cannot be merged |
| `suggestion:` | Recommended improvement | Optional — author decides |
| `question:` | Need clarification | Yes — author must respond |
| `nitpick:` | Minor style or preference | No — take it or leave it |
| `praise:` | Something done well | No — positive reinforcement |

### Writing effective feedback

**Be specific.** Point to the exact line and explain the issue.

```
# BAD
This function is wrong.

# GOOD
blocker: This function does not handle the case where `user` is null.
Line 42 will throw a TypeError if the user lookup returns no result.
Consider adding a null check before accessing `user.email`.
```

**Explain WHY, not just WHAT.** Help the author understand the reasoning.

```
# BAD
suggestion: Use a Map instead of an object.

# GOOD
suggestion: Consider using a Map instead of a plain object here.
Maps have O(1) lookup and handle non-string keys, which matters
because the user IDs could be numeric in some cases. This also
avoids potential prototype pollution issues.
```

**Offer alternatives.** When suggesting a change, show how you would do it.

```
suggestion: This nested if-else chain is hard to follow.
Consider using early returns to flatten the logic:

\`\`\`javascript
if (!user) return res.status(404).json({ error: 'User not found' });
if (!user.isActive) return res.status(403).json({ error: 'Account disabled' });

// Happy path continues here
const token = generateToken(user);
return res.json({ token });
\`\`\`
```

**Acknowledge good work.** Positive feedback reinforces good practices.

```
praise: Clean separation of concerns here. The validation logic
in a separate function makes this very testable.
```

### Batch related comments

If the same issue appears in multiple places, leave one detailed comment and reference it in others:

```
# First occurrence (detailed)
blocker: Error responses are not consistent with our API standard.
We use { error: string, code: string } format. See API guidelines
in docs/api-standards.md.

# Subsequent occurrences (reference)
blocker: Same error format issue as noted in auth-controller.ts line 42.
```

---

## Step 5: Submit Review

### Via CLI

```bash
# Approve
gh pr review <pr-number> --approve --body "Looks good. Clean implementation."

# Request changes
gh pr review <pr-number> --request-changes --body "A few blockers need to be addressed before merge. See inline comments."

# Comment only (no verdict)
gh pr review <pr-number> --comment --body "Left some suggestions. No blockers."
```

### Verdict guidelines

| Verdict | When to Use |
|---------|-------------|
| **Approve** | All acceptance criteria met, no blockers, code is ready to merge |
| **Request changes** | There are `blocker:` comments that must be addressed |
| **Comment** | Only `suggestion:`, `question:`, or `nitpick:` comments — no blockers |

### Review response time

- Aim to review PRs within **4 hours** during working hours
- If you cannot review in time, let the author know
- Do not let PRs sit unreviewed for more than **1 business day**

---

## Re-Review After Changes

When the author pushes new commits to address feedback:

```bash
# View only the new changes since your last review
gh pr diff <pr-number> --since "2026-04-14"

# Or view in browser (GitHub shows new changes since last review)
gh pr view <pr-number> --web
```

Focus on:
- Whether your blockers were addressed correctly
- Whether the fix introduced new issues
- No need to re-review unchanged files

---

## Common Review Patterns

### Pattern: Missing error handling

```
blocker: No error handling for the database query on line 35.
If the query fails, the unhandled promise rejection will crash the server.

Wrap in try-catch and return a 500 response:
\`\`\`javascript
try {
  const users = await db.query('SELECT * FROM users');
  return res.json(users);
} catch (error) {
  logger.error('Failed to fetch users', error);
  return res.status(500).json({ error: 'Internal server error' });
}
\`\`\`
```

### Pattern: Security vulnerability

```
blocker: SQL injection vulnerability on line 28.
The query uses string concatenation with user input:
  `SELECT * FROM users WHERE id = '${userId}'`

Use parameterized query instead:
\`\`\`javascript
db.query('SELECT * FROM users WHERE id = $1', [userId])
\`\`\`
```

### Pattern: Missing test coverage

```
suggestion: The happy path is tested, but there are no tests for:
- What happens when the user is not found (404 case)
- What happens when the database connection fails (500 case)
- What happens with invalid input (400 case)

These edge cases are where most production bugs occur.
```

### Pattern: Over-engineering

```
suggestion: This factory pattern with 3 abstraction layers seems
like overkill for what is currently a single implementation.
Consider using a simpler approach now and extracting the
abstraction when a second implementation is actually needed (YAGNI).
```

---

## Guidelines

- Review the code, not the author — keep feedback objective and impersonal
- Assume positive intent — the author likely had a reason for their approach
- Ask questions before making assumptions about incorrect code
- Be timely — slow reviews block the team and increase merge conflicts
- Keep review scope focused on the PR changes — do not request unrelated improvements
- If a change is correct but you would have done it differently, use `nitpick:` or skip it
- Approve PRs that are "good enough" — do not block for stylistic preferences
- If a PR is too large to review effectively, request it be split

---

## Gotchas

- **Review your own PRs first**: Always self-review before requesting others. It catches obvious issues and saves reviewer time. See `references/pull-requests.md` for the self-review checklist.
- **Approve does not mean perfect**: Approve means "this is safe to merge and meets requirements." Minor suggestions can be addressed in follow-up PRs.
- **Do not rewrite in reviews**: If you find yourself rewriting large portions of the code in review comments, schedule a pairing session instead. It is faster and more collaborative.
- **Stale reviews**: If significant changes are pushed after your review, your approval may be dismissed by branch protection. Re-review the new changes before re-approving.
- **Review fatigue**: If you are reviewing more than 400 lines of changed code, your attention will drop. Ask the author to split large PRs or take a break between review sessions.
- **Conflicting feedback**: If multiple reviewers give conflicting suggestions, the PR author should facilitate a discussion in the PR comments to reach consensus. Do not go back and forth in comments — use a thread or a quick call.
