<!--
PR template for github-git skill.
Auto-detection (base branch, type, labels) — see references/pull-requests.md.
Title format: [Type] Short description.  Example: [Feature] Add JWT refresh token.
-->

## Description

<!-- Brief explanation of what this PR does and why. Lead with the user-facing impact or the bug it fixes. -->

## Changes

<!-- Concise bullet list of what changed. One line per logical change.
Reviewers use this to navigate the diff — keep it specific. -->

- Change 1
- Change 2
- Change 3

## Related Issues

<!-- "Closes #N" auto-closes the issue when this PR is merged into the default branch. -->

Closes #

## Type of Change

- [ ] Bug fix (non-breaking change that fixes an issue)
- [ ] New feature (non-breaking change that adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to change)
- [ ] Refactoring (no functional changes)
- [ ] Performance improvement
- [ ] Documentation update
- [ ] CI/CD changes

## Screenshots / Recordings

<!-- Include before/after screenshots for UI changes. For new UI, include the rendered output.
For backend changes, paste relevant cURL + JSON response.
Omit this section if the change has no observable surface. -->

## Testing Performed

<!-- What did you actually run? Tests pass != feature works.
Example:
- [x] Unit tests added for new validation logic — `npm test src/auth/`
- [x] Manual: registered new user via UI, verified JWT cookie set
- [x] Manual: logged out, confirmed app_session cleared
- [ ] Load test deferred — no perf regression expected -->

- [ ] Tests added/updated for the changes
- [ ] All existing tests pass locally
- [ ] Manual verification of the happy path
- [ ] Manual verification of at least one error path

## Self-Review Checklist

<!-- See references/code-review.md for the full checklist. Hit every box that applies before requesting reviews. -->

- [ ] Self-review performed (read the diff yourself first)
- [ ] Code follows the project's style guidelines
- [ ] Comments added for non-obvious logic (the "why", not the "what")
- [ ] No dead code or commented-out blocks left behind
- [ ] No `console.log`, `print`, `debugger`, or other debug noise
- [ ] No secrets, API keys, or credentials in the diff
- [ ] User input is validated where applicable
- [ ] Documentation updated (README, CHANGELOG, JSDoc) if behavior changed
- [ ] Conventional Commits format on all commits in this branch

## Notes for Reviewers

<!-- Optional. Anything that would help a reviewer focus their attention:
- Specific files to scrutinize
- Trade-offs you considered and the reasoning
- Known limitations or follow-up work
- Context that's not in the diff -->
