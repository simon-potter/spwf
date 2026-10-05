# SPWorkflow — project instructions

## Dogfooding this project locally

This repo develops the SPWF plugins and uses them on itself. Install them
as a local marketplace so edits in `plugins/` apply to your active
session without publishing:

```
/plugin marketplace add ./
/plugin install spwf
/plugin install spwf-agents
/plugin install spwf-beadsify   # optional — only for the Beadsify add-on
/reload-plugins
```

After any edit to `plugins/spwf/**`, `plugins/spwf-agents/**`, or
`plugins/spwf-beadsify/**`, run `/reload-plugins` to pick the change up in the
current session.

**Beadsify** (`spwf-beadsify`) is the optional third plugin that adds [Beads](https://github.com/gastownhall/beads) (`bd`)
as a tracker-dispatch backend — replacing YouTrack/Jira at the tracker layer when
`.spwf/tracker.yaml` is set to `tracker: beads`. SPWF is fully usable without it.
This project dogfoods all three plugins. Beads itself is installed via
[`scripts/install-beads.sh`](scripts/install-beads.sh). For the Beadsify-specific
"do NOT run plain `bd init` or `bd setup claude`" rule and the safe init command,
see [`plugins/spwf-beadsify/README.md`](plugins/spwf-beadsify/README.md).

**Do not hand-roll symlinks** from `.claude/skills/` or `.claude/agents/`
into `plugins/` — let the plugin install own discovery and hook wiring
(`${CLAUDE_PLUGIN_ROOT}` paths in `plugins/spwf/hooks/hooks.json` only
resolve correctly under a real install).

Full how-to and sync table: [`docs/dogfooding.md`](docs/dogfooding.md).

## This repo is the Beads integration test bed

Beadsify is largely untested against real work. From 2026-10-05 this repo
tracks its own changes in Beads (`tracker: beads`) on purpose, to find the
rough edges before downstream projects do. While working here:

- **Use the real path.** Run tracker steps through the spwf skills
  (`capture`, `tracker-comment`, `close`), not hand-run `bd` commands, so the
  integration is what gets exercised. Hand-run `bd` only to inspect state or
  recover.
- **Log every niggle as it happens** in
  [`docs/beads-dogfood.md`](docs/beads-dogfood.md): what you ran, what
  happened, what you expected, the bd version. That includes friction and
  confusing output, not only failures. Don't work around something silently.
- **Report back.** When an entry is understood well enough to fix, capture it
  as a change against `plugins/spwf-beadsify/` (or `_shared/tracker-dispatch.md`)
  and mark the log entry with the change id. Gotchas that downstream users will
  hit belong in `plugins/spwf-beadsify/README.md`, not just the log.
- **Beads data is committed.** `bd` rewrites `.beads/issues.jsonl` and
  `.beads/interactions.jsonl` on every write; commit them with the work they
  belong to.

## Before pushing to main

Bump the version in `plugins/spwf/.claude-plugin/plugin.json` (and `plugins/spwf-agents/.claude-plugin/plugin.json` if agents changed) whenever skills or agents are added, removed, or meaningfully changed. Downstream projects use `/plugin update` to pull changes, and the update command only fetches when the version number has incremented.

Use semver: patch (1.0.x) for fixes/tweaks, minor (1.x.0) for new skills or agents, major (x.0.0) for breaking changes.

## Keeping README.md current

Update `README.md` (and `plugins/spwf/README.md` if relevant) whenever a skill, agent, or hook is added, removed, or meaningfully changed — even if only a sentence or a table row. The READMEs are the first thing a new user reads; they should always reflect the current state of the plugin. Never push a capability change without a corresponding README update in the same commit.
