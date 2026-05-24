<!--
Bug report template for github-git skill.
See references/issues.md for the full structure rules.
Title format: fix: <what is broken>.  Example: fix: logout endpoint missing CSRF token.
Apply label: bug.
-->

## Description

<!-- What is broken and what is the impact? 2–5 sentences.
Lead with the user-facing or security impact if applicable. -->

## Context

<!-- Everything needed to understand the area involved:
- Relevant file paths (e.g. `src/app/api/auth/logout/route.ts`)
- How the current code works and what is wrong with it
- Any prior attempts to fix this
- Links to related PRs, issues, or external docs -->

## Steps to Reproduce

<!-- Exact, ordered, deterministic. Anyone reading should be able to follow these and see the bug. -->

1. Step 1
2. Step 2
3. Step 3

## Expected Behavior

<!-- What should happen? Be specific — "should work" is not a description. -->

## Actual Behavior

<!-- What actually happens? Include error messages, logs, stack traces, screenshots. -->

## Environment

<!-- Where was this reproduced? Helps narrow down env-specific bugs.
Examples:
- App version / commit SHA: `abc1234` (or `1.2.3`)
- Runtime: Node 22.10 / .NET 10 / Flutter 3.27 / Python 3.13
- OS: macOS 26.1 / Ubuntu 26.04 / Windows 11 / iOS 18 / Android 16
- Browser (if web): Chrome 142 / Safari 18
- Backend / database version (if applicable): PostgreSQL 17
- Reproducible in: local / staging / production -->

## Frequency

- [ ] Always (100% reproducible)
- [ ] Often (>50% of the time)
- [ ] Sometimes (intermittent, <50%)
- [ ] Once (cannot reproduce since)

## Severity

- [ ] Critical — production down, data loss, security breach
- [ ] High — major feature broken, no workaround
- [ ] Medium — feature impaired but workaround exists
- [ ] Low — cosmetic, edge case, minor inconvenience

## Scope

<!-- Optional. Define the fix boundary — what should and should NOT be touched.
Prevents the fix PR from turning into an unrelated refactor.
Example:
- IN: fix the missing CSRF token in logout route
- OUT: do not refactor other routes, do not change the auth flow -->

## Acceptance Criteria

- [ ] Bug no longer reproduces following the steps above
- [ ] Existing tests pass
- [ ] Add a regression test that would have caught this bug

## Technical Notes

<!-- Constraints, suspected root cause, hypotheses to investigate, or anything
that would surprise a reader. Required if the fix is non-obvious or involves
an external system (e.g., Sanctum behavior, OAuth provider quirk). -->
