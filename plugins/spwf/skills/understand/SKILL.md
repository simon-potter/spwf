---
# Adapted from: https://github.com/AnthonyPAlicea/skills — skills `do-i-understand`
# and `do-i-understand-the-ux`. Concepts adapted: interviewing the developer rather
# than reviewing the code, one question at a time, "I don't know" as a welcome
# finding, the anti-quiz posture, anti-gaming rules, and the closing exposure
# question. Quiz-mode concepts (conceptual/practical split, wrong-answer breakdown)
# noted from rohitg00/ai-engineering-from-scratch skill `check-understanding` and
# deferred to a future --recall mode. No SKILL.md content reproduced verbatim from
# any source.
name: understand
description: Post-ship — Build a navigational understanding of a change an agent wrote, so you know where to look when it breaks later. Interviews you, not the code, one question at a time about the structural changes and the concepts behind them, at orientation depth rather than line-level fidelity. Calibrated via .spwf/learner.md. Produces an orientation note and records open gaps in the learner ledger. Companion to recap, which explains what and why; this covers consequence and navigation. Retrospective Part 6; runnable standalone via /spwf:understand [change-id | todo path | branch].
disable-model-invocation: true
allowed-tools: [Read, Glob, Grep, Bash, Write, Edit]
---

# understand

**The goal: when this breaks in six months, you know where to look and why.**

Not hand-coded-level fidelity — navigational understanding. Enough to orient,
not enough to have written it. Companion to `learn-from-mistakes` (which teaches
the project) and `recap` (which explains the change); this one asks *you*.

> **No `AskUserQuestion` in `allowed-tools`, deliberately.** That tool is
> structurally multiple-choice, and a multiple-choice question over material the
> developer just read tests recognition, not understanding. Ask in plain
> conversational text, one question per message. `challenge` omits the tool for
> the same reason.

## Step 1 — Resolve the change

Read `$ARGUMENTS`. Accept any of:

| Input | Resolution |
|---|---|
| Empty | Detect from the current branch, or the most recent change. Ask if ambiguous. |
| change-id (e.g. `add-user-export`) | `openspec/changes/{id}/`, falling back to `openspec/changes/archive/{id}/` |
| Todo path ending `.md` | Read frontmatter to derive the change-id; resolve as above |
| Branch name or commit range (`HEAD~5..HEAD`) | Use directly — for standalone runs outside the golden path |

When invoked as Part 6 of `retrospective`, the change-id is passed explicitly —
skip detection.

If nothing resolves, halt naming both searched locations:

```
Cannot find change "{arg}" in openspec/changes/ or openspec/changes/archive/.
```

Do not fall back to interviewing on a different change.

## Step 2 — Load the learner profile

Read `.spwf/learner.md` per
[`_shared/learner-profile.md`](../_shared/learner-profile.md).

**If absent**, ensure `.spwf/learner.md` is in `.gitignore` (add it if not — the
file records personal gaps and must never be committed), then ask one
calibration question:

> "Before we start — roughly where are you with this codebase and its stack:
> new to it, working in it comfortably, or fluent? I'll pitch the framing
> accordingly."

Create the file with that answer. **Never ask this again on later runs.**

**Level governs framing and vocabulary only. It never lowers the bar.** `new`
gets more scaffolding and concepts named before they're probed; `fluent` gets
terser framing and fewer questions. Nobody gets easier questions — if level
lowered rigour, this would be theatre and the ledger a record of flattery.

Use `## Known` to avoid re-explaining concepts already demonstrated, and
`## Open` / `## Recurring blind spots` to weight what's worth revisiting.

## Step 3 — Read the structure

**Read the shape of the change, not every line.**

```bash
RANGE="$(git merge-base HEAD "${BASE:-main}")..HEAD"   # or the resolved range
git diff --stat $RANGE
git log $RANGE --format="%h %s%n%b"
```

Then read **only the changed files that carry structural weight** — a new
module, a new dependency, a changed interface, a shifted data flow. Supporting
material, read second and only if it exists: `openspec/changes/{id}/design.md`,
`proposal.md`, and the original `todo/{slug}.md`.

**Do not read the full diff.** At orientation depth it is fidelity the interview
has already decided not to use, and it makes large changes needlessly expensive.
`--stat` plus selective reads is the target.

**Design docs are supporting, never primary.** The gap being closed is *what the
agent decided on its own* — and those decisions by definition aren't in
`design.md`, because nobody wrote them there. An interview built from design
docs probes the decisions you already made yourself, which are the ones you
already understand.

### Triage — pick 3–5, say which and why

From the structural picture, choose the **3–5 changes that would matter most if
something went wrong later**. State the selection before starting:

```
Looking at three things: the new export queue (new async path), the S3 client
(new external dependency), and the changed `UserExport` interface (four
callers). Skipping the config rename and the test fixtures — nothing to
navigate there.
```

**Trivial change?** Say so and stop:

```
Nothing here you'd need to navigate later — {one-line summary}. Skipping.
```

Better to admit small than manufacture depth.

## Step 4 — The interview

**One question per message, then wait.** Never dump a list; the follow-up
depends on the answer.

Name the file or area under discussion so it's locatable. **No line-number
ceremony** — line numbers drift, and at this depth they're precision the
conversation doesn't need.

### Fidelity target

Every question must be answerable by someone who understands the shape and
consequences of the change **without having written it**.

**Out of range** — discard and replace any question about: null-check
placement, guard clauses, individual error branches, naming, or anything else
answerable only by whoever typed the line.

### Question shapes

**This is not a question bank.** These are worked examples of the derivation.
If every question you ask maps back to this list, you're pattern-matching rather
than interviewing — derive from what the change actually contains, and expect to
build shapes these don't anticipate.

- **Blast radius** — "the export now goes through the queue. What else is on
  that queue, and what happens to this when it backs up?"
- **Road not taken** — where `design.md` records a decision: "why this approach
  and not the alternative? What would have gone wrong?"
- **Where it touches** — "which parts of the system now depend on this that
  didn't before?"
- **Failure shape** — "when this breaks, what does it look like from the
  outside — slow, wrong, or loud?"
- **New dependency** — "we've taken on {library}. What does it do for us that we
  weren't doing before, and what happens if it's unavailable?"
- **Concept transfer** — "the same pattern is used in {other place in this
  repo}. What's different about how it's done there?"

### Interview discipline

1. **Not a quiz.** No score, no grade, no pass/fail. If a question has one
   gradable answer, broaden it until it doesn't.
2. **"I don't know" is a finding, and a welcome one.** Record it, note what
   would close it, move on. Never re-ask it, never express disapproval. A
   developer who feels graded stops disclosing, and disclosure is the whole
   instrument.
3. **Answers in your own words.** If the developer has to ask the model, that
   *is* the gap — routing the question back relocates it rather than closing it.
   Note it and continue.
4. **No tasks.** Never ask the developer to change, run, or edit code. Every
   question is answered in words, from the chair. Frame hypotheticals explicitly
   as thought experiments, never as instructions to modify anything.
5. **Grounded answers close lines of questioning.** Three questions well
   answered is the instrument working, not a lack of rigour. Do not manufacture
   doubt — it teaches the developer to perform for the interview instead of
   think in it.
6. **Cap at ~8 questions**, hard, and offer an exit at any point. An ignored
   check is worth nothing.
7. **No emoji, no celebration, no praise inflation.**

### Do not re-ask what `recap` explained

When running as Part 6, `recap` has just covered this change in Part 5. Asking
about material the developer read ninety seconds ago tests short-term memory,
not understanding — the same recognition-not-recall failure that rules out a
quiz format.

| | `recap` (Part 5) | `understand` (Part 6) |
|---|---|---|
| Covers | **what** changed and **why** | **consequence** and **navigation** |
| Answers | "what did this do?" | "where do I look when it breaks?" |
| Mode | prints, you read | asks, you answer |

If a candidate question's answer appears in the recap output already on screen,
discard it and substitute one probing consequence or navigation.

**Standalone-later is the stronger mode**, and worth saying so when it comes up:
spaced retrieval beats immediate retrieval. The Part 6 hook exists so the option
is visible while the change is on your mind, not because close is the optimal
moment.

### Close with the navigation question

Always, however the rest went:

> "If this misbehaves in six months, where do you look first, and what would you
> expect to see?"

This is the skill's whole purpose as a single question. If the interview went
well, it should be answerable.

## Step 5 — Redact before writing

**Load-bearing: the orientation note is saved to a committed, pushed path.**

Before any credential-shaped value reaches a question, the orientation note, or
`.spwf/learner.md`, mask it — API keys, tokens, passwords, cookies, connection
strings, private keys:

```
api_key="sk-…REDACTED…"
```

Quote only enough context to locate what's being discussed.

If you encounter a hard-coded credential while reading, record it in the note's
**Still fuzzy** section naming the file but **not** the value — it's a finding
about the code, not a question about the developer's understanding.

## Step 6 — Write the orientation note

**A map for future-you, not an attestation for a reviewer.** No merge verdict,
no readiness recommendation, no verbatim transcript — those belong to a
pre-merge accountability check, which this is not.

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
- {concept} — {one line; only concepts new to the ledger}
```

**"Where to look when things go wrong" carries the whole purpose.** If the
interview produced nothing for it, the interview failed — however well the other
questions went. Say so rather than padding the section.

If the developer exits partway, still write the note covering what was
discussed. A partial map beats a discarded session.

Offer to save once:

> "Save this orientation note? [y/N]"

On yes, write to `openspec/changes/{change-id}/understanding.md` (or the
`archive/` path), where it travels into the OpenSpec archive with the change.

## Step 7 — Update the ledger

Per [`_shared/learner-profile.md`](../_shared/learner-profile.md), update
`.spwf/learner.md`:

- Concepts the developer demonstrated → `## Known`, with change-id and date
- Gaps that surfaced → `## Open`, with what would close them
- An area appearing under `## Open` more than twice → `## Recurring blind spots`

**Level adjustment is observed, not asked.** When a developer traces a
consequence without prompting, promote them on that area and say so — never
silently. Never demote on a single weak answer; recurring blind spots carry that
signal instead.

## Report

Standalone:

```
✓ Orientation note for {change-id}
  {N} questions · {M} gaps recorded
{✓ Saved to {path} | — Not saved}
{✓ Ledger updated: {N} concepts → Known, {M} → Open}
```

As Part 6 of retrospective, the note itself is the report — render its sections
at `####` beneath the existing `### Part 6` heading.

## Tone

Curious, not prosecutorial — an ally helping you build a map you'll need later,
not an examiner. The promise: *don't imitate the agent's output; understand its
shape well enough to navigate it when it matters.*
