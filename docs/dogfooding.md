# Dogfooding SPWF locally

This project develops the SPWF plugins (`plugins/spwf` and `plugins/spwf-agents`).
To use them while developing them, install both as a **local marketplace** —
Claude Code reads them straight from the working tree, so edits in `plugins/`
take effect on reload without publishing.

## One-time setup

From the project root, inside Claude Code:

```
/plugin marketplace add ./
/plugin install spwf
/plugin install spwf-agents
/reload-plugins
```

After `/reload-plugins` the session should report all three plugins
(`spwf`, `spwf-agents`, plus the marketplace itself) and their skills,
agents, and hooks. Verify with `/spwf:wfstatus`.

## Keeping the install in sync

| You changed… | What to do |
|---|---|
| `plugins/spwf/skills/<name>/SKILL.md` body | `/reload-plugins` (or start a fresh session) |
| `plugins/spwf-agents/agents/<name>.md` body | `/reload-plugins` |
| `plugins/spwf/hooks/hooks.json` or any `hooks/*.sh` | `/reload-plugins` |
| Added a **new** skill, agent, or hook | `/reload-plugins` |
| Removed a skill, agent, or hook | `/reload-plugins` (and restart if it lingers) |
| Bumped version in `plugins/*/.claude-plugin/plugin.json` | Nothing locally — versions are for downstream `/plugin update` consumers |

If `/reload-plugins` doesn't pick a change up (rare — usually a stale
agent or MCP server), restart Claude Code (`/exit`, then `claude`).

## What NOT to do

- **Don't hand-roll symlinks** from `.claude/skills/` or `.claude/agents/`
  into `plugins/`. They duplicate maintenance, mask reload issues, and
  drift out of sync with the marketplace contract.
- **Don't commit `.claude/settings.json` hook entries** that point at
  `plugins/`. The plugin install registers hooks through
  `plugins/spwf/hooks/hooks.json` using `${CLAUDE_PLUGIN_ROOT}` — let
  Claude Code own that wiring.
- **Don't `/plugin install` from a published source** (GitHub, registry)
  while developing. You'd shadow the local copy and edits in `plugins/`
  would silently stop applying.

## Verifying the install

```
/plugin list
```

Should show `spwf` and `spwf-agents` with the local marketplace path as
the source. Skill availability can be checked with `/spwf:wfstatus` —
the dashboard lists every plugin-scoped skill and agent it can see.

## When to switch back to the published version

If you want to test how downstream users experience the plugin (version
bumps, `/plugin update` flow, install from a clean machine):

```
/plugin uninstall spwf
/plugin uninstall spwf-agents
/plugin marketplace remove spwf
# Then install from the published source as a normal consumer would.
```

Reverse the one-time setup above to return to dogfooding.
