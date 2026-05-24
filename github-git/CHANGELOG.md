# Changelog

All notable changes to the `github-git` skill are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this skill adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

### Added
- README "Compatibility" section explaining cross-agent support (Claude Code, Antigravity CLI, GPT Codex CLI, OpenCode). Links to the root `scripts/export-to-agent.sh` for non-native agents.

### Changed
- `references/branching-commits.md` "Creating a Branch" — now requires branching from `origin/<base>`, not local `<base>`. Recommends `git fetch && git checkout -b <branch> origin/<base>` or two-step with `git pull --ff-only` (which fails loudly if local has unpushed commits).
- `references/branching-commits.md` "Guidelines" — first item updated to say "Always branch from **`origin/develop`** (not local `develop`)".
- `commands/git-pr.md` "Pre-PR checklist" — added a MUST-PASS check that refuses to push if local `<base>` is ahead of `origin/<base>`. The check prevents silent absorption of unpushed commits into the PR's squash diff. Constraints section updated to list this requirement.

### Added
- `references/branching-commits.md` "Gotchas" — new entry **"Silent absorption of unpushed local commits"** documenting the failure mode, symptoms, prevention, and pointing at the PR #12 incident as the concrete example that motivated this rule.

### Retroactive credit
PR #12 ("[Feature] Add implementation-quality skill v1.0.0", squash `055c5ea`) silently absorbed an additional local commit during the squash-merge:

- Original local SHA: `8fb1fa72d0fff52be1be606c7ea748525c44f03d`
- Author: Yoga Prastyo <yogaprastyobayu@gmail.com>
- Message: `chore(skill): support Antigravity agent alongside Claude in github-git constraints`
- Effect: extended the no-AI-mentions constraints in `SKILL.md`, `commands/*.md`, and `agents/*.md` to also cover Antigravity / Gemini, since the skills folder is shared between Claude Code and Antigravity via symlink chain.

The changes are live in `origin/develop` as part of `055c5ea`; this note acknowledges them as Yoga Prastyo's independent work absorbed by the squash-merge, not as part of the implementation-quality feature. PR #12 description has been updated with the same attribution note.

The new branching rule + pre-PR check (above) prevent this from happening again.

---

## [1.1.0] — 2026-05-24

Major upgrade bringing the skill to plugin-grade: slash commands, hooks
at two layers, expanded reference library, focused subagents, example
walkthroughs, cheatsheet, and a plugin manifest.

### Added

**Slash commands** (in `commands/`):
- `/git-issue` — interactive issue creation following the team template
- `/git-commit` — diff analysis with auto-detected type + scope + Conventional Commits message
- `/git-pr` — PR creation with auto base/title/labels
- `/git-review` — checklist-driven PR review with inline comments
- `/git-setup` — bootstrap a new repo with team defaults

**Hooks** (in `hooks/`):
- Claude Code PreToolUse hooks:
  - `guard-push-to-main.sh` — blocks direct push to `main`/`master`
  - `commit-msg-validator.sh` — enforces Conventional Commits, ≤72-char subject, no vague words
  - `settings.example.json` — drop-in snippet for `~/.claude/settings.json`
- Git-level hooks (per-repo, installed via script):
  - `commit-msg` — wraps `validate-commit-msg.sh`, catches heredoc/`-F` commits
  - `pre-push` — refuses pushes to `refs/heads/main`/`refs/heads/master`
- `hooks/README.md` — explains both layers, install/uninstall/bypass

**Reference library expansion** (in `references/`):
- `troubleshooting.md` — 20+ common errors as Symptom → Cause → Fix → Prevention
- `advanced-operations.md` — revert merged PR, undo last commit (pre/post push), resolve merge conflict, sync fork, split commit, cherry-pick, interactive rebase, recover lost commit, `git bisect`, nuclear option
- `issues-api-response.md` — extracted from SKILL.md; single source of truth for the API envelope, per-endpoint structure, pagination, project-specific overrides

**Subagents** (in `agents/`):
- `commit-writer` — generates Conventional Commits messages from a diff
- `pr-reviewer` — runs the review checklist and returns structured findings
- `issue-writer` — turns short descriptions into complete issues following the team template

**Example walkthroughs** (in `examples/`):
- `01-feature-end-to-end.md` — full flow: issue → branch → commit → PR → review → merge
- `02-hotfix-production.md` — emergency hotfix to `main` + backport to `develop`
- `03-conflict-resolution.md` — step-by-step merge conflict resolution

**Tooling**:
- `scripts/install-git-hooks.sh` — symlink/copy git hooks; supports `--copy` and `--uninstall`
- `scripts/verify-install.sh` — checks git/gh/jq/skill files/hooks/commands; pass/fail/warn

**Documentation**:
- `CHEATSHEET.md` — one-page printable quick reference
- `plugin.json` — manifest enumerating commands, agents, hooks, references, assets, scripts, examples

### Changed

- `SKILL.md`:
  - New sections: "Available Commands", "Slash Command Playbooks", "Subagents", "Examples", "Hooks (defense-in-depth)"
  - Decision Tree routes through commands instead of references where applicable
  - "API Response in Issues" trimmed from 20+ lines inline to a short summary linking to `references/issues-api-response.md`
  - Reference Files table extended with `troubleshooting.md`, `advanced-operations.md`, `issues-api-response.md`
  - Scripts table extended with `install-git-hooks.sh`, `verify-install.sh`
- `references/issues.md` — API Response comment points at the dedicated reference
- `README.md` — Quick Start split into slash-commands and natural-language sections; install instructions add `~/.claude/commands/` symlink + Claude hooks snippet + git hooks command + verify-install command; structure tree extended to reflect the new layout

### Asset enrichment

Templates synced with their corresponding reference files:
- `assets/pr-template.md` — adds "Testing Performed", "Notes for Reviewers"; expands "Self-Review Checklist" to match `references/code-review.md`; adds "Performance improvement" type
- `assets/issue-template-bug.md` — adds "Environment", "Frequency", "Severity" sections
- `assets/issue-template-feature.md` — adds inline API Response example using the new envelope, "Dependencies", "Definition of Done" sections

### Workflow demonstrated on the skill itself

Each sprint of this release shipped through the skill's own workflow:
- Issue (#1, #3, #5, #7)
- Feature branch from `develop`
- Conventional commit
- PR (#2, #4, #6, #N) with self-review
- Squash-merge with branch auto-delete

---

## [1.0.0] — 2026-05-24

First stable release. Skill is ready for team distribution via the
[agent-skills](https://github.com/yogaprastyoo/agent-skills) repo.

### Added
- `README.md` with install instructions, prerequisites, and quick start
- `CHANGELOG.md` (this file) following Keep a Changelog format
- Multi-skill repo structure — symlink-friendly install via `~/.claude/skills/`

### Changed
- Standardized all Claude-facing content to English. Indonesian retained only
  inside quoted user-facing prompts (push warning, branch protection question)
- Removed project-specific constraint forbidding GitHub Actions workflows —
  belongs in per-project `CLAUDE.md`, not the shared skill
- Aligned "When to Use" list with sections actually present (removed orphan
  references to CI/CD and Release sections)
- Branch protection reference table now in English (option/description/when-to-use)

### Removed
- Stale references to `references/actions.md` and `references/releases.md`
  (files never existed)
- `scripts/generate-changelog.sh` entry from SKILL.md script table (the file
  remains on disk but is no longer surfaced — pending Sprint 4 cleanup)

### Fixed
- Mixed-language sections that confused Claude during instruction parsing

---

## Pre-1.0 history

Early iterations lived in this skill before 1.0 was tagged. Notable milestones:

- Initial SKILL.md with workflow phases and decision tree
- Reference files for repo-setup, issues, branching-commits, pull-requests, code-review
- Asset templates for issues, PRs, README
- Helper scripts: `create-issue.sh`, `setup-repo.sh`, `validate-commit-msg.sh`
- Strict policy: no `Co-Authored-By: Claude` or AI mentions in Git output
- API Response section integrated with `api-response` skill
- Push-to-main warning with mandatory user confirmation

These were folded into v1.0.0.

---

[Unreleased]: https://github.com/yogaprastyoo/agent-skills/compare/github-git-v1.1.0...HEAD
[1.1.0]: https://github.com/yogaprastyoo/agent-skills/releases/tag/github-git-v1.1.0
[1.0.0]: https://github.com/yogaprastyoo/agent-skills/releases/tag/github-git-v1.0.0
