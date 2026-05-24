# github-git

> Opinionated Git & GitHub workflow skill for Claude Code — standardize how your team creates issues, branches, commits, PRs, and reviews.

A Claude Code [skill](https://docs.anthropic.com/en/docs/claude-code/skills) that turns Claude into a disciplined Git & GitHub collaborator. It enforces conventional commits, branch naming, PR templates, code review checklists, and the full `issue → branch → commit → PR → review → merge` lifecycle.

---

## What this skill does

When loaded, Claude will:

- **Refuse to commit without an issue** — every change is traceable
- **Auto-generate conventional commit messages** from your diff (`feat:`, `fix:`, `refactor:`, etc.)
- **Auto-detect PR base branch & labels** based on your branch prefix
- **Use heredoc for all `gh` commands** — no temp files, no shell escaping bugs
- **Block direct pushes to `main`** and warn before risky operations
- **Apply consistent issue/PR templates** with required sections (Description, Context, Acceptance Criteria)
- **Follow a code review checklist** covering correctness, security, performance, maintainability, tests
- **Never inject `Co-Authored-By: Claude` or AI mentions** into commits, PRs, or issues

---

## Prerequisites

| Tool | Min Version | Check |
|------|-------------|-------|
| `git` | 2.30+ | `git --version` |
| `gh` (GitHub CLI) | 2.0+ | `gh --version` |
| GitHub auth | active | `gh auth status` |

Install GitHub CLI: <https://cli.github.com/>

Authenticate before first use:
```bash
gh auth login
```

---

## Install

This skill lives inside a [multi-skill repo](../README.md). To install only this skill:

```bash
# 1. Clone the skills repo (if not already)
git clone https://github.com/yogaprastyoo/agent-skills.git ~/agent-skills

# 2. Symlink this skill into your Claude skills folder
mkdir -p ~/.claude/skills
ln -s ~/agent-skills/github-git ~/.claude/skills/github-git

# 3. Verify
ls ~/.claude/skills/github-git/SKILL.md
```

Or symlink the **entire** repo as your skills folder (recommended if you want all included skills):

```bash
# Backup existing skills folder if any
mv ~/.claude/skills ~/.claude/skills.bak 2>/dev/null

# Symlink the whole repo
ln -s ~/agent-skills ~/.claude/skills
```

Restart Claude Code. The skill will appear in the available-skills list and auto-trigger on any Git/GitHub keyword.

---

## Verify install

Ask Claude:
> "List apa saja yang bisa dilakukan github-git skill"

If Claude responds with the workflow phases (`setup → issue → branch → commit → PR → review`), the skill is loaded correctly.

---

## Quick start

### Create a new issue
> "Buatin issue feature untuk endpoint POST /api/users yang return JWT token"

Claude will produce a complete issue body following the required template (Description, Context, API Response, Acceptance Criteria, Technical Notes), then run `gh issue create`.

### Commit current changes
> "Commit perubahan ini"

Claude will analyze your diff, auto-detect the commit type, and generate a conventional commit message.

### Create a PR
> "Buatin PR untuk branch ini"

Claude will detect the base branch from your branch prefix, pull the linked issue title, fill the PR template, and run `gh pr create`.

### Review a PR
> "Review PR #42"

Claude will read the linked issue, walk through the review checklist (correctness, security, performance, tests, etc.), and post inline comments via `gh pr review`.

---

## Structure

```
github-git/
├── SKILL.md                    # Skill entry point (loaded by Claude)
├── README.md                   # This file
├── CHANGELOG.md                # Version history
├── references/                 # Detailed playbooks Claude reads on demand
│   ├── repo-setup.md           # Init repo with best practices
│   ├── issues.md               # Issue templates & rules
│   ├── branching-commits.md    # Branch naming + conventional commits
│   ├── pull-requests.md        # PR creation, self-review, merge strategy
│   └── code-review.md          # Review checklist & feedback patterns
├── assets/                     # Ready-to-use templates
│   ├── issue-template-feature.md
│   ├── issue-template-bug.md
│   ├── pr-template.md
│   └── readme-template.md
└── scripts/                    # Helper scripts
    ├── create-issue.sh
    ├── setup-repo.sh
    └── validate-commit-msg.sh
```

---

## Conventions enforced

### Branch naming
```
{prefix}/{issue-number}-{slug}

feature/42-jwt-refresh-token
bugfix/15-fix-uppercase-email-login
hotfix/78-patch-payment-null-response
```

Allowed prefixes: `feature/`, `bugfix/`, `hotfix/`, `refactor/`, `docs/`, `ci/`, `release/`

### Commit format
```
<type>(<scope>): <description>

[optional body — explains WHY, not WHAT]

Closes #<issue>
```

Types: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`, `ci`, `perf`

### Base branch convention
- Default branch: `develop`
- Production branch: `main` (release only)
- Hotfix/Release PRs target `main`, all others target `develop`

---

## Customization

This skill assumes `develop` as default branch and English as the commit/PR/issue language. To override per-project:

- Create a `CLAUDE.md` in your project root with project-specific overrides
- The skill respects project conventions when they conflict with defaults

Example `CLAUDE.md`:
```markdown
# Project conventions

Default branch is `main` (not `develop`). All PRs target `main`.
Commit language is English. Issue language can be Indonesian.
```

---

## Related skills

The following sibling skills are referenced by this one. They are not yet published in this repo (see [root README](../README.md) for status):

- `api-response` — standardize API response envelope (referenced when creating backend endpoint issues)
- `talenthub-backend` — TalentHub-specific backend conventions
- `talenthub-mobile` — TalentHub-specific Flutter conventions

If these aren't installed in your `~/.claude/skills/`, the related sections in this skill will still work — Claude will just skip cross-skill references.

---

## Contributing

This is an opinionated skill — proposals to change defaults should be discussed first. To suggest changes:

1. Open an issue describing the proposed change and the team problem it solves
2. Fork & branch from `develop`
3. Update `CHANGELOG.md` under `[Unreleased]`
4. Open a PR following this skill's own conventions (yes, the skill applies to itself)

---

## License

MIT — see [LICENSE](../LICENSE) at repo root.
