---
# Adapted from: https://skills.sh/obra/superpowers/systematic-debugging (obra superpowers)
# Adaptation: investigation-only — stops before implementation; produces an ideation artefact
# that feeds into the standard workflow (Challenge → Spec → Build) rather than fixing inline.
name: debug
description: Pre-phase entry point for bugs — Accepts a Jira ticket or freeform description, runs systematic root-cause investigation (no fixes), forms a written hypothesis, and produces todo/BUG-{slug}.md ready for /workflow-tools:grill-me. Investigation happens before any fix is attempted. Use whenever an issue occurs.
disable-model-invocation: true
allowed-tools: [Read, Write, Glob, Grep, Bash, mcp__atlassian__jira_get_issue, mcp__atlassian__jira_search_issues]
---

# debug

**NO FIXES WITHOUT ROOT CAUSE INVESTIGATION FIRST.**

Investigate the issue systematically, document findings, form a written hypothesis, and produce an ideation artefact. The fix happens later — via Challenge → Spec → Build — not here.

## Mode detection

Read `$ARGUMENTS`:

| Input | Mode |
|---|---|
| `PROJ-123` or `from jira PROJ-123` | **Jira** — fetch ticket |
| Anything else | **Freeform** — treat as bug description |

If empty, ask: "What is the issue? (Jira ticket key, or describe what's broken)"

---

## Phase 1 — Gather context

Collect as much of the following as is available:

- Error message and stack trace (ask the user if not provided)
- Steps to reproduce consistently
- Recent git changes in the relevant area: `git log --oneline -20 -- {relevant paths}`
- System/environment context (version, config, runtime)

For multi-component systems, identify at which boundary the failure occurs before assuming a root cause.

---

## Phase 2 — Root cause investigation

Trace backward from the symptom:

1. Read the error message and stack trace carefully — where does the trace originate?
2. Read the code at the failure site and its callers
3. Check git history for recent changes to that area: `git log --oneline -10 -- {file}`
4. Look for similar working code in the codebase — compare working vs broken

Document every difference found, however minor. Do not skip anything because it seems unrelated.

---

## Phase 3 — Pattern analysis

Find working code that is structurally similar to the broken code. Compare completely:

- What assumptions does the working code make that the broken code does not?
- What dependencies differ?
- What does the broken code do that the working code avoids?

---

## Phase 4 — Form a written hypothesis

Write a single, specific hypothesis:

```
Hypothesis: {The bug is caused by X, because Y. Evidence: Z.}
```

Rules:
- One hypothesis at a time
- Specific enough to be falsifiable
- Grounded in evidence from Phases 2–3, not assumption
- If the evidence does not support a clear hypothesis: record what is unknown as open questions

**Three-attempt limit**: If three hypotheses have been formed and none explain the evidence, stop and flag that the architecture may need re-examination. Do not continue guessing.

---

## Produce artefact

Generate `todo/BUG-{slug}.md` where `{slug}` is a kebab-case summary of the bug.

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

## Report

```
✓ Bug artefact created: todo/BUG-{slug}.md

Source: {jira PROJ-123 | scratch}
Hypothesis: {one-line summary}
Open questions: {count}

Recommended next step: /workflow-tools:grill-me todo/BUG-{slug}.md
```
