---
source: scratch
created: 2026-07-28
status: ideation
---

# Learn-my-code — a comprehension check for work an agent did

> Plan only. No skill written yet. Two rounds of decisions on 2026-07-28 — the
> initial six open questions, then a `/spwf:challenge` pass that materially
> reshaped the design. See [Challenge decisions](#challenge-decisions) and
> [Residual risks](#residual-risks) at the bottom; the sections below reflect both.

## The goal, in one sentence

**When something breaks in six months, you have an instinct for where to look
and why.** Not hand-coded-level fidelity — navigational understanding. Enough to
orient, not enough to have written it. Every design choice below serves that
sentence; anything that doesn't was cut.

## The problem, named

The workflow ships changes. It does not establish that *you* understand them.
`recap` (shipped, Retrospective Part 5) explains the change to you — but reading
a good explanation produces the *feeling* of understanding without the fact of
it. That gap has a name and a literature now:

- **Comprehension debt** — "the growing gap between how much code exists in your
  system and how much of it any human being genuinely understands." Unlike
  technical debt it accumulates invisibly: metrics stay green while
  understanding hollows out. ([Osmani](https://addyosmani.com/blog/comprehension-debt/))
- Stack Overflow's 2026 survey: **76%** of developers using AI tools reported
  shipping code they did not fully understand at least some of the time.
- The finding that most directly justifies this skill: developers who use AI for
  **code-generation delegation score below 40% on comprehension tests**;
  developers who use it for **conceptual inquiry score above 65%**. The
  difference is not talent, it is whether an act of active engagement happened.

`recap` is passive delivery. What is missing is the active-engagement half —
the thing that converts a summary you read into knowledge you hold.

## What SPWF already has, and why this isn't a fourth wheel

| Skill | Teaches | Mode | Timing |
|---|---|---|---|
| `learn-from-mistakes` | **the project** — writes rules into `docs/` | Extractive, writes files | Retrospective Part 1 |
| `recap` | **the user** — concepts, decisions, surprises | Passive, prints a doc | Retrospective Part 5 |
| `challenge` (ex-`grill-me`) | **the plan** — interrogates the ideation file | Socratic interview | Gate, pre-spec |
| **new** | **the user's actual grasp** — finds where it isn't there | Socratic interview | Post-build |

The new skill is the **post-build sibling of `challenge`**. `challenge` grills
you on the plan before you build; this grills you on the result after. Same
idiom, opposite end of the golden path. That symmetry is the strongest argument
for the design chosen below, and it also means SPWF already has a house style
for this kind of skill to inherit.

It is **not** a variant of `recap`. Different tool shape (interactive vs.
print-once), different sources (this one reads the diff; `recap` deliberately
does not), different output (an orientation map + a persistent gap ledger vs. a
document). They compose: **`recap` is the syllabus, this is the exam** — except
it isn't an exam, for reasons that follow.

---

## Prior art surveyed

Four references, plus the research above. Each contributes something; two of
them are in direct opposition, and resolving that is the central design call.

### 1. `lesson-learned` (softaworks/agent-toolkit)

Extracts one dominant SE lesson from a diff, mapped against a principles
catalogue. **Take:** the "one well-grounded lesson beats seven vague ones" cap,
the honesty escape hatch ("these changes are straightforward — no deep lesson
here"), and "reflective, not prescriptive." **But:** SPWF already has this —
it's `recap`, and `recap` is better fitted (five sources, anti-padding rules).
Nothing here to build; a couple of rules worth stealing.

### 2. `check-understanding` (rohitg00)

Explicit quiz: 8 MCQs (4 conceptual, 4 practical), scored out of 8, graded
Mastered / Almost / Developing / Start Over, with a per-wrong-answer breakdown
pointing back at source material. **Take:** the conceptual/practical split, the
"tag each question with its source" discipline, the wrong-answer breakdown, and
the "what next" fork at the end. **Caution:** it quizzes over a fixed curriculum
of lesson documents. Our source is a diff *the agent just wrote*, which is a
materially different (and more compromised) situation.

### 3. `do-i-understand` (AnthonyPAlicea)

A **reverse code review — review the developer, not the code.** Risk-triaged
region selection, one open question at a time, answers in the author's own
words, ending in a verbatim "Author's understanding" attestation destined for
the PR body. Fires **pre-merge**. **Take:** almost all of it. Specifically:

- The risk triage ladder (auth/money/PII → migrations → concurrency → changed
  contracts → new abstractions → additive bloat → error paths → cargo-cult
  boilerplate → hand-rolled reimplementations).
- **"I don't know" is a finding, and a welcome one.** Grading makes it feel like
  losing; disclosure is the instrument.
- **Anti-gaming:** answers in your own words, no re-querying the model. Routing
  the question back to the AI just relocates the gap.
- **Never ask the developer to run or edit code.** Answered in words, from the chair.
- Citation discipline: verbatim snippet is the anchor, line number is secondary
  and re-derived at ask-time (numbers drift).
- **Grounded answers close lines of questioning.** A short session is the
  instrument working, not a lack of rigour.
- The blind-spot closer: *"which part do you understand least, and if it's
  wrong, how would you find out: review, CI, prod, or never?"*

### 4. `do-i-understand-the-ux` (AnthonyPAlicea)

Same interview machinery aimed at user-facing consequence. **Take:** the
**evidence ladder** — research / data / heuristic / convention / hunch — and its
framing: *"The failure is not being low on the ladder; it's not knowing which
rung you're on, or dressing a hunch as research."* That generalises far beyond
UX and belongs in the code version too. Also the diff→decision translation table
idea (a construct in a diff encodes a decision someone made), which is a good
technique for generating non-obvious questions. **Not v1** as a separate skill,
but noted as the obvious v3.

### 5. "Agents That Teach" ([arXiv 2607.06101](https://arxiv.org/pdf/2607.06101))

Design principles for building incidental learning back into agentic SDLC.
**Take:** three of its named failure modes are ones this skill could walk
straight into —

- **Attention fatigue** — too much educational content and it gets ignored
  wholesale. → hard question caps, early exit, close lines that are already grounded.
- **Misaligned complexity** — explanations pitched patronisingly simple or
  incomprehensibly technical. → this is the mechanical justification for the
  "appropriate to my level" half of the request; see the learner profile below.
- **Silent drift** — gaps aren't noticed until a high-pressure moment. → the
  persistent ledger, so gaps are visible before prod finds them.

Also: trigger at **"natural pause points"** — after generation completes, before
moving to the next task. Relevant to placement.

---

## The central tension, and how it resolves

`check-understanding` and `do-i-understand` want opposite things.

> **check-understanding:** 8 MCQs, one correct answer each, scored out of 8.
>
> **do-i-understand:** *"Don't turn it into a quiz. A quiz question has one
> answer you already hold and can be passed or failed. It rewards puzzle-solving
> and makes 'I don't know' feel like losing, which is the opposite of what you
> want. If your question has a single gradable answer, broaden it until it can't be."*

**Position: the interview wins as the default.** Three reasons, in order of force:

1. **An MCQ over a recap you just read tests recognition, not understanding.**
   The answer is sitting in the text above. This is precisely the fluency
   illusion the skill exists to defeat — it would *certify* the problem.
2. **The examiner wrote the code.** The agent generated the diff, wrote the
   recap, sets the questions and marks them. A scored format makes that
   conflict of interest load-bearing. An open interview that surfaces gaps
   without a grade is far more robust to a sycophantic marker.
3. **Consistency.** `challenge` is already a one-question-at-a-time Socratic
   interview with a 13-dimension probe taxonomy. Two skills, same idiom, both
   ends of the path. A quiz would be a foreign object in this workflow.

**But the quiz format has one legitimate niche**, and it isn't this one:
low-friction **retention checks on concepts from changes you shipped weeks ago**,
where there is no diff to be accountable for and recall genuinely *is* the thing
being measured. Gradability is fine there. So:

| Mode | Format | Scope | When |
|---|---|---|---|
| **default** | Socratic interview, ungraded | the change just shipped | post-build / at close / standalone |
| `--recall` | MCQ, scored, spaced | concepts from the ledger, past changes | ad-hoc, later (Phase 3) |

Each idiom used where it is actually correct, rather than picking a winner.

---

## Skill spec

### Name

**`understand`** — decided. Slash command `/spwf:understand`. Bare verb, matches
the `recap` / `simplify` / `build` / `spec` / `close` family, and reads naturally
in both modes: "understand this change" pre-merge, "understand what shipped" at
close. (Alternatives weighed and rejected: `comprehend` — stilted;
`do-i-understand` — breaks the bare-verb convention and collides with the
upstream name we adapt from; `account-for` — accurate but hyphenated, off-family.)

### Frontmatter (draft)

```yaml
---
# Adapted from: https://github.com/AnthonyPAlicea/skills — skills `do-i-understand`
# and `do-i-understand-the-ux` (risk triage, verbatim attestation, evidence ladder,
# anti-quiz posture, anti-gaming rules). Quiz-mode concepts (conceptual/practical
# split, wrong-answer breakdown) adapted from rohitg00/ai-engineering-from-scratch
# skill `check-understanding`. No SKILL.md content reproduced verbatim.
name: understand
description: Post-ship — Build a navigational understanding of a change an agent wrote, so you know where to look when it breaks later. Interviews you, not the code, one question at a time about the structural changes and concepts, at orientation depth rather than line-level fidelity. Calibrated via .spwf/learner.md. Produces an orientation note and records open gaps in the learner ledger. Companion to recap, which explains what and why; this covers consequence and navigation. Retrospective Part 6; runnable standalone via /spwf:understand [change-id | todo path | branch].
disable-model-invocation: true
allowed-tools: [Read, Glob, Grep, Bash, Write, Edit]
---
```

`Edit` is for the ledger only (append/update `.spwf/learner.md`). The skill never
touches source files — enforced by the "no tasks" rule below.

**No `AskUserQuestion`** — deliberate, and the reason matters. That tool is
structurally multiple-choice (2–4 options). Using it would silently reintroduce
the MCQ format rejected above, under a different name. `challenge` faces the same
problem and resolves it the same way: `allowed-tools: [Read, Write, Grep, Glob,
Bash]`, questions asked as plain conversational text, one per message.

### Inputs

**Structure-anchored, not line-anchored.** The interview is about the *shape* of
what changed — new modules, new dependencies, changed interfaces, altered data
flow, things newly wired together — not about individual lines. That anchor is
chosen deliberately: the gap being closed is *what the agent decided on its own*,
and those decisions by definition aren't in `design.md`, because nobody wrote them
there. A design-anchored interview would probe the decisions you already made
yourself, which are the ones you already understand.

```
1. .spwf/learner.md                                — level + known/open ledger
2. recap output (in-session, Part 5 ran just before) — what/why already covered
3. git diff --stat + git log $(git merge-base HEAD {base})..HEAD
                                                   — the shape of the change
4. Selective reads of the significant changed files — only those that matter
5. openspec/changes/{id}/design.md, proposal.md    — supporting, not primary
6. todo/{slug}.md                                  — original intent
```

**Not the full diff.** Reading `--stat` plus the files that actually matter is
sufficient at orientation depth, and it disposes of the "diff too large to
triage" edge case for free. Reading every line would be gathering fidelity the
interview has already decided not to use.

Standalone runs have no `recap` output in session. Fall back to reading
`recap.md` if saved, otherwise proceed without — the interview works from
structure regardless. Do not hard-depend on a syllabus.

### Steps

1. **Resolve the change.** Same 3-form resolution as `close` / `recap`
   (empty → detect from branch; change-id; todo path). Additionally accept a
   bare branch name or `HEAD~N` range for standalone use outside the golden path.
2. **Load the learner profile.** Read `.spwf/learner.md`. If absent, ask the one
   calibration question (below) and create it. Never ask twice.
3. **Map the structure, pick what matters.** From `--stat` and the log, identify
   the **3–5 structural changes that would matter most if something went wrong
   later** — a new integration point, a changed interface, a new dependency, a
   shift in where data flows. State which were picked and why. Skip renamed
   locals, log lines, and anything at variable-name granularity.
4. **Interview.** One question at a time, then wait. Name the file or area under
   discussion so it's locatable; no line-number ceremony. Probe thin answers once
   or twice. Close a line of questioning as soon as the answer is grounded.
5. **The evidence ladder.** When an answer offers a rationale, establish which
   rung it stands on (research / data / heuristic / convention / hunch). Low
   rungs are fine at low stakes; *not knowing which rung you're on* is the finding.
6. **The navigation question.** Always, however the rest went: *"If this
   misbehaves in six months, where do you look first, and what would you expect
   to see?"* This is the skill's whole purpose expressed as a single question —
   if the rest of the interview went well, this one should be answerable.
7. **Write the orientation note.** See Output below.
8. **Update the ledger.** Move demonstrated concepts to `Known`, record gaps as
   `Open` with what would close them.

### Question shapes

**Not a question bank.** These are worked examples of the derivation, and the
SKILL.md must say so — `do-i-understand` warns that if every question maps back
to the list, you're pattern-matching rather than interviewing. Derive from what
the change actually contains; expect to build shapes these don't anticipate.

Every question must fail the "answerable by reading the code aloud" test, and
must sit at orientation depth rather than implementation depth:

- **Blast radius** — "this change means the export now goes through the queue.
  What else is on that queue, and what happens to this when it backs up?"
- **Road not taken** — from `design.md` Decisions where they exist: "why this
  approach and not the alternative? What would have gone wrong?"
- **Where it touches** — "which parts of the system now depend on this that
  didn't before?"
- **Failure shape** — "when this breaks, what does it look like from the
  outside? Slow, wrong, or loud?"
- **New dependency** — "we've taken on {library}. What does it do for us that we
  weren't doing before, and what happens if it's unavailable?"
- **Concept transfer** — "the same pattern is used in {other place in this repo}.
  What's different about how it's done there?"

**Explicitly out of range** (the fidelity target): null-check placement, guard
clauses, individual error branches, naming, anything answerable only by having
written the line. If a question could only be answered by someone who typed the
code, it is the wrong question for this skill.

---

## "Appropriate to my level" — the learner profile

The paper names **misaligned complexity** as a first-order failure mode.
Calibration needs state, and it needs to compound: the third session should be
better aimed than the first.

### `.spwf/learner.md`

Sits beside `.spwf/priorities.md` and `.spwf/tracker.yaml`, following the
existing `_shared/project-priorities.md` convention (markdown, not YAML, to
match). **Gitignored by default** — unlike `priorities.md` this is personal, not
a team-shared statement of intent, and "Simon is shaky on migrations" does not
belong in a shared repo. Add `.spwf/learner.md` to `.gitignore` as part of this work.

```markdown
# Learner profile

## Level
{new | working | fluent} overall, with per-area overrides:
- {area, e.g. Postgres migrations} — {new | working | fluent}

## Known
Concepts demonstrated in a session, with the change that proved it.
- {concept} — {change-id}, {YYYY-MM-DD}

## Open
Gaps flagged and not yet closed.
- {concept} — {change-id}, {YYYY-MM-DD}. To close: {what would}

## Recurring blind spots
Areas that have shown up as Open more than twice.
- {area}

_updated {YYYY-MM-DD} by /spwf:understand_
```

> **Review this after ~5 real runs.** The ledger is the one part of the design
> that is additive to the stated goal rather than required by it, and it is the
> most likely thing here to rot: written each run, read rarely, drifting from
> reality. Keep it only if "which areas do I keep not understanding" turns out to
> be information you actually use. If it hasn't earned its place by then, cut it —
> the skill works without it, calibrating within a session from how you answer.

### How level is used — and how it is not

**Level changes the explanation depth and vocabulary. It does not change the
rigour of the check.**

- `new` — more scaffolding, an analogy where one genuinely helps, the concept
  named before it's probed.
- `working` — the default; concept assumed, consequence probed.
- `fluent` — terser framing, straight to the tradeoff, fewer questions.

Nobody gets *easier questions*. If level lowered the bar, the check would be
theatre and the ledger would be a record of flattery. This rule is
non-negotiable and belongs in the SKILL.md verbatim.

### How level is set

One question on first run, never repeated. Thereafter adjusted by observed
answers ("you traced that consequence without prompting → promoted to fluent on
X"), announced when it changes so it's never silent.

---

## Workflow placement

**One hook.** `simplify`, `pr-create` and `recap` are not modified. The pre-merge
`--gate` mode was designed, then cut — see [Challenge decisions](#challenge-decisions) #1.

### Retrospective Part 6 — at close, so you know what you just signed off on

Immediately after `recap` (Part 5), pushing `changelog` to Part 7.

**Optional with a strong recommendation** — `[Y/n]`, default yes, with a reason
specific to *this* change rather than a generic offer. A bare prompt gets
reflexively declined; one that names what's at stake doesn't:

```
Part 6 — Understand what you just shipped

This change touched 3 areas you haven't worked in before (the export queue,
the retry wrapper, the new S3 client). Ten minutes now means knowing where
to look when one of them misbehaves later.

Run it? [Y/n]   (or later: /spwf:understand add-user-export)
```

**Standalone is the stronger mode, and the prompt should not pretend otherwise.**
Spaced retrieval outperforms immediate retrieval; running this a week later
against an archived change is pedagogically better than running it at close. The
close hook exists so the option is visible at the moment you're thinking about
the change, not because close is the optimal time.

### The Part 5 / Part 6 adjacency problem

Running an interview 90 seconds after `recap` explained the same change is
lecture-then-test — you answer from short-term memory and learn nothing. This is
the recognition-not-recall failure used above to reject the MCQ format, and it
applies just as hard here. It is the single biggest risk in the design.

**The rule that resolves it:** `understand` must not re-ask what `recap` just
explained. The two divide cleanly —

| | `recap` (Part 5) | `understand` (Part 6) |
|---|---|---|
| Covers | **what** changed and **why** | **consequence** and **navigation** |
| Question it answers | "what did this do?" | "where do I look when it breaks?" |
| Mode | prints, you read | asks, you answer |

`recap` never answers "where would you look" — so Part 6 has genuine material
that Part 5 didn't cover, and asking it isn't recall of something just read.
Enforce this as an explicit rule in the SKILL.md, not an aspiration.

### v2 — spaced recall (`--recall`)

MCQ mode over `Known` and `Open` in the ledger, spanning past changes. This is
where `check-understanding`'s format earns its place. Deferred.

---

## Rules baked into the SKILL.md

Non-negotiables. Several of these exist specifically because the agent that
wrote the code is the one running the check.

1. **Not a quiz.** No score, no grade, no pass/fail. If a question has one
   gradable answer, broaden it until it doesn't.
2. **"I don't know" is a finding and is welcomed as one.** Note the region and
   what would close it. An author who feels graded stops disclosing.
3. **Answers in the user's own words.** No re-querying the model. If the user
   has to ask the AI, that is itself the flagged gap — routing the question back
   relocates the gap, it doesn't close it.
4. **No tasks.** Never ask the user to change, run, or edit code. Every question
   is answered in words, from the chair. Hypotheticals framed explicitly as
   thought experiments.
5. **One question at a time.** Never dump a list. The follow-up is the instrument.
6. **Ban recap-lookup questions.** If the answer is a verbatim phrase from the
   recap the user just read, it tests recognition, not understanding. Discard it.
7. **Ban trivia.** No "which file changed", no "how many lines". Concepts,
   consequences and rationale only.
8. **Grounded answers close lines.** A three-question session where all three
   were answered well is a success, not a failure of rigour. Do not manufacture
   doubt — it teaches the user to perform for the interview instead of think in it.
9. **Cap the session.** Max ~8 questions, hard. Offer an exit at any point.
   (Attention fatigue is a named failure mode; an ignored check is worth nothing.)
10. **Orientation depth, not implementation depth.** If a question could only be
    answered by someone who typed the line, it's the wrong question. Name the
    file or area so it's locatable; skip line-number ceremony. Redact secrets
    from anything quoted.
11. **Don't re-ask what `recap` just explained.** Part 5 covers what and why;
    this covers consequence and navigation. See the adjacency problem above.
12. **Tiny-change escape hatch.** Mirror `recap`'s: if nothing changed that
    you'd need to navigate later, say so and stand down — *"nothing here worth
    an interview; skipping."* Better to admit small than fake depth.
13. **No emoji, no celebration, no praise inflation.** Same tone contract as `recap`.

---

## Output

### 1. The orientation note (in-session, offered for saving)

**A map for future-you, not an attestation for a reviewer.** The original draft
borrowed `do-i-understand`'s "Author's understanding" block — verbatim quotes,
"Ready to merge" verdict — but that artefact exists so a *reviewer* can tell your
words from an AI's. There is no reviewer here, so verbatim quoting and the
merge verdict both drop.

```markdown
## Orientation: {change-id}

### The shape of this change
{2–4 sentences: what moved, what's new, what now depends on what.}

### Where to look when things go wrong
- **{symptom}** → {file/area}, because {reason}
- ...

### Still fuzzy
- {thing} — {what would clear it up}

### Concepts this touched
- {concept} — {one line, only for concepts new to the ledger}
```

"Where to look when things go wrong" is the section that carries the whole
purpose. If the interview produced nothing for it, the interview failed —
irrespective of how well the other questions went.

Offer to save to `openspec/changes/{id}/understanding.md`, which travels into
the OpenSpec archive with the change, same as `recap.md`.

### 2. The ledger update

Append to `.spwf/learner.md`. This is the compounding artefact and the answer to
the paper's "silent drift" failure mode — gaps become visible as a list before
they become visible as an incident.

---

## Implementation work items

| # | Item | Notes |
|---|---|---|
| 1 | `plugins/spwf/skills/understand/SKILL.md` | The skill. Attribution header per house style (see `challenge`, `simplify`). |
| 2 | `plugins/spwf/skills/_shared/learner-profile.md` | Convention doc for `.spwf/learner.md`, mirroring `_shared/project-priorities.md` in shape and tone. |
| 3 | `retrospective/SKILL.md` | New Part 6; renumber `changelog` 6 → 7. Update the header block, the part list, the frontmatter description ("Six-part" → "Seven-part"), and the Report template. |
| 4 | `close/SKILL.md` | Step 2 line 113 — "All six parts run as normal" → seven, plus the list beneath it. Also the frontmatter description, which enumerates the parts. |
| 5 | `changelog/SKILL.md` | **Pre-existing bug**, surfaced by this work: line 3 says "call from the retrospective orchestrator as Part 5". It has been Part 6 since `recap` was inserted. Fix to Part 7. |
| 6 | `.gitignore` | Add `.spwf/learner.md` with a one-line comment on why (personal, not team-shared). Existing SPWF installs won't have the line — note it in the skill so a first run adds it. |
| 7 | `README.md` | Skill table (~L389, beside `recap`), Close row (~L64) which enumerates retrospective parts, `changelog` row (~L391, says "Part 6"), workflow diagram. |
| 8 | `plugins/spwf/README.md` | Skill table (~L44), Close row (~L20), and extend the existing "Learning modes" section (~L219) — it currently names `recap` as *the* post-hoc complement; it becomes explain + navigate. |
| 9 | `plugins/spwf/.claude-plugin/plugin.json` | 1.19.0 → **1.20.0** (minor — new skill). `spwf-agents` unchanged; no new agent. |
| 10 | `workflow-lint` sanity pass | New skill must appear in the golden-path coverage tables or it lints as orphaned. Run it after, before pushing. |

**Not touched:** `simplify`, `pr-create`, `recap`. The `--gate` mode that would
have modified the first two was cut.

No new agents. No new dependencies. No external services. The interview runs in
the main session — a subagent would break the one-question-at-a-time interaction.

---

## Explicitly out of scope for v1

- **Pre-merge `--gate` mode** and any change to `simplify` or `pr-create` — cut,
  see challenge decision 1
- **Hand-coded-level fidelity.** The interview deliberately stops at orientation
  depth; line-level probing is a non-goal, not a deferred feature
- `--recall` MCQ / spaced-repetition mode (v2)
- A UX-consequence variant (`do-i-understand-the-ux`'s territory) — a good v3,
  and mostly a different question set over the same machinery
- Cross-project learner profile at `~/.claude/` (v1 is project-scoped)
- Auto-inferring level from transcript behaviour rather than declaration
- Anki / external SRS export
- Any hook that fires this automatically without being asked

---

## Decisions — round 1 (2026-07-28)

| # | Question | Decision |
|---|---|---|
| 1 | Pre-merge hook now or later? | ~~Both in v1~~ — **superseded by challenge #1 below. Gate cut entirely.** |
| 2 | Name | **`understand`** — `/spwf:understand`. Bare-verb family. |
| 3 | Ledger scope | **Project-scoped `.spwf/learner.md`.** Plugin owns the convention (`_shared/learner-profile.md`); the data file lives in the target project beside `priorities.md` and `tracker.yaml`, so it survives `/plugin update`. |
| 4 | Committed or gitignored? | **Gitignored.** Personal, not a team statement of intent. |
| 5 | Default at close | ~~OFF~~ — **revised to `[Y/n]` default-yes with a change-specific reason.** "Optional with a strong suggest." |
| 6 | Does `recap` survive? | **Yes, separate.** Division of labour sharpened by challenge #5. |

**Consequence carried forward:** #3 + #4 together mean the ledger doesn't follow
you across machines. Project-scoped *and* gitignored is the safest combination
and the least durable — a fresh clone starts empty and re-asks the calibration
question. Acceptable; if it bites, the escape hatch is the "level global, gaps
per-project" split rejected in question 3.

## Challenge decisions

`/spwf:challenge` pass, 2026-07-28. Five decisions that changed the design, plus
the codebase findings that forced them.

**1. The `--gate` mode is cut.** No `simplify` or `pr-create` changes; one hook
only, at Retrospective Part 6. Route: `pr-create` first (rejected — it declares
`allowed-tools: [Read, Bash]`, can't write, is a mechanical halt-or-pass
checklist, and sets the explicit precedent *"Do not invoke `/spwf:close`
automatically. pr-create points forward only"*), then `simplify` Pass 3
(better fit — already pins `BASE_SHA..HEAD_SHA`, already short-circuits trivial
diffs), then cut altogether once the goal was restated. The gate's entire
justification was *actionability* — find the gap while it's still fixable. Under
a navigational goal nothing needs fixing, so that justification evaporated.

**2. The goal is navigational, not accountability.** *"In case of problems in
future, they have an instinct on where and what to look at and why."* Recorded as
the success definition at the top of this file. Everything below follows from it.

**3. Structure-anchored at orientation depth.** Questions come from the shape of
what changed — new modules, dependencies, interfaces, data flow — not from diff
regions or design docs. Explicitly *not* hand-coded fidelity: no null-check
placement, no guard clauses, no naming. If only someone who typed the line could
answer, it's the wrong question. Consequence: reads `--stat` plus selective
files, not the full diff, which also disposes of the large-diff edge case.

**4. The artefact is an orientation map, not an attestation.** "What I can
account for" / "Ready to merge" was borrowed from `do-i-understand`, where the
output serves a *reviewer*. There is no reviewer here, so verbatim quoting and
the merge verdict both drop. Replaced by "Where to look when things go wrong",
which carries the whole purpose.

**5. Part 5 / Part 6 division of labour is now an enforced rule.** Surfaced by
the premortem: running an interview 90 seconds after `recap` explained the same
change is lecture-then-test, and you'd answer from short-term memory. `recap`
covers what and why; `understand` covers consequence and navigation. It must not
re-ask what `recap` just explained.

**6. No `AskUserQuestion` in `allowed-tools`.** Found by inspection: `challenge`
omits it deliberately. The tool is structurally multiple-choice, so using it
would reintroduce the MCQ format under another name. Plain conversational text,
one question per message.

**7. Ledger kept, with a scheduled review.** Review after ~5 real runs; cut if
"which areas do I keep not understanding" isn't information actually used.

**8. Pre-existing bug found.** `changelog/SKILL.md:3` claims it's called "as Part
5" — stale since `recap` took Part 5. Added to the work items; the renumber to
Part 7 forces the fix regardless.

## Residual risks

Carried into spec rather than resolved.

| Risk | Confidence | Note |
|---|---|---|
| **Part 6 gets declined every time** | Medium | `[Y/n]` default-yes with a change-specific reason is the mitigation. If it's still skipped after ~5 changes, the hook is dead weight — cut it and keep standalone only, rather than leaving a prompt nobody answers. |
| **Not conventionally testable** | High | An interview has no deterministic output; there is nothing to assert. Dogfooding on this repo's own changes is the only verification available. Accept it. |
| **Success is unmeasurable at run time** | High | "Instinct in six months" cannot be observed now, by definition. The proxy — whether the "where to look" section comes out substantive or empty — is weak but is all there is. |
| **Questions come out generic** | Medium | Carry over `recap`'s banned-vocabulary rules. If the first real runs produce "why did you add a new module?", the derivation method needs work, not the question list. |
| **Ledger rots** | Medium | Covered by the scheduled review (challenge decision 7). |
