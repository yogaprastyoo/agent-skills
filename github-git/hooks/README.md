# Hooks

This directory holds two layers of automation that catch workflow violations:

| Layer | When it fires | Catches |
|-------|---------------|---------|
| **Claude Code hooks** (in this directory) | Before Claude runs a tool call | Actions Claude is about to take |
| **Git hooks** (in `git-hooks/`) | When `git` itself runs | Actions a human takes at the terminal |

Use both for defense-in-depth. They overlap intentionally — the Claude-layer hooks stop the AI from doing the wrong thing, the git-layer hooks stop a human (or any tool that doesn't go through Claude) from doing the wrong thing.

---

## Claude Code hooks

### `guard-push-to-main.sh`

Blocks Bash commands that push directly to `main` or `master`. Matches:

- `git push origin main`
- `git push origin master`
- `git push --force origin main`
- `git push origin HEAD:main`

### `commit-msg-validator.sh`

Blocks Bash `git commit -m "..."` invocations whose message fails Conventional Commits validation. Validates:

- First line follows `<type>(<scope>)?!?: <description>`
- Type is one of: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`, `ci`, `perf`, `revert`
- Subject line ≤ 72 characters
- Description isn't a vague word like `stuff`, `update`, `wip`, `fix`

Heredoc (`-m "$(cat <<'EOF' ... EOF)"`) and `-F <file>` forms pass through to the git-level hook (which inspects the full message after `git` writes it to disk).

### Install (Claude Code hooks)

1. Merge the snippet from [`settings.example.json`](./settings.example.json) into your `~/.claude/settings.json` (or create the file if it doesn't exist):

   ```json
   {
     "hooks": {
       "PreToolUse": [
         {
           "matcher": "Bash",
           "hooks": [
             { "type": "command", "command": "$HOME/.agents/skills/github-git/hooks/guard-push-to-main.sh" },
             { "type": "command", "command": "$HOME/.agents/skills/github-git/hooks/commit-msg-validator.sh" }
           ]
         }
       ]
     }
   }
   ```

2. Make sure the hook scripts are executable:

   ```bash
   chmod +x ~/.agents/skills/github-git/hooks/*.sh
   ```

3. Restart Claude Code. From the next session, every Bash tool call passes through these hooks.

### Uninstall

Remove the entries from `~/.claude/settings.json`. The scripts remain on disk but no longer fire.

---

## Git hooks

### `git-hooks/commit-msg`

A git-level `commit-msg` hook that wraps `scripts/validate-commit-msg.sh`. Runs after `git` writes the commit message to disk — catches heredoc and `-F file` cases the Claude-layer hook can't inspect.

### `git-hooks/pre-push`

A git-level `pre-push` hook that refuses pushes whose target ref is `refs/heads/main` or `refs/heads/master`.

### Install (git hooks)

These are per-repository — install them once in each repo where you want the protection:

```bash
cd /path/to/your/repo
bash ~/.agents/skills/github-git/scripts/install-git-hooks.sh
```

The installer symlinks (or copies, depending on flags) the hooks from this directory into `<repo>/.git/hooks/`.

### Bypass for a single commit/push

Both `commit-msg` and `pre-push` git hooks honor the `--no-verify` flag:

```bash
git commit --no-verify -m "<message>"
git push --no-verify origin main
```

Use sparingly — the convention is "never bypass without a reason worth writing down."

---

## Troubleshooting

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| Hook never fires | Not executable | `chmod +x <hook>` |
| Hook fires twice | Multiple entries in `settings.json` | Deduplicate the `hooks.PreToolUse` array |
| `jq: command not found` warning | `jq` not installed | Install jq (`apt install jq` / `brew install jq`) — fallback parser still works |
| Validator finds nothing wrong but commit still blocked | Stale shell function | Reopen the terminal so the hook re-reads from disk |
| Bypassing repeatedly | Reconsider whether the hook rule still serves the team. If yes, retrain. If no, edit or remove the hook. | — |
