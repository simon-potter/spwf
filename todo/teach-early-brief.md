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

**After `approve-plan`, before `build`.** The last moment before code exists.
The plan is vetted, the tasks are final, and nothing has been written yet — the
natural pause point.

```
challenge → spec → approve-plan → [brief] → build → … → close → recap → understand
                                    ▲                                        ▲
                            what WILL be built                    what WAS built,
                              and why                          and where to look
```

`approve-plan` invokes `/spwf:brief` as its final step — a one-way call, the same
architecture as `retrospective` → `understand`. Also runnable standalone.

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

Decisions taken during `spec` that the developer never specified: technical
approach, task decomposition, file layout, anything that landed in `design.md`
without being asked for.

This is the highest-value part and needs no question to work. These are, by
definition, the things the developer has no awareness of — the same reasoning
that made `understand` structure-anchored rather than design-anchored. Surfacing
them is simultaneously teaching *and* the cheapest possible error-catch.

**Escape hatch:** on a simple change there may be none. Say so and skip the
section — never invent decisions to fill it.

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

## Rough scope

| Item | Notes |
|---|---|
| `plugins/spwf/skills/brief/SKILL.md` | The skill. Reuses `_shared/learner-profile.md`. |
| `approve-plan/SKILL.md` | One invocation as its final step, non-blocking, plus the frontmatter description. |
| `README.md`, `plugins/spwf/README.md` | Golden path table, workflow diagram, skill tables. |
| Plugin version | Minor bump — new skill. |

No new agents, dependencies, or shared modules.

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
