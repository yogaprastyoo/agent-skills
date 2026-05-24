# Changelog

All notable changes to the `implementation-quality` skill are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this skill adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

### Added
- README "Compatibility" section explaining cross-agent support (Claude Code, Antigravity CLI, GPT Codex CLI, OpenCode). Links to the root `scripts/export-to-agent.sh` for non-native agents.

---

## [1.0.0] — 2026-05-24

First release. Cross-cutting quality skill that enforces hard constraints
during any implementation task. Designed to compose with `github-git` and
project-specific skills.

### Added

- `SKILL.md` — entry point with the five constraint categories:
  - **CODE REUSE** — grep first, extract aggressively, reuse constants
  - **CODE QUALITY** — descriptive names, no dead code, null safety, Indonesian user-facing errors
  - **EFFICIENCY** — no heavy widgets in build(), no over-fetch, lazy lists, setState on real change
  - **SECURITY** — validate input, parameterized queries, no logged secrets, auth on every protected route
  - **TECH STACK COMPLIANCE** — read stack first, match dominant pattern, no new deps without confirmation
- Workflow integration section explaining composition with `github-git`
- Decision-points table (when to ASK vs PROCEED) with quick reference
- Anti-patterns section showing concrete BAD examples
- Auto-trigger keywords: `implement`, `kerjakan`, `kerjain`, `buat fitur`, `tambah fitur`, `fix bug`, `perbaiki bug`, `implementasi`, `refactor`, plus issue-number + action-verb patterns

- `references/per-stack.md` — quality items specific per stack:
  - Flutter / Dart (widgets, state management, null safety, async, build perf, localization, testing)
  - ASP.NET Core / C# / .NET (async patterns, nullable refs, IDisposable, EF Core, validation, logging, testing)
  - Node.js / TypeScript (type safety, async, modules, deps, framework, testing)
  - Python (typing, idioms, async, testing)
  - Go (errors, concurrency, std-lib-first, testing)
  - Generic items applying to every stack

- `references/decision-points.md` — when to ASK vs PROCEED:
  - 8 categories that warrant pausing (ambiguous AC, refactor existing fn, new dep, adjacent bug, pattern conflict, missing tests, scope split, security)
  - 8 categories that warrant proceeding without asking (trivial styling, established folder structure, formatting, etc.)
  - Template for "how to ask well" (situation + options + trade-offs + recommendation)
  - Frequency budget guidance (0-1 asks trivial bug, 3-6 asks for >500 LoC feature)

- `README.md` — install instructions, usage examples, structure, composition guidance with other skills

### Composition model

The skill is explicitly designed to be **lower-precedence than project-specific skills**:

- Generic constraints (no `any`, no dead code, validate input) live here
- Project-specific overrides (TalentHub uses BLoC, Indonesian for error messages, this folder for that thing) live in the relevant project skill
- When in doubt, project-specific wins

This means teammates can install this skill without worrying about it conflicting with project skills they already use.

[Unreleased]: https://github.com/yogaprastyoo/agent-skills/compare/implementation-quality-v1.0.0...HEAD
[1.0.0]: https://github.com/yogaprastyoo/agent-skills/releases/tag/implementation-quality-v1.0.0
