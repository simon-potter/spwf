---
name: retrospective
description: Post-ship orchestrator — Three-part retrospective after completing a change. (1) Extract learnings from commits via learn-from-mistakes. (2) Audit the current change's OpenSpec artefacts against what was actually built — flags spec drift, undocumented decisions, orphaned requirements. (3) Broad doc-lint pass across project docs for general drift and quality degradation.
disable-model-invocation: true
allowed-tools: [Read, Glob, Grep, Bash, Edit, Write]
---

# retrospective

Three-part post-ship retrospective for the completed change.

```
Part 1 → learn-from-mistakes     (extract learnings from recent commits)
Part 2 → change spec audit       (align OpenSpec artefacts with what was built)
Part 3 → doc-lint                (broad project docs drift check)
```

---

## Part 1 — Learn from commits

Invoke `workflow-tools:learn-from-mistakes`:

- Reads recent commit history for the current change
- Extracts decisions, surprises, and recurring patterns while context is still warm
- Updates project learning docs with findings

---

## Part 2 — Change spec audit

Check whether the OpenSpec artefacts for the just-completed change still accurately describe what was built. Implementation always diverges from spec in small ways; this step closes the gap.

### Step 1: Identify the change

If `$ARGUMENTS` contains a change-id, use it. Otherwise detect from context (most recently completed change) or ask.

Confirm all tasks in `tasks.md` are `[x]` before proceeding.

### Step 2: Read the artefacts

Read in order:
1. `openspec/changes/{change-id}/proposal.md` — Why and What Changes
2. `openspec/changes/{change-id}/design.md` — decisions and rationale (if exists)
3. `openspec/changes/{change-id}/tasks.md` — the full task history
4. `openspec/changes/{change-id}/specs/*/spec.md` — requirements and scenarios

### Step 3: Read the implementation evidence

Read the test files written during the build phase. The tests are the ground truth for what was actually built — compare what they assert against what the specs require.

### Step 4: Flag drift

| Drift type | Description |
|---|---|
| **Undocumented decision** | Implementation made a choice not captured in `design.md` |
| **Scope drift** | What was built differs from what `proposal.md` describes (expanded or contracted) |
| **Orphaned requirement** | A spec scenario has no corresponding test |
| **Stale task** | A task description no longer describes what was actually implemented |
| **Evolved rationale** | A design decision's rationale changed during implementation but wasn't updated |

### Step 5: Propose updates

For each drift item, propose a minimal surgical update to bring the artefact back into alignment. Do not rewrite — one sentence changes preferred. Present for approval before applying.

---

## Part 3 — Broad doc lint

Invoke `workflow-tools:doc-lint`:

- Scans project `docs/` for naming, metadata, staleness, and structural issues
- Runs in report-only mode (no auto-fix)
- Surfaces docs that have drifted or degraded in quality since the last retrospective

If `docs/documentation-rules.md` does not exist, note this and skip rather than failing.

---

## Report

```
## Retrospective: {change-id}

### Part 1 — Learnings
{summary from learn-from-mistakes}

### Part 2 — Spec alignment
{✓ No drift | list of drift items with proposed fix for each}

### Part 3 — Doc quality
{✓ Clean | summary of doc-lint findings}

### Recommended actions
- [ ] {update design.md: undocumented decision — X}
- [ ] {update spec scenario Y: test asserts Z, spec says W}
- [ ] {docs/path/to/file.md: staleness warning — last reviewed N months ago}
```
