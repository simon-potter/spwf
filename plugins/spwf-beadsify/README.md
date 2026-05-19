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

3. **`.gitignore` entries.** `bd init` adds `.dolt/`, `*.db`, and `.beads-credential-key` to the project-root `.gitignore` automatically (and auto-commits the change). **Do NOT add `.beads/` yourself** — bd manages `.beads/` partially: the config, metadata, and project_id are committed (so a clone+init produces the same id namespace), while the Dolt DB and runtime files are gitignored via `.beads/.gitignore` (which bd creates). OpenSpec change directories remain source-of-truth for spec content; Beads is the execution-time scratchpad for issue tracking.

4. **Expect JSONL exports to evolve with usage.** After every bd write, bd auto-exports issues to `.beads/issues.jsonl` and interactions to `.beads/interactions.jsonl`. These files are **intentionally tracked** (not in `.beads/.gitignore`) — they're the git-friendly audit view of your issue history. Routine bd operations produce git diffs in these two files; commit them alongside other work in your normal workflow. If you want strict "git status clean" semantics, disable auto-export with `bd config set export.auto false` — at the cost of losing the JSONL audit view.

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

## Multi-session workflow (braindump while building)

Beadsify supports running two Claude Code sessions in the same project simultaneously:
one session running `/spwf:build` against an active change, a second session capturing
new stories into Beads as ideas surface. Both sessions share `./.beads/` via the `bd`
CLI; Beads is designed for multi-agent workflows (hash-based ids, designed-in
concurrent writers).

**The build session keeps focus.** When `/spwf:build` runs against a change whose
`proposal.md` contains `beads_story_id: bd-<hash>`, the build hook scopes `bd next` to
that story's subtree only. Stories created by another session land at the top level
(or under a different parent) and remain invisible to the build session's task
selection.

**Patterns that work:**

| Session A — building | Session B — braindump |
|---|---|
| `/spwf:build` (Beads-mode) | `/spwf:capture "rate-limit on /login"` — creates `bd-<hash>` via dispatch |
| `/spwf:build` (Beads-mode) | `bd q "rotate JWT secrets weekly" -p bd-<existing>` — link as child of an existing epic |
| `/spwf:build` (Beads-mode) | `bd remember "auth team prefers Argon2"` — write project-level agent memory (loaded at `bd prime` in future sessions) |

**One sharp edge to know:** if the braindump session adds a *dependency edge* into an
in-flight task (e.g. blocks the task the build session is currently implementing),
the bd graph mutates mid-execution. The build session's next `bd next` call will
return the new blocker. This is "you broke your own kneecap" territory — bd is doing
the right thing; the human did the wrong thing. Avoid editing the active change's
subtree from the braindump session.

**For terminals (without Claude Code):**

The braindump pattern also works from a plain terminal. `bd q "thought"` from the
project root creates a story. `bd remember "<insight>"` writes to the persistent
memory store. Useful when an idea surfaces while you're paged into something else
entirely.

## Status

`spwf-beadsify` is shipped as v0.1.0 — Beads as a tracker-dispatch backend
(`/spwf:capture`, `/spwf:tracker-comment`, `/spwf:close`). The build-loop integration
(`/spwf:build` consulting `bd next`/`bd done` during task execution) ships in a
follow-up change `add-beadsify-build-loop`.
