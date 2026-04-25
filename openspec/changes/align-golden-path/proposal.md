# Proposal: align-golden-path

> **Authoritative Reference:** [`todo/Code_spec_drift.md`](../../../todo/Code_spec_drift.md) contains the complete inventory of drift items, all 16 resolved decisions, staging plan, and cross-reference lists. This document summarises key points; consult the source for specifics.

## Why

The plugins were built before the golden path stabilised. Skill names, agent names, and internal cross-references now diverge from the agreed workflow step names. This creates confusion about which command to run at each step, makes the golden path table misleading, and leaves stale references throughout skill bodies, agent files, and OpenSpec artefacts.

## What Changes

**Change A — Structural cleanup (no new behaviour)**

- **FIX** `openspec:apply` → `opsx:apply` in `build/SKILL.md`, `workflow-core/README.md`, root `README.md`
- **FIX** Add `opsx:verify` as the final sign-off step of `build` (after `run-tests`); stop with message on failure
- **RENAME** 7 skills to match golden path step names: `grill-me` → `challenge`, `task-to-spec` → `spec`, `plan-signoff` → `approve-plan`, `ship` → `pr-create`, `pr-reviewer` → `pr-review`, `test-creator` → `write-tests`, `test-runner` → `run-tests`
- **KEEP** `grill-me` as a deprecation stub that redirects to `/workflow-tools:challenge`
- **DELETE** `incremental-implementation` skill (orphaned; `build` now uses `opsx:apply`)
- **DELETE** `test` orchestrator (redundant; verify is inside `build`; `run-tests` covers standalone need)
- **RENAME** 2 agents: `planner` → `approver`, `shipper` → `pr-creator`
- **UPDATE** 7 agent bodies: stale skill name references, phase number labels
- **UPDATE** 3 plugin READMEs: rename rows, remove deleted skills, add Quality tools grouping
- **UPDATE** 3 OpenSpec artefacts (`add-plugin-marketplace` design.md, tasks.md, spec.md)

**Change B — Additive only**

- **NEW** 3 agents: `challenger` (Challenge step), `debugger` (Debug step), `retrospector` (Retrospective step)
- **NEW** 1 skill: `workflow-lint` (cross-cutting coherence auditor for the golden path)
- **UPDATE** `retrospective/SKILL.md`: add Part 4 — `workflow-lint` pass (ships with the skill)

## Impact

- **Affected plugins:** workflow-core (6 skill renames, 2 deletes), workflow-tools (1 rename + stub, 1 new skill)
- **Affected agents:** workflow-agents (2 renames, 3 additions, 7 body updates)
- **Affected artefacts:** `add-plugin-marketplace` design.md, tasks.md, specs/marketplace/spec.md
- **No breaking changes to any project using the plugins** — renames update directory names and frontmatter; existing invocations via the old names (`grill-me`) redirect via the stub
- **`grill-me` stub** prevents hard breakage for users with the old name in muscle memory
- **After Change A:** golden path table, skill names, agent names, and all cross-references are consistent
- **After Change B:** every golden path step has a matching agent; `workflow-lint` can audit coherence on every future change
