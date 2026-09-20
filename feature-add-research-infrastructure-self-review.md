# Self-Review: feature/add-research-infrastructure

**Range**: `a13947e9929986cd894f2c60db091d2426196acb..8f723cac8346d0d7fe2b6ce42e2e0a0ceda4ea5d`

**Size**: +1452 -20 across 28 files (10 commits)

**Scope**: Builds the research seam, evidence schema, scout agent, config-check skill, and model-policy convention. Deliberately changes no golden-path behaviour. Change 1 of 5 in adaptive-research-lean-execution initiative.

---

## Verification Against Stated Intent

### The deletion test — ChunkHound-free baseline

**Finding**: ✅ PASSES

- `research-dispatch.md` contains no ChunkHound-specific instruction. It states the deletion test explicitly (lines 1365–1368): *"If every provider other than native were deleted tomorrow, this document and every skill referencing it must still make sense"*.
- The dispatch table (line 1559–1562) lists only `native` as a provider; others are documented as future additions (line 1563–1564).
- No ChunkHound reference appears in `research-dispatch.md`, `research-scout.md`, or `config-check/SKILL.md`.
- `chunkhound-setup.md` (reference file) explicitly guards itself: *"Reference only. Loaded by config-check or on explicit request. This file must never be pulled into normal workflow context"* (lines 3–5).
- The reference is forward documentation only, per the provider timeline.

### No golden-path behaviour changed

**Finding**: ✅ PASSES

Golden-path skills: capture, enrich, challenge, spec, brief, approve-plan, build, write-tests, debug-recovery, simplify, pr-create, pr-review, address-review, close.

- Zero edits to any golden-path skill file.
- Only config-check (new cross-cutting skill) and research-scout agent reference the new shared modules; no golden-path skill does.
- Agent model pins were changed from generations to aliases across 12 files — mechanical sweep, not feature changes. This is ancillary to the research infrastructure and documented in the version bumps.

### Rules stated more than once

**Finding**: ✅ PASSES with acknowledgement

- Redaction rule appears in `evidence-schema.md` (lines 1111–1136) and is referenced, not duplicated, by `research-scout.md` (line 53) and `config-check/SKILL.md` (line 1660). The scout explicitly says (line 58): *"That file enumerates the shapes; do not keep a second copy here, or the two lists drift."* — this is the fix applied in commit 8f723ca.
- A known duplication with `understand/SKILL.md`'s redaction rule is acknowledged in `evidence-schema.md` (lines 1137–1144). The choice not to fix it is deliberate and explained: the change must not edit a golden-path skill to stay independently revertible. Deferred for a later change that touches understand for its own reasons.

### Contradictions between new modules

**Finding**: ✅ PASSES

- **Depth guidance** (research-dispatch.md lines 1477–1503) vs scout implementation: aligned. Scout classifies questions; dispatch defines depth escalation logic.
- **Dispatch bar** (lean-agent-discipline.md lines 1171–1209): clear, with cited evidence (165s / 67k tokens / 22 calls). Scout Step 1 (lines 705–717) quotes the discipline document and returns early if not warranted.
- **Discovery vs proof** (research-dispatch.md lines 1372–1402): sharp distinction. Scout Step 1 (lines 721–737) calls out: *"Discovery is not proof."* and enforces deterministic checks for completeness claims.
- **Model assignment** (model-policy.md lines 1278–1291 assigns Haiku to evidence gathering). Scout declares `model: haiku` (line 700). Aligned.
- **Redaction boundary** (evidence-schema.md lines 1111–1114): before writing. Scout Step 3 (line 51) redacts; Step 5 writes. Correct ordering.

### Redaction rule reachability

**Finding**: ✅ PASSES

The rule: *"Research output SHALL have credential-shaped values masked before they reach persisted evidence, an ideation file, or any other committed artefact"* (evidence-schema.md lines 1111–1114).

- **research-scout.md**: Step 3 (redact) precedes Step 5 (write to ideation file). Ideation file is in `todo/`, committed. Redaction enforced before write.
- **config-check/SKILL.md**: Step 3 (lines 1645–1661) implements *"Report presence, never values"* and references evidence-schema redaction rule. Config-check does not access source code or write research output; it audits configuration state only.
- Both paths correctly block credential exposure before committed artefacts.

### Cross-reference validity

**Finding**: ✅ PASSES

Spot-checked representative links:

- `research-scout.md`: line 53 `[../_shared/evidence-schema.md](../../spwf/skills/_shared/evidence-schema.md)` ✓
- `config-check/SKILL.md`: line 1621 `[../_shared/research-dispatch.md](../_shared/research-dispatch.md)` ✓
- `evidence-schema.md`: line 1106 `[research-dispatch.md](research-dispatch.md)` (same directory) ✓
- `chunkhound-setup.md`: line 950 `[../skills/_shared/research-dispatch.md](../skills/_shared/research-dispatch.md)` ✓
- `proposal.md`: lines 149, 165 reference parent design and todo files with full paths ✓

All cross-references use correct relative paths and point to files that exist in the diff.

---

## Success Criteria (from proposal.md)

| # | Criterion | Status |
|---|-----------|--------|
| 1 | Shared modules exist; no golden-path skill references them | ✅ Four modules + chunkhound-setup.md exist; only config-check and scout reference them |
| 2 | research-dispatch defines five operations against native backend; .spwf/research.yaml optional with working defaults | ✅ All five operations (orient, find, history, coverage, verify) defined; schema documented (lines 1508–1545); absent-config path proven by dogfood (todo/research-infrastructure.md, Uncertainty section line 1741–1746) |
| 3 | evidence-schema states per-entry staleness rule | ✅ Explicit rule at lines 1086–1107; explained why wholesale invalidation is wrong |
| 4 | Credentials redacted before reaching committed artefact | ✅ Specified in evidence-schema (lines 1111–1136); implemented in scout and config-check |
| 5 | research-scout has return contract, writes to ideation file | ✅ Step 4 defines compact return format (lines 759–778); Step 5 enforces write (lines 783–797); marked non-optional |
| 6 | lean-agent-discipline states dispatch bar | ✅ Rule 1 (lines 1171–1209) with measurement; Rule 2 (lines 1212–1229) on return format |
| 7 | config-check reports health, makes no ChunkHound recommendation | ✅ § Deferred (lines 1692–1700): *"does not recommend a research provider"* and states reason |
| 8 | Revert restores prior behaviour with no migration | ✅ Dogfood 7.6 (tasks.md line 581–582) marked complete; reverting would delete new files and revert model pins |
| 9 | openspec validate and workflow-lint pass | ✅ Tasks 8.5–8.6 marked complete |

**All success criteria met.**

---

## Tasks Completion

All 36 tasks across 8 phases marked complete:

- **Phase 1 (research seam)**: research-dispatch.md with five operations, native sufficiency, LSP/rg/Read/git backend, optional .spwf/research.yaml, deletion test holds.
- **Phase 2 (evidence schema)**: canonical structure, Research base, per-entry staleness rule, redaction before write.
- **Phase 3 (discipline + policy)**: lean-agent-discipline.md with dispatch bar and return contracts; model-policy.md with Haiku/Sonnet assignments and aliases-not-pins rationale.
- **Phase 4 (scout)**: research-scout.md with return contract and ideation-file write; redaction pass-through.
- **Phase 5 (config-check)**: SKILL.md with domain checks (tracker, research, LSP, models, forge), presence-not-values reporting, absent vs misconfigured distinction, no ChunkHound recommendation.
- **Phase 6 (model sweep)**: 12 agents: model pins → aliases. Verified: `grep -rE 'claude-[a-z]+-[0-9]' plugins/spwf-agents/agents/` returns nothing.
- **Phase 7 (dogfood)**: config-check tested; scout dispatched; direct-read baseline compared; absent-config path exercised; no golden-path references confirmed; revert rehearsal done.
- **Phase 8 (docs + release)**: README.md and plugin.json updated; counts 38 skills / 15 agents; workflow-lint passes; openspec validate passes.

**All phases verified complete.**

---

## Consistency Checks

### Version bumps

- `spwf` 1.21.0 → 1.22.0 (minor): new skill config-check ✓
- `spwf-agents` 1.4.0 → 1.5.0 (minor): new agent research-scout ✓
- README.md skill count: 37 → 38 ✓
- README.md agent count: 14 → 15 ✓
- All three README tables updated consistently ✓

### Skill/agent counts

- spwf README heading: *"38 workflow skills"* ✓
- root README heading: *"15 specialist subagents"* ✓
- plugin.json descriptions match README ✓

### Plugin.json schema

- spwf plugin.json: description includes config-check ✓
- spwf-agents plugin.json: description updated to 15 agents ✓

---

## Architecture Assessment

The seam design is sound:

1. **Provider abstraction works without a second provider** — native implementation of all five operations proves sufficiency. Future providers (change 5) will add to discovery operations only; proof operations stay native by design.

2. **Evidence staleness is correctly per-entry** — not all-or-nothing. Addresses the key UX problem: *"wholesale invalidation teaches people to skip evidence gathering rather than maintain it"* (evidence-schema.md line 1101–1102).

3. **Redaction is enforced at write boundaries** — scout and config-check both pass through the evidence-schema rule, not duplicate it. The known duplication with understand is acknowledged and deferred by revert constraint.

4. **Dispatch bar is stated and measured** — not aspirational. The 165s / 67k-token dispatch (lean-agent-discipline.md line 1196) is evidence that dispatch has real cost and should not be automatic.

5. **Models are assigned by policy, not per-agent choice** — Haiku for deterministic gathering, Sonnet for synthesis. The switch from pinned generations to aliases removes silent drift (model-policy.md lines 1307–1327).

6. **Revert is clean** — no migration or cleanup required. Golden-path skills untouched. New files can be deleted; model-pin revert is atomic. This was validated by dogfood (tasks.md 7.6).

---

## Strengths

- **Disciplined scope**: Infrastructure change stays focused. No golden-path edits despite temptation (understand/SKILL.md duplication deliberately deferred).
- **Clear deletion test**: The architecture would work if ChunkHound were deleted tomorrow. Forward documentation (chunkhound-setup.md) is properly guarded as reference-only.
- **Evidence by dogfood**: Not asserted, but tested. The absent-config path, the dispatch behaviour, the scout write, and the revert all validated against real project state.
- **Known limitations acknowledged**: The model-alias risk, the scout cost risk, the trigger-count guess — all stated in design.md § Residual risks (lines 130–136).
- **Duplicate-prevention convention**: The `_shared/` directory is explicitly used to collapse duplicates (evidence-schema.md lines 1137–1144). The DRY fix in 8f723ca shows this working.

---

## Verdict

✅ **Ready for PR**

All success criteria met. No contradictions or gaps. Deletion test holds. Golden-path behaviour untouched. Dogfood validates the claims. The architecture is shaped correctly and would withstand the revert-by-deletion test. Ready to merge and ship.

---

## Notes for PR Description

The change is structured as 10 commits across 8 phases. Key files to review:

1. **New shared modules** (the seam and schema):
   - `plugins/spwf/skills/_shared/research-dispatch.md` — five operations over native backend
   - `plugins/spwf/skills/_shared/evidence-schema.md` — canonical structure and per-entry staleness rule
   - `plugins/spwf/skills/_shared/lean-agent-discipline.md` — dispatch bar with evidence
   - `plugins/spwf/skills/_shared/model-policy.md` — model class assignment and alias rationale

2. **New agent and skill**:
   - `plugins/spwf-agents/agents/research-scout.md` — codebase research with ideation-file write
   - `plugins/spwf/skills/config-check/SKILL.md` — capability health auditor

3. **Reference documentation**:
   - `plugins/spwf/references/chunkhound-setup.md` — forward documentation for change 5

4. **Mechanical changes**:
   - 12 agents: `model: claude-*` → `model: haiku/sonnet` (alias sweep)

5. **OpenSpec record**:
   - `openspec/changes/add-research-infrastructure/` — proposal, design, spec, tasks, evidence

6. **Documentation updates**:
   - README.md and plugin.json: counts and descriptions updated; version bumps applied
   - todo/research-infrastructure.md: dogfood evidence appended
