---
# Adapted from: ~/.claude/skills/jira-to-openspec/ — original by Simon Potter. Strips all OpenSpec generation; output is a lightweight ideation file only.
name: issue-to-task
description: Pre-phase — Capture a Jira ticket as a lightweight ideation file at todo/{slug}.md. Fetches the ticket via MCP, extracts context and open questions, and produces an ideation file ready for /spwf:challenge. Does NOT generate OpenSpec — that is spec's job.
disable-model-invocation: true
allowed-tools: [Read, Write, mcp__atlassian__jira_get_issue, mcp__atlassian__jira_search_issues]
---

# issue-to-task

Fetch a Jira ticket and produce a lightweight ideation file at `todo/{slug}.md`. This file is the input to `challenge` and eventually `spec`. It is intentionally lightweight — not an OpenSpec.

## Step 1: Fetch the ticket

If `$ARGUMENTS` contains a ticket key (e.g. `ABAU-951`), fetch it:

```
mcp__atlassian__jira_get_issue(issue_key="{TICKET}", fields="*all")
```

If no argument given, ask for the ticket key.

## Step 2: Extract content

Parse the Jira ticket (arrives as Jira wiki markup) and extract:

| Jira content | Maps to |
|---|---|
| Summary/title | File title and slug |
| Description overview | Context section |
| Acceptance criteria, must/shall statements | What we know |
| TBD items, questions, blockers | Open questions |
| Ordered task lists, phases, scope | Rough scope |

## Step 3: Derive the slug

```
{ticket-id}-{kebab-case-title}
```

Example: `ABAU-951-add-safeguarding-free-course`

Ensure `todo/` directory exists:
```bash
mkdir -p todo/
```

Check for an existing file at `todo/{slug}.md` before writing.

## Step 4: Write the ideation file

```markdown
---
source: jira
ticket: {TICKET-ID}
created: {YYYY-MM-DD}
status: ideation
---

# {Title}

## Context
{Why this needs doing — extracted from ticket description overview, 2-3 sentences}

## What we know
{Facts, constraints, and acceptance criteria already understood from the ticket}

## Open questions
{TBD items, unknowns, and things requiring stakeholder decision}

## Rough scope
{High-level what needs to change — from ticket task lists and scope description, no implementation detail}
```

## Step 5: Report

```
✓ Ideation file created: todo/{slug}.md

Source: {TICKET-ID}
Title: {title}

Recommended next step: /spwf:challenge todo/{slug}.md
```

Do not generate OpenSpec output. Do not interpret or suggest implementation approaches.
