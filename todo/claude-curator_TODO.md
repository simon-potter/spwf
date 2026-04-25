---
source: scratch
created: 2026-04-25
status: ideation
---

# Claude Curator — QOL skill integration plan

> Integrating `claudemd-curator` (from `todo/claudemd-curator.tar.gz`) into the plugin marketplace as a quality-of-life skill under `workflow-tools`.

---

## Background

The asset is a fully-built Claude Code skill produced externally. It solves a real, recurring problem: CLAUDE.md and AGENTS.md files bloat over time, drift from each other, and accumulate dead or never-followed rules. Left unmanaged, this degrades every session: wasted context tokens, contradictory instructions, and mid-session rule drift under compaction.

The skill synthesises three published sources into a structured five-phase pipeline:

| Phase | What it does |
|---|---|
| 1 — Inventory | Reads all agent instruction files, measures size, checks AGENTS.md sync state |
| 2 — Behavioural audit | Mines `~/.claude/projects/*.jsonl` transcripts; spawns Sonnet subagents to surface violated rules, candidate additions, dead rules |
| 3 — Layer classification | Assigns every line in CLAUDE.md to L0–L4 (identity/map, discipline, decision posture, pointers, housekeeping) or marks it for removal |
| 4 — Sync verification | Runs `sync-agents-md.sh check` to report: OK_SYMLINK, OK_SHIM, DUAL (drift risk), CLAUDE_ONLY, AGENTS_ONLY |
| 5 — Propose, don't apply | Produces a numbered proposal; waits for explicit human approval before editing anything |

The three-source synthesis (Karpathy discipline block, product-mode decision posture, ykdojo behavioural feedback loop) is the intellectual content. The scripts and reference docs are tooling around it.

---

## Asset inventory

### What ships in the tarball (1028 lines, 7 files, 18K compressed)

| File | Lines | Purpose |
|---|---|---|
| `claudemd-curator/SKILL.md` | ~217 | Main skill — five phases, three-source synthesis, examples, pitfalls |
| `references/layer-model.md` | ~128 | Full L0–L4 definitions, templates, worked example (280→65 line refactor) |
| `references/karpathy-block.md` | ~68 | Canonical Karpathy discipline block, ready to paste |
| `references/product-mode-block.md` | ~53 | Canonical product-mode decision posture block, ready to paste |
| `references/anti-patterns.md` | ~102 | 12 specific things to remove, with rationale and redirect |
| `scripts/mine-conversations.sh` | ~118 | Extracts JSONL transcripts from `~/.claude/projects/` |
| `scripts/sync-agents-md.sh` | ~349 | Verifies/repairs AGENTS.md ↔ CLAUDE.md relationship (4 subcommands) |

### Quality assessment

**Strengths:**
- The SKILL.md is production-quality — clear phase structure, concrete examples, common pitfalls section, explicit "propose don't apply" constraint
- The two bash scripts are well-written: `set -euo pipefail`, `jq`-based JSONL parsing, coloured terminal output, clean exit codes, no external deps beyond `bash` + `jq`
- The reference docs are dense reference material, appropriate for on-demand reading (not always-on context)
- The layer model (L0–L4) with length budgets is a solid opinionated framework that will survive over time
- The AGENTS.md sync guidance is current as of April 2026 and matches platform reality

**Gaps requiring adaptation for the marketplace:**

| Gap | Fix needed |
|---|---|
| No `disable-model-invocation: true` | Add to frontmatter — required for all workflow-tools skills |
| No `allowed-tools` declaration | Add: `[Read, Write, Bash, Glob, Grep, Agent]` — Agent is needed for Phase 2 Sonnet subagents |
| Script paths assume `.claude/skills/claudemd-curator/` install path | Adapt to use `find`-based script discovery, with inline fallback |
| SKILL.md references `scripts/mine-conversations.sh` as relative path | Fix: resolve script dir at runtime via `find ~/.claude -name 'sync-agents-md.sh' ...` |
| References in SKILL.md point to `references/*.md` as relative paths | Fix: make clear they live alongside the SKILL.md; Claude reads them via the Agent's Read tool — no path change needed if structure preserved |
| Skill isn't in any README or plugin table | Add to `workflow-tools/README.md` under `## Quality tools` |
| No attribution in frontmatter | Add: three source attributions (Karpathy, product-mode, ykdojo) |

---

## Integration plan

### Placement

**Plugin:** `workflow-tools`
**Section:** `## Quality tools` (alongside `doc-lint`, `agent-optimise`, `workflow-lint`)
**Skill name:** `claudemd-curator` (matches the asset and the description's invocation guidance)
**Invoke:** `/workflow-tools:claudemd-curator`

### Tasks

- [ ] A.1 Create `plugins/workflow-tools/skills/claudemd-curator/SKILL.md` — adapted from the asset with: `disable-model-invocation: true`, `allowed-tools: [Read, Write, Bash, Glob, Grep, Agent]`, attribution comment, script-discovery fix
- [ ] A.2 Create `plugins/workflow-tools/skills/claudemd-curator/scripts/mine-conversations.sh` — verbatim from asset (already production-quality)
- [ ] A.3 Create `plugins/workflow-tools/skills/claudemd-curator/scripts/sync-agents-md.sh` — verbatim from asset
- [ ] A.4 Create `plugins/workflow-tools/skills/claudemd-curator/references/layer-model.md` — verbatim from asset
- [ ] A.5 Create `plugins/workflow-tools/skills/claudemd-curator/references/karpathy-block.md` — verbatim from asset
- [ ] A.6 Create `plugins/workflow-tools/skills/claudemd-curator/references/product-mode-block.md` — verbatim from asset
- [ ] A.7 Create `plugins/workflow-tools/skills/claudemd-curator/references/anti-patterns.md` — verbatim from asset
- [ ] A.8 Update `plugins/workflow-tools/README.md` to add `claudemd-curator` row under `## Quality tools`

### Key SKILL.md adaptations (detail)

**Frontmatter additions:**
```yaml
# Source: claudemd-curator skill, synthesising Karpathy/product-mode/ykdojo
# Scripts: scripts/mine-conversations.sh, scripts/sync-agents-md.sh
# References: references/layer-model.md, references/karpathy-block.md,
#             references/product-mode-block.md, references/anti-patterns.md
name: claudemd-curator
description: <unchanged — already well-written and appropriately trigger-happy>
disable-model-invocation: true
allowed-tools: [Read, Write, Bash, Glob, Grep, Agent]
```

**Script discovery (Phase 2 and 4):**

Replace hardcoded `scripts/mine-conversations.sh` with:
```bash
CURATOR_SCRIPTS="$(find ~/.claude -name 'sync-agents-md.sh' \
  -path '*/claudemd-curator/scripts/*' 2>/dev/null | head -1 | xargs dirname 2>/dev/null || echo '')"
```

If `$CURATOR_SCRIPTS` is empty (script not found on the Claude Code path), fall back to inline equivalent Bash. The SKILL.md body already contains enough prose to do this inline — the scripts are acceleration, not a requirement.

**Reference file paths:**

Prefix each reference pointer with the discovery pattern above, or simply tell Claude that the references live alongside SKILL.md and to `find` them:
```bash
CURATOR_REFS="$(find ~/.claude -name 'layer-model.md' \
  -path '*/claudemd-curator/references/*' 2>/dev/null | head -1 | xargs dirname 2>/dev/null || echo '')"
```

---

## Decisions

### D1 — Use skill name `claudemd-curator` not `claude-curator`

The full name matches the asset, the tarball, and the description. It's unambiguous about what it curates.

### D2 — Keep scripts as files, not inlined into SKILL.md

The scripts are independently useful (can be run ad-hoc, cron-able, piped into other tools). Inlining them into SKILL.md would break that. The discovery mechanism handles the path issue cleanly.

### D3 — `allowed-tools` includes `Agent`

Phase 2 explicitly spawns Sonnet subagents for transcript batches. Without the Agent tool, the skill degrades to inline analysis only (still useful, but slower for large transcript sets).

### D4 — Do not add `claudemd-curator` to the root README.md golden path table

It's a Quality tool, not a workflow step. It belongs in the `workflow-tools/README.md` Quality tools section only, and optionally as a pointer in CLAUDE.md/AGENTS.md for users who want it in their context.

### D5 — scripts/ files need execute bit

After copying, `chmod +x` is needed. Note this in the README under prerequisites or in the SKILL.md's Phase 1 setup block.

---

## Notes

- The behavioural audit (Phase 2) needs `~/.claude/projects/` to be populated. Zero transcripts → Phase 2 produces an empty findings section (graceful, not a failure). Document this limitation.
- The skill is intentionally non-destructive (Phase 5 proposes, doesn't apply). This is a feature, not a limitation.
- The description is "deliberately pushy" (the creator's words) — watch for overtriggering once installed; the description lists enough trigger phrases that it will activate broadly. This is correct behaviour for a maintenance skill.
- `jq` is a dependency of `mine-conversations.sh`. The SKILL.md should note this prerequisite in Phase 2 or in a prerequisites section.
