# spwf-beadsify

Optional SPWorkflow add-on: makes [Beads](https://github.com/gastownhall/beads) (`bd`) the project's tracker by plugging into spwf core's `_shared/tracker-dispatch.md` abstraction. Every `/spwf:*` skill that talks to a tracker (capture, tracker-comment, close) keeps working unchanged — only the backend differs.

**SPWF works without this plugin.** Install only if you want Beads as your tracker. See the parent project's `README.md` § "Optional add-on: Beadsify (in development)" for the two workflow profiles.

## Install

```
/plugin install spwf-beadsify@spwf
```

Then set the tracker for this project:

```yaml
# .spwf/tracker.yaml
tracker: beads
```

## Prerequisites

1. **Beads CLI (`bd`) installed and on PATH.** The parent repo ships a wrapper at `scripts/install-beads.sh` — `bash scripts/install-beads.sh` from the project root installs it via the upstream installer.

2. **Initialise Beads in the project, but use the safe flags.** The plugin halts on first dispatch if `.beads/` is missing. To create it, run **in the project root**:

   ```bash
   bd init --skip-agents --skip-hooks --non-interactive
   ```

   **Do not run plain `bd init`.** See the "Forbidden commands" section below for why.

3. **`.gitignore` entries.** `bd init` adds `.dolt/`, `*.db`, and `.beads-credential-key` to `.gitignore` automatically (and auto-commits the change). Add `.beads/` yourself:

   ```bash
   echo ".beads/" >> .gitignore
   ```

   The Beads database is per-checkout execution state, not source-of-truth — OpenSpec is.

## Forbidden commands

**Two `bd` commands are forbidden inside an SPWF project.** Both install Beads' own Claude Code integration, which conflicts with SPWorkflow's (32 skills, 13 agents, 5 hooks) — at best unpredictable interactions, at worst overwriting your `CLAUDE.md` and `AGENTS.md`.

| Command | What it does (verified against bd 1.0.4) | Use this instead |
|---|---|---|
| `bd init` (plain, no flags) | Creates `.beads/`, **writes `CLAUDE.md` and `AGENTS.md` to the project root**, creates `.claude/settings.json` with SessionStart + PreCompact hooks, modifies `.gitignore`, auto-commits | `bd init --skip-agents --skip-hooks --non-interactive` |
| `bd setup claude` | Installs Beads' Claude Code integration on its own (separate from init) | Don't run it. Period. |

This plugin only ever invokes the raw `bd` CLI directly (`bd q`, `bd show`, `bd comment`, `bd close`). It never invokes any Beads command that installs Claude Code integration.

### Recovery if you already ran the wrong command

If `bd init` (plain) or `bd setup claude` was already run on this machine in your project:

- Check `git log` for an auto-commit titled `bd init: initialize beads issue tracking` — revert it
- Restore your project's `CLAUDE.md` from git history (if it was overwritten)
- Delete the project-root `AGENTS.md` (if you didn't have one before)
- Remove `.claude/settings.json` hook entries Beads added (`SessionStart`, `PreCompact` with bd-related commands)
- Re-run `bd init --skip-agents --skip-hooks --non-interactive` to keep the `.beads/` database

## Status

In development. The full feature set lives in `openspec/changes/add-beadsify-tracker/`. This README will be expanded in Phase 4 tasks (4.1 + 4.2 + 4.5 multi-session workflow section).
