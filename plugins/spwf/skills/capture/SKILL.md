---
# Qualification heuristic inspired by: https://skills.sh/obra/superpowers/brainstorming (obra superpowers)
# Bug investigation adapted from: https://skills.sh/obra/superpowers/systematic-debugging (obra superpowers)
# Adaptation: investigation-only — stops before implementation; produces an ideation artefact
# that feeds into Challenge → Spec → Build rather than fixing inline.
name: capture
description: Pre-phase orchestrator — accepts any input (Jira ticket, file, or freeform description), classifies it as a bug or a change, then routes to the appropriate path. Bug path runs systematic root-cause investigation and produces todo/BUG-{slug}.md. Change path runs a lightweight qualification check and produces todo/{slug}.md. Both outputs feed /spwf:challenge.
disable-model-invocation: true
allowed-tools: [Read, Write, Glob, Grep, Bash, mcp__atlassian__jira_get_issue, mcp__atlassian__jira_search_issues]
---

# capture

Accept any input, classify it, and produce an ideation file ready for `/spwf:challenge`.

## Step 1 — Fetch input

Read `$ARGUMENTS`:

| Input pattern | Action |
|---|---|
| Empty | Ask: "What are you capturing? (Jira ticket key, file path, or describe it)" |
| `PROJ-123` or `from jira PROJ-123` | **Jira** — fetch with `mcp__atlassian__jira_get_issue` |
| File path ending `.md` | **File** — read existing file |
| Anything else | **Freeform** — treat as-is |

For Jira, extract: summary, description, acceptance criteria, issue type, labels, priority.

---

## Step 2 — Classify: bug or change?

Apply in order — stop at the first confident match.

**Bug signals:**
- Jira `issuetype = Bug`
- Input contains a stack trace (multi-line with file paths and line numbers)
- Input contains: `error`, `exception`, `crash`, `traceback`, `not working`, `broken`, `failing`, `regression`, `500`, `null pointer`, `undefined is not`
- Input starts with `BUG:` or `FIX:`

**Change signals:**
- Jira `issuetype = Story / Task / Epic / Improvement`
- Input contains: `add`, `implement`, `build`, `create`, `new feature`, `support`, `allow`, `as a user`
- Input describes a desired future state

**If ambiguous** — ask one question: *"Is this something that's broken, or something new to build?"* Then route accordingly.

---

## Bug path

### Phase 1 — Gather context

Collect as much of the following as is available:

- Error message and full stack trace (ask the user if not provided)
- Steps to reproduce consistently
- Recent git changes in the relevant area: `git log --oneline -20 -- {relevant paths}`
- Environment context (version, config, runtime)

For multi-component systems, identify at which boundary the failure occurs before assuming a root cause.

### Phase 2 — Root cause investigation

Trace backward from the symptom:

1. Read the error message and stack trace carefully — where does the trace originate?
2. Read the code at the failure site and its callers
3. Check git history for recent changes: `git log --oneline -10 -- {file}`
4. Look for similar working code — compare working vs broken

Document every difference found, however minor.

### Phase 3 — Pattern analysis

Find working code structurally similar to the broken code. Compare completely:

- What assumptions does the working code make that the broken code does not?
- What dependencies differ?
- What does the broken code do that the working code avoids?

### Phase 4 — Form a written hypothesis

Write a single, specific hypothesis:

```
Hypothesis: {The bug is caused by X, because Y. Evidence: Z.}
```

Rules:
- One hypothesis at a time — specific enough to be falsifiable
- Grounded in evidence from Phases 2–3, not assumption
- If three hypotheses fail to explain the evidence: stop and flag that the architecture may need re-examination

### Produce bug artefact

Generate `todo/BUG-{slug}.md`:

```markdown
---
source: jira | scratch
ticket: PROJ-123          # omit if not jira
created: YYYY-MM-DD
status: ideation
type: bug
---

# BUG: {Title}

## Context
{What is broken: observed behaviour vs expected behaviour}

## Reproduction
{Steps to reproduce consistently; "cannot reproduce" if applicable}

## Root cause hypothesis
{The written hypothesis from Phase 4 — specific and evidenced}

## Evidence
{Stack traces, error messages, relevant git log, working vs broken comparison}

## Affected area
{Files, components, or systems involved}

## Open questions
{What remains unclear; gaps that Challenge will surface}

## Rough scope
{What a fix would likely touch; rough complexity estimate}
```

---

## Change path

### Qualify

Lightweight check — catch obviously incomplete inputs before Challenge. Four checks:

| Check | Passes when |
|---|---|
| **Problem clarity** | There is a discernible problem or opportunity being addressed |
| **Actor** | There is at least one named or implied user/system affected |
| **Scope boundary** | It is roughly clear what is in scope (even if vague) |
| **Motivation** | There is a reason this matters (business value, user pain, technical debt) |

For each check that fails, ask **one targeted question** before continuing — never more than one per message.

**Limit:** After two clarifying questions, proceed regardless. Record remaining gaps as open questions — Challenge will surface them.

If the input clearly passes all four checks: proceed immediately, no questions.

### Produce ideation file

Generate `todo/{slug}.md`:

```markdown
---
source: jira | file | scratch
ticket: PROJ-123          # omit if not jira
created: YYYY-MM-DD
status: ideation
---

# {Title}

## Context
{Problem or opportunity — from description or qualify dialogue}

## What we know
{Concrete facts, constraints, or acceptance criteria from the input}

## Open questions
{Gaps that remain after qualify; may be empty if input was complete}

## Rough scope
{What's in scope; note anything explicitly out of scope}
```

---

## Report

**Bug path:**
```
✓ Bug artefact created: todo/BUG-{slug}.md

Source: {jira PROJ-123 | scratch}
Classified as: bug ({signal that triggered classification})
Hypothesis: {one-line summary}
Open questions: {count}

Recommended next step: /spwf:challenge todo/BUG-{slug}.md
```

**Change path:**
```
✓ Ideation file created: todo/{slug}.md

Source: {jira PROJ-123 | file path | scratch}
Classified as: change ({signal that triggered classification, or "confirmed by user"})
Qualify: {passed cleanly | 1 question asked | 2 questions asked — {N} gaps remain}
Open questions: {count}

Recommended next step: /spwf:challenge todo/{slug}.md
```
