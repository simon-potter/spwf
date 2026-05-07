---
# Adapted from: ~/.claude/skills/jira-to-openspec/ — original by Simon Potter. Strips all OpenSpec generation; output is a lightweight ideation file only. Tracker-agnostic via _shared/tracker-dispatch.md (YouTrack default; Jira and others supported).
name: issue-to-task
description: Pre-phase — Capture an issue tracker ticket (YouTrack default; Jira and others supported) as a lightweight ideation file at todo/{slug}.md. Fetches the ticket via the configured tracker MCP, extracts context and open questions, and produces an ideation file ready for /spwf:challenge. Does NOT generate OpenSpec — that is spec's job.
disable-model-invocation: true
allowed-tools: [Read, Write, mcp__youtrack__*, mcp__atlassian__jira_get_issue, mcp__atlassian__jira_search_issues]
---

# issue-to-task

Fetch an issue tracker ticket and produce a lightweight ideation file at `todo/{slug}.md`. This file is the input to `challenge` and eventually `spec`. It is intentionally lightweight — not an OpenSpec.

This skill is by definition tracker-bound. If no tracker MCP is configured, it fails
fast — see `_shared/tracker-dispatch.md` for setup. Tracker selection follows the
default probe (YouTrack → Jira) unless overridden in `.spwf/tracker.yaml`.

## Step 1: Fetch the ticket

If `$ARGUMENTS` contains a ticket id (e.g. `ACAD-42`, `PROJ-123`), dispatch to the
active tracker's `get_issue` operation:

```
get_issue(id="{TICKET}", include_all_fields=true)
```

If `$ARGUMENTS` is empty, ask for the ticket id.

**Fail fast on missing MCP.** If neither `mcp__youtrack__*` nor `mcp__atlassian__jira_*`
is available, stop with: *"No issue tracker MCP configured. Add YouTrack or Atlassian
MCP in user settings — see plugins/spwf/skills/_shared/tracker-dispatch.md."* Do not
fall back to interactive content gathering — the user invoked this skill specifically
to fetch from a tracker.

## Step 2: Extract content

Parse the ticket body (markdown for YouTrack, wiki markup for Jira — both supported) and
extract:

| Ticket content | Maps to |
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

Example: `ACAD-42-add-feature-name`

Ensure `todo/` directory exists:
```bash
mkdir -p todo/
```

Check for an existing file at `todo/{slug}.md` before writing.

## Step 4: Write the ideation file

```markdown
---
source: youtrack | jira | linear
tracker: {tracker}
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
