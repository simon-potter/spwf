---
# Qualification check inspired by: https://skills.sh/obra/superpowers/brainstorming (obra superpowers) — one-question-at-a-time heuristic gate before proceeding
name: capture
description: Pre-phase orchestrator — Captures a requirement from any source (Jira ticket, existing file, or freeform description) and runs a lightweight qualification check before producing an ideation file. Detects input mode from arguments; prompts if ambiguous. Quick-fails vague or incomplete inputs with one targeted question at a time. Produces todo/{slug}.md ready for /workflow-tools:grill-me.
disable-model-invocation: true
allowed-tools: [Read, Write, Glob, Bash, mcp__atlassian__jira_get_issue, mcp__atlassian__jira_search_issues]
---

# capture

Capture a requirement from any source, qualify it quickly, and produce an ideation file.

## Mode detection

Read `$ARGUMENTS`:

| Input pattern | Mode |
|---|---|
| Empty | **Prompt** — ask which mode |
| `from jira PROJ-123` or just a ticket key | **Jira** — fetch from Atlassian |
| `from todo/…` or a file path ending `.md` | **File** — read existing ideation file |
| Anything else | **Freeform** — treat as raw description |

If empty, ask:

```
Where is this requirement coming from?
1. Jira ticket (provide ticket key)
2. An existing file (provide path)
3. I'll describe it now
```

Wait for the answer before proceeding.

---

## Mode 1 — Jira

Use the Atlassian MCP to fetch the ticket:
- `mcp__atlassian__jira_get_issue` with the ticket key
- Extract: summary, description, acceptance criteria, reporter, labels, priority

Proceed to **Qualify**.

## Mode 2 — File

Read the file at the given path. Treat its content as the raw input.

Proceed to **Qualify**.

## Mode 3 — Freeform

The `$ARGUMENTS` string is the requirement. Treat it as-is.

Proceed to **Qualify**.

---

## Qualify

Lightweight heuristic check — not a deep dive. The goal is to catch obviously incomplete inputs before they waste time in Challenge. Four checks:

| Check | Passes when |
|---|---|
| **Problem clarity** | There is a discernible problem or opportunity being addressed |
| **Actor** | There is at least one named or implied user/system affected |
| **Scope boundary** | It is roughly clear what is in scope (even if vague) |
| **Motivation** | There is a reason this matters (business value, user pain, technical debt) |

For each check that fails, ask **one targeted question** before continuing. Ask questions one at a time — never more than one per message.

**Examples of targeted questions:**
- "Who would use this, and what would they be trying to do?" (missing actor)
- "What problem does this solve — what happens today without it?" (missing motivation)
- "Is there a boundary here — what's explicitly out of scope?" (unclear scope)

**Limit:** After two clarifying questions, proceed regardless. Record any remaining gaps as open questions in the ideation file — Challenge will surface them properly.

If the input clearly passes all four checks without questions: proceed immediately, no delay.

---

## Produce ideation file

Generate `todo/{slug}.md` where `{slug}` is a kebab-case summary of the requirement.

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

For **Jira mode**: map ticket fields directly. Flag any acceptance criteria that are ambiguous or missing as open questions.

For **File mode**: read the existing content and reformat into the ideation file structure if needed. If it already matches the format, leave it and note it was reviewed.

For **Freeform mode**: construct all sections from the description and qualify dialogue.

---

## Report

```
✓ Ideation file created: todo/{slug}.md

Source: {jira PROJ-123 | file path | scratch}
Qualify: {passed cleanly | 1 question asked | 2 questions asked — {N} gaps remain}
Open questions: {count} (will be surfaced in Challenge)

Recommended next step: /workflow-tools:grill-me todo/{slug}.md
```
