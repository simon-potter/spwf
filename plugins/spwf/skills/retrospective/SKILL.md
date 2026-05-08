---
name: retrospective
description: Post-ship orchestrator — Six-part retrospective after completing a change. (1) Extract learnings from commits via learn-from-mistakes. (2) Audit the current change's OpenSpec artefacts against what was actually built. (3) Broad doc-lint pass. (4) workflow-lint sweep. (5) Recap — teaching summary for the human (default on, one-key skip). (6) Changelog — release notes (default off, opt-in for releases).
disable-model-invocation: true
allowed-tools: [Read, Glob, Grep, Bash, Edit, Write]
---

# retrospective

Three-part post-ship retrospective for the completed change.

```
Part 1 → learn-from-mistakes     (extract learnings from recent commits)
Part 2 → change spec audit       (align OpenSpec artefacts with what was built)
Part 3 → doc-lint                (broad project docs drift check)
Part 4 → workflow-lint           (full golden path coherence sweep)
Part 5 → recap                   (teaching summary for the user; default on, one-key skip)
Part 6 → changelog               (release notes; default off, opt-in for releases)
```

---

## Part 1 — Learn from commits

Invoke `spwf:learn-from-mistakes`:

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

Invoke `spwf:doc-lint`:

- Scans project `docs/` for naming, metadata, staleness, and structural issues
- Runs in report-only mode (no auto-fix)
- Surfaces docs that have drifted or degraded in quality since the last retrospective

If `docs/documentation-rules.md` does not exist, note this and skip rather than failing.

---

## Part 4 — workflow-lint pass

Invoke `spwf:workflow-lint`:

- Runs a full golden path coherence sweep — not just changed files
- Checks step↔skill coverage, agent coverage, cross-reference validity, stale names, attribution presence, orphaned skills/agents, diagram↔table consistency
- Outputs a P1/P2/P3 prioritised health report

This is a full sweep. Do not scope it to the current change only — the point is to catch drift that accumulated across multiple changes.

---

## Part 5 — Recap (teaching summary for the user)

Default on, one-key skip. Ask:

```
Generate recap? [Y/n]
```

Pressing enter accepts. If the user says "n" / "no", skip and note "Part 5 skipped (recap declined)" in the retrospective report.

If yes, invoke `spwf:recap` with the change-id passed explicitly and a marker
indicating Part-5 invocation (so the skill renders at `####` heading depth
nested under `### Part 5 — Recap`). The recap mines five sources (todo file,
proposal, design, specs, git log) and produces 5 sections: What changed,
Concepts touched, Decisions, What surprised us, Read next. Anti-padding rules
ensure empty sections are skipped rather than filled.

After the recap is printed, the skill offers to save it to
`openspec/changes/{change-id}/recap.md` (default no). If saved, the file
travels with the change into the OpenSpec archive automatically when `close`
runs `opsx:archive` later.

This is **distinct from `learn-from-mistakes`** in Part 1: that captures rules
for the project (added to `docs/`); this captures takeaways for the user
(printed in-session, optionally saved).

---

## Part 6 — Changelog (release only)

**Only run this part if the user is preparing a release.** Ask explicitly before proceeding:

```
Preparing a release? Run /spwf:changelog to generate a changelog section from these commits? (yes / no)
```

If yes, invoke `spwf:changelog`. The skill will:

- Detect the commit range since the last git tag
- Classify commits by conventional type (feat, fix, security, perf, breaking)
- Draft a changelog section in Keep a Changelog format
- Present for approval before writing to `CHANGELOG.md`

If no, skip silently — the retrospective report notes "Part 6 skipped (no release)".

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

### Part 4 — workflow-lint
{✓ Coherent | P1/P2/P3 findings from workflow-lint}

### Part 5 — Recap
{skipped (declined) | full recap inline as #### sub-sections; "✓ Saved to {path}" or "— Not saved" footer}

### Part 6 — Changelog
{skipped (no release) | ✓ CHANGELOG.md updated — v{version}, {N} entries}

### Recommended actions
- [ ] {update design.md: undocumented decision — X}
- [ ] {update spec scenario Y: test asserts Z, spec says W}
- [ ] {docs/path/to/file.md: staleness warning — last reviewed N months ago}
- [ ] {workflow-lint P1: stale name in skill body — X}
```
