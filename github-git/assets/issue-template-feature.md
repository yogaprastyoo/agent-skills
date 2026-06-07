<!--
Feature/enhancement template for github-git skill.
See references/issues.md for the full structure rules.
Title format: feat: <what to build>.  Example: feat: add JWT refresh token mechanism.
Apply label: enhancement.
-->

## Description

<!-- What needs to be built and why? 2–5 sentences explaining the task and its impact.
Lead with the business/user motivation, not the technical implementation.
Include what is IN scope in the last sentence (e.g. "This issue covers X, Y, and Z.").
Do NOT add a ## Scope section — OUT of scope belongs in Technical Notes. -->

## Context

<!-- Everything needed to understand the codebase area involved:
- Relevant file paths (e.g. `src/services/auth.ts`, `src/controllers/users.ts`)
- How the current code works and what is missing
- Links to related PRs, issues, or external docs (RFCs, vendor docs, design specs)
- Any prior attempts or decisions already made -->

## API Response

<!-- REQUIRED for backend endpoint issues. Omit for mobile, UI/UX, and test-only issues.
See references/issues-api-response.md for the full envelope rules.
Include one block per endpoint — success + all relevant errors.
Check the project Technical Document for project-specific additions (e.g. auth `code` field). -->

### POST /api/v1/example

**Request**

```json
{ "field": "value" }
```

**Success — 201 Created**

```json
{ "success": true, "message": "Created", "data": {} }
```

**Error — 400 Bad Request**

```json
{ "success": false, "message": "Validation failed", "errors": { "field": ["..."] } }
```

## Dependencies

<!-- Optional. List blocking work that must land first, or issues that depend on this one.
- Blocked by: #N (must merge before this can start)
- Blocks: #M (this must merge before #M can start)
- Depends on external: e.g., needs new env var APP_FOO from infra team -->

## Acceptance Criteria

<!-- Each item must be independently verifiable. "Works correctly" is not a criterion. -->

- [ ] Specific, testable requirement
- [ ] Another requirement
- [ ] Include a test coverage requirement
- [ ] Documentation updated where applicable

## Technical Notes

<!-- Constraints, edge cases, what is explicitly OUT of scope, and anything that would
surprise a reader unfamiliar with this area. Required if the implementation is non-obvious
or involves an external system.
Do NOT write step-by-step implementation instructions or paste full file content here. -->
