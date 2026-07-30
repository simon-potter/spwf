# Proposal: Add `/spwf:brief` — teach before the build, not only after

**Change ID**: `add-brief-skill`
**Status**: Draft
**Created**: 2026-07-30
**Source**: [todo/teach-early-brief.md](../../../todo/teach-early-brief.md)

---

## Why

`add-understand-skill` put teaching at the *end* of the golden path
(Retrospective Part 6). That leaves the whole build unteaching: the agent writes
code for hours and the developer's first explanation arrives after it has all
shipped.

Two costs. **Comprehension debt starts accruing at build time, not at close** —
teaching at the end treats a debt already incurred. And **there is no agency**:
at close you are learning about something finished, whereas before the build you
can still say "that's not what I meant", and a mismatch caught there costs a
conversation instead of a change.

The comprehension-debt literature prescribes exactly this: *"be ruthlessly
explicit about what a change is supposed to do before it's written."* Nothing in
the workflow currently does that in plain language.

## What Changes

- **NEW** `plugins/spwf/skills/brief/SKILL.md` — a new golden-path step between
  `spec` and `approve-plan`. Explains what will be built and why across five
  sections (expand, then summarise), ending in one skippable prompt. Never
  blocks. Reuses `_shared/learner-profile.md` for level calibration.
- **MODIFIED** `plugins/spwf/skills/spec/SKILL.md` — two edits:
  (1) the `proposal.md` template gains a `**Type**: bug | change` line so `brief`
  can tell features from bugs; (2) the terminal next-step pointer moves from
  `approve-plan` to `brief`.
- **MODIFIED** `README.md`, `plugins/spwf/README.md` — golden path table and
  workflow diagram gain a step; skill tables gain a row.
- **MODIFIED** `plugins/spwf/.claude-plugin/plugin.json` — 1.20.0 → 1.21.0.

**Explicitly not changed:** `approve-plan`. An earlier draft made `brief` its
final step; that was rejected during challenge because approve-plan runs
*present → stop and wait → commit*, so a "final step" fires after approval and
wastes the cheapest moment to object.

## Impact

- **Affected areas**: `plugins/spwf/skills/` (one new skill, one modified skill),
  both READMEs, plugin manifest.
- **No breaking changes.** Additive. `spec`'s new `Type` line is a template
  addition; changes spec'd before it exists are handled by treating an absent
  `Type` as a change.
- **Golden path grows by one step** — the first structural change to the path
  since branch enforcement.
- **No new agents, dependencies, or shared modules.** Reuses the
  `learner-profile` convention shipped with `add-understand-skill`.

---

## Decisions

All questions from the ideation file are resolved; none carried as TBD. The seven
decisions that shaped the design, and the alternatives rejected, are in
`design.md`. Five residual risks are carried forward rather than solved — see
`design.md` § Residual risks. The load-bearing one:

**`brief` is opt-in by pointer, not invoked.** This skill exists because teaching
at the end was too late, and it is now skippable too. The trigger is recorded: if
it is skipped on more than half of the first ten changes, switch `spec` to
invoking it rather than adding a reminder somewhere.

**Dependency on `add-understand-skill`.** That change is merged and released
(1.20.0) but **not yet archived**, so the `comprehension` capability it declares
is not in `openspec/specs/` yet. This change adds requirements to the same
capability, so the two must be archived in order.

## Success Criteria

1. **Teaching is primary: the developer could explain the plan to someone else
   after reading the brief.** Error-catching via "choices you didn't make" is a
   valuable side effect, not the criterion — on most changes the plan is right
   and there is nothing to catch.
2. `brief` runs standalone and as the step after `spec`, explains across five
   sections, and never blocks.
3. "Choices you didn't make" surfaces consequential decisions only — an approach,
   dependency, boundary or constraining ordering — not naming or mechanical task
   decomposition.
4. `enrich` output in the ideation file is treated as "what you asked for", never
   re-surfaced as an unasked-for choice.
5. On a mismatch, `brief` names the remedy and does not act.
6. Bugs are skipped; an absent `Type` line is treated as a change.
7. `openspec validate --strict` and `workflow-lint` both pass; `brief` appears in
   the golden path and is not flagged as orphaned.
