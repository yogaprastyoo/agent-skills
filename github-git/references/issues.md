# Issue Management

Every issue will be read by a developer or an AI agent. Write it so that the reader can implement the task **without asking a single follow-up question**. Assume the reader has zero prior context about why the task exists.

---

## Workflow

1. Determine issue type → pick label
2. Write a complete issue body
3. Run `gh issue create`
4. Create a branch from the issue number

---

## Step 1: Determine Issue Type

| Type | When | Label |
|------|------|-------|
| Bug | Something is broken or behaving incorrectly | `bug` |
| Feature / Enhancement | New functionality or improvement | `enhancement` |
| Documentation | Docs, comments, README | `documentation` |

Only use these three labels — they exist by default in every GitHub repo. Other labels must be created first with `gh label create` or the command will fail.

---

## Step 2: Write a Complete Issue Body

### What "complete" means

A complete issue answers all of these questions:

- **What** is the problem or task?
- **Why** does it need to be done? (business reason, bug impact, security risk, etc.)
- **Where** is the relevant code? (file paths, function names, line numbers if known)
- **How** should the reader approach it? (suggested fix, constraints, prior attempts)
- **How do we know it's done?** (acceptance criteria as testable checkboxes)

If any of these questions is unanswered, the issue is incomplete.

### Required sections

```markdown
## Description

[2–5 sentences explaining WHAT the problem/task is and WHY it matters.
Include the user-facing impact or security implication if applicable.]

## Context

[Everything the reader needs to understand the codebase area involved:
- Relevant file paths (e.g. `src/app/api/auth/logout/route.ts`)
- How the current code works and what is wrong with it
- Any prior attempts or decisions already made
- Links to related PRs, issues, or external docs]

## API Response

<!-- REQUIRED for backend endpoint issues — omit for mobile, UI/UX, or test-only issues.
Follow the api-response skill format (~/.agents/skills/api-response/SKILL.md).
Include one example per endpoint: success + all relevant errors.
Place this section between Context and Acceptance Criteria. -->

[For each endpoint, show request + success response + all error responses.
Follow the envelope format: { success, message, data } / { success, message, errors }
For list endpoints, include pagination inside data.
Check the project's Technical Document for project-specific additions (e.g. auth `code` field).]

## Acceptance Criteria

- [ ] Specific, testable requirement — written so anyone can verify it by reading the code or running a test
- [ ] Another requirement
- [ ] Include a test coverage requirement if applicable

## Technical Notes

[Optional. Constraints, edge cases, suggested implementation approach,
or anything that would surprise a reader unfamiliar with this area.]
```

### Rules

- **Description must explain WHY**, not just what. "Fix logout" is not a description. "Logout POST to Laravel is missing X-XSRF-TOKEN — if Sanctum config tightens this will return 419" is a description.
- **Context must include file paths.** Never write "the logout file" — write `src/app/api/auth/logout/route.ts`.
- **Acceptance criteria must be checkboxes** (`- [ ]`). Each item must be independently verifiable.
- **No vague criteria.** "Works correctly" is not a criterion. "Returns 200 and clears `app_session` cookie" is a criterion.
- **Technical Notes is required** whenever the fix is non-obvious, has constraints, or requires knowledge of an external system (e.g. Laravel Sanctum behavior).
- Keep body under 500 words. If you need more, split into multiple issues.

---

## Step 3: Create the Issue

Use heredoc — no temp files:

```bash
gh issue create --title "type: short description" --body "$(cat <<'EOF'
## Description

...

## Context

...

## API Response

<!-- Include this section ONLY for backend endpoint issues -->

**POST /api/v1/resource**

Request:
```json
{ "field": "value" }
```

Success 201:
```json
{ "success": true, "message": "...", "data": {} }
```

Error 400:
```json
{ "success": false, "message": "...", "errors": { "field": "..." } }
```

## Acceptance Criteria

- [ ] ...

## Technical Notes

...
EOF
)" --label "bug"
```

Always use `'EOF'` (single-quoted) to prevent shell variable expansion inside the body.

---

## Title Format

```
type: short description of what needs to be done
```

| Prefix | When |
|--------|------|
| `feat:` | new feature or enhancement |
| `fix:` | bug fix |
| `refactor:` | code improvement without behavior change |
| `test:` | adding or fixing tests |
| `docs:` | documentation only |
| `chore:` | maintenance, deps, config |

Good titles:
```
fix: logout BFF missing CSRF token and stateful headers
feat: add pagination to task list API
test: add unit tests for csrf.ts helpers
docs: document app_session optimistic marker in proxy.ts
```

Bad titles:
```
fix stuff
update logout
new feature
```

---

## Complete Example

```bash
gh issue create --title "fix: logout BFF missing CSRF token and stateful headers" --body "$(cat <<'EOF'
## Description

`src/app/api/auth/logout/route.ts` sends a POST to Laravel without a CSRF token
or stateful headers. This works today because Sanctum's current config is lenient,
but it will return 419 if config tightens. It is also inconsistent with how
`login/route.ts` and `register/route.ts` work.

## Context

The BFF pattern was introduced in PR #8. Login and register routes both:
1. Call `fetchCsrfTokens(origin)` to get `XSRF-TOKEN` from Laravel
2. Forward `Cookie`, `X-XSRF-TOKEN`, `Origin`, and `Referer` to Laravel

The logout route skips all of these. It also:
- Uses `credentials: 'include'` which is ignored by Node.js fetch (browser-only)
- Does not wrap in `try/catch` like login/register do
- Sets `app_session` clear cookie without the `secure` flag (missing `secure: request.nextUrl.protocol === 'https:'`)

Relevant helpers are already available in `src/lib/csrf.ts`:
- `fetchCsrfTokens(origin)` — returns `{ cookieHeader, xsrfToken }`
- `createStatefulRequestHeaders(origin)` — returns `{ Origin, Referer }`
- `getSetCookies(response)` — returns `string[]` of Set-Cookie headers

## Acceptance Criteria

- [ ] Call `fetchCsrfTokens(origin)` before POST to `/api/auth/logout`
- [ ] Forward `X-XSRF-TOKEN` header to Laravel
- [ ] Forward `Origin` and `Referer` via `createStatefulRequestHeaders()`
- [ ] Remove dead `credentials: 'include'`
- [ ] Wrap in `try/catch` — always clear `app_session` even if Laravel fails
- [ ] Add `secure: request.nextUrl.protocol === 'https:'` to `app_session` clear cookie
- [ ] Forward any `Set-Cookie` from Laravel response

## Technical Notes

Even if the Laravel request fails, the route should return 200 and clear
`app_session` locally. This ensures the user can always log out from the UI
even when the backend is unreachable.
EOF
)" --label "bug"
```

---

## Step 4: Create Branch from Issue

After the issue is created, note the issue number from the output, then:

```bash
git checkout develop
git pull origin develop
git checkout -b bugfix/9-fix-logout-bff   # use prefix matching the issue type
```

Branch prefix map:

| Issue type | Branch prefix |
|------------|---------------|
| `fix:` / `bug` | `bugfix/` |
| `feat:` / `enhancement` | `feature/` |
| `refactor:` | `refactor/` |
| `test:` / `docs:` / `chore:` | `test/`, `docs/`, `chore/` |

---

## Gotchas

- **Label not found**: Only use `bug`, `enhancement`, `documentation` without prior setup. Other labels require `gh label create` first.
- **Heredoc quoting**: Use `'EOF'` not `EOF` — single quotes prevent variable expansion.
- **Auto-close**: `Closes #N` in a PR body only auto-closes the issue when merged into the **default branch** (`develop`). Merging into a feature branch does not close it.
- **One issue per concern**: If the body needs more than 5 acceptance criteria, split into multiple focused issues.
- **Check for duplicates first**: `gh issue list --search "keyword"` before creating.
