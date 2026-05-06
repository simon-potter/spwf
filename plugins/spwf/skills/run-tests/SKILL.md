---
# Source: https://github.com/addyosmani/agent-skills — MIT licence
name: run-tests
description: Phase 3 atomic — Run the full test suite and report pass/fail clearly. Stops on the first failure with file, line, and error details. Does not attempt to fix failures — that is debug-recovery's job. Use this skill directly or let /spwf:build invoke it.
disable-model-invocation: true
allowed-tools: [Read, Bash]
---

# run-tests

Run the full test suite. Report pass or fail clearly. Stop on first failure with enough detail to act on. Do not fix anything.

## Step 1: Detect the test command

```bash
# Check for common test configs
ls package.json pytest.ini pyproject.toml jest.config.* vitest.config.* 2>/dev/null
```

Read `package.json` scripts section or pytest config to determine the correct test command.

If no test configuration is found, report:

```
No test configuration detected. Cannot run tests.

Expected one of: package.json (scripts.test), pytest.ini, pyproject.toml [tool.pytest]
```

## Step 2: Run the full suite

```bash
{test command}
```

Run with enough verbosity to capture:
- Which tests passed
- Which test failed first (file, test name, line number)
- The full error message and stack trace

## Step 3: Report results

### On pass

```
✓ All tests passing

{X} tests passed
Suite: {test command used}
```

### On failure

```
✗ Test failure

File: {test file path}:{line number}
Test: {test name}
Error:
{full error message}

{additional context if relevant}

{X} tests passed before this failure
{Y} tests not run

Recommended next step: /spwf:debug-recovery
```

Stop after the first failure. Do not run remaining tests if one has already failed.

Do not attempt to fix the failing test or the code under test.
