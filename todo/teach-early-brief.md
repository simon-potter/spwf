---
source: scratch
created: 2026-07-29
status: ideation
---

# brief — teach before the build, not only after

> Companion proposal to [`Learn-my-code.md`](Learn-my-code.md) (change
> `add-understand-skill`, mid-build). **Sequenced after it, deliberately** — see
> Sequencing.

## The gap

`add-understand-skill` puts teaching at the *end* of the golden path
(Retrospective Part 6). That leaves the whole build unteaching: the agent writes
code for hours and the developer's first explanation arrives after it has all
shipped.

Two costs:

1. **Comprehension debt starts accruing at build time, not at close.** Teaching
   at the end treats a debt that's already been incurred.
2. **No agency.** At close you're learning about something finished. Before the
   build you can still say "that's not what I meant" — and a mismatch caught
   there costs a conversation instead of a change.

The comprehension-debt literature says the same thing prescriptively: *"be
ruthlessly explicit about what a change is supposed to do before it's written."*
Right now nothing in the workflow does that in plain language.

## Placement

**Its own golden-path step, between `spec` and `approve-plan`.** You learn what
it is, then you review it, then you approve it.

```
challenge → spec → [brief] → approve-plan → build → … → close → recap → understand
                      ▲                                                      ▲
              what WILL be built                                 what WAS built,
                 and why                                       and where to look
```

**Why not inside `approve-plan`, as originally drafted.** That skill's steps run:
present for sign-off → *stop and wait for the human decision* → commit. A
briefing as its "final step" would fire after approval, which guts the
error-catch — section 3 exists to surface decisions you never made, and printing
them once you've said yes wastes the cheapest moment to object.

`spec` **points at** `brief` as its next step; `brief` points at `approve-plan`.
Pointing rather than invoking, consistent with `spec` being an artefact producer
rather than an orchestrator — and with `pr-create`, which points at `close` and
explicitly refuses to invoke it. `approve-plan` is **not modified** by this
change. Also runnable standalone.

**Never blocking.** `approve-plan` is already a human gate; a second gate two
lines later is friction that gets routed around. `brief` prints, offers one
skippable prompt, and returns. This belongs in the spec as a requirement, not as
an intention, so nobody later "improves" it into a gate.

## Shape — expand, then summarise

Not the teach → check → deepen cycle. That's right for post-build, where there's
a real artefact to build a mental model of. Pre-build there's nothing to check
comprehension *against* yet — the developer hasn't seen any code. So `brief` is
mostly explanation, with one invitation rather than a check.

### 1. What will be built

Plain language, 3–5 sentences. The substance, **not** the task list —
`approve-plan` just printed that. If the reader can't tell a friend what's about
to happen after reading this, it's failed.

### 2. Why this way

The shaping decisions and their reasons, drawn from `design.md`. Where an
alternative was rejected, name it and why.

### 3. Choices you didn't make ← **the section that earns this skill**

**Derived from the todo → plan delta**, not from `design.md`. What the developer
asked for is the ideation file; what got planned is `proposal.md` + `tasks.md` +
`design.md`. Anything in the plan with no antecedent in the ideation file is, by
construction, a decision something else made.

`design.md` is the wrong primary source for two reasons: `spec` only creates it
when the ideation file carried technical decisions, so it is frequently absent;
and it records only decisions someone thought worth writing down — the ones that
never got written down are precisely the dangerous ones.

**Two constraints on the delta, both load-bearing:**

1. **Filter for consequence.** A spec is *always* more detailed than the ideation
   file — that is what `spec` does — so a literal delta is most of the plan.
   A decision qualifies only if choosing differently would change the **shape**
   of the result: an approach, a dependency, a boundary, an ordering that
   constrains later work. Naming and mechanical task decomposition do not
   qualify. Without this filter section 3 lists forty banal items and buries the
   two that matter.
2. **`enrich` output counts as "what you asked for".** If the change went through
   `/spwf:enrich`, the ideation file already carries `## Directions considered`,
   `## Recommended direction` and `## Not doing` — decisions the developer *did*
   make. The delta's left-hand side is the whole ideation file, those sections
   included. Re-surfacing them as unasked-for would be both wrong and insulting.

**Escape hatch:** on a simple change there may be none. Say so and skip the
section — never invent decisions to fill it.

**Protected by the length cap.** Under teaching-primary (below), section 3 is the
natural thing to trim when a brief runs long. It must not be — it is the section
with no substitute elsewhere in the workflow. Cut depth from 1, 2 and 4 first.

### 4. What this touches

Blast-radius preview from `tasks.md` and the proposal's Impact section, so the
size is visible before it happens rather than after.

### 5. Summary

Two or three lines. The what and the why, crystallised. This is what the
developer carries into the build.

### The one prompt

> "Anything here not what you expected? [enter to continue]"

An invitation, not a check. Answering costs two seconds; ignoring it costs
nothing. It exists so a mismatch has somewhere to surface.

**On a "yes", `brief` names the remedy and does not act.** It classifies roughly
what kind of mismatch it is and points:

| Mismatch | Remedy |
|---|---|
| A task looks wrong | Raise it at `approve-plan` — it's the next command and can revise tasks |
| The plan is wrong | Re-run `/spwf:spec`, or edit the artefacts directly |
| The idea is wrong | Back to `/spwf:challenge` |

Then it returns. It must not re-run anything itself: offering to act turns a
teaching step into a control-flow step, and that is where the "never blocking"
requirement quietly dies.

## Level calibration — a useful knock-on

`brief` reads the same `.spwf/learner.md` as `understand`, via
[`_shared/learner-profile.md`](../plugins/spwf/skills/_shared/learner-profile.md).
Level sets explanation depth, exactly as it does post-build.

Because `brief` runs earlier in the lifecycle, **it becomes the natural home for
the first-run calibration question.** By the time `understand` runs at close, the
profile already exists — so the close-time session never has to interrupt with
setup. Worth building deliberately rather than discovering later.

## Consequence: this squeezes `recap`

Introducing `brief` makes three skills that explain:

| Skill | When | Covers | Mode |
|---|---|---|---|
| `brief` | pre-build | what **will** be built, why | printed |
| `recap` | close, Part 5 | what **was** built, why | printed |
| `understand` | close, Part 6 | consequence, navigation | taught + checked |

`recap` becomes the weakest of the three. Its what-and-why is largely the same
what-and-why `brief` already delivered — read once before the build and again
after it, with the second reading adding little. `understand` meanwhile is now
the only one that teaches.

**This strengthens the merge case that `Learn-my-code.md` Decision 8 rejected and
Decision 9 flagged for revisiting.** Don't act on it yet — decide after
`understand`'s rewrite has been dogfooded, with `brief` in hand as the third data
point. But go in expecting the retrospective to end up with `recap` folded into
`understand`, rather than three explainers.

## Sequencing — build this *after* `add-understand-skill`

Not a scope call; a dependency.

`brief` should reuse the teaching voice, the anti-jargon rules, the level
semantics, and the escape-hatch discipline that `understand`'s rewrite is about
to establish. Building it now would mean **duplicating an unproven pattern into a
second skill** — and the first version of that pattern has already failed one
dogfood. Finish the rewrite, re-dogfood it, then port what demonstrably worked.

Separate OpenSpec change, on the scope-sizing signals: independently deployable
(each works without the other), different phase of the workflow, different
"done" definition.

## Success definition

**Teaching is primary.** Success is *"you could explain the plan to someone
else."* Error-catching via section 3 is a valuable side effect of explaining
clearly, not the criterion.

This matters as a tiebreaker: on the overwhelming majority of changes the plan is
basically right and there is nothing to catch. Making error-catching primary
would score most successful runs as failures for finding nothing.

## Rough scope

| Item | Notes |
|---|---|
| `plugins/spwf/skills/brief/SKILL.md` | The skill. Reuses `_shared/learner-profile.md`. Handles an absent `.spwf/learner.md` by asking the calibration question, same as `understand`. |
| `spec/SKILL.md` | Two edits: add `**Type**: bug \| change` to the `proposal.md` template, and repoint the terminal "next step" from `approve-plan` to `brief`. |
| `README.md`, `plugins/spwf/README.md` | Golden path table and diagram gain a step; skill tables gain a row. |
| Plugin version | Minor bump — new skill. |

`approve-plan` is **not** modified. No new agents, dependencies, or shared
modules.

### Edge cases settled

- **Absent `Type` line** (every change spec'd before this ships) — treat as a
  change and run. A briefing on an old bug change is mildly off-target, not
  harmful; the alternative is a skill that silently does nothing on everything
  that already exists.
- **First-run calibration** — both `brief` and `understand` must handle an absent
  `.spwf/learner.md`. `brief` usually gets there first on features, but bug
  changes never reach it and `brief` can be skipped, so `understand` keeps the
  capability it already has.
- **Very large change** — hard cap plus escape hatch, not proportional growth. A
  brief that scales with the diff has stopped being a brief.
- **Trivial change** — escape hatch. Say there's nothing worth briefing and stop.

## Decisions (resolved 2026-07-29)

| # | Question | Decision |
|---|---|---|
| 1 | Name | **`brief`** — `/spwf:brief`. Verb and noun; pairs with `recap`. |
| 2 | Structure | **Expand, then summarise.** Sections 1–4 build the detail, a 2–3 line summary crystallises at the end. |
| 3 | Bug path | **Features only.** `brief` does not run on the bug path. |
| 4 | The prompt | **Keep it.** One skippable "anything here not what you expected? [enter to continue]". |

### Consequences worth tracking

- **#3 leaves a gap I'd want revisited after real use.** Bug fixes are where an
  agent's unasked-for choices bite hardest — a "quick fix" that quietly changes
  a shared helper is the classic case, and section 3 is exactly what would catch
  it. Skipping the bug path keeps `brief` focused and avoids near-empty output
  on two-line fixes, which is a fair trade for v1. But if a bug fix ever ships a
  surprise that section 3 would have surfaced, that is the signal to reverse
  this rather than to add a checklist elsewhere.
- **#4 needs a guard against reflex.** A prompt answered with enter every single
  time trains the reflex and stops being a moment of attention. If it becomes
  automatic in practice, the fix is to make it conditional on section 3 being
  non-empty (rejected in #4 for unpredictability) — not to add weight to it.
- **#1 + the `recap` squeeze.** With `brief` named and placed, the workflow has
  `brief` → `recap` → `understand` all explaining. See "Consequence: this
  squeezes `recap`" above; decide after the next dogfood, not now.

## Challenge decisions

`/spwf:challenge` pass, 2026-07-29. Seven decisions, plus the codebase findings
that forced three of them.

**1. `brief` is its own golden-path step between `spec` and `approve-plan`** —
not the final step of `approve-plan` as originally drafted. Found by inspection:
approve-plan runs *present → stop and wait → commit*, so a "final step" fires
after approval, wasting the cheapest moment to object. Consequence:
`approve-plan` is untouched, and `spec` must repoint its successor.

**2. `spec` gains a `**Type**: bug | change` line** in the `proposal.md`
template, and `brief` reads it. Decision #3 (features only) had **no detection
mechanism** — neither `spec` nor `approve-plan` references `BUG-` anywhere.
Rejected: matching the `BUG-` prefix out of `proposal.md`'s Source line, because
keying behaviour to a filename convention is the same fragility that produced
the `changelog` "Part 5" bug, and it fails silently.

**3. Section 3 derives from the todo → plan delta**, not from `design.md` —
which is optional and, by construction, records only decisions someone thought
worth writing down. Two constraints added from the premortem: a **consequence
filter** (or the delta is most of the plan), and **`enrich` output counts as
what you asked for** (or it re-surfaces decisions the developer did make).

**4. On a "yes" at the prompt, `brief` names the remedy and does not act.**
Offering to re-run `spec` or `challenge` would turn a teaching step into a
control-flow step, which is where "never blocking" dies.

**5. `spec` points at `brief`; it does not invoke it.** Consistent with `spec`
being a producer rather than an orchestrator, and with `pr-create`'s explicit
refusal to auto-invoke `close`. Risk accepted — see Residual risks.

**6. The `recap` merge is deferred**, not folded in. Removing a shipped slash
command is a breaking change and this change has already grown. Revisit trigger,
written down rather than left as a feeling: after `brief` has run on a handful of
real changes, ask *"did you read `recap` at close, or skip it because `brief`
already told you?"*

**7. Teaching is primary; error-catching is a side effect.** Governs what gets
cut when a brief runs long — everything except section 3.

## Residual risks

| Risk | Confidence | Note |
|---|---|---|
| **Nobody runs it** | High | Decision 5 made `brief` opt-in by pointer. The red-team hit lands: this exists *because* teaching at the end was too late, and now teaching early is skippable too. The defence — `approve-plan` has the same exposure — doesn't hold, because `approve-plan` is a gate people want and `brief` is homework. **Trigger: if it's skipped on more than half of the first ten changes, switch `spec` to invoking it.** Do not respond with a reminder somewhere. |
| **The consequence filter is a judgement call** | High | "Would choosing differently change the shape of the result" has no mechanical test. Too loose and section 3 is noise; too tight and it's empty. Only real usage will calibrate it, and the first version will probably be wrong in one direction. |
| **The `Type` line drifts** | Medium | A prose claim in a template with no validator — exactly the `changelog` "Part 5" class. `workflow-lint` does not check ordinals or template fields. Mitigated by absent-Type being handled gracefully; not solved. |
| **Not conventionally testable** | High | Same as `understand`: no assertion proves a briefing taught anything. Structural checks plus dogfooding. |
| **Redundancy with `approve-plan`** | Low | The two now run back to back over the same plan. Different content — `brief` explains substance, `approve-plan` reviews quality — but the adjacency makes overlap more visible than the original design would have. Watch for it reading as one long ceremony. |
