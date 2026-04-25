---
# Source: https://github.com/addyosmani/agent-skills — MIT licence
name: test
description: Phase 4 orchestrator — Run the full test suite and recover from failures. Invokes test-runner to run all tests, then invokes debug-recovery on any failure. Reports the final pass/fail outcome. Use after build and test-creator are complete.
disable-model-invocation: true
allowed-tools: [Read, Edit, Bash]
---

# test

Orchestrate the test step. Run all tests. Recover from failures. Report the final outcome.

## What this skill does

This orchestrator composes two atomic skills:

1. **Invoke `workflow-core:test-runner`** — runs the full test suite and reports pass/fail. On first failure, reports the file, line, and error clearly.

2. **If any test fails, invoke `workflow-core:debug-recovery`** — diagnoses the root cause, applies a minimal fix, and re-runs to confirm recovery. If unresolvable after two attempts, stops and reports.

## Execution

### Phase 1: Run tests

Invoke `workflow-core:test-runner`:

- Detect the test command from project config
- Run the full suite
- If all pass → proceed to Phase 3
- If any fail → proceed to Phase 2

### Phase 2: Recover from failure

Invoke `workflow-core:debug-recovery`:

- Read the failure details from test-runner output
- Diagnose the root cause
- Apply a minimal fix to the implementation or test file
- Re-run the suite via `workflow-core:test-runner`
- If pass → proceed to Phase 3
- If still failing → repeat once more
- If still failing after two attempts → stop and report

### Phase 3: Report final outcome

#### All tests passing

```
✓ All tests passing

{X} tests passed

Recommended next step: /workflow-core:pr-reviewer <PR number>
```

#### Unresolved failure

```
✗ Tests still failing after recovery attempts

{failure details}

The issue requires manual investigation. See debug-recovery output above.
```
