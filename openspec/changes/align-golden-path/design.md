# Design: align-golden-path

> **Authoritative Reference:** [`todo/Code_spec_drift.md`](../../../todo/Code_spec_drift.md) contains all 16 resolved decisions with rationale. This document captures the key architectural decisions; consult the source for full context.

## Context

The `add-plugin-marketplace` change built the plugin structure before the golden path was finalised. As the golden path evolved (TDD integration, adversarial review, retrospective, debug step), the skill/agent names and internal references were not kept in sync. This change makes a single focused pass to align everything.

## Goals

- Every golden path step maps 1:1 to a skill name and an agent name
- No stale internal references (`openspec:apply`, `grill-me`, `incremental-implementation`, phase numbers)
- `opsx:verify` is integrated into `build` as the spec sign-off step
- Every golden path step has a corresponding specialist agent
- `workflow-lint` provides ongoing enforcement so drift doesn't re-accumulate

## Non-Goals

- No functional changes to any skill's behaviour (Change A only cleans up names and references)
- No changes to the plugin schema, marketplace catalog, or installation mechanism
- No changes to `add-plugin-marketplace` tasks that are already complete (historical record preserved)

---

## Key Decisions

### Decision 1 — `opsx:apply` replaces `openspec:apply`

`openspec:apply` is the legacy alias. `opsx:apply` is the current command and matches the `opsx:*` command family. All three files that reference the legacy alias are updated.

### Decision 2 — `opsx:verify` as build sign-off

After the test suite passes (`run-tests` green), the build cycle validates the implementation against OpenSpec artefacts with `opsx:verify`. This is not a code quality check — it's a spec alignment check. On failure, stop with a message; do NOT invoke `debug-recovery`. The failure mode is a human decision (update spec or revise code), not a code bug.

**Stop message on failure:**
```
⚠ Spec artefact misalignment detected.

Review the opsx:verify findings. Then either:
  • Update the spec artefacts to reflect what was built, or
  • Revise the implementation to match the spec

Re-run /workflow-core:build when resolved.
```

### Decision 3 — `test-runner` → `run-tests` (not `verify`)

Initially proposed as `verify`, but `opsx:verify` already owns the "verify" concept (artefact sign-off). Naming the test-running skill `verify` would cause conceptual collision. `run-tests` is accurate and unambiguous.

### Decision 4 — Two-change staging

Change A is structural cleanup only — renames, deletions, cross-reference updates. Zero new behaviour. Change B is additive only — three new agents and `workflow-lint`. Staging allows Change A to ship immediately as a clean-up commit; Change B adds features after.

### Decision 5 — `grill-me` → `challenge` with deprecation stub

No native alias support exists in SKILL.md format. Solution: rename the skill directory and frontmatter to `challenge`, then create a new `grill-me/SKILL.md` as a stub with `disable-model-invocation: true` that outputs one line:
```
⚠ This skill has been renamed. Use /workflow-tools:challenge instead.
```
This prevents hard breakage for existing users while making the correct name obvious.

### Decision 6 — `incremental-implementation` deleted, not renamed

The `build` skill now uses `opsx:apply` for the Green phase. `incremental-implementation` is orphaned — `build` no longer invokes it, and the whole workflow requires OpenSpec (no valid standalone use case). Keeping it would mislead users into thinking it's an alternative.

### Decision 7 — `test` orchestrator deleted

Its purpose was `test-runner` + `debug-recovery` on failure. Verify (now `run-tests`) is a step inside `build`. The standalone atomic `run-tests` covers post-simplify usage directly. The orchestrator adds no value and creates confusion.

### Decision 8 — `tester` and `tdd-expert` both kept, clarified

Both agents serve distinct roles: `tester` is the execution agent (runs TDD steps, invoked by `build`); `tdd-expert` is the advisory agent (consulted when unsure what to test or stuck in Red-Green). The disambiguation is added to both descriptions.

### Decision 9 — Phase numbers removed from agent descriptions

Phase numbers are misleading now that Debug and Capture are pre-steps outside the numbered phases. Replace with step-name labels (e.g. "PR Review agent") — these are stable and meaningful.

### Decision 10 — New agents all at Sonnet

`challenger` (reasoning required for gap detection), `debugger` (investigation reasoning), `retrospector` (semantic drift detection). All three require reasoning depth that Haiku cannot reliably provide.

### Decision 11 — `workflow-lint` in Change B

Ships alongside the three new agents it validates (challenger, debugger, retrospector). First run is always clean because the skill and the agents it checks are added in the same change.

### Decision 12 — Quality tools grouped in README only

`doc-lint`, `agent-optimise`, and `workflow-lint` are all cross-cutting maintenance skills. They belong in `workflow-tools` plugin (already correct). Group them under `## Quality tools` in the `workflow-tools/README.md` — README structure only, no separate plugin.

### Decision 13 — `capturer` agent rewritten as thin wrapper

The `capturer` agent should not duplicate `capture/SKILL.md` logic. It is a thin wrapper: updates description to reflect three modes (Jira, file, freeform) and adds a brief body noting it delegates to `workflow-tools:capture`.

---

## Risks / Trade-offs

| Risk | Mitigation |
|---|---|
| Breakage for users with `grill-me` in scripts/muscle memory | Deprecation stub redirects immediately |
| OpenSpec artefact history becoming confusing (old names in completed tasks) | Only future tasks (task 6.6 onwards) updated; historical task descriptions preserved |
| `workflow-lint` validating against a state it helped define | Ships together with Change B; designed to run on every subsequent change, not retroactively |
