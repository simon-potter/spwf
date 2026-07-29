---
# Adapted from: https://github.com/AnthonyPAlicea/skills — skills `do-i-understand`
# and `do-i-understand-the-ux`. Concepts adapted: structure-first topic selection,
# orientation-depth fidelity, one topic at a time, and the closing navigation
# question. NOTE: those skills are pre-merge accountability audits and explicitly
# refuse to explain ("the developer showing their understanding, not explaining
# things to them"). This skill inverts that — it is a learning tool, so a gap is
# the trigger to teach. See design.md Decision 9 in the change that added this.
# Quiz-mode concepts from rohitg00/ai-engineering-from-scratch `check-understanding`
# noted and deferred to a future --recall mode. No content reproduced verbatim.
name: understand
description: Post-ship — Teach the developer what a change did, so they know where to look when it breaks later. Works through 3-4 structural topics, and for each one explains before asking anything, then checks the explanation landed, then explains again by a different route if it didn't. Uncertainty is the trigger to teach, never a gap to record. Calibrated via .spwf/learner.md. Produces an orientation note of what the developer now knows. Companion to recap, which prints what and why; this teaches consequence and navigation. Retrospective Part 6; runnable standalone via /spwf:understand [change-id | todo path | branch].
disable-model-invocation: true
allowed-tools: [Read, Glob, Grep, Bash, Write, Edit]
---

# understand

**The goal: when this breaks in six months, the developer knows where to look
and why.**

Not hand-coded fidelity — navigational understanding. Enough to orient, not
enough to have written it.

## The one rule that governs everything else

**Explain first. Always. Every topic, every level.**

This skill teaches. It does not audit. If the developer says "I don't know",
that is the moment to teach — not a gap to write down and move past.

> **Why this warning is here.** The first version of this skill was adapted from
> `do-i-understand`, a pre-merge accountability audit which correctly refuses to
> explain (explaining would launder the very gap the audit exists to expose). That
> posture was imported wholesale and it produced a session the developer called
> *"difficult and abstract and not great for learning."* The technique was worth
> borrowing; the posture was not. Do not reintroduce it.

**No `AskUserQuestion` in `allowed-tools`, deliberately** — it is structurally
multiple-choice, and this is not a quiz. Plain conversational text.

## Step 1 — Resolve the change

Read `$ARGUMENTS`:

| Input | Resolution |
|---|---|
| Empty | Detect from the current branch, or the most recent change. Ask if ambiguous. |
| change-id | `openspec/changes/{id}/`, falling back to `openspec/changes/archive/{id}/` |
| Todo path ending `.md` | Read frontmatter to derive the change-id; resolve as above |
| Branch name or commit range | Use directly — standalone runs outside the golden path |

As Part 6 of `retrospective`, the change-id is passed explicitly — skip detection.

If nothing resolves, halt naming both searched locations. Do not interview on a
different change.

```
Cannot find change "{arg}" in openspec/changes/ or openspec/changes/archive/.
```

## Step 2 — Load the learner profile

Read `.spwf/learner.md` per
[`_shared/learner-profile.md`](../_shared/learner-profile.md).

**If absent**, ensure `.spwf/learner.md` is in `.gitignore` (add it if not — it
records personal gaps and must never be committed), then ask once:

> "Before we start — roughly where are you with this codebase and its stack:
> new to it, working in it comfortably, or fluent? It sets how much background
> I put around each explanation."

**Never ask this again on later runs.**

### What level changes — and what it must not

Level sets **how much scaffolding each explanation carries**. It never decides
*whether* explanation happens, and it never makes the check questions easier.

| Level | Explanations |
|---|---|
| `new` | Name concepts before using them. Offer an analogy or worked example where one genuinely clarifies. More background per topic. |
| `working` | Assume the vocabulary; explain the specifics of *this* change and why it's shaped that way. |
| `fluent` | Terser. Straight to the decision and its consequence. Fewer topics if the change is small. |

If level ever results in no explanation, the calibration question was pointless
and this skill has regressed to its failed first version.

## Step 3 — Read the structure and pick topics

**Read the shape of the change, not every line.**

```bash
RANGE="$(git merge-base HEAD "${BASE:-main}")..HEAD"   # or the resolved range
git diff --stat $RANGE
git log $RANGE --format="%h %s%n%b"
```

Then read only the changed files carrying structural weight — a new module, a
new dependency, a changed interface, a shifted data flow. Read `design.md`,
`proposal.md` and the `todo/` file second, as supporting material.

**Do not read the full diff.** At orientation depth it is fidelity the session
has already decided not to use.

### Choosing 3–4 topics

Pick things that are **teachable**, not merely checkable. A topic needs
substance to explain: a reason behind it, a consequence, a connection to
something else. "The `.gitignore` entry changed" is checkable and worthless to
teach; "personal state now lives outside the repo, and here's what that costs
you" is a topic.

Weight toward what would matter if something went wrong later.

State the selection up front so the developer knows the shape of the session:

```
Four topics, ~10 minutes:
  1. The export queue — why the write path is now async
  2. The S3 client — a new external dependency and what it assumes
  3. The UserExport interface change — four callers moved
  4. Where failures surface

Skipping the config rename and test fixtures — nothing to navigate there.
```

**Trivial change?** Say so and stop:

```
Nothing here you'd need to navigate later — {one-line summary}. Skipping.
```

## Step 4 — The cycle, per topic

Announce position each time: **"Topic 2 of 4 — the S3 client"**.

### 4a. Explain

**This is the first move. Never open a topic with a question.**

A short paragraph or two — not an essay, not a single line. Cover:

- **What changed**, concretely, naming the file or area
- **Why it's that way** — the reason, and the alternative if one was rejected
- **What now depends on it** — the connection that makes it matter

Pitch the background to the recorded level. Name the thing before reasoning
about it.

If `recap` ran in Part 5, don't re-explain its ground (what changed and why in
the abstract) — go straight to consequence and connection. Standalone, include a
compact what/why as setup, since nothing has covered it.

### 4b. Check

**One question, answerable from the explanation just given plus ordinary
reasoning.**

Good checks ask the developer to *apply* or *extend* what they were just told:

- "Given that, if you added a fifth caller, what would you have to remember?"
- "So when the queue backs up, which of those two symptoms would you see first?"
- "Does that reasoning also hold for the other place we use this pattern?"

**Banned — the failure mode of the first version:**

- Questions needing information not given. *"If someone inserts a Part 8 next
  year, where does the drift surface first"* asked the developer to derive
  something they had no basis to derive.
- Questions with one gradable answer being held back. That is a quiz.
- Questions about null-check placement, guard clauses, individual error
  branches, or naming — below orientation depth.

If a candidate question could only be answered by someone who typed the code, or
by someone who read something you didn't explain, discard it.

### 4c. Deepen — the step that makes this a learning tool

**Any signal of uncertainty routes back into teaching.** That includes:

- "I don't know" or equivalent
- Hedging, or an answer that restates the question
- An answer that appeals to what the agent said
- A wrong answer

**Explain again, by a different route than the first time.** Not the same words
rearranged — a genuinely different angle:

| First explanation was… | Try instead |
|---|---|
| Structural ("A now calls B") | Trace it — walk the actual sequence in the code |
| Abstract | A concrete worked example with real values |
| Descriptive | Consequence-first: "here's what breaks if this is wrong" |
| Prose | The two-line version, stripped to the essential claim |

Then confirm it landed — lightly, not as a re-test: *"Does that make more
sense?"*

**Only if a second explanation also fails** does the item go into the note's
open list, with a concrete suggestion for what would close it. Then move on
without a third attempt in the same session.

**Never** express disapproval, assign a score, or move to the next topic leaving
a gap unexplained.

### Worked example of one topic

> **Topic 1 of 4 — the retrospective's part numbers**
>
> The retrospective is an ordered list of parts, and each part's number is
> written down in four separate files: the orchestrator itself, `close` (which
> lists what it runs), `changelog` (whose description names its own position),
> and the README. There's no single source — each states its number
> independently.
>
> That's why `changelog` sat claiming "Part 5" for two releases after `recap`
> took that slot. And `workflow-lint`, the drift checker, didn't catch it: it
> verifies that *names resolve to real files*, not that *numbers agree*.
>
> So — if you added a Part 8 tomorrow, how many files would you expect to touch,
> and would anything tell you if you missed one?

The developer answers from what they were just told. Contrast the first
version's question on the same subject, which asked them to work all of that out
unaided.

### Pace

- **Cap at 4 topics**, and offer an exit at any point.
- A topic where the check lands first time is a topic done. Move on — do not
  manufacture doubt to prove rigour.
- Total target ~10 minutes. If it is running much longer, drop remaining topics
  rather than pressing on.

## Step 5 — Close with the navigation question

Always, however the session went:

> "If this misbehaves in six months, where do you look first, and what would you
> expect to see?"

**If the developer can't answer it, walk through the answer explicitly.** This
question summarises material already taught, so an unanswerable close means the
teaching didn't land — not that the developer has a gap to record. Give the
answer, then note in the orientation note which topic needs revisiting.

## Step 6 — Redact before writing

**Load-bearing: the orientation note can be saved to a committed, pushed path.**

Mask any credential-shaped value — API keys, tokens, passwords, cookies,
connection strings, private keys — before it reaches an explanation, a question,
the note, or `.spwf/learner.md`:

```
api_key="sk-…REDACTED…"
```

Redaction fires before a value enters an **explanation**, not only before the
save: a leaked value printed in the session is already in the transcript, which
no commit hook ever sees.

If you find a hard-coded credential while reading, put it in the note's open
items naming the file but **not** the value.

## Step 7 — Write the orientation note

**A record of what the developer now knows.** Not an inventory of gaps, not a
verdict, no score.

```markdown
## Orientation: {change-id}

### The shape of this change
{2–4 sentences: what moved, what's new, what now depends on what.}

### Where to look when things go wrong
- **{symptom}** → {file/area}, because {reason}
- ...

### Still open
- {only items that survived two explanations} — {what would close it}

### Concepts covered
- {concept} — {one line}
```

**"Where to look when things go wrong" carries the whole purpose.** If the
session produced nothing for it, say so plainly rather than padding it.

If the developer exits partway, write the note for the topics reached. A partial
map beats a discarded session.

Offer to save once:

> "Save this orientation note? [y/N]"

On yes, write to `openspec/changes/{change-id}/understanding.md` (or the
`archive/` path), where it travels into the OpenSpec archive with the change.

## Step 8 — Update the ledger

Per [`_shared/learner-profile.md`](../_shared/learner-profile.md):

- Concepts taught and confirmed → `## Known`, with change-id and date
- **Only** items that survived two explanations → `## Open`, with what would
  close them
- An area appearing under `## Open` more than twice → `## Recurring blind spots`

**Level adjustment is observed, not asked.** If the developer reasons through
consequences unprompted across several topics, promote them for that area and
say so — never silently. Never demote on a single weak answer.

## Report

Standalone:

```
✓ Orientation note for {change-id}
  {N} topics covered · {M} needed a second explanation · {K} still open
{✓ Saved to {path} | — Not saved}
{✓ Ledger updated: {N} concepts → Known}
```

As Part 6 of retrospective, the note is the report — render its sections at
`####` beneath the existing `### Part 6` heading.

## Tone

A colleague explaining their work to someone who'll maintain it, not an examiner
checking whether you did the reading. Concrete, names files, no emoji, no
celebration, no praise inflation.

The promise: *you didn't write this, but you'll know where to start when it
breaks.*
