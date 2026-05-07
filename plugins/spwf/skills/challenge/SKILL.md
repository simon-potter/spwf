---
# Adapted from: https://github.com/mattpocock/skills/grill-me (via npx skills@latest add mattpocock/skills/grill-me). Added $ARGUMENTS file path support and file-first read step.
name: challenge
description: Gate — Challenge a plan, ideation file, or design relentlessly. Accepts a file path as $ARGUMENTS (defaults to the most recent file in todo/ if omitted). Reads the file first, interviews until all open questions are resolved, then runs a scope-sizing check — recommends splitting into multiple changes if the work spans independent boundaries, or proceeding as one change if tightly coupled.
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

## Step 2: Begin the interview

Walk through every aspect of the plan — every decision, every assumption, every open question — asking one question at a time.

For each question:
- Provide your recommended answer based on what you know from the codebase and context
- Wait for the user to confirm, override, or expand
- Do not move to the next question until the current one is resolved

Work through these categories in order, but skip any that are already clearly resolved in the file:

1. **Ambiguous requirements** — any "what we know" item that could be interpreted multiple ways
2. **Open questions** — the explicitly listed ones in the file, one by one
3. **Scope creep risks** — things the rough scope implies but doesn't state
4. **Hidden dependencies** — other systems, people, or decisions this depends on
5. **Failure modes** — what could go wrong at each step
6. **Success definition** — is "done" clearly defined?

If a question can be answered by exploring the codebase, explore it before asking.

## Step 3: Continue until done

Keep going until every branch of the decision tree is resolved. Do not summarise prematurely. Do not accept vague answers — if the answer raises another question, ask it.

The interview is complete only when there are no remaining open questions and the rough scope is unambiguous enough to write a spec from.

## Step 4: Write decisions back to the todo file

Once the interview is complete, update the source todo file:

- Replace the `## Open questions` section with the resolved answers — each question followed by its answer in one or two sentences
- Append a `## Challenge decisions` section listing every new decision made during the interview that was not already in the file
- Do not touch any other section

## Step 5: Scope-sizing check

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

If the scope is large but tightly coupled, recommend structuring `tasks.md` with explicit phases so `build` can commit between phases. Note this in the summary. Proceed to Step 6.

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

## Step 6: Summarise and commit

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
