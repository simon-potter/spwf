# SPWorkflow — project instructions

## Dogfooding this project locally

This repo develops the SPWF plugins and uses them on itself. Install them
as a local marketplace so edits in `plugins/` apply to your active
session without publishing:

```
/plugin marketplace add ./
/plugin install spwf
/plugin install spwf-agents
/reload-plugins
```

After any edit to `plugins/spwf/**` or `plugins/spwf-agents/**`, run
`/reload-plugins` to pick the change up in the current session.

**Do not hand-roll symlinks** from `.claude/skills/` or `.claude/agents/`
into `plugins/` — let the plugin install own discovery and hook wiring
(`${CLAUDE_PLUGIN_ROOT}` paths in `plugins/spwf/hooks/hooks.json` only
resolve correctly under a real install).

Full how-to and sync table: [`docs/dogfooding.md`](docs/dogfooding.md).

## Before pushing to main

Bump the version in `plugins/spwf/.claude-plugin/plugin.json` (and `plugins/spwf-agents/.claude-plugin/plugin.json` if agents changed) whenever skills or agents are added, removed, or meaningfully changed. Downstream projects use `/plugin update` to pull changes, and the update command only fetches when the version number has incremented.

Use semver: patch (1.0.x) for fixes/tweaks, minor (1.x.0) for new skills or agents, major (x.0.0) for breaking changes.

## Keeping README.md current

Update `README.md` (and `plugins/spwf/README.md` if relevant) whenever a skill, agent, or hook is added, removed, or meaningfully changed — even if only a sentence or a table row. The READMEs are the first thing a new user reads; they should always reflect the current state of the plugin. Never push a capability change without a corresponding README update in the same commit.
