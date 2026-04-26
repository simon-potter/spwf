---
source: scratch
created: 2026-04-25
status: ideation
---

# AgentLint integration assessment

## Context

AgentLint (`@agent-lint/cli`, MIT, Node 18+) is a TypeScript CLI and MCP server that bills itself as "ESLint for your coding agents." It scans a workspace for all agent artifacts — `CLAUDE.md`, `AGENTS.md`, skills, rules, workflows, plans — and evaluates each against a 12-dimension quality framework. It is read-only and non-destructive. It can run as an MCP server, making it natively callable as a tool inside a Claude Code session.

We currently have four QoL skills: `claudemd-curator`, `agent-optimise`, `doc-lint`, `workflow-lint`. The question is whether agentlint supersedes some or all of them, augments them, or is best integrated into them as a sub-tool.

---

## What each tool uniquely owns

### AgentLint — uniquely does

- **12-dimension quality scoring** (clarity, specificity, scope control, completeness, actionability, verifiability, safety, injection resistance, secret hygiene, token efficiency, platform fit, maintainability) scored 0–10 per dimension across ALL artifact types — not just CLAUDE.md
- **Stale reference detection** — finds file paths referenced in artifacts that no longer exist on disk
- **Placeholder/incomplete section detection** — surfaces `TODO`, `TBD`, placeholder markers automatically
- **Platform contamination detection** — finds Claude-specific syntax bleeding into Cursor/Copilot rules or vice versa
- **Secret hygiene** — regex-based detection of hardcoded credentials in artifacts
- **Injection resistance checks** — looks for prompt-injection guards
- **Signal detection** — knows when artifact updates are needed based on git changes to code (package.json, CI configs, auth files, new src/ directories trigger specific artifact types)
- **Prompt generation** — produces a ready-to-paste IDE prompt contextualised to the current workspace health and recent git diff
- **MCP server mode** — agentlint can run as `npx @agent-lint/mcp` and be called as a tool directly inside a Claude Code session, without shell-out
- **Coverage breadth** — scans up to 200 files, 6 levels deep; covers the entire `.claude/`, `.github/`, `.cursor/` trees in one pass

### claudemd-curator — uniquely does

- **Behavioural audit from transcripts** — mines `~/.claude/projects/*.jsonl` to surface: rules violated in actual sessions, patterns observed but not yet in CLAUDE.md, dead rules that were never followed. No equivalent in agentlint.
- **AGENTS.md ↔ CLAUDE.md sync management** — detects and repairs the symlink/shim relationship; runs `sister-tools` to symlink Copilot/Cursor/Gemini/Windsurf rules to AGENTS.md. Agentlint observes these files but doesn't manage the relationship.
- **L0–L4 layer classification** — opinionated content framework for CLAUDE.md specifically: identity/map, Karpathy discipline, product-mode posture, pointers, housekeeping. Agentlint evaluates quality dimensions but doesn't structure content.
- **Three-source synthesis** — canonical content for L1 (Karpathy block) and L2 (product-mode block) is reference material the curator can paste verbatim. Agentlint has no content templates.
- **Propose-then-approve workflow** — generates a numbered diff proposal and waits for explicit human approval before any edit. Agentlint generates prompts for the LLM but doesn't produce a ready-to-approve diff.

---

## Where they overlap (and who does it better)

| Concern | claudemd-curator | agentlint | Better fit |
|---|---|---|---|
| Inventory of instruction files | Phase 1 — manual `ls` + line counts | `scan` — automated, all artifact types, 200-file depth | agentlint |
| File quality assessment | L0–L4 layer test (CLAUDE.md-focused) | 12-dimension scoring (all artifact types) | agentlint (breadth); claudemd-curator (CLAUDE.md depth) |
| Stale reference detection | Not present | `scan` — built in | agentlint |
| Placeholder detection | Not present | `scan` — built in | agentlint |
| Secret detection | Not present | `score` — regex-based | agentlint |
| AGENTS.md sync state | `sync-agents-md.sh check` | Observes but does not manage | claudemd-curator |
| Transcript behavioural audit | Phase 2 — full | Not present | claudemd-curator |
| Content templates | karpathy-block, product-mode-block | None | claudemd-curator |
| MCP integration | Not present | `npx @agent-lint/mcp` | agentlint |
| Covers our own skills/agents | No | Yes — scores SKILL.md files against 12 dimensions | agentlint |

### Impact on other QoL skills

| Skill | Overlap with agentlint | Assessment |
|---|---|---|
| `agent-optimise` | High — agentlint `score` covers agent quality across 12 dimensions with specificity our hand-built skill lacks | agentlint likely supersedes most of agent-optimise |
| `doc-lint` | Moderate — agentlint detects stale refs and placeholders; doc-lint has broader markdown/README scope | partial overlap; coexistence makes sense |
| `workflow-lint` | Low — agentlint checks artifact quality; workflow-lint checks golden path coherence (skill names, phase coverage, cross-references) | different concerns; keep both |

---

## Integration possibilities

### Option A — Replace claudemd-curator's Phases 1 and 3 with agentlint

Run `npx @agent-lint/cli scan` (inventory) and `npx @agent-lint/cli score CLAUDE.md` (quality) as Phase 1, then proceed to claudemd-curator's unique phases: behavioural audit (Phase 2), AGENTS.md sync (Phase 4), propose diff (Phase 5). Drop the hand-built L0–L4 layer classification and use agentlint's 12-dimension score as the quality signal instead.

**Pros:** Inventory is immediately more comprehensive. Quality scoring is more rigorous and multi-dimensional. Stale references and secrets detected for free.

**Cons:** Loses the opinionated L0–L4 structure that guides the user toward canonical CLAUDE.md content. The layer model is prescriptive in a way the 12-dimension score isn't — it tells you what to *put* in CLAUDE.md, not just whether it's good. The two frameworks are complementary, not redundant.

**Verdict:** Partially attractive. Better as a precursor than a replacement.

---

### Option B — Use agentlint as MCP tool inside claudemd-curator

Since agentlint ships an MCP server, it can be added to Claude Code's MCP config and called as a native tool. claudemd-curator's Phase 1 would call `mcp__agentlint__scan` and `mcp__agentlint__score` directly — no shell-out, no subprocess management. The results feed into the rest of the pipeline.

**Pros:** Cleanest integration. agentlint's analysis arrives as structured data. No need to replicate its checks in the skill. Keeps claudemd-curator's unique phases.

**Cons:** Introduces an MCP dependency (user must add agentlint to their MCP config). Adds a new tool the user has to install and manage. Makes the skill less self-contained than it currently is.

**Verdict:** The right long-term architecture if agentlint matures and becomes a standard tool. Premature to couple to it now unless the MCP API is stable.

---

### Option C — New orchestrator skill: `workspace-health`

Create a new skill that runs both tools in sequence:
1. agentlint `scan` + `score` — structural quality across all artifacts
2. claudemd-curator's behavioural audit — session transcript mining
3. claudemd-curator's AGENTS.md sync check
4. Combined proposal — structural findings from agentlint + behavioural findings from curator, merged into one numbered diff for human approval

Retire or simplify `agent-optimise` since agentlint's agent scoring is stronger.

**Pros:** Users get one invocation that covers all concerns. The combined output is richer than either tool alone. Provides a clear upgrade path as agentlint matures.

**Cons:** More complex to maintain. Requires agentlint to be installed (adds friction). The combined proposal format needs design work — agentlint findings and curator findings are structurally different.

**Verdict:** The most ambitious and most correct end state, but needs agentlint to prove stability first.

---

### Option D — Run agentlint standalone, keep claudemd-curator unchanged

Add agentlint as a separate QoL tool in its own right: install it, add the MCP server to Claude Code config, and let users call `npx @agent-lint/cli scan` or use it via MCP. claudemd-curator remains unchanged. Both tools coexist.

**Pros:** Zero integration work. Users get agentlint's value immediately. No coupling risk.

**Cons:** Users have to know to use both tools. The overlap areas (inventory, quality checks) produce duplicate effort. No synergy between the transcript audit and the quality score.

**Verdict:** Viable as a short-term step while the integration is designed. Not the right end state.

---

## AgentLint as MCP server — setup and tool surface

AgentLint ships two entry points: `@agent-lint/cli` (interactive CLI) and `@agent-lint/mcp` (MCP server). The MCP server exposes the same scan/score/prompt capabilities as native tools inside a Claude Code session, without any shell-out.

### Installation in Claude Code settings

Add to `~/.claude/settings.json` (global) or `.claude/settings.json` (project):

```json
{
  "mcpServers": {
    "agentlint": {
      "command": "npx",
      "args": ["-y", "@agent-lint/mcp"],
      "env": {}
    }
  }
}
```

For HTTP transport (useful if running the MCP server as a persistent daemon):

```json
{
  "mcpServers": {
    "agentlint": {
      "command": "npx",
      "args": ["-y", "@agent-lint/mcp", "--http", "--port", "3001"],
      "env": {}
    }
  }
}
```

### Tools exposed via MCP

Once registered, agentlint exposes tools callable as `mcp__agentlint__*` inside any skill or agent that lists them in `allowed-tools`. The tool surface (from the `@agent-lint/mcp` package):

| MCP tool | Equivalent CLI | What it returns |
|---|---|---|
| `mcp__agentlint__scan` | `npx @agent-lint/cli scan --json` | Full workspace scan: discovered artifacts, missing types, stale refs, placeholder sections, platform contamination, categorised issues |
| `mcp__agentlint__score` | `npx @agent-lint/cli score <file> --json` | 12-dimension quality score (0–10 per dimension) for a single artifact, with improvement recommendations |
| `mcp__agentlint__prompt` | `npx @agent-lint/cli prompt --stdout` | Contextualised maintenance prompt based on workspace health + recent git diff, ready to paste into any IDE |

### How claudemd-curator would call these

In Phase 1 (Inventory), replace the manual `ls` + line count block with:

```
mcp__agentlint__scan()
→ returns: discovered artifacts, missing sections, stale refs, placeholder content
```

In Phase 3 (Layer classification), augment the L0–L4 layer test with:

```
mcp__agentlint__score(file="CLAUDE.md", type="agents")
→ returns: dimension scores; low scores on token-efficiency or completeness
   inform which layer classification decisions are most impactful
```

The behavioural audit (Phase 2), AGENTS.md sync (Phase 4), and propose diff (Phase 5) remain owned by claudemd-curator — agentlint has no equivalents.

### Dependency and stability notes

- `@agent-lint/mcp` is pre-1.0. The MCP tool names (`mcp__agentlint__scan` etc.) may change between versions. Pin the version in the `args` array once a stable release ships: `["-y", "@agent-lint/mcp@0.x.y"]`.
- The MCP server is stateless (no persistent process required with `npx`). Each tool call cold-starts the server, adds ~1–2s latency. Acceptable for quality tools; would be slow if called per-task in the build loop.
- Both `@agent-lint/cli` and `@agent-lint/mcp` are MIT licensed and require no API key or external service.

---

## What we know

- agentlint's 12-dimension scoring is strictly more comprehensive than the L0–L4 layer test for quality assessment of individual artifacts
- agentlint covers the plugin marketplace's **own** skills and agents — it would score our SKILL.md files against its quality rubric, which our current tools cannot do
- The behavioural audit (transcript mining) is claudemd-curator's highest-value differentiator and has no equivalent anywhere else
- The AGENTS.md sync management (symlink/shim/sister-tools) is a concrete, mechanical operation that agentlint deliberately avoids — it remains owned by claudemd-curator
- agentlint's MCP mode is the right integration point if we commit to coupling, but adds a dependency and installation step
- `agent-optimise` is the weakest of our QoL skills relative to agentlint's coverage — it is the most redundant

## Open questions

- Is agentlint's MCP API stable enough to depend on? (It is pre-1.0, repo is early-stage)
- Does agentlint's `score` command support SKILL.md files in our plugin marketplace format? (folder-based skills with frontmatter — agentlint says it supports folder-based skills but we'd need to test)
- What does agentlint produce when it scores our existing SKILL.md files? Would it flag issues we haven't caught?
- Can agentlint be run without `npx` (local install) for offline/air-gapped environments?
- How does agentlint's stale reference detection handle our `openspec/changes/` paths, which are created and destroyed during the workflow?
- Should `agent-optimise` be deprecated in favour of agentlint, or does it do something agentlint doesn't?

## Rough scope (if we proceed)

**Immediate (low risk, high value):**
- Run agentlint scan against the current plugin marketplace to get a baseline quality score on our own artifacts
- Document findings — this tells us empirically whether agentlint adds value for our case
- Update `workflow-tools/README.md` to reference agentlint as a recommended standalone complement
- Add agentlint MCP config block to marketplace root README under Prerequisites (MCP server setup is now documented in this file — see section above)

**Short-term:**
- Update claudemd-curator's Phase 1 to call `mcp__agentlint__scan` (if registered) or fall back to `npx @agent-lint/cli scan --json` — graceful if neither available
- Update claudemd-curator's `allowed-tools` to include `mcp__agentlint__scan` and `mcp__agentlint__score` once MCP registration is in place
- Retire or simplify `agent-optimise` if agentlint's agent scoring covers its ground

**Medium-term (if agentlint proves stable and MCP API stabilises):**
- Design the `workspace-health` orchestrator skill (Option C) as the unified entry point
- Replace claudemd-curator's Phase 1 and Phase 3 with agentlint MCP calls, keeping Phases 2 (transcript audit), 4 (sync), and 5 (propose)
- Pin `@agent-lint/mcp` to a stable semver version in the MCP config block
