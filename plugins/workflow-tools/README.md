# workflow-tools

Extended workflow skills covering the phases that surround the seven canonical phases: capturing ideas before spec, challenging them before committing, and extracting learnings after shipping.

All skills set `disable-model-invocation: true`.

## Skills

| Skill | Invoke | Phase |
|---|---|---|
| `capture` | `/workflow-tools:capture [source]` | Pre — Capture (orchestrator) |
| `debug` | `/workflow-tools:debug [ticket or description]` | Pre — Capture for bugs |
| `issue-to-task` | `/workflow-tools:issue-to-task` | Pre — Capture from Jira (atomic) |
| `new-task` | `/workflow-tools:new-task` | Pre — Capture from scratch (atomic) |
| `challenge` | `/workflow-tools:challenge [file]` | Gate — Challenge |
| `grill-me` | `/workflow-tools:grill-me [file]` | Gate — Challenge (deprecated: use challenge) |
| `learn-from-mistakes` | `/workflow-tools:learn-from-mistakes` | Post — Retrospective (atomic) |
| `retrospective` | `/workflow-tools:retrospective` | Post — Retrospective (orchestrator) |

## Quality tools

| Skill | Invoke | Responsibility |
|---|---|---|
| `doc-lint` | `/workflow-tools:doc-lint` | Cross-cutting — documentation drift and quality check |
| `agent-optimise` | `/workflow-tools:agent-optimise` | Cross-cutting — agent/skill audit across both scopes |
| `workflow-lint` | `/workflow-tools:workflow-lint` | Cross-cutting — coherence audit of the full golden path |

## Ideation file format

Both `issue-to-task` and `new-task` produce the same lightweight ideation file at `todo/{slug}.md`. This format is the input to `challenge` and `spec`.

```markdown
---
source: jira | scratch
ticket: PROJ-123          # omit if scratch
created: YYYY-MM-DD
status: ideation
---

# {Title}

## Context
## What we know
## Open questions
## Rough scope
```
