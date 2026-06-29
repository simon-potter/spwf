---
# Adapted from: ~/.claude/skills/jira-to-openspec/ — original by Simon Potter. Strips all OpenSpec generation; output is a lightweight ideation file only. Tracker-agnostic via _shared/tracker-dispatch.md (YouTrack default; Jira and others supported).
name: issue-to-task
description: Pre-phase — Capture an issue tracker ticket (YouTrack default; Jira, Beads via spwf-beadsify, and others supported via tracker-dispatch) as a lightweight ideation file at todo/{slug}.md. Fetches the ticket via the configured tracker (MCP or skill backend), extracts context and open questions, and produces an ideation file ready for /spwf:challenge. Does NOT generate OpenSpec — that is spec's job.
disable-model-invocation: true
allowed-tools: [Read, Write, Bash, mcp__youtrack__*, mcp__atlassian__jira_get_issue, mcp__atlassian__jira_search_issues, mcp__atlassian__jira_update_issue]
---

# issue-to-task

Fetch an issue tracker ticket and produce a lightweight ideation file at `todo/{slug}.md`. This file is the input to `challenge` and eventually `spec`. It is intentionally lightweight — not an OpenSpec.

This skill is by definition tracker-bound. If no tracker is available, it fails
fast — see `_shared/tracker-dispatch.md` for setup. Tracker selection: read
`.spwf/tracker.yaml` if present; otherwise probe MCP defaults (YouTrack → Jira).
Skill backends (e.g. Beads via spwf-beadsify) are opt-in — only used when
`.spwf/tracker.yaml` sets `tracker:` to a skill-backend value.

## Step 1: Fetch the ticket

If `$ARGUMENTS` contains a ticket id (e.g. `ACAD-42`, `PROJ-123`, `spwf-a3f2dd`),
dispatch to the active tracker's `get_issue` operation per `_shared/tracker-dispatch.md`:

```
get_issue(id="{TICKET}", include_all_fields=true)
```

If `$ARGUMENTS` is empty, ask for the ticket id.

**Fail fast on missing tracker.** If the active tracker is not available in this
session (and `tracker:` isn't `none`), stop with the dispatch-resolved error and do
not silently fall back to interactive content gathering — the user invoked this
skill specifically to fetch from a tracker. "Available" depends on backend type
(see `_shared/tracker-dispatch.md` § "Backend types"):

- **MCP backend** (`tracker: youtrack` / `jira`, or unset and one of the MCPs is
  configured): available iff the MCP's tools (`mcp__youtrack__*`,
  `mcp__atlassian__jira_*`) respond. If neither responds and `tracker:` is unset,
  halt with: *"No issue tracker MCP configured. Add YouTrack or Atlassian MCP in
  user settings, or set `tracker: beads` and install spwf-beadsify for an in-repo
  tracker. See `plugins/spwf/skills/_shared/tracker-dispatch.md`."*
- **Skill backend** (`tracker: beads`): available iff the backend module SKILL.md is
  loadable in the current session. If not, use the verbatim error from
  `_shared/tracker-dispatch.md` § "Configured-but-not-installed error".
- **Opted out** (`tracker: none`): halt with: *"Tracker integration is opted out
  for this repo (`tracker: none`). Cannot fetch a ticket — use `/spwf:new-task`
  instead."*

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

## Step 4b: Move the ticket to in-progress

Fetching the ticket into a todo means work has begun, so move it to the project's
start state — the transition the SPWF lifecycle expects at capture time
(stage → Doing). Resolve `start_state` from `.spwf/tracker.yaml` (default
`In Progress`; kanban / YouTrack boards typically set `Doing`) and dispatch
`set_state` per `_shared/tracker-dispatch.md`.

- Skip silently if `tracker: none` or `start_state: none`.
- Skip if the ticket is already in `start_state` or a later state (in-review /
  done / closed) — **never move a ticket backward**.
- Otherwise `set_state(id="{TICKET}", state="{start_state}")`.

**Courtesy flip — never blocks.** The ideation file is the deliverable. On
failure (auth, network, unknown state name) emit one soft note and continue:

```
ℹ Couldn't move {TICKET} to "{start_state}" ({reason}). Set it manually, or
  configure `start_state:` in .spwf/tracker.yaml (or `start_state: none` to skip).
```

## Step 5: Report

```
✓ Ideation file created: todo/{slug}.md

Source: {TICKET-ID}
Title: {title}
{Ticket: {TICKET-ID} → {start_state}   | ticket already {state}   | omit if start_state: none}

Recommended next step: /spwf:challenge todo/{slug}.md
```

Do not generate OpenSpec output. Do not interpret or suggest implementation approaches.
