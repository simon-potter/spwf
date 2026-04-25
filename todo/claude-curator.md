Finishing the script, then packaging everything for download.One small bug in the drift signal calculation — `pipefail` is making the `|| echo 0` fallback trigger spuriously. Quick fix:Clean. Now packaging everything for download.---

## Skill complete and verified

**1028 lines across 7 files, 18K compressed.** Both scripts pass `bash -n` syntax check and end-to-end smoke tests against synthetic repos covering all four sync states (`OK_SYMLINK`, `OK_SHIM`, `DUAL`, `AGENTS_ONLY`).

### Installation

For a single project:
```bash
tar xzf claudemd-curator.tar.gz -C .claude/skills/
```

For your local plugin marketplace (per the migration in progress per your memory):
```bash
tar xzf claudemd-curator.tar.gz -C <marketplace>/plugins/<plugin-name>/skills/
```

### What you can do with it immediately

```bash
# Audit current repo's sync state (no changes)
.claude/skills/claudemd-curator/scripts/sync-agents-md.sh check --recursive

# Migrate to AGENTS.md-canonical with shim (preserves Claude-only content space)
.claude/skills/claudemd-curator/scripts/sync-agents-md.sh migrate --mode=shim

# Symlink Copilot/Cursor/Gemini/Windsurf rules to AGENTS.md
.claude/skills/claudemd-curator/scripts/sync-agents-md.sh sister-tools

# Mine recent transcripts for the current project
.claude/skills/claudemd-curator/scripts/mine-conversations.sh -n 20
```

Then in Claude Code, invoke the skill itself for the full four-phase pipeline (inventory → behavioural audit → layer classification → sync verification → diff proposal).

### Three things worth flagging

**The skill description is deliberately "pushy"** per Anthropic's skill-creator guidance to combat undertriggering — it lists explicit phrases, the post-`/init` cleanup case, the rule-violation case, and the AGENTS.md migration case. If you find it triggering too aggressively in practice, the natural next step is to run `skill-creator`'s description-optimisation loop (`run_loop.py`) against an eval set built from your actual transcripts. Happy to help draft that eval set if useful.

**Phase 5 is intentionally non-destructive.** The skill proposes a diff and waits for explicit approval before editing. This matters more than it sounds — running an automated CLAUDE.md refactor without review is exactly the kind of one-way door the L2 block warns against, and it'd be hypocritical for the skill that teaches the principle to violate it.

**The behavioural-audit phase has a quiet dependency on `~/.claude/projects/` being populated.** On a fresh install or after `/clear`-heavy usage there may be nothing to mine. The skill handles this gracefully (Phase 2 produces an empty findings section rather than failing) but it's worth knowing — the audit gets sharper the more you use the project. Don't run it on day one of a repo and expect insight.

Want me to draft the description-optimisation eval set next, or run this skill against an actual CLAUDE.md you'd like to refactor as a real-world test?