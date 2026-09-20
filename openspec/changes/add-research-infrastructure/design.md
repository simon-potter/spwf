# Design: `add-research-infrastructure`

The architectural rationale lives in the parent design,
[`todo/chunkhound_simplify_upgrade.md`](../../../todo/chunkhound_simplify_upgrade.md)
§67, and the rollout rules in
[`docs/phase-release-contract.md`](../../../docs/phase-release-contract.md).
This file records only what is specific to change 1, and points at the parent
rather than restating it.

## Decision 1 — The seam ships with one backend

`research-dispatch.md` defines five operations and implements exactly one
provider: native (LSP → `rg` → Read → git). No ChunkHound.

A seam with a single implementation looks like over-abstraction, and would be, if
the second provider were speculative. It is not — change 5 is planned and its
value is articulated. What this ordering buys is attribution: the native baseline
must exist and be measured before an accelerator is added, or any improvement is
unattributable.

**Rejected:** shipping both together. It would make the deletion test expensive
(deleting the provider would mean editing this change rather than reverting one),
and Phase 1 could not be validated without first deciding whether to pay for
embeddings.

## Decision 2 — Staleness is per-entry

Evidence records `Research base: <SHA>`. A consumer compares cited files against
the current tree; entries under `### Important components` and
`### Consumers / blast radius` whose files changed are marked stale and
re-verified before use. Unchanged entries stand.

**Rejected:** invalidating a whole evidence file when any cited file moves. It is
simpler, and it is worse — a two-week-old file whose cited code has not moved is
still good, and wholesale invalidation teaches people to skip evidence gathering
rather than maintain it.

The rule lives in `evidence-schema.md` rather than in each consumer, so changes
2-4 inherit it instead of reinventing it.

## Decision 3 — The scout writes to the ideation file

`research-scout`'s return contract requires its compact result to be written into
the ideation file, not merely returned in-session.

This is what makes the change measurable. Every other phase has a durable artefact
to check a trigger against — `evidence.md`, git diffs, review reports. Without
this, change 1 produces nothing that outlives a session, and its trigger degrades
to an impression.

It also front-loads the evidence habit that change 2 formalises, on a smaller
surface where getting it wrong is cheap.

## Decision 4 — A subagent must beat reading the files

`lean-agent-discipline.md` states the bar explicitly rather than implying it.

Grounded in measurement, not preference: during the challenge that produced this
change, one subagent dispatch cost **165 seconds, 67,669 tokens and 22 tool calls**
to return a single finding — one wrong word in a README row that a direct read
would have surfaced immediately.

Dispatch when work is broad, repetitive, or would otherwise pour many files into
the main session. Not when three targeted reads would do.

## Testability

This change is skill and documentation artefacts, not executable code. There is no
behavioural assertion to write about a Markdown convention, so "tests" are
**structural assertions** — greppable checks that each artefact declares what the
spec requires — plus `workflow-lint` and a dogfood.

This is the same posture as `add-understand-skill` and `add-brief-skill`, and it
has a known weakness: a structural assertion can verify that
`lean-agent-discipline.md` contains the beats-direct-reads bar, and cannot verify
that any agent honours it. Only the keep/revert trigger tests that, and only after
real use.

## Residual risks

Inherited from the parent §68, narrowed to this change.

| Risk | Confidence | Note |
|---|---|---|
| A scout may not beat reading files directly | Medium | The 165s / 67k-token dispatch above. If that generalises, the scout is overhead and the trigger should fire |
| `config-check` becomes a nag | Low-Medium | Recommendation heuristics were drafted before anyone ran it once |
| Model aliases drift | Low | Aliases could later resolve to models that behave differently, degrading scouts silently |
| The trigger number is a guess | High | "3 real changes" was chosen for plausibility, not evidence |
| The seam stays single-provider | Medium | If change 5 never ships, this is abstraction serving one implementation. The deletion test is the guard: the architecture must stand up without ChunkHound, not merely tolerate its absence |
