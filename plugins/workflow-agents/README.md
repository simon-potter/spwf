# workflow-agents

Nine specialist subagents covering every workflow phase. Each agent is scoped to a single phase responsibility and right-sized to a model that matches the cognitive demand.

## Agents

| Agent | Phase | Model | Core constraint |
|---|---|---|---|
| `capturer` | Pre-phase | Haiku | Fetches and summarises only — no interpretation, no implementation |
| `specifier` | Phase 1 — Spec | Sonnet | Asks clarifying questions, writes spec artefacts — refuses to suggest implementation |
| `planner` | Phase 2 — Approve plan | Haiku | Reviews the generated task list — quality check + Skeptic/Architect/Minimalist adversarial lenses; does not produce tasks |
| `builder` | Phase 3 — Build | Sonnet | Reads current task, implements it, stops at task boundary |
| `tester` | Phase 4 — Test | Sonnet | Reads code, writes tests, runs suite, reports pass/fail |
| `reviewer` | Phase 5 — Review | Haiku | Reads diff/PR, produces structured review — no edits, one Write for the report |
| `simplifier` | Phase 6 — Simplify | Haiku | Identifies candidates for removal — does not touch tests |
| `shipper` | Phase 7 — Ship | Haiku | Runs deploy checklist, gates on all checks — does not deploy |
| `tdd-expert` | Phase 3 — Build (advisory) | Sonnet | Advises on failing tests to write, reviews test quality, guides Red-Green-Refactor when stuck — does not implement |

## Model rationale

- **Haiku**: Extraction, summarisation, structured output, checklists — tasks where speed matters more than reasoning depth.
- **Sonnet**: Implementation, test writing, review analysis — tasks requiring reasoning and code generation.
