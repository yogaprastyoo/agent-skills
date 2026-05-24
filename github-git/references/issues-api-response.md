# API Response in Issues

Backend endpoint issues MUST include an `## API Response` section showing the request payload and every possible response (success + each error case). This file is the authoritative source — `SKILL.md` and `issues.md` both link here.

For the response envelope itself, this skill defers to the [`api-response`](https://github.com/yogaprastyoo/agent-skills/tree/develop/api-response) skill (when installed). The format below is a summary; the linked skill is the source of truth.

---

## When this section is required

Include `## API Response` whenever the issue creates, modifies, or removes a backend endpoint that returns a body. Concretely:

- New REST endpoint (`POST /api/users`, `GET /api/orders/:id`, etc.)
- Change to an existing endpoint's request/response shape
- Bug fix that alters the response (status code, error structure, missing field)

Omit the section for:

- Pure mobile/UI issues that consume an existing, unchanged endpoint
- Test-only issues (adding test coverage without changing behavior)
- Documentation, refactoring, or infrastructure issues

---

## Required envelope

```json
// Success
{
  "success": true,
  "message": "Human-readable summary of what happened",
  "data": { /* the actual payload, or {} when there's no payload to return */ }
}

// Error
{
  "success": false,
  "message": "Human-readable summary of what went wrong",
  "errors": null  // or { fieldName: ["error 1", "error 2"], ... } for validation failures
}
```

`success` is always a boolean. `message` is always a string. The third field is `data` for success or `errors` for failure — never both, never neither.

For paginated list endpoints, `data` contains the items array AND a `pagination` object:

```json
{
  "success": true,
  "message": "Users fetched",
  "data": {
    "items": [ /* ... */ ],
    "pagination": {
      "page": 1,
      "pageSize": 20,
      "total": 142,
      "totalPages": 8
    }
  }
}
```

---

## Required structure in the issue body

Place `## API Response` between `## Context` and `## Acceptance Criteria`. One subsection per endpoint affected by the issue.

### Per-endpoint subsection

```markdown
### POST /api/v1/users

**Request**

```json
{
  "email": "ada@example.com",
  "password": "<plaintext>",
  "name": "Ada Lovelace"
}
```

**Success — 201 Created**

```json
{
  "success": true,
  "message": "User registered",
  "data": {
    "id": "usr_01H...",
    "email": "ada@example.com",
    "name": "Ada Lovelace"
  }
}
```

**Error — 400 Bad Request** (validation)

```json
{
  "success": false,
  "message": "Validation failed",
  "errors": {
    "email": ["Email is already registered"],
    "password": ["Password must be at least 8 characters"]
  }
}
```

**Error — 500 Internal Server Error**

```json
{
  "success": false,
  "message": "Unexpected error",
  "errors": null
}
```
```

---

## Rules

1. **One example per endpoint.** If the issue touches three endpoints, the section has three subsections.
2. **Show every relevant error.** At minimum: validation error (if request body), auth error (if endpoint requires auth), and 500. Skip error cases the endpoint genuinely cannot return.
3. **Include the actual status code** in the heading (`201 Created`, not just "success").
4. **Do NOT invent custom shapes.** No `error: "..."` instead of `errors: {...}`. No `result` instead of `data`. The envelope is fixed.
5. **For list endpoints, `pagination` lives inside `data`** — never as a sibling of `data`.
6. **Project-specific additions** (e.g., an auth `code` field, a `meta` block) must come from that project's Technical Document — never invented in the issue.

---

## Project-specific overrides

If a project extends the envelope (for example, TalentHub backend adds a `code` field for auth responses), check the project's Technical Document and per-project skill (e.g., `talenthub-backend`) BEFORE writing the response example. Project-specific overrides take precedence over this file's defaults.

When in doubt, ask the project owner. Inventing a custom shape and shipping it to docs is harder to reverse than asking.

---

## Cross-reference

- Issue structure overall → `issues.md`
- Branch naming after issue is filed → `branching-commits.md`
- PR template (which surfaces the same API context for reviewers) → `pull-requests.md`
- Code review for endpoint changes → `code-review.md`
- Standard envelope definition (authoritative) → `api-response` skill, if installed
