# Phase release contract

Governs the `adaptive-research-lean-execution` rollout — five separate OpenSpec
changes sharing one architectural design. Written during
`/spwf:challenge` on [`todo/chunkhound_simplify_upgrade.md`](../todo/chunkhound_simplify_upgrade.md),
2026-09-19, before any phase was spec'd.

This lives in `docs/` rather than a change's `design.md` because it applies
across all five changes, and no single one owns it.

## The contract

A phase may ship only when:

1. It is independently useful.
2. It does not depend on an unshipped later phase.
3. Existing artefacts without its new fields remain valid.
4. Its commit range can be cleanly reverted.
5. The prior phase still works after that revert.
6. Its version bump identifies exactly when the behavioural change entered SPWF.
7. **It states a falsifiable keep/revert trigger, in advance.**
8. **It modifies only files it introduces, or files no earlier live phase depends
   on.** Shared modules are append-only once their phase has shipped.

Condition 7 exists because the rollback mechanism is *phase revert*, not a
runtime flag — see "Why no kill switch" below. A revert decision made on
impression is not a decision; it is a rationalisation. The trigger is written
before the phase ships so it cannot be adjusted to fit the outcome.

### Why condition 8

Conditions 4 and 5 promise a clean revert, but nothing enforced it. Phase 3
(`build`, `write-tests`, `debug-recovery`) and Phase 4 (`simplify`, `reviewer`,
`pr-review`, `address-review`) both consume `lean-agent-discipline.md` and
`model-policy.md` from Phase 1. Had Phase 4 rewritten a rule those files already
carried, reverting Phase 3 alone would have conflicted — the guarantee failing at
exactly the moment it was needed, while still appearing satisfied on paper.

Append-only makes it structural: if Phase 4 needs a new rule in a shared module it
**adds a section** rather than editing an existing one. Reverting Phase 4 removes
that section and leaves Phase 3's rules untouched.

## Enforcement

A trigger nobody evaluates is decoration. `brief` shipped with a good trigger —
*"if skipped on more than half of the first ten changes, switch `spec` to invoking
it"* — and it has never been checked. Nothing prevents that repeating.

**Rule: Phase N+1 may not be spec'd until Phase N's trigger has been evaluated and
the result written down.**

Self-enforcing, because the wish to build the next phase is the forcing function.
It needs no tooling and composes with condition 6: version bumps mark when each
phase entered, so "how many changes since Phase 2 shipped" is computable from git
rather than remembered.

**Outcomes are keep / revert / amend** — not keep or revert. A phase is more often
70% right than wholly wrong, and a binary choice makes "keep" win dishonestly,
because reverting good work to shed one bad part is obviously wrong. `amend`
requires writing down what was cut and why.

Without the third outcome, expect every trigger to resolve as "keep, with
reservations" — which is how the evidence-nobody-reads failure actually happens.
Not through dishonesty, but because the available answers do not fit the
situation.

## Why no kill switch

The alternative was `.spwf/research.yaml: evidence: false`, in the style of
`branch.yaml: enforce: false` and `tracker.yaml: tracker: none`. Rejected: those
switches guard *genuinely optional capabilities*. A flag around the core workflow
would make nine skills permanently carry both an old and a new algorithm, so the
upgrade itself becomes a lasting source of complexity.

**Optional switches stay for optional things** (`tracker: none`,
`provider: native | chunkhound`, `enforce: false`) — not for the core workflow.

Backward compatibility is handled instead by a rule that costs nothing extra:

> **Evidence is optional input.** Evidence present → incorporate it. Evidence
> absent → continue from the existing artefacts.

Old changes have no `evidence.md`, and native or low-value research may
legitimately produce little. Handling absence is required regardless, and is not
the same thing as maintaining a second implementation path.

## What is measured, and what is not

Seven of the ten metrics originally proposed (§64) cannot be captured. Main-session
context usage, subagent tokens, files read by the main agent and narrative volume
live inside a Claude Code session and are gone when it ends. Cost and latency are
the same class. Collecting them needs a telemetry pipeline larger than this
upgrade.

**Kept — derivable from committed artefacts:**

| Metric | Source |
|---|---|
| Depth escalations | `## Research trace` in `evidence.md` |
| Diff size before / after `simplify` | `git diff --shortstat` across the pinned range |
| Scope-drift events | recorded by the scope-drift guard |
| Review findings, rework after review | review reports; `fix(review):` commits |

**Dropped:** context usage, subagent tokens, files read, narrative volume, cost,
latency. Do not claim to measure these.

### A worked caution

On `add-brief-skill`, `simplify` removed a net 4 lines from a 3,824-line diff —
about 0.1%. Read alone that says the pass failed. In fact 74% of the diff was a
planning document `simplify` correctly left alone. **The free metrics are cheap and
durable; they are not a verdict.** Always read them against what the change
actually contained.

## Known weaknesses of this approach

Recorded so they can be recognised rather than rediscovered. If the rollout goes
wrong, start here.

1. **The trigger numbers are guesses.** "After 5 real changes" was chosen for
   plausibility, not from evidence. A phase whose benefit only appears at change
   15 will be reverted at 5, and the revert will look justified.
2. **Revert is binary; reality usually is not.** A phase is more often 70% right
   than wholly wrong. The contract offers keep or revert and no vocabulary for
   "keep, but cut the part that became ceremony". Expect to need that third option.
3. **This repo is a weak measurement sample.** SPWF is mostly Markdown, solo, and
   self-designed. Metrics premised on code volume — especially `simplify`'s removal
   rate — may never produce a clean signal here, however well they would work on
   the large Python/Nuxt codebases this upgrade targets.
4. **Nothing collects the metrics automatically.** Even the free ones need someone
   to run the commands at each boundary and write the number down. If that slips,
   every trigger silently becomes unfalsifiable while still appearing rigorous.
5. ~~**Phase 1's trigger has no artefact to check.**~~ **Resolved during challenge.**
   Phase 1 originally produced nothing durable — `research-dispatch`, `model-policy`,
   `lean-agent-discipline`, `research-scout` and `config-check` all act within a
   session and leave nothing behind, so "did the scout save context?" was a
   judgement call. Fixed by extending §23's return contract: **the scout's compact
   result is written into the ideation file**, not only returned in-session. Phase 1
   is now evaluable on its own terms, and the evidence habit Phase 2 formalises
   starts one phase earlier. Left visible here because a phase that produces no
   durable artefact cannot be measured — worth checking against any phase added
   later.
6. **Self-assessment bias.** Whoever did the work evaluates its trigger. Prefer a
   number that can be computed over an impression that can be argued.
7. **"Use it on real work between phases" assumes real work exists.** If the only
   work available is SPWF itself, the sample is unrepresentative in every dimension
   that matters.

## Per-phase triggers

Stated in advance, per condition 7. Revise as phases are spec'd — the numbers are
guesses (weakness 1), not evidence.

| Phase | Trigger |
|---|---|
| 1 — infrastructure | After 3 real changes, if no scout result written into an ideation file contained a fact that shaped the change, revert. A scout whose output never reaches an artefact is indistinguishable from a scout nobody ran. |
| 2 — pre-build intelligence | After 5 real changes, if `evidence.md` has not once contained a fact that changed a spec decision, revert. Evidence nobody acts on is ceremony. |
| 3 — lean build | After 5 real changes, if `simplify`'s removal rate on *code* files has not dropped against the Phase 2 baseline, revert. The ladder and stop conditions exist to prevent excess up front; if `simplify` still removes as much, prevention did not work. |
| 4 — simplify / review | After 3 real changes, if findings-per-change has not fallen, or the same finding categories keep recurring, revert. Better methodology should change what gets found. |
| 5 — ChunkHound provider | Trigger to be set when spec'd. Ships after Phase 2 so there is a native baseline to compare against. |

Phase 3's is the strongest: computable from git alone, with a real before-and-after
number rather than an impression.

## Premortem — failure modes to watch for

From the adversarial pass during challenge. Each is grounded in something that
actually happened, not a hypothetical.

| # | Failure | Grounded in |
|---|---|---|
| 1 | **Evidence nobody reads.** `evidence.md` written faithfully for twenty changes, influencing no decision — and never reverted, because the trigger check is never run | `brief` shipped with the trigger "if skipped on more than half of the first ten changes, switch `spec` to invoking it". That check has never been run |
| 2 | **Phase revert proves impossible** because phases share files | Addressed by condition 8 |
| 3 | **The scout is slower than reading the files.** Dispatch, prompt and compression cost more than three direct reads, and flatten nuance | The one subagent dispatch during this challenge took 165s, 67,669 tokens and 22 tool calls to return a single finding — one wrong word in a README row |
| 4 | **`config-check` becomes a nag** — eleven recommendations on first run, ignored thereafter | §16–19 define four recommendation heuristics before anyone has run it once |
| 5 | **Model aliases drift**, and Haiku scouts silently degrade | §24 replaces pinned models with aliases |

Failure 1 is the one to design against hardest, because nothing about it feels
like failure while it is happening.

Failure 3 sets a bar worth stating plainly: **a scout must beat reading the files
directly, or it is overhead with extra steps.** Dispatch when the work is broad or
repetitive, not when three targeted reads would do.

## Status

No phase spec'd yet. This document precedes implementation and should be revised
as phases ship.
