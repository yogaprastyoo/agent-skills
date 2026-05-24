# Changelog

All notable changes to the `github-git` skill are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this skill adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

### Added
- Slash commands in `commands/` — `/git-issue`, `/git-commit`, `/git-pr`, `/git-review`, `/git-setup`
- "Available Commands" and "Slash Command Playbooks" sections in `SKILL.md`
- Decision Tree updated to route through the new commands
- README install instructions now include the `~/.claude/commands/` symlink step
- README "Quick start" split into slash-commands and natural-language sections
- Claude Code hooks in `hooks/`:
  - `guard-push-to-main.sh` — PreToolUse hook blocking direct push to `main`/`master`
  - `commit-msg-validator.sh` — PreToolUse hook enforcing Conventional Commits + 72-char subject + no-vague-words
  - `settings.example.json` — drop-in snippet for `~/.claude/settings.json`
- Git-level hooks in `hooks/git-hooks/`:
  - `commit-msg` — wraps `scripts/validate-commit-msg.sh` (catches heredoc/`-F` commits the Claude hook can't inspect)
  - `pre-push` — refuses pushes to `refs/heads/main` / `refs/heads/master`
- `hooks/README.md` — explains both layers, install steps, troubleshooting
- New scripts:
  - `scripts/install-git-hooks.sh` — symlink/copy git hooks into the current repo; supports `--copy` and `--uninstall`
  - `scripts/verify-install.sh` — checks git/gh/jq/skill files/hooks/commands and reports pass/fail/warn
- README hooks install section (Claude hooks + git hooks + verify-install command)
- "Hooks (defense-in-depth)" section in `SKILL.md`
- Structure tree in README extended with `hooks/`, `install-git-hooks.sh`, `verify-install.sh`

### Added (Sprint 4)
- `references/troubleshooting.md` — common errors (tool install, auth, push/sync, merge conflicts, commits, .gitignore, hooks). Symptom → Cause → Fix → Prevention per entry.
- `references/advanced-operations.md` — revert merged PR, undo last commit (pre/post push), resolve merge conflict, sync fork, split commit, cherry-pick, interactive rebase, recover lost commit, git bisect, branch deletion, nuclear option
- `references/issues-api-response.md` — extracted API Response rules from `SKILL.md`. Single source of truth for envelope shape, per-endpoint structure, pagination, project-specific overrides
- "Reference Files" table in `SKILL.md` extended with `troubleshooting.md`, `advanced-operations.md`, `issues-api-response.md`

### Changed (Sprint 4)
- `SKILL.md` "API Response in Issues" section is now a short summary that links to `references/issues-api-response.md` (was 20+ lines inline)
- `references/issues.md` API Response section comment points at `issues-api-response.md` for the full rules
- Asset templates enriched and synced with reference files:
  - `assets/pr-template.md` — adds "Testing Performed", "Notes for Reviewers"; expands "Self-Review Checklist" to match `references/code-review.md`; adds "Performance improvement" type
  - `assets/issue-template-bug.md` — adds "Environment", "Frequency", "Severity" sections (standard bug-report fields)
  - `assets/issue-template-feature.md` — adds inline API Response example using the new envelope, "Dependencies", "Definition of Done" sections

### Planned
- Custom subagents: `commit-writer`, `pr-reviewer`, `issue-writer`
- Example walkthroughs and cheatsheet
- `plugin.json` manifest for formal distribution

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

[Unreleased]: https://github.com/yogaprastyoo/agent-skills/compare/github-git-v1.0.0...HEAD
[1.0.0]: https://github.com/yogaprastyoo/agent-skills/releases/tag/github-git-v1.0.0
