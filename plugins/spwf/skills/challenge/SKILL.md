---
# Adapted from: https://github.com/mattpocock/skills/grill-me (via npx skills@latest add mattpocock/skills/grill-me). Added $ARGUMENTS file path support and file-first read step. Extended beyond the upstream cooperative interview with: an explicit question map for provable coverage, a 13-dimension probe taxonomy, an adversarial pass (premortem + red-team, drawing on grill-with-docs/domain-modeling rigor), and a completeness self-audit.
name: challenge
description: Gate — Challenge a plan, ideation file, or design relentlessly. Accepts a file path as $ARGUMENTS (defaults to the most recent file in todo/ if omitted). Builds an explicit question map, interviews one question at a time across a 13-dimension taxonomy, runs an adversarial premortem + red-team pass, then a completeness self-audit so coverage is provable rather than vibes — finishing with a scope-sizing check that recommends splitting independent work or proceeding as one change.
disable-model-invocation: true
allowed-tools: [Read, Write, Grep, Glob, Bash]
---

# challenge

Read the target file. Then interview relentlessly about every aspect of the plan until all open questions are resolved.

## Step 1: Identify the target file

If `$ARGUMENTS` contains a file path, read that file.

If no argument given, find the most recently created file in `todo/`:

```bash
ls -t todo/*.md | head -1
```

Read the file completely.

## Step 2: Build the question map

Before interviewing, enumerate the decision tree so coverage is **provable, not a
feeling** — this is what stops a challenge from being "light." Produce an explicit
working checklist (in your reply, not the file yet) of every point that must be
resolved, drawn from:

- Every `## What we know` item open to more than one reading
- Every entry in `## Open questions`
- Every dimension in the taxonomy below that plausibly applies

The interview is not complete until every item on the map is either **resolved**
or **consciously marked N/A with a one-line reason** — never silently skipped.
Silent skipping is the failure mode this map exists to prevent.

### Probe taxonomy

Walk these in order. For each: ask (one question at a time) or mark `N/A — {reason}`.

1. **Ambiguous requirements** — any "what we know" item open to multiple readings
2. **Open questions** — the explicitly listed ones, one by one
3. **Scope creep risks** — what the rough scope implies but doesn't state
4. **Explicit non-goals** — what is deliberately out of scope (state it, don't leave it implied)
5. **Hidden dependencies** — other systems, people, data, or decisions this rides on
6. **Alternatives considered** — which approaches were rejected and why (guards against tunnel vision)
7. **Non-functional requirements** — performance, security, accessibility, scale, data volume, concurrency, cost
8. **Edge & boundary cases** — empty / null / zero, maximum, duplicate, concurrent, partial failure
9. **Backwards-compat & migration** — existing data, users, and API consumers; rollout and rollback path
10. **Failure modes** — what breaks at each step, and what happens when it does
11. **Observability & testability** — how we'll know it works, debug it, and verify it
12. **Reversibility / blast radius** — how hard to undo; the worst realistic outcome
13. **Success definition** — is "done" unambiguous and measurable?

## Step 3: Interview — one question at a time

Drive the map to zero. For each unresolved item:

- Provide your recommended answer from the codebase and context — **explore the codebase before asking** when it can answer the question
- Ask exactly one question; wait for the user to confirm, override, or expand
- Do not advance until it is resolved; if an answer raises a new question, add it to the map and resolve that too
- Do not accept vague answers

Walk down each branch of the decision tree, resolving dependencies between
decisions one by one. Tick items off the map as they resolve.

## Step 4: Adversarial pass

Cooperative questioning surfaces what the planner already half-knows; this step
**attacks the plan** to surface what they don't. It is where "misses nothing"
actually comes from — do not skip it.

1. **Premortem.** Pose: *"Assume this shipped and failed badly in production six
   months from now — what went wrong?"* Generate 3–5 **concrete, evidence-grounded**
   failure stories (not vague hypotheticals). For each plausible one, ask the
   question it implies and resolve it.
2. **Red-team the riskiest decisions.** Take the 2–3 highest-stakes or
   least-certain decisions from the map and argue the *opposing* case for each
   ("a skeptic would say…"). Any decision that can't survive its counter-argument
   goes back onto the map for resolution.

Every new issue found here re-enters Step 3.

## Step 5: Completeness self-audit

Before declaring done, run one explicit meta-check — the guard against a
*confidently incomplete* interview:

- Is every item on the question map resolved or consciously marked N/A?
- For each dimension marked N/A: is it genuinely irrelevant, or did I dodge it?
- *"What would a domain expert in this area notice is still missing?"* — answer
  honestly; resolve anything that surfaces.

State the outcome: either **"no open items — every branch resolved,"** or the
explicit **residual risks** carried into spec, each tagged with confidence. The
challenge is complete only when the map is clear and this audit surfaces nothing
new. Do not summarise before this passes.

## Step 6: Write decisions back to the todo file

Once the interview, adversarial pass, and self-audit are complete, update the source todo file:

- Replace the `## Open questions` section with the resolved answers — each question followed by its answer in one or two sentences
- Append a `## Challenge decisions` section listing every new decision made during the interview that was not already in the file (include the ones surfaced by the premortem / red-team in Step 4)
- If the self-audit (Step 5) carried any **residual risks** into spec, append a `## Residual risks` section listing each with its confidence — so spec and build inherit them explicitly rather than rediscovering them
- Do not touch any other section

## Step 7: Scope-sizing check

With all questions resolved and the rough scope now clear, assess whether this is one coherent OpenSpec change or whether it should be split.

### Split signals — recommend splitting if two or more are true

| Signal | Description |
|---|---|
| **Independent deployability** | Part A could ship and be useful without Part B |
| **Natural system boundary** | Parts touch different layers, services, or teams |
| **Different risk profiles** | One part is safe/mechanical; another is exploratory or risky |
| **Scope suggests > 2 phases** | The rough scope breaks into phases that have no dependencies on each other |
| **Different "done" definitions** | Success for part A looks nothing like success for part B |

### Keep-as-one signals — proceed as single change if any are true

| Signal | Description |
|---|---|
| **Tight coupling** | The parts only make sense shipped together |
| **Single user journey** | One unbroken flow from the user's perspective |
| **Shared data model change** | A migration or schema change that both parts depend on |

### Outcomes

**If keeping as one change:**

If the scope is large but tightly coupled, recommend structuring `tasks.md` with explicit phases so `build` can commit between phases. Note this in the summary. Proceed to Step 8.

**If splitting is recommended:**

Present the proposed split clearly:

```
Scope check: this work spans independent boundaries and would be cleaner as
separate changes.

Proposed split:
  1. {slug-a} — {one sentence: what this delivers and why it stands alone}
  2. {slug-b} — {one sentence: what this delivers and why it stands alone}
  {3. ...}

Original ticket ({PROJ-123 or slug}) stays as the parent — each child references it.

Confirm split? (yes / no — 'no' keeps it as a single change)
```

**If split confirmed:**

- Write a new `todo/{slug-a}.md` and `todo/{slug-b}.md` (etc.) using the ideation file format, carrying over `ticket:` if present and setting `status: ideation`
- Update the original todo file: set `status: split`, add a `## Split into` section listing the child file paths
- Do not create OpenSpec changes yet — each child will go through `spec` independently

**If split declined:**

Note "kept as one change" in the summary and proceed.

---

## Step 8: Summarise and commit

Print the summary:

```
Challenge complete. All questions resolved.

Key decisions made:
- {decision 1}
- {decision 2}
...
```

Show `git diff todo/` so the user can see what changed, then propose a commit.

**If kept as one change:**
```
docs: challenge {slug} — resolve open questions

Decisions made:
- {decision 1}
- {decision 2 — include any gotcha or non-obvious constraint that emerged}

{note any surprises from codebase exploration}
{note if large scope: "structured as N phases in tasks.md due to size"}
```

**If split:**
```
docs: challenge {slug} — split into {N} changes

{slug-a}: {one sentence}
{slug-b}: {one sentence}

Original marked status: split. Each child carries ticket: {PROJ-123}.
```

Ask: "Ready to commit? Confirm with 'yes' or edit the message first."

After confirming, stage all affected todo files and commit:

```bash
git add todo/
git commit -m "{confirmed message}"
```

**Recommended next step:**
- Single change: `/spwf:spec todo/{slug}.md`
- Split: `/spwf:spec todo/{slug-a}.md` (then repeat for each child)
