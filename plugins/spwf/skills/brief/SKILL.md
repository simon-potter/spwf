---
name: brief
description: Phase 1.5 — Explain a planned change before it is built. Runs between spec and approve-plan, so a mismatch costs a conversation rather than a change. Five sections, expanding then summarising — what will be built, why this way, the choices you didn't make, what it touches, and a short summary. Never blocks: it prints, offers one skippable prompt, and returns. Calibrated via .spwf/learner.md. Companion to recap and understand, which teach after the fact; this teaches before. Runs on changes, not bug fixes.
disable-model-invocation: true
allowed-tools: [Read, Glob, Grep, Bash, Write, Edit]
---

# brief

**Explain what is about to be built, while it can still be changed cheaply.**

`recap` and `understand` teach after the work has shipped. By then comprehension
debt has already been incurred and there is nothing to be done about a wrong
turn. `brief` runs before the build, when "that's not what I meant" costs a
conversation.

**Teaching is the point; catching errors is a side effect.** Success is that you
could explain the plan to someone else afterwards. Most plans are fine and
section 3 will find nothing — that is a successful run, not a wasted one.

> **Never blocking.** This skill prints, offers one skippable prompt, and
> returns. It does not gate `approve-plan`, does not require an answer, and does
> not act on what you tell it. `approve-plan` is the gate; a second gate two
> lines earlier is friction that gets routed around. Any future edit that makes
> this skill halt, insist, or re-run something contradicts this paragraph.

## Step 1 — Resolve the change

Read `$ARGUMENTS`:

| Input | Resolution |
|---|---|
| Empty | Detect from the current branch, or the most recent change. Ask if ambiguous. |
| change-id | `openspec/changes/{id}/`, falling back to `openspec/changes/archive/{id}/` |
| Todo path ending `.md` | Read frontmatter to derive the change-id; resolve as above |

If nothing resolves, halt naming both searched locations:

```
Cannot find change "{arg}" in openspec/changes/ or openspec/changes/archive/.
```

**Incomplete artefacts.** `brief` needs `proposal.md` and `tasks.md`. If either is
missing, say which and stop:

```
Cannot brief {change-id} — {proposal.md | tasks.md} is missing.
Run /spwf:spec first, or check the change id.
```

Do not brief from partial artefacts. A brief assembled from half a plan is worse
than none, because it reads as complete.

**Every exit path ends by naming the next step** — including the halts above, the
bug skip in Step 2, and the trivial-change stop in Step 5:

```
── Next step ───────────────────────────────────────────────────
/spwf:approve-plan — review the task list and give the go/no-go
```

## Step 2 — Check the change type

Read the `**Type**:` line from `proposal.md`.

| Value | Action |
|---|---|
| `change` | Proceed. |
| `bug` | Skip, stating why (below). |
| Absent | **Treat as a change and proceed.** |

On a bug:

```
Briefs cover changes rather than bug fixes — a fix's plan is usually its
diagnosis, and there's little to explain ahead of it that the bug report
didn't already say.
```

Then name the next step and stop.

**Why absent means proceed.** Every change spec'd before the `Type` line existed
has no value to read. Treating absent as "unknown, do nothing" would make this
skill silently inert on the entire back catalogue. A brief on an old bug fix is
mildly off-target; silence on everything is worse.

## Step 3 — Load the learner profile

Read `.spwf/learner.md` per
[`_shared/learner-profile.md`](../_shared/learner-profile.md).

**If absent — order matters.** Ensure `.spwf/learner.md` is listed in
`.gitignore` **before writing the file**. The profile records what a person does
not yet understand; a first run in a fresh project must not commit that. Add the
entry if it is missing, then ask:

> "Before I explain this — roughly where are you with this codebase and its
> stack: new to it, working in it comfortably, or fluent? It sets how much
> background I put around each section."

Create the file with the answer. **Never ask again on later runs.**

`understand` already implements this ordering; copy it rather than reinventing it.

### What level changes

Level sets **how much background each section carries**. It never changes which
sections appear.

| Level | Sections |
|---|---|
| `new` | Name concepts before using them; more background per section; an analogy where one genuinely clarifies. |
| `working` | Assume the vocabulary; explain the specifics of *this* plan. |
| `fluent` | Terser. Straight to the decision and its consequence. |

All five sections appear at every level.

## Step 4 — Read the plan

```
1. todo/{slug}.md                          — what was asked for (the left side of §3's delta)
2. openspec/changes/{id}/proposal.md       — Why, What Changes, Impact
3. openspec/changes/{id}/tasks.md          — the shape and size of the work
4. openspec/changes/{id}/design.md         — if it exists; supporting only
```

## Step 5 — Write the brief

Five sections, **expanding then summarising** — detail first, so the summary
lands as a takeaway rather than a heading.

**Trivial change?** Say so and stop, naming the next step:

```
Nothing here worth briefing — {one-line summary of the plan}.
```

### 1. What will be built

Plain language, 3–5 sentences. The substance.

**Not the task list** — `approve-plan` will print that in a moment. If the reader
couldn't tell a colleague what is about to happen after reading this section, it
has failed.

### 2. Why this way

The shaping decisions and their reasons, from `design.md` and the proposal's Why.
Where an alternative was rejected, name it and say why.

### 3. Choices you didn't make

**The section this skill exists for.** Derived from the **todo → plan delta**:
what you asked for is the ideation file; what got planned is `proposal.md` +
`tasks.md` + `design.md`. Anything in the plan with no antecedent in the ideation
file is, by construction, a decision something else made.

`design.md` is **supporting detail only, never the primary source.** It is
frequently absent, and it records only decisions someone thought worth writing
down — the ones that never got written down are precisely the dangerous ones.

**Two filters, both load-bearing.**

**a) Consequence.** A spec is *always* more detailed than the ideation file — that
is what `spec` does — so a literal delta is most of the plan. Report a candidate
only if **choosing differently would change the shape of the result**:

| Report | Don't report |
|---|---|
| An approach or mechanism chosen among alternatives | What a file or symbol is called |
| A new dependency taken on | How tasks were split or ordered for convenience |
| A boundary drawn — what's in scope, what's separate | Which phase a task landed in |
| An ordering that constrains later work | Wording, formatting, structure of the artefacts |

If you find yourself listing more than about five, the filter is too loose.
Forty banal items bury the two that matter, and a section nobody reads catches
nothing.

**b) `enrich` output counts as "what you asked for".** If the ideation file
carries `## Directions considered`, `## Recommended direction` or `## Not doing`,
those are decisions **the developer made** — `enrich` walked them through it.
The delta's left side is the *whole* ideation file, those sections included.
Re-surfacing them as unasked-for is both wrong and insulting.

**Empty is a real answer.** If nothing survives the filters, say so and omit the
section:

```
Nothing significant here you didn't ask for — the plan follows the ideation
file closely.
```

Never invent decisions to fill it.

#### Worked example

Ideation file said: *"add a learning step at close that explains the change."*

Plan contains a new `_shared/` convention doc, a gitignored state file, and a
renumbering of the retrospective's parts.

> **Choices you didn't make**
>
> - **The learner profile is a new file in `.spwf/`, gitignored.** You asked for
>   calibration "appropriate to my level"; the plan decided that means persistent
>   per-project state rather than asking each run. Consequence: it doesn't follow
>   you across machines.
> - **The retrospective grew a part rather than extending `recap`.** The plan
>   treats teaching and summarising as separate steps, which means two things run
>   back to back at close.

Both change the shape of the result. Neither is in the ideation file. Naming the
convention doc `learner-profile.md` is *not* in this list — it changes nothing.

### 4. What this touches

Blast radius, from `tasks.md` and the proposal's Impact — which areas, roughly
how much, anything load-bearing. So the size is visible before it happens rather
than after.

### 5. Summary

Two or three lines. The what and the why, crystallised. This is what you carry
into the build.

### Length

Cap the whole brief at roughly one screen. When it runs long, **reduce depth in
sections 1, 2 and 4 — never section 3.** Section 3 is the only one with no
substitute anywhere else in the workflow; the others restate material that also
exists in the artefacts.

## Step 6 — The prompt

One prompt, then return:

> "Anything here not what you expected? [enter to continue]"

An invitation, not a check. Enter dismisses it.

**On a "yes": name the remedy, do not act on it.**

| What's wrong | Remedy |
|---|---|
| A task looks wrong | Raise it at `approve-plan` — it's the next command and can revise tasks |
| The plan is wrong | Re-run `/spwf:spec`, or edit the artefacts directly |
| The idea is wrong | Back to `/spwf:challenge` |

Say which applies and why, then stop. **Do not re-run `spec`, reopen
`challenge`, or edit any artefact.** Offering to act is where a teaching step
becomes a control-flow step, and where the non-blocking guarantee at the top of
this file quietly dies.

## Step 7 — Update the ledger

Per [`_shared/learner-profile.md`](../_shared/learner-profile.md), record the
concepts the brief covered under `## Known` with the change-id and date.

`brief` explains rather than checks, so it has no evidence the developer
understood anything — **it must not record anything under `## Open`**, and must
not adjust level. Those need a check to justify them, which is `understand`'s
job at close.

## Report

```
✓ Brief for {change-id}
  {N} sections · {M} unasked-for decisions surfaced

── Next step ───────────────────────────────────────────────────
/spwf:approve-plan — review the task list and give the go/no-go
```

## Tone

A colleague telling you what they're about to do and why, before they start.
Concrete, names files, no emoji, no celebration. Short enough that reading it is
never the expensive part of the change.
