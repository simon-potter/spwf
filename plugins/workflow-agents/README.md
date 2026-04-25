# workflow-agents

Twelve specialist subagents covering every workflow phase. Each agent is scoped to a single phase responsibility and right-sized to a model that matches the cognitive demand.

## Agents

| Agent | Phase | Model | Core constraint |
|---|---|---|---|
| `capturer` | Pre-phase — Capture | Haiku | Accepts Jira/file/freeform; delegates to workflow-tools:capture — no interpretation, no implementation |
| `debugger` | Pre-phase — Debug | Sonnet | Systematic root-cause investigation (no fixes); produces todo/BUG-{slug}.md for Challenge |
| `challenger` | Gate — Challenge | Sonnet | Reads ideation file; interviews relentlessly until all gaps closed — does not proceed to spec until resolved |
| `specifier` | Spec | Sonnet | Asks clarifying questions, writes spec artefacts — refuses to suggest implementation |
| `approver` | Approve plan | Haiku | Reviews the generated task list — quality check + Skeptic/Architect/Minimalist adversarial lenses; does not produce tasks |
| `builder` | Build | Sonnet | Reads current task, implements it via opsx:apply, stops at task boundary |
| `tester` | Build — TDD execution | Sonnet | Writes failing tests (Red), runs suite (Verify), reports pass/fail — execution counterpart to tdd-expert |
| `tdd-expert` | Build — TDD advisory | Sonnet | Advises on failing tests to write, reviews test quality, guides Red-Green-Refactor when stuck — does not execute |
| `reviewer` | PR Review | Haiku | Reads diff/PR, produces structured review — no edits, one Write for the report |
| `simplifier` | Simplify | Haiku | Identifies candidates for removal — does not touch tests |
| `pr-creator` | PR Create | Haiku | Runs deploy checklist, gates on all checks — does not deploy |
| `retrospector` | Post-ship — Retrospective | Sonnet | Extracts learnings from commits; audits spec drift; doc-lint pass — produces retrospective report |

## Model rationale

- **Haiku**: Extraction, summarisation, structured output, checklists — tasks where speed matters more than reasoning depth.
- **Sonnet**: Implementation, test writing, review analysis, investigation — tasks requiring reasoning and code generation.
