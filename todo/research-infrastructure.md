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

## Codebase evidence

Research base: 7b729b5f5d3e3355c8b7b4825b43c4b0b08c8d0c
Provider: native
Depth: surface

### Existing behaviour

- `brief` (Step 4): already reads `evidence.md` if present, marked "supporting only"; no change needed when evidence arrives (plugins/spwf/skills/brief/SKILL.md:128, 155-157)
- Golden-path skills reading openspec/changes/{id}/ artifacts: brief, approve-plan, write-tests, simplify Pass 2, recap, understand, retrospective Part 2
- Task artifacts flow: ideation (todo/) → spec (proposes) → brief/approve-plan (review) → build (implement) → close/retrospective (validate)

### Important components

- `plugins/spwf/skills/brief/SKILL.md:128` — evidence.md insertion already designed into Step 4 read sequence
- `plugins/spwf/skills/approve-plan/SKILL.md:35-36` — Step 2 reads proposal.md + tasks.md (candidate point for evidence of feasibility/risk)
- `plugins/spwf/skills/write-tests/SKILL.md:16-18` — Step 1 reads tasks.md + specs (candidate: evidence of existing tests, patterns, components)
- `plugins/spwf/skills/simplify/SKILL.md:180-182` — Pass 2 references proposal/tasks/design for reviewer subagent baseline

### Consumers / blast radius

- `approve-plan` assesses plan quality across five dimensions (atomicity, testability, clarity) + three adversarial lenses; evidence would strengthen feasibility + architect + security lenses (skills/approve-plan/SKILL.md:47-99)
- `write-tests` determines test coverage and edge cases; evidence supplies existing tests, prior patterns, important components to reuse (skills/write-tests/SKILL.md:32-51)
- `address-review` evaluates fixes against design decisions in openspec/changes/*/design.md; evidence directly cited (skills/address-review/SKILL.md:29, 136)
- `pr-review` makes code-quality claims from diff only; evidence could anchor those to codebase precedent and load-bearing boundaries (skills/pr-review/SKILL.md:72-99)

### Uncertainty

- Changes 2-4 will define when each skill actually reads evidence; this evidence maps potential points only
- Brief's "supporting only" stance means evidence doesn't block downstream (confirmed by comment at 155-157), but whether other skills treat it the same way depends on changes 2-4
- Skills like challenge/enrich/capture are explicitly out-of-scope per change 1's rough scope (todo/research-infrastructure.md:93, 95)
- No golden-path skill currently makes code claims and then verifies them against codebase within the same skill (evidence will address this pattern in changes 2+)

### Research trace

- Orient: which golden-path skills read openspec/changes/ artifacts and where; which make code claims without codebase grounding; any conflicts
- Searches: grep for "openspec/changes\|evidence.md\|proposal.md\|design.md\|tasks.md" across all 16 golden-path SKILL.md files
- Deterministic checks: read Step/Phase definitions in brief, approve-plan, write-tests, simplify, recap, understand, retrospective, close
- Verified source: plugins/spwf/skills/{brief,approve-plan,write-tests,simplify,recap,understand,retrospective,close}/SKILL.md; todo/research-infrastructure.md; openspec/changes/add-research-infrastructure/tasks.md
