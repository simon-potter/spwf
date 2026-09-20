# Lean agent discipline — shared convention

How skills and agents spend the two resources that actually run out: the main
session's context, and the reader's attention.

Three rules, all measurable, all easy to violate with good intentions.

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

## Rule 3 — A subagent's report is a claim, not a result

Verify the strongest claim a subagent makes before acting on it. **Especially when
the report is clean.**

A dispatched agent reads a slice of the repo, reasons about it once, and returns
prose. That prose is indistinguishable in shape from a verified finding, and the
dispatcher has no view of what the agent actually looked at. Confidence in the
report is not evidence about the codebase.

### The measurements

Three dispatches, same day, same repo:

| Dispatch | Cost | Outcome |
|---|---|---|
| `reviewer` on a 3.8k-line change | 67,669 tok · 165s | Found a genuine Critical — a README documenting the exact rule the commit existed to overturn |
| `research-scout`, evidence question | 67,140 tok · 134s | 39 lines of evidence; all four cited `path:line` locations verified exact |
| `reviewer` on a 1.4k-line change | 63,632 tok · 255s | **0 Critical, 0 Important, 0 Minor — and wrong.** It explicitly asserted "depth guidance aligns across modules"; the spec required `depth: adaptive`, a value the schema does not define |

The third was found by checking that exact sentence. Nothing else in the report
suggested a problem, and the report had already been believed once.

### Why clean reports deserve more scrutiny, not less

A large change written by one agent in one sitting contains mistakes. That is the
base rate, and it is why the review was dispatched. **A report finding nothing has
therefore either beaten that base rate or failed to look** — and the second is
cheaper to produce than the first.

A report with findings carries its own evidence: you can check the finding. A
report with none carries nothing checkable except its assertions, so those are
what you check.

### What this is not

Not a reason to skip dispatching. Two of the three returned real value, and the
one that missed a defect still cost less than reading 1,400 lines. It is a reason
to treat the return as the **start** of verification rather than the end of it.

Pick the one or two claims the report leans on hardest — the ones that would be
most expensive if false — and check those against the repo directly. Not the whole
report; the load-bearing part.

---

## Scheduled review

> **Reassess once a scout has run on several real changes.** Rule 1's bar is
> stated from a single measurement, and Rule 3's from three. Enough to justify
> writing them down; not enough to calibrate them.
>
> What to watch: how often a dispatch returns something that targeted reads would
> not have found. If the answer is rarely, the bar should rise — or the scout
> should be cut.
