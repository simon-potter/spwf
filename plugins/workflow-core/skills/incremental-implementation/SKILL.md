---
# Source: https://github.com/addyosmani/agent-skills — MIT licence
name: incremental-implementation
description: Phase 3 atomic — Green phase of TDD. Find the first unchecked task, implement only what is needed to make the failing tests pass, mark the task complete, and stop. Assumes test-creator has already written failing tests for this task. Does not move to the next task. Use this skill directly for granular control, or let /workflow-core:build invoke it.
disable-model-invocation: true
allowed-tools: [Read, Edit, Write, Bash]
---

# incremental-implementation

**Green phase.** Implement the first unchecked task — write only what is needed to make the failing tests pass. Mark the task complete. Stop at the task boundary.

`test-creator` should have already written failing tests for this task. If no test file exists for the current task, stop and run `/workflow-core:test-creator` first.

## Step 1: Find the active change

If `$ARGUMENTS` contains a change-id, use it. Otherwise detect from context or ask.

## Step 2: Read all context files

Read these files before writing any code:

1. `openspec/changes/{change-id}/tasks.md` — find the first `- [ ]` item
2. `openspec/changes/{change-id}/proposal.md` — understand the goal
3. `openspec/changes/{change-id}/design.md` — understand constraints (if exists)
4. Any specs under `openspec/changes/{change-id}/specs/` — understand requirements

## Step 3: Identify the current task

Find the first unchecked item: `- [ ]`

If all tasks are checked:

```
All tasks complete for change: {change-id}

Consider archiving: openspec archive {change-id}
```

Stop.

## Step 4: Implement the task

Implement only the identified task. Keep changes:
- Minimal — do exactly what the task says, no more
- Scoped — do not refactor unrelated code
- Faithful — if the task says "add X", add X — do not redesign

If the task is ambiguous, stop and ask for clarification rather than guessing.

## Step 5: Mark the task complete

In `openspec/changes/{change-id}/tasks.md`, update:

```
- [ ] N.N {task text}
```

to:

```
- [x] N.N {task text}
```

## Step 6: Report and stop

```
✓ Task N.N complete: {task text}

Files changed:
- {path}: {brief description}

Progress: {X}/{total} tasks complete

Recommended next step: /workflow-core:test-creator
```

Do not automatically move to the next task. Stop here.
