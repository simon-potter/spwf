---
name: write-tests
description: Phase 3 atomic — Red phase of TDD. Read the next unchecked task, write failing tests that define the expected behaviour, then run them to confirm they fail. Tests must fail before implementation begins — a test that passes before the code exists is wrong. Use before build, or let /spwf:build invoke it.
disable-model-invocation: true
allowed-tools: [Read, Write, Bash, Grep, Glob]
---

# write-tests

**Red phase.** Write failing tests that define the behaviour required by the next task. The tests must fail when run — that failure is the signal that they are correctly describing code that does not yet exist.

Do not implement anything. Do not fix the failures. Stop at Red.

## Step 1: Identify the next task

Read `openspec/changes/{change-id}/tasks.md`. Find the first `- [ ]` item — this is what the tests will cover.

Read the relevant spec under `openspec/changes/{change-id}/specs/` to understand the required behaviour precisely.

## Step 2: Identify the test framework in use

```bash
ls package.json pytest.ini pyproject.toml jest.config.* vitest.config.* 2>/dev/null
```

Read the config to determine: how tests are run, where test files live, and what the naming convention is.

## Step 3: Identify the target module or function

From the task description and spec, determine what code unit will be created or changed. If the module does not yet exist, write imports as if it does — the import failure is part of Red.

## Step 4: Write behaviour tests

Place the test file following project convention:
- Python: `tests/test_{module}.py`
- TypeScript/JS: `{file}.test.ts` or `__tests__/{file}.test.ts`

Each test must:
- Name the **behaviour**: `test_returns_empty_list_when_no_items`, not `test_function`
- Follow **Arrange / Act / Assert** structure
- Assert on **observable outcomes**, not internal state

Cover at minimum:
- Happy path: expected input → expected output
- Edge cases: empty, boundary, missing optionals
- Error cases: invalid input, expected failures

**Do not test:**
- Private methods or internal state
- Framework behaviour
- Code that has not changed

## Step 5: Run the tests — confirm they fail

```bash
{test command}
```

**All tests must fail at this point.** This is the Red check.

If a test passes before any implementation:
- The test is asserting something that already exists, or
- The test is not actually testing what the task requires

Fix the test until it fails for the right reason.

## Step 6: Report

```
✗ Tests failing (Red) — ready for implementation

Test file: {path}
Failing tests:
- {test name}: {why it fails — expected vs actual}
- {test name}: {why it fails}

Failing correctly? ✓

Recommended next step: /spwf:build (opsx:apply phase)
```

Do not proceed to implementation. Stop here. `build` will invoke `opsx:apply` for the Green phase.
