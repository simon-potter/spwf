# Proposal: Research infrastructure — the seam, the schema, and the scout

**Change ID**: `add-research-infrastructure`
**Status**: Draft
**Type**: change
**Created**: 2026-09-20
**Source**: [todo/research-infrastructure.md](../../../todo/research-infrastructure.md)

---

## Why

SPWF has no abstraction for codebase research. Skills that need to understand
existing behaviour do it ad hoc — grep, read, follow references — directly in the
main session, where every file read consumes the scarcest resource available.

There is also nowhere to put what research finds. A question answered during
`challenge` is answered again during `build`, because the answer lived only in a
conversation that has since been cleared.

This change builds the seam, the evidence format, and the scout that uses them.
It is change 1 of 5 in the `adaptive-research-lean-execution` initiative
([parent design](../../../todo/chunkhound_simplify_upgrade.md)), and it
deliberately changes **no golden-path behaviour** — that is changes 2-4.

That constraint is what makes it shippable alone: it can be installed, exercised
and judged without altering a single workflow step.

## What Changes

- **NEW** `plugins/spwf/skills/_shared/research-dispatch.md` — five logical
  operations (`orient`, `find`, `history`, `coverage`, `verify`) over a **native
  backend only** (LSP → `rg` → Read → git), plus the `.spwf/research.yaml` schema
  (`provider`, `depth`, `fallback`). Mirrors `tracker-dispatch.md` and
  `forge-dispatch.md` in shape.
- **NEW** `plugins/spwf/skills/_shared/evidence-schema.md` — the canonical evidence
  structure and the **per-entry staleness rule**.
- **NEW** `plugins/spwf/skills/_shared/lean-agent-discipline.md` — interaction
  rules, compact return contracts, and the stated bar that a subagent must beat
  reading the files directly.
- **NEW** `plugins/spwf/skills/_shared/model-policy.md` — cheap models for
  deterministic evidence gathering, Sonnet-class for synthesis and consequential
  review.
- **NEW** `plugins/spwf/references/chunkhound-setup.md` — reference only, loaded by
  `config-check` or on explicit request; never enters normal workflow context.
- **NEW** `plugins/spwf-agents/agents/research-scout.md` — returns compact evidence
  and **writes its result into the ideation file**.
- **NEW** `plugins/spwf/skills/config-check/SKILL.md` — broad project capability
  health (tracker, research backend, LSP, model assignments, forge).
- **MODIFIED** `plugins/spwf-agents/agents/*.md` — model pins become aliases.
- **VERSION BUMP** `spwf` minor (new skill), `spwf-agents` minor (new agent).

**Explicitly not changed:** `challenge`, `spec`, `approve-plan`, `build`,
`write-tests`, `debug-recovery`, `simplify`, `pr-review`, `address-review`. No
ChunkHound provider — that is change 5. No `capture` or `enrich` upgrade — see the
parent's `## Not doing`.

## Impact

- **Affected areas**: one new skill, one new agent, four new shared modules, one
  new reference file, agent model pins.
- **No golden-path behaviour change.** Nothing in the workflow consumes the new
  modules yet; they are infrastructure for changes 2-4.
- **No breaking changes.** `.spwf/research.yaml` is optional with working defaults
  (`provider: auto`, `depth: surface`, `fallback: native`). Absent config behaves
  as native.
- **New capability**: `codebase-research`.
- **Blast radius on revert**: deleting the new files and reverting the model-pin
  change restores current behaviour exactly, because nothing depends on them.

---

## Decisions

All resolved during `/spwf:challenge` on the parent (2026-09-20). None carried as
TBD. The full set is in the parent's §67; the ones binding on this change:

**Native-only dispatch.** No ChunkHound provider ships here. The governing
invariant is the deletion test — *if the ChunkHound provider were deleted
tomorrow, would the architecture still make sense and still be an upgrade?* If
this change cannot answer yes, it is wrong.

**Evidence staleness is per-entry, not all-or-nothing.** Entries are compared
against `Research base`; only those whose files changed are re-verified. Wholesale
invalidation would push people to skip evidence gathering entirely.

**The scout writes into the ideation file.** Without a durable artefact this
change leaves nothing behind and its keep/revert trigger becomes a judgement call
— exactly what release-contract condition 7 exists to eliminate.

**`config-check` ships without the ChunkHound recommendation heuristic**, which
travels with change 5. Otherwise this change contains a skill recommending
something that does not exist.

## Success Criteria

1. The four shared modules and `references/chunkhound-setup.md` exist, and no
   golden-path skill references them yet.
2. `research-dispatch` defines all five operations against the native backend, and
   `.spwf/research.yaml` is optional with working defaults — **proven by exercising
   the absent-config path, not by documenting the defaults**.
3. `evidence-schema.md` states the per-entry staleness rule.
4. Credential-shaped values are redacted before reaching persisted evidence, an
   ideation file, or any other committed artefact.
5. `research-scout` has a return contract that writes a compact result into the
   ideation file.
6. `lean-agent-discipline.md` states the bar that a subagent must beat reading the
   files directly.
7. `config-check` reports capability health and makes no ChunkHound
   recommendation.
8. Reverting this change's commit range restores current behaviour with no
   migration or cleanup.
9. `openspec validate --strict` and `workflow-lint` both pass.

## Keep / revert trigger

Stated in advance per release-contract condition 7. Must be evaluated and written
down before change 2 (`pre-build-intelligence`) may be spec'd.

> After 3 real changes, if no scout result written into an ideation file contained
> a fact that shaped the change, **revert**. A scout whose output never reaches an
> artefact is indistinguishable from a scout nobody ran.

Outcomes are keep / revert / **amend**; amend requires recording what was cut.
