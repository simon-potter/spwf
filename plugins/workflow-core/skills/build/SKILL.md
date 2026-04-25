---
# Source: https://github.com/addyosmani/agent-skills — MIT licence
name: build
description: Phase 3 orchestrator — Full Red-Green-Refactor cycle. For each pending task: invokes test-creator (Red: write failing tests), then openspec:apply (Green: implement via OpenSpec), then test-runner (Verify: confirm green before moving on). Loops until all tasks complete. Recommends simplify (Refactor) on completion.
disable-model-invocation: true
allowed-tools: [Read, Edit, Write, Bash, Grep, Glob]
---

# build

Orchestrate the **Red → Green → Verify** cycle for every pending task in the active OpenSpec change, then recommend Refactor.

## The cycle

```
For each pending task:
  Red    → test-creator     (write failing tests that define the task's behaviour)
  Green  → openspec:apply   (implement the task via OpenSpec)
  Verify → test-runner      (confirm full suite is green before moving to the next task)

On all tasks complete:
  Refactor → recommend simplify
```

If the suite is still red after implementation, invoke `debug-recovery` before proceeding.

---

## Phase 1 — Red: write failing tests

Invoke `workflow-core:test-creator`:

- Reads the next `- [ ]` task from the active OpenSpec `tasks.md`
- Reads the relevant spec scenario(s) to understand the required behaviour
- Writes tests that will fail because the code does not yet exist
- Runs them — **confirms they fail for the right reason**

Do not proceed to Green until the tests are genuinely red. If a test passes before implementation, test-creator will flag this as a problem.

## Phase 2 — Green: implement via OpenSpec

Invoke `openspec:apply`:

- Implements the current pending task using the OpenSpec change artefacts
- Marks the task `[x]` on completion
- Stops at the task boundary — does not proceed to the next task automatically

The implementation constraint: write only what makes the failing tests pass. Nothing more.

## Phase 3 — Verify: confirm tests are green

Invoke `workflow-core:test-runner`:

- Runs the full test suite
- If all green → loop back to Phase 1 for the next pending task
- If any test fails → invoke `workflow-core:debug-recovery`

`debug-recovery` diagnoses the failure, applies a minimal fix, and re-runs. If unresolvable after two attempts, stop and report.

## Phase 4 — Loop or complete

If pending tasks remain, return to Phase 1 for the next task.

If all tasks are complete:

```
✓ All tasks complete for change: {change-id}

Tests passing: {count}/{count}

Recommended: /workflow-core:simplify (Refactor)
Clean up the implementation while tests stay green, then /workflow-core:pr-reviewer → /workflow-core:ship
```
