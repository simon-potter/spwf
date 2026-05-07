# SPWorkflow — project instructions

## Before pushing to main

Bump the version in `plugins/spwf/.claude-plugin/plugin.json` (and `plugins/spwf-agents/.claude-plugin/plugin.json` if agents changed) whenever skills or agents are added, removed, or meaningfully changed. Downstream projects use `/plugin update` to pull changes, and the update command only fetches when the version number has incremented.

Use semver: patch (1.0.x) for fixes/tweaks, minor (1.x.0) for new skills or agents, major (x.0.0) for breaking changes.

## Keeping README.md current

Update `README.md` (and `plugins/spwf/README.md` if relevant) whenever a skill, agent, or hook is added, removed, or meaningfully changed — even if only a sentence or a table row. The READMEs are the first thing a new user reads; they should always reflect the current state of the plugin. Never push a capability change without a corresponding README update in the same commit.
