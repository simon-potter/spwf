---
source: scratch
created: 2026-05-20
status: archived
archived: 2026-06-29
---

# Multi-harness distribution — Codex first, others later

> **ARCHIVED 2026-06-29 — out of date, not being pursued.** This ideation seed
> (written 2026-05-20) reflects the harness landscape and SPWF layout at that
> time and has not been kept current. Kept for reference only. If multi-harness
> distribution is revived, re-validate every assumption below (Codex's plugin
> model, the draft-cli-plugin pattern, the skill/agent/hook inventory) against
> the then-current codebase before acting — do not treat it as a live plan.

## Context

SPWorkflow today ships exclusively as a [Claude Code](https://docs.claude.com/en/docs/claude-code) plugin via the native `/plugin marketplace` mechanism. Users on other coding-agent harnesses ([Codex CLI](https://github.com/openai/codex), [Cursor](https://cursor.com/), [Cline](https://cline.bot/), [Aider](https://aider.chat/), and the next entrants) cannot install SPWF without rebuilding it inside their own conventions.

Distribution gap matters because:
- The workflow value (capture → challenge → spec → build → simplify → ship → close) is harness-independent — the discipline is the same regardless of which agent runs it.
- Beadsify, recently shipped, makes SPWF more attractive to solo-and-agentic users who often use multiple harnesses.
- The reference plugin [`idodekerobo/draft-cli-plugin`](https://github.com/idodekerobo/draft-cli-plugin) demonstrates that a single source tree can install cleanly into Claude Code + Codex + Cursor with per-harness manifest dirs + setup scripts. We can adopt the same pattern.

**Codex is the priority target** (the user has it installed and uses it). Cursor / Cline / Aider come later but the layout should not preclude them.

## What we know

### Current SPWF distribution (Claude Code only)

- Marketplace catalog at `.claude-plugin/marketplace.json` declares three plugins: `spwf`, `spwf-agents`, `spwf-beadsify` (post-Beadsify).
- Plugins published from `plugins/<name>/` with `.claude-plugin/plugin.json` per plugin.
- 33+ skills under `plugins/spwf/skills/<name>/SKILL.md` — markdown body + YAML frontmatter (`name`, `description`, `disable-model-invocation`, `allowed-tools`).
- 13 agents under `plugins/spwf-agents/agents/<name>.md` — markdown body + YAML frontmatter.
- 5 hooks under `plugins/spwf/hooks/` referenced by `plugins/spwf/hooks/hooks.json` using `${CLAUDE_PLUGIN_ROOT}`.
- Tracker dispatch via `plugins/spwf/skills/_shared/tracker-dispatch.md` (MCP backends + skill-based backend for Beads).

### Codex's plugin model (researched from draft-cli-plugin)

Codex CLI does **not** have a native plugin marketplace. Plugins ship via setup scripts that install files into well-known locations under `~/.codex/`:

| Location | Purpose |
|---|---|
| `~/.codex/AGENTS.md` | Top-level agent instructions (analogous to `CLAUDE.md` for Claude Code) |
| `~/.codex/agents/<name>.toml` | Sub-agent definitions — **TOML, not markdown** |
| `~/.codex/hooks.json` | Hook registry — different schema than Claude Code's `hooks.json` |
| `~/.codex/hooks/<plugin>/<script>.sh` | Hook scripts |
| `~/.codex/config.toml` | Codex config; `codex_hooks` feature flag must be enabled |
| `~/.agents/skills/<name>/SKILL.md` | Skills — Codex reads skills from a generic location (shared with other harnesses?) |

Codex's slash-command prefix is `$` instead of `/`: `$spwf:capture` instead of `/spwf:capture`. (Behaviour is otherwise equivalent — the prefix is a Codex convention, not a content difference.)

draft-cli-plugin uses a `curl -fsSL https://raw.githubusercontent.com/.../scripts/codex-setup.sh | bash` install path. The script:
1. Creates `~/.codex/hooks/<plugin>/` and copies hook scripts in.
2. Registers hooks in `~/.codex/hooks.json` (merge, not overwrite).
3. Enables `codex_hooks` in `~/.codex/config.toml`.
4. Translates agent definitions from the repo's `agents/<name>.md` into `~/.codex/agents/<name>.toml`.
5. Writes a top-level `~/.codex/AGENTS.md` from the repo's `.codex/AGENTS.md`.
6. Installs skills into `~/.agents/skills/<name>/SKILL.md`.

### Reusable vs harness-specific content (gap analysis)

| Asset | Cross-harness? | Why |
|---|---|---|
| **Skill bodies** (`SKILL.md`) | ✓ Yes | Markdown + YAML frontmatter is portable. Slash-prefix difference (`/` vs `$`) is invocation, not body. |
| **Agent bodies** (markdown narrative) | ⚠ Partially | Same content can drive both; format differs (Claude expects MD with frontmatter; Codex expects TOML). Needs transformation step. |
| **Hook scripts** (`*.sh`) | ✓ Yes | The shell scripts themselves are portable. |
| **Hook registry** (`hooks.json`) | ✗ No | Schema differs per harness. Each harness needs its own registry, generated from a shared source. |
| **Tracker dispatch** (`_shared/tracker-dispatch.md`) | ✓ Yes | Pure instruction document — harness-agnostic. |
| **Forge dispatch** (`_shared/forge-dispatch.md`) | ✓ Yes | Same. |
| **Marketplace manifest** (`.claude-plugin/marketplace.json`) | ✗ No | Claude Code only. Codex has no equivalent (uses curl-install). |
| **Plugin version** (`plugin.json`) | ⚠ Concept-reusable | Codex install scripts version via repo tags / `VERSION` file. |

## Open questions

- **Translation strategy.** Do we (a) write skill/agent bodies once in a neutral format and have the setup script translate at install time, or (b) maintain harness-specific manifest dirs (`.claude-plugin/`, `.codex/`, `.cursor-plugin/`) that each reference the same shared `skills/` and `agents/` content?
- **Slash-prefix invariance.** Skill bodies sometimes reference other skills by name (e.g. `/spwf:simplify` in `/spwf:close`'s instructions). If Codex uses `$` prefix, do we need to text-substitute at install time, or do we update SKILL.md bodies to use a prefix-agnostic form (`spwf:simplify` with no leading character, harness-templated at runtime)?
- **Hook compatibility.** The 5 spwf-core hooks are useful but not all are universally desirable. (`plugin-version-check.sh` is for spwf development; others are general workflow hygiene.) Which hooks ship to Codex by default, and how do users disable individuals?
- **Agent format conversion.** Codex's `~/.codex/agents/<name>.toml` schema — what does it look like (need to read the Codex docs or a draft-cli-plugin example), and is markdown → TOML conversion lossless for our 13 agents?
- **AGENTS.md analog for SPWF.** Claude Code reads `CLAUDE.md`; Codex reads `AGENTS.md`. Do we ship a `.codex/AGENTS.md` derived from the current `CLAUDE.md`, or write a Codex-specific one that points at the same content?
- **Beadsify-specific:** Beadsify's `bd setup claude` warning currently mentions only Claude. The equivalent on Codex would be `bd setup codex` — which exists per the research. Does the same warning apply? Probably yes (same "we provide the integration, don't double up" reasoning).
- **Update path.** Claude Code uses `/plugin update`. Codex has no equivalent — users would re-run the setup script or we'd ship an `spwf-update` skill that pulls fresh content. What's the canonical update story?
- **Other harnesses' priority.** Cursor next? Cline? Aider? Or skip past those to wait-and-see on the next major entrant?

## Rough scope

### Stage 1 — Codex support (this proposal's scope when challenged)

**In scope:**
- New `.codex/` directory at repo root containing:
  - `AGENTS.md` — top-level Codex instructions (Codex's analog to our `CLAUDE.md`)
  - `agents/<name>.toml` — 13 agents translated from `plugins/spwf-agents/agents/<name>.md`
  - Possibly a sub-agent manifest if Codex requires one
- `scripts/codex-setup.sh` — modeled on draft-cli-plugin's, installs:
  - Hook scripts → `~/.codex/hooks/spwf/`
  - Hook registry merge → `~/.codex/hooks.json`
  - `codex_hooks` feature flag → `~/.codex/config.toml`
  - Agent TOMLs → `~/.codex/agents/`
  - `AGENTS.md` → `~/.codex/AGENTS.md`
  - Skills → `~/.agents/skills/spwf/<name>/` (or whatever the cross-harness skill convention turns out to be)
- `scripts/codex-uninstall.sh` — symmetric reversal.
- Install instructions in `README.md` (and `plugins/spwf-beadsify/README.md` for Beadsify-on-Codex).
- Document the slash-prefix difference (`/spwf:foo` Claude / `$spwf:foo` Codex).

**Out of scope (for Stage 1):**
- Cursor / Cline / Aider — design the layout so adding them is a matter of adding a new `.cursor-plugin/` dir + `scripts/cursor-setup.sh`, but ship Codex only first.
- Automated update mechanism (`spwf-update` skill) — for v1, document the re-run-setup-script path.
- Cross-harness skill-prefix abstraction — for v1, accept prefix-substitution at install time as a setup-script step.
- Per-harness CI testing — manual smoke verification on Codex install path is the v1 acceptance bar.

### Stage 2 — Cursor / generalisation (separate change)

- `.cursor-plugin/` + `scripts/cursor-setup.sh`.
- Factor common setup logic into `scripts/_shared/` (curl-install detection, file installation helpers, prefix substitution).
- Document the "adding a new harness" procedure.

### Stage 3+ — Aider / Cline / future entrants

- Slot in as new `.<harness>-plugin/` dirs + setup scripts following the Stage 2 template.
- If a harness has a native marketplace at this point, also publish through it.

## Reference

- [`idodekerobo/draft-cli-plugin`](https://github.com/idodekerobo/draft-cli-plugin) — the working pattern for cross-CLI distribution. Key files to read: `scripts/codex-setup.sh`, `.codex/AGENTS.md`, the per-harness manifest dirs.
- [Codex CLI documentation](https://github.com/openai/codex) — for hook schema, AGENTS.md conventions, sub-agent TOML format, and the `codex_hooks` feature flag.
- SPWF's own `CLAUDE.md` and `docs/dogfooding.md` — for the Claude Code marketplace mechanics this layer parallels.

## Notes for the next step

This file is an **ideation seed**, written 2026-05-20 while `feature/add-beadsify-tracker` (PR #1) was awaiting merge. It is not part of that PR's scope — Codex support is a separate change.

The natural next steps once Beadsify ships:
1. `/spwf:challenge todo/multi-harness-distribution.md` — pressure-test the open questions above, decide on the translation strategy, and split into stages if it ends up larger than one change.
2. `/spwf:spec` once the scope is settled.
3. Stage 1 implementation: probably 1-2 weeks of focused work given the volume of skills/agents to translate and verify.

The bd integration shipped in PR #1 gives us a tracker that can hold the "do this on the next pass" notes if any of the open questions need to be parked while Stage 1 progresses.
