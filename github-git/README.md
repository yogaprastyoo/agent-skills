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

This skill lives inside a [multi-skill repo](../README.md). Two-step install — the skill itself plus its slash commands:

```bash
# 1. Clone the skills repo (if not already)
git clone https://github.com/yogaprastyoo/agent-skills.git ~/agent-skills

# 2. Symlink the skill into your Claude skills folder
mkdir -p ~/.claude/skills
ln -s ~/agent-skills/github-git ~/.claude/skills/github-git

# 3. Symlink the slash commands into your Claude commands folder
mkdir -p ~/.claude/commands
for cmd in ~/agent-skills/github-git/commands/*.md; do
  ln -sf "$cmd" ~/.claude/commands/
done

# 4. Verify
ls ~/.claude/skills/github-git/SKILL.md
ls ~/.claude/commands/git-*.md
```

Or symlink the **entire** repo as your skills folder (skills only — commands still need step 3):

```bash
# Backup existing skills folder if any
mv ~/.claude/skills ~/.claude/skills.bak 2>/dev/null

# Symlink the whole repo
ln -s ~/agent-skills ~/.claude/skills
```

Restart Claude Code. The skill will appear in the available-skills list and auto-trigger on any Git/GitHub keyword. The slash commands appear in the `/` menu.

### Optional — install hooks (defense-in-depth)

The skill ships two hook layers that prevent direct pushes to `main` and reject malformed commit messages. Both are opt-in.

**Claude Code hooks** (catch what Claude tries to do):

```bash
# Merge this into ~/.claude/settings.json — see hooks/settings.example.json
{
  "hooks": {
    "PreToolUse": [{
      "matcher": "Bash",
      "hooks": [
        { "type": "command", "command": "$HOME/.agents/skills/github-git/hooks/guard-push-to-main.sh" },
        { "type": "command", "command": "$HOME/.agents/skills/github-git/hooks/commit-msg-validator.sh" }
      ]
    }]
  }
}
```

**Git hooks** (catch what humans do at the terminal — install per repo):

```bash
cd /path/to/your/repo
bash ~/agent-skills/github-git/scripts/install-git-hooks.sh
```

**Verify the whole stack at any time:**

```bash
bash ~/agent-skills/github-git/scripts/verify-install.sh
```

---

## Verify install

Ask Claude:
> "List apa saja yang bisa dilakukan github-git skill"

If Claude responds with the workflow phases (`setup → issue → branch → commit → PR → review`), the skill is loaded correctly.

---

## Quick start

Two ways to invoke: explicit slash commands (recommended for teams) or natural-language prompts.

### Slash commands

| Command | What it does |
|---------|--------------|
| `/git-issue [type:] <title>` | Create a GitHub issue following the team template |
| `/git-commit [scope]` | Analyze diff, auto-detect type, create conventional commit |
| `/git-pr [--draft]` | Open PR from current branch with auto-detected base & title |
| `/git-review <pr-number>` | Review a PR using the checklist; post inline comments |
| `/git-setup <repo-name>` | Bootstrap a new repo with team defaults |

See [`commands/`](./commands/) for full playbooks.

### Natural language (auto-triggered)

Without slash commands, the skill triggers on any Git/GitHub keyword:

> "Buatin issue feature untuk endpoint POST /api/users yang return JWT token"

→ Claude generates a complete issue body following the required template, then runs `gh issue create`.

> "Commit perubahan ini"

→ Claude analyzes your diff, auto-detects the commit type, and generates a conventional commit message.

> "Buatin PR untuk branch ini"

→ Claude detects the base branch from your branch prefix, pulls the linked issue title, fills the PR template, and runs `gh pr create`.

> "Review PR #42"

→ Claude reads the linked issue, walks through the review checklist (correctness, security, performance, tests), and posts a review via `gh pr review`.

---

## Structure

```
github-git/
├── SKILL.md                    # Skill entry point (loaded by Claude)
├── README.md                   # This file
├── CHANGELOG.md                # Version history
├── commands/                   # Slash commands (symlink into ~/.claude/commands/)
│   ├── git-issue.md
│   ├── git-commit.md
│   ├── git-pr.md
│   ├── git-review.md
│   └── git-setup.md
├── hooks/                      # Automation hooks
│   ├── README.md               # Hook layers explained
│   ├── guard-push-to-main.sh   # Claude Code PreToolUse hook
│   ├── commit-msg-validator.sh # Claude Code PreToolUse hook
│   ├── settings.example.json   # Snippet for ~/.claude/settings.json
│   └── git-hooks/              # Per-repo git hooks (installed via script)
│       ├── commit-msg
│       └── pre-push
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
    ├── validate-commit-msg.sh
    ├── install-git-hooks.sh    # Wire git hooks into a repo
    └── verify-install.sh       # Sanity-check the install
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
