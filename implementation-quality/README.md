# implementation-quality

> Make Claude a disciplined implementer, not just a code-emitter that "makes it work."

A [Claude Code](https://docs.anthropic.com/en/docs/claude-code/skills) skill that applies quality constraints to **every** implementation task — feature, bug fix, refactor, or working an existing GitHub issue. Code reuse, code quality, efficiency, security, and tech-stack compliance are treated as HARD CONSTRAINTS, not suggestions.

Designed to compose with `github-git` (workflow) and project-specific skills (per-project conventions).

---

## What this skill does

When loaded, Claude will (during any implementation task):

- **Grep before writing.** Search the codebase for similar logic before introducing a duplicate.
- **Reject hardcoded values** that already have named constants elsewhere.
- **Extract large units** — widgets >30 lines, functions >50 lines, classes >300 lines.
- **Refuse to commit** until lint/format/test pass.
- **Refuse to introduce a new dependency** without explicit user confirmation.
- **Validate user input** at every system boundary.
- **Use parameterized queries.** No string concatenation for SQL/NoSQL.
- **Surface decision points** instead of silently making assumptions — see `references/decision-points.md`.
- **Match the codebase's existing patterns** (BLoC vs Provider, async style, naming convention).

---

## When it triggers

Auto-triggers on any mention of:

- `implement`, `kerjakan`, `kerjain`, `buat fitur`, `tambah fitur`
- `fix bug`, `perbaiki bug`, `refactor`, `implementasi`
- An issue number followed by an action verb (`kerjakan #42`, `implement issue 87`)

Does NOT trigger when the user just reads, asks, or discusses code without committing to change it.

---

## Prerequisites

None directly. The skill is pure guidance — no scripts, no hooks. It complements other skills:

- `github-git` (recommended) — workflow standardization (issue → branch → PR)
- Project-specific skill (recommended) — `talenthub-mobile`, `talenthub-backend`, etc.

---

## Install

Same pattern as the rest of [`agent-skills`](https://github.com/yogaprastyoo/agent-skills):

```bash
# 1. Clone the repo (if not already)
git clone https://github.com/yogaprastyoo/agent-skills.git ~/agent-skills

# 2. Symlink this skill
mkdir -p ~/.claude/skills
ln -s ~/agent-skills/implementation-quality ~/.claude/skills/implementation-quality

# 3. Verify
ls ~/.claude/skills/implementation-quality/SKILL.md
```

Restart Claude Code. The skill appears in the available-skills list and triggers automatically on the keywords above.

---

## Usage

No slash command required — just describe an implementation task and the skill activates:

```
Kerjakan issue #42
```

```
Implement fitur upload avatar — POST /api/users/me/avatar
```

```
Fix bug login yang sering force-logout
```

Claude will:
1. Read the issue (or your description) and surface any ambiguity (see `references/decision-points.md`)
2. Grep the codebase for related/reusable code before writing
3. Apply the five constraint categories as it works
4. Run the project's lint/test/format gates before committing
5. Open the PR via `github-git` skill

---

## Structure

```
implementation-quality/
├── SKILL.md                    # Entry point — 5 constraint categories
├── README.md                   # This file
├── CHANGELOG.md                # Version history
└── references/
    ├── per-stack.md            # Flutter, .NET, Node, Python, Go-specific items
    └── decision-points.md      # When to ASK vs PROCEED
```

---

## The five constraint categories

1. **CODE REUSE** — grep first, extract aggressively, reuse constants
2. **CODE QUALITY** — descriptive names, no dead code, null safety, Indonesian user-facing errors
3. **EFFICIENCY** — no heavy widgets in `build()`, no over-fetch, lazy lists, setState on real change
4. **SECURITY** — validate input, parameterized queries, no logged secrets, auth on every protected route
5. **TECH STACK COMPLIANCE** — read the stack first, match dominant pattern, no new deps without confirmation

Full detail in [`SKILL.md`](./SKILL.md).

---

## Composition with other skills

This skill is intentionally cross-cutting. It works WITH project-specific skills, not against them:

| Skill | Scope | Precedence |
|-------|-------|------------|
| `implementation-quality` (this) | Generic quality across all projects | Lower (defaults) |
| `talenthub-mobile` | TalentHub Flutter specifics | Higher (overrides) |
| `talenthub-backend` | TalentHub backend specifics | Higher (overrides) |
| `github-git` | Workflow (orthogonal) | Composes (no conflict) |

If a project-specific skill says "use this pattern," its instruction wins over this skill's generic guidance.

---

## Why this matters

Without enforced constraints, AI-generated code drifts toward:

- Duplicated logic (because grepping is "extra work")
- Hardcoded magic numbers (because finding the constant takes a beat)
- Heavy widgets in `build()` (because extracting needs more files)
- Silent dependencies (because `npm install` is easy)
- Dead code commented out (because deleting feels destructive)
- Lint warnings deferred (because "we'll fix in next commit")

Each violation, alone, is small. Compounded over months of AI-assisted work, they turn a codebase into legacy faster than human-only development would.

This skill makes those tendencies explicit and refuses them.

---

## Contributing

The constraints are opinionated by design. Proposals to change defaults should be discussed first:

1. Open an issue describing the current constraint, the proposed change, and the team problem the change solves
2. Branch from `develop` using `feature/<issue>-<slug>` convention
3. Update [`CHANGELOG.md`](./CHANGELOG.md) under `[Unreleased]`
4. Open a PR — the `github-git` skill applies to this repo too

---

## License

MIT — see [LICENSE](../LICENSE) at repo root.
