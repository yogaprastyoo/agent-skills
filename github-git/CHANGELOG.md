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

### Planned
- Hooks: `guard-push-to-main`, `commit-msg-validator`
- References: `troubleshooting.md`, `advanced-operations.md`
- Custom subagents: `commit-writer`, `pr-reviewer`, `issue-writer`
- Example walkthroughs and cheatsheet

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
