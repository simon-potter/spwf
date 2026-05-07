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

Invoke `spwf:write-tests`:

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

Invoke `spwf:run-tests`:

- Runs the full test suite
- If all green → loop back to Phase 1 for the next pending task
- If any test fails → invoke `spwf:debug-recovery`

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

Re-run /spwf:build when resolved.
```

Do NOT invoke `debug-recovery` on a spec misalignment — this is a human decision, not a code bug.

## Phase 4.5 — Commit per task

After `opsx:verify` passes for a task, **before looping to the next task**, propose a commit.

Show `git diff --stat HEAD` so the user sees exactly what was written, then propose:

```
feat({change-id}): {task description — the exact task text from tasks.md}

{1-2 sentences on what was implemented — not what the task says, what was actually built}
{if any unexpected discovery: e.g. "found existing X was incompatible — worked around by Y"}
{if any design decision made during implementation that wasn't in the spec}
{if any edge case discovered and handled that the tests didn't originally cover}
```

Ask: "Ready to commit task {N}? Confirm with 'yes' or edit the message first."

After confirming:

```bash
git add -p   # show a patch-mode summary so nothing accidental is staged
git commit -m "{confirmed message}"
```

If the user declines: note "Skipped — changes are unstaged" and continue to the next task. Do not force commits.

---

## Phase 5 — Loop or complete

If pending tasks remain, return to Phase 1 for the next task.

If all tasks are complete and spec sign-off passed:

```
✓ All tasks complete for change: {change-id}

Tests passing: {count}/{count}
Spec sign-off: ✓

Recommended: /spwf:simplify (Refactor)
Clean up the implementation while tests stay green, then /spwf:pr-review → /spwf:pr-create
```
