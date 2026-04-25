---
# Source: https://github.com/addyosmani/agent-skills — MIT licence
name: build
description: Phase 3 orchestrator — Full Red-Green-Refactor cycle. For each pending task: invokes write-tests (Red: write failing tests), then opsx:apply (Green: implement via OpenSpec), then run-tests (Verify: confirm green before moving on). Loops until all tasks complete. After all tasks complete, runs opsx:verify (spec sign-off), then recommends simplify (Refactor).
disable-model-invocation: true
allowed-tools: [Read, Edit, Write, Bash, Grep, Glob]
---

# build

Orchestrate the **Red → Green → Verify** cycle for every pending task in the active OpenSpec change, then sign off against the spec and recommend Refactor.

## The cycle

```
For each pending task:
  Red    → write-tests     (write failing tests that define the task's behaviour)
  Green  → opsx:apply      (implement the task via OpenSpec)
  Verify → run-tests       (confirm full suite is green before moving to the next task)

On all tasks complete:
  Spec sign-off → opsx:verify
  Refactor      → recommend simplify
```

If the suite is still red after implementation, invoke `debug-recovery` before proceeding.

---

## Phase 1 — Red: write failing tests

Invoke `workflow-core:write-tests`:

- Reads the next `- [ ]` task from the active OpenSpec `tasks.md`
- Reads the relevant spec scenario(s) to understand the required behaviour
- Writes tests that will fail because the code does not yet exist
- Runs them — **confirms they fail for the right reason**

Do not proceed to Green until the tests are genuinely red. If a test passes before implementation, write-tests will flag this as a problem.

## Phase 2 — Green: implement via OpenSpec

Invoke `opsx:apply`:

- Implements the current pending task using the OpenSpec change artefacts
- Marks the task `[x]` on completion
- Stops at the task boundary — does not proceed to the next task automatically

The implementation constraint: write only what makes the failing tests pass. Nothing more.

## Phase 3 — Verify: confirm tests are green

Invoke `workflow-core:run-tests`:

- Runs the full test suite
- If all green → loop back to Phase 1 for the next pending task
- If any test fails → invoke `workflow-core:debug-recovery`

`debug-recovery` diagnoses the failure, applies a minimal fix, and re-runs. If unresolvable after two attempts, stop and report.

## Phase 4 — Spec sign-off: verify against artefacts

When all pending tasks are complete, invoke `opsx:verify`:

- Checks the implementation against the OpenSpec artefacts for this change
- If aligned → proceed to Phase 5

If `opsx:verify` reports misalignment, stop with:

```
⚠ Spec artefact misalignment detected.

Review the opsx:verify findings. Then either:
  • Update the spec artefacts to reflect what was built, or
  • Revise the implementation to match the spec

Re-run /workflow-core:build when resolved.
```

Do NOT invoke `debug-recovery` on a spec misalignment — this is a human decision, not a code bug.

## Phase 5 — Loop or complete

If pending tasks remain, return to Phase 1 for the next task.

If all tasks are complete and spec sign-off passed:

```
✓ All tasks complete for change: {change-id}

Tests passing: {count}/{count}
Spec sign-off: ✓

Recommended: /workflow-core:simplify (Refactor)
Clean up the implementation while tests stay green, then /workflow-core:pr-review → /workflow-core:pr-create
```
