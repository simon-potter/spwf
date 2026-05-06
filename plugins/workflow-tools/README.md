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
| `changelog` | `/workflow-tools:changelog [ref]` | Post — Release notes from conventional commits (atomic) |

## Quality tools

| Skill | Invoke | Responsibility |
|---|---|---|
| `doc-lint` | `/workflow-tools:doc-lint` | Cross-cutting — documentation drift and quality check |
| `agent-optimise` | `/workflow-tools:agent-optimise` | Cross-cutting — agent/skill audit across both scopes |
| `workflow-lint` | `/workflow-tools:workflow-lint` | Cross-cutting — coherence audit of the full golden path |
| `claudemd-curator` | `/workflow-tools:claudemd-curator` | Cross-cutting — audit, refactor, and sync CLAUDE.md and AGENTS.md |
| `workspace-health` | `/workflow-tools:workspace-health` | Cross-cutting — periodic health check: agentlint scan + behavioural audit + sync check |
| `security-scan` | `/workflow-tools:security-scan [path]` | On-demand — deep security review: OWASP Top 10 + SQL injection |
| `dep-audit` | `/workflow-tools:dep-audit` | Pre-PR / on-demand — multi-ecosystem dependency CVE audit; Docker Compose-aware |
| `php-code-simplifier` | `/workflow-tools:php-code-simplifier [path]` | On-demand — PHP-aware refactor: guard clauses, match, nullsafe, DTOs, enums |
| `php-code-quality-reviewer` | `/workflow-tools:php-code-quality-reviewer [path]` | On-demand — PHP bad-practice analysis: correctness, security, performance, maintainability |

## Recommended external skills

These are not part of this plugin but are referenced from within workflow skills when relevant:

| Skill | Source | When referenced |
|---|---|---|
| `semgrep` | `trailofbits/skills` — [skills.sh/trailofbits/skills/semgrep](https://skills.sh/trailofbits/skills/semgrep) | Invoked as `/trailofbits:semgrep`. Referenced by `pr-create` when SAST findings need deep review, and by `approve-plan` when security-sensitive tasks are flagged. Curated rulesets (Trail of Bits + 0xdea + Decurity), SARIF output, `--metrics=off` enforced. Use this instead of raw semgrep for production security review. |

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
