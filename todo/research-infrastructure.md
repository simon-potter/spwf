---
source: scratch
created: 2026-09-20
status: ideation
---

# research-infrastructure — the seam, the schema, and the scout

> **Change 1 of 5** in the `adaptive-research-lean-execution` initiative.
> Parent design: [`todo/chunkhound_simplify_upgrade.md`](chunkhound_simplify_upgrade.md).
> Release rules: [`docs/phase-release-contract.md`](../docs/phase-release-contract.md).
>
> The parent has been challenged; decisions binding on this change are in its
> §67. This file carries only what is specific to change 1.

## Context

SPWF has no abstraction for codebase research. Skills that need to understand
existing behaviour do it ad hoc — grep, read, follow references — directly in the
main session, where every file read consumes the scarcest resource there is.

This change builds the seam, the evidence format, and the scout that uses them.
It deliberately changes **no workflow behaviour**: `challenge`, `spec`,
`approve-plan`, `build` and the rest are untouched. Their upgrade is change 2
onward.

That constraint is what makes this shippable on its own. It can be installed,
exercised and judged without altering a single golden-path step.

## What we know

**Four shared modules, one reference** (parent §67 decision 3):

```text
_shared/
  research-dispatch.md      orient · find · history · coverage · verify
  evidence-schema.md
  lean-agent-discipline.md
  model-policy.md

references/
  chunkhound-setup.md       loaded by config-check or on request only
```

**`research-dispatch` is native-only in this change.** It mirrors
`tracker-dispatch.md` and `forge-dispatch.md` in shape: skills request a logical
operation, the dispatcher knows which backend serves it. The native backend is
LSP → `rg` → Read → git. No ChunkHound provider ships here — that is change 5.

**The deletion test governs the design** (parent §67 decision 2): if the
ChunkHound provider were deleted tomorrow, this architecture must still make sense
and still be an upgrade.

**`evidence-schema.md` carries the staleness rule** (parent §67 decision 14).
Entries under `### Important components` and `### Consumers / blast radius` are
compared against `Research base`; those whose files have changed are marked stale
and re-verified against source before use. Unchanged entries stand. Per-entry, not
all-or-nothing — wholesale invalidation would push people to skip evidence
gathering entirely. Nothing consumes evidence in this change; the rule ships here
so every later consumer inherits it.

**`research-scout` writes its result into the ideation file** (parent §67
decision 13). Not merely returned in-session. Without a durable artefact this
change leaves nothing behind and its trigger becomes a judgement call, which
condition 7 exists to eliminate.

**A scout must beat reading the files directly.** During challenge, one subagent
dispatch cost 165s, 67,669 tokens and 22 tool calls to return a single finding.
Dispatch when work is broad or repetitive; not when three targeted reads would do.
This belongs in `lean-agent-discipline.md` as a stated bar, not a vibe.

**`config-check` is broad capability health** (parent §67 decision 4) — tracker,
research backend, LSP, model assignments, forge. Its ChunkHound recommendation
heuristic (parent §16) ships with change 5, or this change contains a skill
recommending something that does not exist.

## Rough scope

**In scope**

- **NEW** `_shared/research-dispatch.md` — capability contract, native backend, `.spwf/research.yaml` schema (`provider`, `depth`, `fallback`)
- **NEW** `_shared/evidence-schema.md` — canonical structure + the staleness rule
- **NEW** `_shared/lean-agent-discipline.md` — interaction rules, compact return contracts, the beats-direct-reads bar
- **NEW** `_shared/model-policy.md` — cheap models for evidence gathering, Sonnet-class for synthesis and consequential review
- **NEW** `references/chunkhound-setup.md` — reference only, never in normal workflow context
- **NEW** `plugins/spwf-agents/agents/research-scout.md` — with a return contract that writes into the ideation file
- **NEW** `plugins/spwf/skills/config-check/SKILL.md` — capability health, no ChunkHound heuristic
- **MODIFIED** agent model pins → aliases (parent §24)
- **VERSION BUMP** minor — new skill + new agent

**Out of scope**

- Any change to `challenge`, `spec`, `approve-plan`, `build`, `write-tests`, `debug-recovery`, `simplify`, `reviewer`, `pr-review`, `address-review` — changes 2-4
- The ChunkHound provider and its `config-check` heuristic — change 5
- `capture` bug path and `enrich` — not doing (parent §67 Not doing)

## Keep / revert trigger

Stated in advance per condition 7. Evaluated before change 2 may be spec'd.

> After 3 real changes, if no scout result written into an ideation file contained
> a fact that shaped the change, **revert**. A scout whose output never reaches an
> artefact is indistinguishable from a scout nobody ran.

Outcomes are keep / revert / **amend**; amend requires writing down what was cut.

## Residual risks

Inherited from the parent §68, narrowed to this change:

| Risk | Confidence | Note |
|---|---|---|
| A scout may not beat reading files directly | Medium | The 165s / 67k-token dispatch during challenge. If this holds generally, the scout is overhead and the trigger should fire |
| `config-check` becomes a nag | Low-Medium | Recommendation heuristics defined before anyone has run it once |
| Model aliases drift | Low | Aliases could later point at models that behave differently, degrading scouts silently |
| Trigger number is a guess | High | "3 real changes" was chosen for plausibility, not evidence |
