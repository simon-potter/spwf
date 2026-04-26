# workflow-core

Seven-phase workflow skills covering the canonical engineering cycle. All skills set `disable-model-invocation: true` — they are explicit user-triggered checkpoints, not autonomous suggestions.

**Plugin boundary rule:** if a skill reads or writes `openspec/changes/` or `openspec/specs/` — or is only useful in a project where `openspec init` has been run — it belongs here. Skills that work on any repo regardless of OpenSpec belong in `workflow-tools`.

## Two-tier architecture

Skills are organised in two named tiers within the single `skills/` directory:

- **Atomic skills** — single-responsibility capabilities with descriptive names. Can be invoked directly or composed by orchestrators.
- **Orchestrator skills** — short action names that compose one or more atomic skills. Their body explicitly names the atomics they invoke.

## Skills

### Atomic skills

| Skill | Invoke | Responsibility |
|---|---|---|
| `spec` | `/workflow-core:spec` | Convert a challenged ideation file into a full OpenSpec change proposal |
| `approve-plan` | `/workflow-core:approve-plan` | Review and quality-check the generated task list; human sign-off gate before building |
| `write-tests` | `/workflow-core:write-tests` | Red phase: write failing tests for the next unchecked task before implementation; confirm they fail |
| `run-tests` | `/workflow-core:run-tests` | Run the full test suite; report pass/fail; stop on first failure |
| `debug-recovery` | `/workflow-core:debug-recovery` | Diagnose a failing test or broken build; apply a minimal fix |
| `pr-review` | `/workflow-core:pr-review <PR>` | Fetch and review a specific PR; produce a structured report |
| `simplify` | `/workflow-core:simplify` | Remove dead code and unnecessary complexity from changed files |
| `pr-create` | `/workflow-core:pr-create` | Run pre-PR checks and create the PR; CI/CD owns deployment |

### Orchestrator skills

| Skill | Invoke | Composes |
|---|---|---|
| `build` | `/workflow-core:build` | `write-tests` (Red) → `opsx:apply` (Green) → `run-tests` (Verify) → `debug-recovery` on failure → `opsx:verify` (spec sign-off) → recommends `simplify` (Refactor) |

## Attribution

Five skills are seeded from [addyosmani/agent-skills](https://github.com/addyosmani/agent-skills) (MIT licence). Each carries an attribution comment in its SKILL.md frontmatter. Simon's additions and adaptations accumulate on top.

| Skill | Source |
|---|---|
| `approve-plan` | `planning-and-task-breakdown` |
| `run-tests` | `test-driven-development` |
| `simplify` | `code-simplification` |
| `pr-create` | `git-workflow-and-versioning` |
| `build` | `incremental-implementation` (upstream orchestrator pattern) |
