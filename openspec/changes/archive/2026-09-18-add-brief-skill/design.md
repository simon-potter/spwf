# Design: `add-brief-skill`

Decisions and rejected alternatives. Sourced from
[`todo/teach-early-brief.md`](../../../todo/teach-early-brief.md) and its
`/spwf:challenge` pass (2026-07-29).

---

## Decision 1 — Its own golden-path step, between `spec` and `approve-plan`

**Chosen:** a new step. `spec` → `brief` → `approve-plan` → `build`.

**Rejected: the final step of `approve-plan`** (the original draft). Found by
inspection during challenge: approve-plan's steps run *present for sign-off →
stop and wait for the human decision → commit on approval*. A "final step" fires
after approval, which guts the error-catch — section 3 exists to surface
decisions the developer never made, and printing them once they have said yes
wastes the cheapest moment to object.

**Rejected: inside `approve-plan`, before its sign-off gate.** Better than the
above, and it would inform the gate. Rejected because it makes approve-plan's
already-long output longer before the decision point, and because *learn what it
is → review it → approve it* is a cleaner order than interleaving teaching into a
review.

**Consequence:** `approve-plan` is not modified by this change at all.

## Decision 2 — `spec` points at `brief`; it does not invoke it

**Chosen:** `spec`'s terminal output names `brief` as the next step, replacing the
current pointer to `approve-plan`. `brief` in turn points at `approve-plan`.

The codebase has both patterns and they split on skill type. `retrospective`
**invokes** `understand`, because it is an orchestrator that runs parts.
`pr-create` **points at** `close` and states flatly *"Do not invoke
`/spwf:close` automatically"*. `spec` is an artefact producer, not an
orchestrator, so it points.

**Rejected: `spec` invokes `brief`.** Guarantees teaching happens, but makes
`spec` do two jobs, and would fire a briefing on every `spec` run — including
runs where the developer is iterating on artefacts, which is when a briefing is
least wanted.

**Risk accepted, not resolved.** See Residual risks — this is the design's
weakest point.

## Decision 3 — "Choices you didn't make" derives from the todo → plan delta

**Chosen:** what the developer asked for is the ideation file; what got planned is
`proposal.md` + `tasks.md` + `design.md`. Anything in the plan with no antecedent
in the ideation file is, by construction, a decision something else made.

**Rejected: read `design.md`.** Two defects. `spec` creates it only when the
ideation file carried technical decisions, so it is frequently absent — and it
records only decisions someone thought worth writing down. The decisions that
never got written down are precisely the dangerous ones, and a `design.md`-sourced
section is structurally blind to them.

**Rejected: fall back to `tasks.md` when `design.md` is absent.** Inherits the
same blind spot.

Two constraints on the delta, both surfaced by the premortem and both
load-bearing:

1. **Consequence filter.** A spec is *always* more detailed than the ideation file
   — that is what `spec` does — so a literal delta is most of the plan. A decision
   qualifies only if choosing differently would change the **shape** of the
   result: an approach, a dependency, a boundary, an ordering that constrains
   later work. Naming and mechanical task decomposition do not qualify. Without
   this filter, section 3 lists forty banal items and buries the two that matter.
2. **`enrich` output counts as "what you asked for".** If the change went through
   `/spwf:enrich`, the ideation file already carries `## Directions considered`,
   `## Recommended direction` and `## Not doing` — decisions the developer *did*
   make. The delta's left-hand side is the whole ideation file, those sections
   included. Re-surfacing them as unasked-for would be both wrong and insulting.

## Decision 4 — `spec` records the change type explicitly

**Chosen:** `spec`'s `proposal.md` template gains `**Type**: bug | change`, and
`brief` reads it.

The ideation file decided features-only (no bug path), but **nothing implemented
that** — neither `spec` nor `approve-plan` references `BUG-` anywhere, and bug
changes go through `spec` exactly like features.

**Rejected: match the `BUG-` prefix from `proposal.md`'s Source line.** Works
today with zero changes elsewhere, but keys behaviour to a filename convention —
the same class of fragility that produced the `changelog` "Part 5" bug in this
codebase — and it fails *silently*: a renamed todo file yields a briefing nobody
wanted, with no signal.

**Rejected: run on bugs too, letting the escape hatch handle thinness.** Reverses
a decision already made deliberately.

**Migration:** changes spec'd before this ships have no `Type` line. Absent →
treat as a change and run. A briefing on an old bug change is mildly off-target,
not harmful; the alternative is a skill that silently does nothing on every
pre-existing change.

## Decision 5 — On a mismatch, name the remedy; do not act

**Chosen:** the single prompt ("anything here not what you expected?") is an
invitation. On a "yes", `brief` classifies the mismatch and points at the remedy:

| Mismatch | Remedy |
|---|---|
| A task looks wrong | Raise it at `approve-plan` — next command, and it can revise tasks |
| The plan is wrong | Re-run `/spwf:spec`, or edit the artefacts directly |
| The idea is wrong | Back to `/spwf:challenge` |

**Rejected: offer to re-run `spec` or reopen `challenge`.** Most helpful in the
moment, and the point at which a teaching step becomes a control-flow step — which
is where the "never blocking" requirement quietly dies.

**Rejected: record the objection and move on.** Loses nothing, routes nothing.

## Decision 6 — The `recap` merge is deferred

Adding `brief` means three skills that explain: `brief` (pre-build, printed),
`recap` (close Part 5, printed), `understand` (close Part 6, taught). `recap`'s
what-and-why becomes largely a repeat of `brief`'s a few hours later.

**Chosen:** ship `brief`, live with the redundancy, decide later. Merging `recap`
into `understand` removes a shipped slash command — a breaking change — and this
change has already grown a golden-path step and an edit to `spec`. Bundling a
deprecation makes the diff harder to review and the rollback coarser.

**Revisit trigger, recorded rather than left as a feeling:** after `brief` has run
on a handful of real changes, ask *"did you read `recap` at close, or skip it
because `brief` already told you?"*

## Decision 7 — Teaching is primary; error-catching is a side effect

**Chosen:** success is "you could explain the plan to someone else". Section 3's
error-catching is valuable but subordinate.

This governs what gets cut when a brief runs long, and what counts as a
successful run. Making error-catching primary would score most successful runs as
failures, since on the overwhelming majority of changes the plan is right and
there is nothing to catch.

**Corollary that inverts the obvious reading:** section 3 is the natural thing to
trim under teaching-primary, and it must not be — it is the section with no
substitute anywhere else in the workflow. Cut depth from sections 1, 2 and 4
first.

---

## Reversal triggers

Two decisions were taken knowing they might be wrong. Both carry a specific
signal that should reverse them, recorded so the reversal is a decision rather
than a rediscovery.

**Bugs are out of scope (Decision 4).** Bug fixes are where an agent's
unasked-for choices bite hardest — a "quick fix" that quietly changes a shared
helper is the classic case, and section 3 is exactly what would catch it.
Excluding them keeps `brief` focused and avoids near-empty output on two-line
fixes, which is a fair trade for v1. **Trigger: if a bug fix ships a surprise
that section 3 would have surfaced, bring the bug path in** — do not respond by
adding a checklist somewhere else.

**The prompt is unconditional (Decision 5).** A prompt answered with enter every
single time trains the reflex and stops being a moment of attention. **Trigger:
if it becomes automatic in practice, make it conditional on section 3 being
non-empty** — rejected during challenge for unpredictability, but the right
fallback — rather than making the prompt heavier or more insistent.

## Testability

**Same unfalsifiable problem as `add-understand-skill`, and the task list reflects
it.** There is no assertion that proves a briefing taught anything. Three
substitute layers:

1. **Structural assertions** (greppable, and what most tasks assert): frontmatter,
   the five sections present, the non-blocking guarantee stated, the consequence
   filter documented, `spec`'s two edits.
2. **`workflow-lint`** — step↔skill coverage, successor handoff (which now has a
   three-link chain to verify: `spec` → `brief` → `approve-plan`), orphaned
   skills, diagram↔table consistency.
3. **Dogfooding** — running `brief` against a real change. The only check on
   whether it teaches, and it is subjective.

Dogfood runs **before** docs and release, as it did for `add-understand-skill` —
where that ordering caught a fundamental failure before the version bump. Do not
reorder it.

## Residual risks

| Risk | Confidence | Note |
|---|---|---|
| **Nobody runs it** | High | Decision 2 made `brief` opt-in by pointer. The red-team hit lands: this exists *because* teaching at the end was too late, and now teaching early is skippable too. The defence — that `approve-plan` has the same exposure — does not hold, because `approve-plan` is a gate people want and `brief` is homework. **Trigger: if skipped on more than half of the first ten changes, switch `spec` to invoking it.** Not a reminder somewhere. |
| **The consequence filter is a judgement call** | High | "Would choosing differently change the shape of the result" has no mechanical test. Too loose and section 3 is noise; too tight and it is empty. Only real usage calibrates it, and the first version will probably err in one direction. |
| **The `Type` line drifts** | Medium | A prose claim in a template with no validator — the `changelog` "Part 5" class exactly. `workflow-lint` checks names and references, not template fields. Mitigated by absent-Type being handled; not solved. |
| **Not conventionally testable** | High | See Testability. Structural checks plus dogfooding; no behavioural assertion exists. |
| **Redundancy with `approve-plan`** | Low | The two now run back to back over the same plan. Different content — `brief` explains substance, `approve-plan` reviews quality — but the adjacency makes overlap more visible than the original design would have. Watch for it reading as one long ceremony. |
