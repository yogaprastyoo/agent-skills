# agent-skills

> A curated collection of agent skills for opinionated team workflows. Primary target is [Claude Code](https://docs.anthropic.com/en/docs/claude-code), with the same `SKILL.md` format also supported by Gemini Antigravity and other agent runtimes.

Each subdirectory is a self-contained skill that the agent loads on demand. Install the whole bundle or pick individual skills — they're symlink-friendly.

---

## Included skills

| Skill | Status | What it does |
|-------|--------|--------------|
| [`github-git`](./github-git/) | ✅ v1.1.0 | Standardize Git/GitHub workflow — issues, branches, conventional commits, PRs, code review |

### Coming soon

The following skills exist in development and will be published here in upcoming releases:

| Skill | Status | What it does |
|-------|--------|--------------|
| `api-response` | 🚧 internal | Standard API response envelope (`{ success, message, data }` / `{ success, message, errors }`) for all projects |
| `talenthub-mobile` | 🚧 internal | TalentHub mobile (Flutter) — business rules, architecture, gotchas |
| `talenthub-backend` | 🚧 internal | TalentHub backend (ASP.NET Core .NET 10) — auth, RBAC, response formatting |
| `refactor-flutter` | 🚧 internal | Incremental Flutter refactor — extract widgets without changing behavior |

---

## Install

### Option A — Symlink individual skills (recommended)

```bash
git clone https://github.com/yogaprastyoo/agent-skills.git ~/agent-skills
mkdir -p ~/.claude/skills

ln -s ~/agent-skills/github-git ~/.claude/skills/github-git
# ...add more skills here as they become available
```

### Option B — Symlink the entire repo

If you want every skill from this repo (and don't mind your `~/.claude/skills/` being managed by git):

```bash
git clone https://github.com/yogaprastyoo/agent-skills.git ~/agent-skills

# Backup existing skills folder if any
[ -d ~/.claude/skills ] && mv ~/.claude/skills ~/.claude/skills.bak

ln -s ~/agent-skills ~/.claude/skills

ls ~/.claude/skills/
```

### Option C — Plain copy (not recommended)

If you can't use symlinks (e.g., Windows without developer mode):

```bash
git clone https://github.com/yogaprastyoo/agent-skills.git
cp -r agent-skills/github-git ~/.claude/skills/
```

You'll need to manually re-copy when updates land.

---

## Verify install

Restart Claude Code, then ask:

> "List skills yang tersedia"

You should see all installed skills in the response. Or check directly:

```bash
ls ~/.claude/skills/
```

---

## Update

If installed via symlink (Option A or B):

```bash
cd ~/agent-skills
git pull
```

Skills are immediately updated for all Claude Code sessions.

---

## Versioning

Each skill is versioned independently via git tags using the format `<skill-name>-vX.Y.Z`:

```
github-git-v1.1.0
api-response-v1.0.0
talenthub-mobile-v0.3.0
```

See each skill's `CHANGELOG.md` for version history.

---

## Repository structure

```
agent-skills/
├── README.md                   # This file
├── LICENSE                     # MIT
├── .gitignore
│
└── github-git/                 # Skill: Git/GitHub workflow
    ├── SKILL.md
    ├── README.md
    ├── CHANGELOG.md
    ├── references/
    ├── assets/
    └── scripts/

# Additional skills will be added as separate top-level directories
# in future releases.
```

---

## Contributing

Skills are intentionally opinionated. Before proposing changes:

1. Open an issue describing the team problem and the proposed solution
2. Branch from `develop` using `feature/<issue>-<slug>` convention
3. Update the affected skill's `CHANGELOG.md` under `[Unreleased]`
4. Open a PR — the `github-git` skill applies to this repo as well

For new skills, create a new top-level directory with `SKILL.md`, `README.md`, and `CHANGELOG.md` at minimum.

---

## License

MIT — see [LICENSE](./LICENSE).
