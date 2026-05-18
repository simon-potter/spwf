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
2. **`bd init` run once in the project root.** Creates `./.bd/`. Without this, the plugin halts with a clear error on the first dispatch.
3. **`.bd/` in `.gitignore`.** The Beads database is per-checkout execution state, not source-of-truth — OpenSpec is.

Full details for items 2 and 3 are filled in by tasks 4.1 / 4.3 of `add-beadsify-tracker`.

## Do NOT run `bd setup claude`

Beads ships with a `bd setup claude` command that installs its own Claude Code integration scaffolding. **Do not run it.** SPWF provides the canonical Claude Code integration via the `spwf` and `spwf-agents` plugins; layering Beads' opinionated defaults on top would create unpredictable interactions. This plugin invokes the raw `bd` CLI directly (`bd q`, `bd show`, `bd comment`, `bd close`) — that's the only Beads integration surface we use.

If `bd setup claude` was already run on this machine, see the `bd` documentation for cleanup instructions.

## Status

In development. The full feature set lives in `openspec/changes/add-beadsify-tracker/`. This README will be expanded in Phase 4 tasks (4.1 + 4.2 + 4.5 multi-session workflow section).
