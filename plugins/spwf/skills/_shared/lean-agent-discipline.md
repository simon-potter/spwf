# Lean agent discipline — shared convention

How skills and agents spend the two resources that actually run out: the main
session's context, and the reader's attention.

Two rules, both measurable, both easy to violate with good intentions.

---

## Rule 1 — A subagent must be cheaper than reading the files

Dispatching a subagent is not free and is not automatically leaner. It costs a
prompt, a cold context, a round trip, and a compression step that flattens nuance
on the way back.

**Justified when the work is:**

- **broad** — the answer could be in any of many places
- **repetitive** — the same check across many files
- **noisy** — logs, generated output, or large search results that would otherwise
  land in the main session
- **independent** — a concern that can be answered without the main thread's state

**Not justified when a few targeted reads would answer the question.** If you know
which three files hold the answer, read them.

### The measurement behind this

This is evidence, not taste.

During the challenge that produced this convention, one subagent was dispatched to
review a branch diff. It cost:

```text
165 seconds · 67,669 tokens · 22 tool calls
```

It returned **one** real finding: a single wrong word in a README table row.
Reading that row directly would have cost seconds and a few hundred tokens.

The dispatch was not wrong — the diff was large and the concern was genuinely
broad. But the ratio is the point. A subagent that returns one line you could have
grepped for has not saved context; it has spent a great deal to move a small
amount of work off the main thread.

**The test before dispatching:** *could I answer this by reading three files I can
already name?* If yes, read them.

---

## Rule 2 — Return findings, not a narrative of the search

A subagent's return is consumed by a main session that is short of room. It gets
the conclusion, not the journey.

**Return:**

```text
finding · path:line · why it matters
```

**Do not return** a narrative of how the search was performed — which greps were
run, which directories were walked, what turned out to be a dead end. That belongs
in the research trace ([`evidence-schema.md`](evidence-schema.md)), bounded to ten
lines, if it is worth recording at all.

An agent that reports its process is reporting the expensive part and withholding
the useful part.

### Narration during autonomous work

Visible output while a skill is working is for **decisions, blockers, deviations,
and security or destructive warnings**. Not for progress.

A completion report is a status block:

```text
✓ Task 3.2 complete
  Changed: 3 files · Verified: 18 tests pass · Deviation: none
```

**Exemption — deliberate human-facing explanation.** This rule governs narration
emitted as a side effect of doing something else. It does not govern skills whose
prose *is* the deliverable and whose audience is the developer: `brief`, `recap`
and `understand` are exempt. Compressing those to a status block deletes the
capability rather than the noise.

The test: *would the developer have asked for this text?* Narration fails it; a
brief passes it.

---

## Scheduled review

> **Reassess once a scout has run on several real changes.** Rule 1's bar is
> stated from a single measurement. One data point is enough to justify writing
> the rule down and not enough to calibrate it.
>
> What to watch: how often a dispatch returns something that targeted reads would
> not have found. If the answer is rarely, the bar should rise — or the scout
> should be cut.
