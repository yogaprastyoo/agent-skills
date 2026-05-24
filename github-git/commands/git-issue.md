---
description: Create a GitHub issue following the team's template (Description, Context, API Response, Acceptance Criteria)
argument-hint: [type:] <short description>
---

# /git-issue

Create a GitHub issue that follows the github-git skill's required template.

## What this command does

1. Parses `$ARGUMENTS` as a hint for type and title — accepts plain text or conventional prefix (`feat:`, `fix:`, `refactor:`, `docs:`, `test:`, `chore:`)
2. Asks the user (in Indonesian) for any missing pieces: type, title, description, context, acceptance criteria
3. Detects whether this issue is for a backend endpoint and, if so, requires the `## API Response` section
4. Generates the full issue body via heredoc following `~/.claude/skills/github-git/references/issues.md`
5. Creates the issue with `gh issue create`
6. Reports the issue URL and the recommended branch name

## Workflow

When invoked:

### Step 1 — Verify prerequisites

```bash
gh auth status
```

If not authenticated, stop and ask the user to run `gh auth login`.

### Step 2 — Parse arguments

`$ARGUMENTS` may be:
- Empty → ask user for everything interactively
- `"feat: add JWT refresh"` → use `feat` as type, rest as title
- `"add JWT refresh"` → ask user for type, use this as title hint

Accepted types map to labels:
| Type | Label |
|------|-------|
| `feat` / `enhancement` | `enhancement` |
| `fix` / `bug` | `bug` |
| `docs` / `documentation` | `documentation` |
| `refactor`, `test`, `chore` | *(no default label — omit `--label`)* |

### Step 3 — Read the template

Read `~/.claude/skills/github-git/references/issues.md` (or `~/.agents/skills/github-git/references/issues.md` if symlinked) for the required template and rules.

### Step 4 — Detect backend endpoint context

If the user's description mentions any of:
- HTTP verbs (`GET`, `POST`, `PUT`, `PATCH`, `DELETE`)
- Endpoint paths (`/api/...`, `/v1/...`)
- "endpoint", "API", "controller", "route"

→ the `## API Response` section is **mandatory**. Follow `references/issues.md` + the `api-response` skill format. Ask the user for request, success, and error examples.

### Step 5 — Gather required sections

Required:
- **Description** (2–5 sentences, WHY not WHAT)
- **Context** (file paths, current behavior, prior decisions)
- **API Response** (if backend endpoint — see Step 4)
- **Acceptance Criteria** (`- [ ]` checkboxes, each independently verifiable)

Optional:
- **Technical Notes** (constraints, edge cases, suggested approach)

Ask for each section concisely. Do not invent content the user did not provide.

### Step 6 — Generate and create

Use heredoc with single-quoted `'EOF'` to prevent shell expansion:

```bash
gh issue create --title "type: <description>" --body "$(cat <<'EOF'
## Description

...

## Context

...

## Acceptance Criteria

- [ ] ...
EOF
)" --label "enhancement"
```

### Step 7 — Report and suggest next step

Print the issue URL returned by `gh`, then suggest the branch name:

```
Issue created: https://github.com/.../issues/42
Next: git checkout develop && git pull && git checkout -b feature/42-<slug>
```

Or invoke nothing — let the user decide.

## Constraints

- MUST follow `references/issues.md` template — no shortcuts
- MUST use single-quoted `'EOF'` heredoc
- MUST NOT include `Co-Authored-By: Claude`, `Co-Authored-By: Antigravity`, AI mentions, or "Generated with Claude" / "Generated with Antigravity" anywhere in the issue
- MUST verify `gh auth status` first
- MUST detect duplicate issues: `gh issue list --search "<keywords>"` before creating
- Title format: `type: short description` (lowercase, no period)
- Use only default GitHub labels (`bug`, `enhancement`, `documentation`) unless custom labels were created with `gh label create`

## Example invocations

```
/git-issue
/git-issue feat: add JWT refresh token
/git-issue fix: logout endpoint missing CSRF token
/git-issue docs: document app_session cookie behavior
```

## See also

- `references/issues.md` — full issue template and rules
- `references/branching-commits.md` — branch naming from issue number
- `~/.agents/skills/api-response/SKILL.md` — API response envelope (if installed)
