---
name: debug-recovery
description: Phase 3/4 atomic — Diagnose a failing test or broken build, identify the root cause, apply a minimal fix, re-run to confirm recovery. Reports clearly if unable to resolve. Use after test-runner or build reports a failure.
disable-model-invocation: true
allowed-tools: [Read, Edit, Bash]
---

# debug-recovery

Diagnose the failure, fix the root cause with a minimal change, and confirm recovery. If unable to resolve, report clearly and stop.

## Step 1: Gather failure context

Read the failure output. If it was produced by `test-runner` or `build`, the error should be in the conversation. If not:

```bash
{test command} 2>&1 | head -100
```

Capture:
- Failing file and line number
- Error message and stack trace
- Any recent changes that may have caused the failure

## Step 2: Read the failing code

Read:
1. The test file at the failing line
2. The implementation file being tested
3. Any dependencies the test exercises

## Step 3: Identify the root cause

Classify the failure:

| Type | Symptom | Fix target |
|---|---|---|
| Implementation bug | Code does wrong thing | Implementation file |
| Test bug | Test has wrong expectation | Test file |
| Missing dependency | Import or config missing | Setup/config |
| Environment issue | Works locally, fails in CI | Build/config |
| Type or schema mismatch | Wrong data shape | Either |

State the root cause explicitly before making any change.

## Step 4: Apply a minimal fix

Fix only what is broken. Do not:
- Refactor surrounding code
- Fix other issues noticed along the way
- Change behaviour unrelated to the failure

If the fix requires changing more than 10 lines, pause and ask the user — a large fix may indicate a deeper design issue.

## Step 5: Re-run to confirm

```bash
{test command}
```

If the failure is resolved:

```
✓ Recovery confirmed

Root cause: {one-sentence description}
Fix applied: {brief description of change}
Files changed: {list}
Tests now passing.
```

If a new failure appears, repeat from Step 1 for the new failure.

## Step 6: Report if unable to resolve

If after two attempts the failure is not resolved:

```
✗ Unable to resolve

Root cause identified: {description}

Attempted fixes:
1. {fix 1} — {outcome}
2. {fix 2} — {outcome}

Blocked on: {specific blocker}

Options:
1. {suggested path forward}
2. {alternative}
```

Stop and wait for guidance.
