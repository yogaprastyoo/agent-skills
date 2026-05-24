---
name: implementation-quality
description: >
  Quality constraints applied during any implementation task. Use this skill
  when implementing a feature, fixing a bug, refactoring code, or working on
  an existing GitHub issue. Trigger on any mention of 'implement', 'kerjakan',
  'kerjain', 'buat fitur', 'tambah fitur', 'fix bug', 'perbaiki bug',
  'implementasi', 'refactor', or when the user references an issue number
  followed by an action verb. Enforces code reuse, code quality, efficiency,
  security, and tech-stack compliance as HARD CONSTRAINTS — not suggestions.
---

# Implementation Quality Skill

## Goal

Make the implementing agent a **disciplined implementer**, not just a code-emitter that "makes it work." Every implementation must satisfy the constraints below before being considered complete. "It runs" is the minimum, not the target.

The skill complements (does not replace) workflow skills like `github-git`. Workflow skills cover *how* code flows (issue → branch → PR). This skill covers *what* code is allowed to look like when it's written.

---

## When To Use

Auto-trigger when the user asks to:

- Implement a new feature or endpoint
- Fix a bug
- Refactor code
- Work on an existing GitHub issue ("kerjakan #42", "implementasi issue 87")
- Add functionality of any kind

Do NOT trigger when the user:

- Just asks a question about code
- Reads / explores the codebase without changing it
- Discusses approach without committing to implementation
- Generates documentation only

---

## The Five Constraint Categories

These are **HARD CONSTRAINTS**. Do not compromise to "save time" or "ship faster." If a constraint blocks progress, surface the conflict to the user — do not silently violate.

### 1. CODE REUSE

- **Before writing a new function/class/widget, search the codebase first.** Use `grep`, `Glob`, or the project's index. If something similar already exists, reuse or extend it instead of duplicating.
- **Reuse existing constants.** Never hardcode colors, strings, dimensions, magic numbers that are already defined in `constants/`, `theme/`, `config/`, or equivalent. If unsure where constants live, grep first.
- **Extract aggressively when a unit grows large.** Concrete thresholds:
  - Widget > 30 lines → extract to `widgets/` (Flutter)
  - Function > 50 lines → extract helpers
  - Class > 300 lines → extract collaborators
  - Same logic appearing in 2+ places → extract immediately, do not wait for the 3rd
- **Prefer composition over inheritance.** Reach for inheritance only when the language pattern actually demands it.

### 2. CODE QUALITY

- **Names are descriptive and consistent with the surrounding code.** If neighbors use `userId`, do not introduce `user_id` or `uid`. If neighbors use `fetchUser`, do not introduce `getUser`.
- **No dead code.** No commented-out blocks. No unused imports, variables, methods, parameters. Delete it — the diff history preserves it if anyone wants to recover.
- **Null safety is handled correctly.** No null-bang (`!`), no `as!`, no force-unwrap without a justifying comment that explains why null is genuinely impossible.
- **User-facing error messages are in Bahasa Indonesia.** Internal logs / errors / exception messages can be English. Anything a user reads on-screen must be Indonesian.
- **Type-safe over dynamic.** No `dynamic` / `any` / `object` unless interfacing with truly polymorphic external data; then document why.
- **No magic numbers or strings.** If `0.85` appears in code, give it a name (`MAX_RETRY_BACKOFF` or similar).
- **One commit = one logical change.** Do not lump unrelated work into one commit even if you did it in one sitting.

### 3. EFFICIENCY

- **Never define heavy widgets inside `build()`.** Container with complex children, ListView with logic, computed lists — extract to a `const` widget, a method, or a top-level constant. `build()` runs on every rebuild.
- **Never fetch more than the current task needs.** No "preloading for the future." No "while we're here." Fetch only what the acceptance criterion requires.
- **`setState` / `emit` only when state actually changes.** Compare new value to old before notifying. Do not call setState in a loop.
- **List rendering uses lazy builders.** `ListView.builder` (Flutter) / virtualization (web) for any list whose length is not statically tiny.
- **Avoid N+1 query patterns.** Batch DB reads. Use `Include` / eager loading / DataLoader patterns.
- **Memoize expensive computations** that re-run on each frame / request / call.

### 4. SECURITY

- **Validate and sanitize all user input** before it reaches a database, file system, shell, or external API. Trust nothing crossing a system boundary.
- **Use parameterized queries.** No string concatenation building SQL / NoSQL queries.
- **No credentials in code or commits.** API keys, tokens, passwords belong in env vars or a secret manager. Never in source.
- **Never log sensitive data.** No `print(user.password)`, no `logger.info(token)`, no full PII in error messages. If you must log a user for debugging, log the ID, not the email.
- **Auth/authz checks present on every protected route.** Do not assume "we already checked upstream" — verify.
- **Outbound URLs are validated.** No user-supplied URLs used directly in server-side fetches without an allowlist (prevents SSRF).

### 5. TECH STACK COMPLIANCE

- **Before coding, learn the stack.** Read `pubspec.yaml`, `package.json`, `*.csproj`, `go.mod`, or equivalent. Identify the framework, state management approach, testing framework, lint config.
- **Match the dominant pattern in the codebase.** If the project uses BLoC, do not introduce Provider. If it uses Riverpod, do not reach for setState. Consistency > personal preference.
- **Match style.** Follow the project's import ordering, naming conventions, file structure. Run the project's linter / formatter before committing if available.
- **Do not introduce a new dependency without explicit user confirmation.** Even a "small" package adds maintenance, security, and bundle-size cost. List the dependency and the alternative (build it ourselves), let the user choose.
- **Respect existing folder structure.** Put new files where similar files already live. If unclear, ask before placing.
- **Run the project's quality gates before commit.** `flutter analyze`, `dotnet build`, `npm run lint`, `pytest -q` — whatever the project uses. Fix all warnings/errors before committing.

---

## Workflow Integration

This skill enforces *what* you write. The `github-git` skill enforces *how* it flows. They work together:

```
        [github-git workflow]
        Issue → Branch → Implement → Commit → PR → Review → Merge
                            ▲
                            │
                            └── [implementation-quality is ACTIVE here]
                                Apply 5 constraint categories
                                Run quality gates
                                Refuse to commit until clean
```

Concretely:

1. `/git-issue` files the issue (workflow concern → `github-git`)
2. Branch created via `github-git` conventions
3. **Implementation begins → this skill activates.** Apply all five categories as you write. Search for reuse opportunities. Run linter. Address every warning before proceeding to commit.
4. `/git-commit` (workflow concern → `github-git`) — but only after this skill confirms the diff satisfies the constraints
5. `/git-pr` opens the PR

Quality gates must pass *before* the commit. Do not commit with the intent to "fix linting in the next commit" — that defers the work and pollutes review.

---

## Decision Points — ASK vs PROCEED

Some situations require pausing the implementation to confirm with the user. See `references/decision-points.md` for the full list. The quick map:

| Situation | ASK or PROCEED |
|-----------|----------------|
| Acceptance criterion is ambiguous | **ASK** |
| Existing function needs refactor to fit new feature | **ASK** |
| New dependency would simplify the implementation | **ASK** |
| Bug discovered in adjacent code | **ASK** (file separate issue) |
| Pattern conflict (issue says X, codebase does Y) | **ASK** |
| Trivial style choice with multiple valid answers | **PROCEED**, mention briefly in PR |
| Adding a helper file in the established folder structure | **PROCEED** |
| Renaming a local variable for clarity | **PROCEED** |

When asking, frame the question with the options and a recommendation. Do not ask "is this OK?" — ask "I see two approaches: A (...) or B (...). I recommend B because (...). Sound good?"

---

## Anti-Patterns (do not do these)

### "Make it work, refactor later"

```dart
// BAD: duplicating logic because grep felt slow
class UserCard extends StatelessWidget {
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),     // ← hardcoded
      decoration: BoxDecoration(
        color: Color(0xFF1E88E5),       // ← hardcoded
        borderRadius: BorderRadius.circular(8),
      ),
      // ... 80 more lines inline
    );
  }
}
```

A widget like this needs to be split. The hardcoded values almost certainly already exist as `AppTheme.cardPadding` / `AppColors.primary` / `AppRadius.medium`. Grep first.

### "Will fix the lint warnings in the next commit"

Lint warnings in the committed diff means future readers (and CI) treat them as "we're OK with this." They compound. Fix before commit, not after.

### "I'll just add the package, it's small"

Every new dependency:
- Increases bundle/binary size
- Adds maintenance surface
- Adds a supply-chain attack vector
- Costs reviewer time

Ask before adding. Even `lodash`. Even `dayjs`. Even (especially) something with "small" in its name.

### "It compiles, ship it"

Compilation is the floor. Above that:
- Does it match the codebase style?
- Could a teammate maintain it in 6 months?
- Are all the acceptance criteria actually met?
- Did the lint/test/format gates pass?

---

## Constraints (recap)

The five categories, restated as MUST-NOTs:

- Do NOT duplicate logic that already exists — grep first
- Do NOT hardcode values that already have named constants
- Do NOT leave dead code, commented blocks, or unused imports
- Do NOT use `!` / `as!` / force-unwrap without a justifying comment
- Do NOT define heavy widgets inside `build()`
- Do NOT fetch more than the task requires
- Do NOT commit before lint/format/test pass
- Do NOT introduce dependencies without explicit user confirmation
- Do NOT use string concatenation to build queries
- Do NOT log sensitive data
- Do NOT mix unrelated changes into one commit
- Do NOT compromise constraints to "ship faster" — surface the conflict to the user instead

---

## Reference Files

| Topic | File |
|-------|------|
| Per-stack quality checklists (Flutter, .NET, Node, etc) | `references/per-stack.md` |
| Decision-points — when to ASK vs PROCEED | `references/decision-points.md` |

## Related Skills

- `github-git` — workflow standardization (issue/branch/commit/PR)
- `talenthub-mobile` — TalentHub Flutter-specific conventions (overrides apply)
- `talenthub-backend` — TalentHub backend-specific conventions (overrides apply)
- `api-response` — API envelope format for backend endpoints

When a project-specific skill is also active, its conventions take precedence over the generic guidance here.
