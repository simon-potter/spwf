# workflow-core

Seven-phase workflow skills covering the canonical engineering cycle. All skills set `disable-model-invocation: true` — they are explicit user-triggered checkpoints, not autonomous suggestions.

## Two-tier architecture

Skills are organised in two named tiers within the single `skills/` directory:

- **Atomic skills** — single-responsibility capabilities with descriptive names. Can be invoked directly or composed by orchestrators.
- **Orchestrator skills** — short action names that compose one or more atomic skills. Their body explicitly names the atomics they invoke.

## Skills

### Atomic skills

| Skill | Invoke | Responsibility |
|---|---|---|
| `task-to-spec` | `/workflow-core:task-to-spec` | Convert a challenged ideation file into a full OpenSpec change proposal |
| `plan-signoff` | `/workflow-core:plan-signoff` | Review and quality-check the generated task list; human sign-off gate before building |
| `incremental-implementation` | `/workflow-core:incremental-implementation` | Find the first unchecked task, implement it exactly, mark it done |
| `test-creator` | `/workflow-core:test-creator` | Red phase: write failing tests for the next unchecked task before implementation; confirm they fail |
| `test-runner` | `/workflow-core:test-runner` | Run the full test suite; report pass/fail; stop on first failure |
| `debug-recovery` | `/workflow-core:debug-recovery` | Diagnose a failing test or broken build; apply a minimal fix |
| `pr-reviewer` | `/workflow-core:pr-reviewer <PR>` | Fetch and review a specific PR; produce a structured report |
| `simplify` | `/workflow-core:simplify` | Remove dead code and unnecessary complexity from changed files |
| `ship` | `/workflow-core:ship` | Run pre-PR checks and create the PR; CI/CD owns deployment |

### Orchestrator skills

| Skill | Invoke | Composes |
|---|---|---|
| `build` | `/workflow-core:build` | `test-creator` (Red) → `openspec:apply` (Green) → `test-runner` (Verify) → `debug-recovery` on failure → recommends `simplify` (Refactor) |
| `test` | `/workflow-core:test` | `test-runner` → `debug-recovery` on failure |

## Attribution

Five skills are seeded from [addyosmani/agent-skills](https://github.com/addyosmani/agent-skills) (MIT licence). Each carries an attribution comment in its SKILL.md frontmatter. Simon's additions and adaptations accumulate on top.

| Skill | Source |
|---|---|
| `plan-signoff` | `planning-and-task-breakdown` |
| `incremental-implementation` | `incremental-implementation` |
| `test-runner` | `test-driven-development` |
| `simplify` | `code-simplification` |
| `ship` | `git-workflow-and-versioning` |
| `build` | `incremental-implementation` (orchestrator wrapper) |
| `test` | `test-driven-development` (orchestrator wrapper) |
