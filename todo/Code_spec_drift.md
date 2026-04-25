---
source: scratch
created: 2026-04-25
status: challenged
type: spec-drift
---

# Code/Spec Drift: Skills, Agents, and Cross-References

Everything that needs to change before Phase 5 (migration validation) begins.
Organised by category. Each item lists the change and every file that references the old name.

## Resolved decisions

| # | Decision | Resolution |
|---|---|---|
| 1 | `openspec:apply` vs `opsx:apply` | `opsx:apply` — legacy alias deprecated; fix everywhere |
| 2 | `opsx:verify` in build | Add as final step (sign-off); stop with message on failure, no auto-recovery |
| 3 | `test-runner` rename | → `run-tests` (not `verify` — that concept belongs to `opsx:verify`) |
| 4 | Staging | Two changes: A (structural cleanup), B (additive: agents + workflow-lint) |
| 5 | `grill-me` → `challenge` | Rename with full attribution; keep `grill-me` stub redirect in place |
| 6 | `task-to-spec` → `spec` | Confirmed — namespace scoping makes it unambiguous |
| 7 | `incremental-implementation` | Delete — whole workflow requires OpenSpec; no valid fallback use case |
| 8 | `test` orchestrator | Delete — Verify inside `build`; `run-tests` standalone covers post-simplify need; add nudge to `simplify` |
| 9 | `tester` vs `tdd-expert` | Keep both; disambiguate — `tester` = execution agent, `tdd-expert` = advisory agent |
| 10 | Phase numbers in agents | Remove entirely; replace with step name (e.g. "Build agent", "PR Review agent") |
| 11 | `workflow-lint` | New skill in Change B; audits golden path coherence |
| 12 | Quality tools grouping | README grouping only (`## Quality tools` section in workflow-tools); no separate plugin |
| 13 | `opsx:verify` failure | Stop with clear message — spec alignment is a human decision, not auto-recoverable |
| 14 | New agent models | All three (challenger, debugger, retrospector) at Sonnet — confirmed |
| 15 | `workflow-lint` in retrospective | Add as Part 4 in Change B; ships together with the skill |
| 16 | `capturer` rewrite scope | Thin agent — update description + brief body; delegates to `capture` skill, no logic duplication |

---

## Staging plan

**Change A — Structural cleanup** (renames, removals, body updates, opsx fixes, README updates)
No new behaviour. All items in sections 0–3 and 5–7.

**Change B — Additive only**
New agent files: `challenger`, `debugger`, `retrospector` (section 4). New skill: `workflow-lint` (section 7).

---

## 0. Immediate fixes — `opsx` command corrections

### 0.1 `openspec:apply` → `opsx:apply` everywhere

`opsx:apply` is the current command. `openspec:apply` is the legacy alias (still works but deprecated).

**Files to fix:**
- `plugins/workflow-core/skills/build/SKILL.md`: 3 occurrences (description, cycle diagram, Phase 2 body)
- `plugins/workflow-core/README.md`: orchestrators table
- Root `README.md`: golden path Build row Invokes column

### 0.2 Add `opsx:verify` as the final step of `build`

`/opsx:verify` validates the implementation against the OpenSpec artefacts — it's the spec sign-off after the test suite passes. It belongs at the end of the build cycle, after `run-tests` is green.

**Updated build cycle:**
```
Red      → write-tests   (write failing tests)
Green    → opsx:apply    (implement via OpenSpec)
Test     → run-tests     (confirm test suite green)
Sign-off → opsx:verify   (validate implementation matches spec artefacts)
Refactor → recommend simplify
```

**On `opsx:verify` failure:** stop with a clear message — do NOT invoke `debug-recovery`. This is a spec alignment issue (implementation vs artefacts), not a code bug. Output:
```
⚠ Spec artefact misalignment detected.

Review the opsx:verify findings. Then either:
  • Update the spec artefacts to reflect what was built, or
  • Revise the implementation to match the spec

Re-run /workflow-core:build when resolved.
```

**Files to update:**
- `plugins/workflow-core/skills/build/SKILL.md`: add Phase 4 — `opsx:verify` with stop-on-failure message; renumber old Phase 4 (report) to Phase 5
- `plugins/workflow-core/README.md`: orchestrators table composition column
- Root `README.md`: golden path Build row Invokes column

### 0.3 `test-runner` rename: use `run-tests` not `verify`

Since `opsx:verify` now owns the "verify" concept (artefact sign-off), renaming our test-runner to `verify` would cause conceptual confusion. Rename to `run-tests` instead.

**Replaces item 1.7 in this document** — update all references there from `verify` to `run-tests`.

---

## 1. Skills to rename

Golden path steps should map 1:1 to skill names. These don't.

### 1.1 `grill-me` → `challenge` (workflow-tools) + deprecation stub

**Why:** Golden path step is "Challenge". `/workflow-tools:challenge` is unambiguous; `grill-me` requires knowing the nickname. Full attribution to Matt Pocock preserved in frontmatter.

**Alias approach:** No native alias support in SKILL.md format. Keep `grill-me/SKILL.md` as a deprecation stub — `disable-model-invocation: true`, body outputs one line and stops:
```
⚠ This skill has been renamed. Use /workflow-tools:challenge instead.
```

**Files to change:**
- `plugins/workflow-tools/skills/grill-me/` → rename directory to `challenge/`
- `challenge/SKILL.md` frontmatter: `name: grill-me` → `name: challenge`; preserve full attribution comment
- `challenge/SKILL.md` description: update "grill-me" self-references
- Create NEW `plugins/workflow-tools/skills/grill-me/SKILL.md` — deprecation stub only
- `plugins/workflow-tools/skills/capture/SKILL.md`: "Recommended next step: /workflow-tools:grill-me" → `/workflow-tools:challenge`
- `plugins/workflow-tools/skills/debug/SKILL.md`: "Recommended next step: /workflow-tools:grill-me" → `/workflow-tools:challenge`
- `plugins/workflow-agents/agents/specifier.md`: "Use after grill-me has resolved..." → "after challenge"
- `plugins/workflow-tools/README.md`: table row
- Root `README.md`: golden path table (Challenge row command)
- `openspec/changes/add-plugin-marketplace/tasks.md`: task 3.8, 3.9 descriptions reference `grill-me/SKILL.md`
- `openspec/changes/add-plugin-marketplace/specs/marketplace/spec.md`: any `grill-me` references

---

### 1.2 `task-to-spec` → `spec` (workflow-core)

**Why:** Golden path step is "Spec". `/workflow-core:spec` is clean; `task-to-spec` describes internals, not the step.

**Files to change:**
- `plugins/workflow-core/skills/task-to-spec/` → rename directory to `spec/`
- `spec/SKILL.md` frontmatter: `name: task-to-spec` → `name: spec`
- `spec/SKILL.md` description: update references
- `spec/SKILL.md` body: Step 5 says "Suggested next step: /workflow-core:plan-signoff" → `/workflow-core:approve-plan` (after 1.3)
- `plugins/workflow-core/skills/plan-signoff/SKILL.md`: "Run /workflow-core:task-to-spec first" → `/workflow-core:spec`
- `plugins/workflow-agents/agents/planner.md`: "task list generated by task-to-spec" → "generated by spec"
- `plugins/workflow-agents/agents/specifier.md`: body references task-to-spec
- `plugins/workflow-core/README.md`: atomic skills table
- `plugins/workflow-tools/README.md`: any references
- Root `README.md`: golden path table (Spec row command)
- `openspec/changes/add-plugin-marketplace/tasks.md`: Phase 2 task descriptions reference `task-to-spec`
- `openspec/changes/add-plugin-marketplace/design.md`: multiple references

---

### 1.3 `plan-signoff` → `approve-plan` (workflow-core)

**Why:** Golden path step is "Approve plan". `/workflow-core:approve-plan` states exactly what the user is doing.

**Files to change:**
- `plugins/workflow-core/skills/plan-signoff/` → rename directory to `approve-plan/`
- `approve-plan/SKILL.md` frontmatter: `name: plan-signoff` → `name: approve-plan`
- `approve-plan/SKILL.md` body: self-references, output text "re-run /workflow-core:plan-signoff" → `/workflow-core:approve-plan`
- `plugins/workflow-core/skills/spec/SKILL.md` (after 1.2): Step 5 suggestion
- `plugins/workflow-agents/agents/planner.md`: output text "re-run /workflow-core:plan-signoff"
- `plugins/workflow-core/README.md`: atomic skills table
- Root `README.md`: golden path table (Approve plan row command)
- `openspec/changes/add-plugin-marketplace/design.md`: Decision 5, Decision 11 table, Decision 12
- `openspec/changes/add-plugin-marketplace/specs/marketplace/spec.md`
- `openspec/changes/add-plugin-marketplace/tasks.md`: task 6.6

---

### 1.4 `ship` → `pr-create` (workflow-core)

**Why:** Golden path step is "PR Create". `ship` implies deployment; this skill only creates the PR. Renaming removes ambiguity about what it actually does.

**Files to change:**
- `plugins/workflow-core/skills/ship/` → rename directory to `pr-create/`
- `pr-create/SKILL.md` frontmatter: `name: ship` → `name: pr-create`
- `plugins/workflow-core/skills/build/SKILL.md`: completion text "→ /workflow-core:ship" → `/workflow-core:pr-create`
- `plugins/workflow-core/skills/simplify/SKILL.md`: any next-step references to `ship`
- `plugins/workflow-agents/agents/shipper.md` (see 3.2): body references `workflow-core:ship`
- `plugins/workflow-core/README.md`: atomic skills table + attribution table
- Root `README.md`: golden path table (PR Create row command)
- `openspec/changes/add-plugin-marketplace/tasks.md`: task 6.6, task 2.24–2.26
- `openspec/changes/add-plugin-marketplace/design.md`: Decision 9

---

### 1.5 `pr-reviewer` → `pr-review` (workflow-core)

**Why:** Golden path step is "PR Review". Drops the `-er` suffix for consistency with `pr-create`.

**Files to change:**
- `plugins/workflow-core/skills/pr-reviewer/` → rename directory to `pr-review/`
- `pr-review/SKILL.md` frontmatter: `name: pr-reviewer` → `name: pr-review`
- `plugins/workflow-core/skills/build/SKILL.md`: completion text "→ /workflow-core:pr-reviewer" → `/workflow-core:pr-review`
- `plugins/workflow-agents/agents/reviewer.md`: body references
- `plugins/workflow-core/README.md`: atomic skills table + attribution table
- Root `README.md`: golden path table (PR Review row command)
- `openspec/changes/add-plugin-marketplace/tasks.md`: task 2.19–2.20

---

### 1.6 `test-creator` → `write-tests` (workflow-core)

**Why:** Used standalone as "Write tests (TDD Red/failing)". `write-tests` states what it does; `test-creator` sounds like a factory.

**Files to change:**
- `plugins/workflow-core/skills/test-creator/` → rename directory to `write-tests/`
- `write-tests/SKILL.md` frontmatter: `name: test-creator` → `name: write-tests`
- `write-tests/SKILL.md` description: "Use before incremental-implementation" → "Use before build, or let /workflow-core:build invoke it"
- `plugins/workflow-core/skills/build/SKILL.md`: all references to `test-creator` / `workflow-core:test-creator`
- `plugins/workflow-agents/agents/tester.md`: description and body reference test-creator
- `plugins/workflow-agents/agents/tdd-expert.md`: body may reference test-creator
- `plugins/workflow-core/README.md`: atomic skills table + orchestrators composition column
- Root `README.md`: golden path Build row Invokes column
- `openspec/changes/add-plugin-marketplace/tasks.md`: tasks 2.12–2.13

---

### 1.7 `test-runner` → `run-tests` (workflow-core)

**Why:** Runs the test suite. `run-tests` is accurate and distinct from `opsx:verify` (which validates against artefacts). See item 0.3.

**Files to change:**
- `plugins/workflow-core/skills/test-runner/` → rename directory to `run-tests/`
- `run-tests/SKILL.md` frontmatter: `name: test-runner` → `name: run-tests`
- `run-tests/SKILL.md` description: update "Use this skill directly or let /workflow-core:test invoke it" → "or let /workflow-core:build invoke it"
- `plugins/workflow-core/skills/build/SKILL.md`: all references to `test-runner` / `workflow-core:test-runner`
- `plugins/workflow-core/skills/debug-recovery/SKILL.md`: any references to test-runner
- `plugins/workflow-agents/agents/tester.md`: Mode 2 Verify section
- `plugins/workflow-core/README.md`: atomic skills table + attribution table + orchestrators composition column
- `openspec/changes/add-plugin-marketplace/tasks.md`: tasks 2.14–2.16

---

## 2. Skills to REMOVE

### 2.1 `incremental-implementation` (workflow-core) — REMOVE

**Why:** The Green phase in `build` now uses `openspec:apply`, not `incremental-implementation`. The skill's own description says "Use this skill directly for granular control, or let /workflow-core:build invoke it" — but `build` no longer invokes it. It is orphaned and misleading.

**Action:** Delete `plugins/workflow-core/skills/incremental-implementation/` entirely.

**Cross-references to clean up before deleting:**
- `plugins/workflow-core/skills/write-tests/SKILL.md` (after 1.6): description says "Use before incremental-implementation" → update
- `plugins/workflow-agents/agents/builder.md`: description says "Delegates to workflow-core:incremental-implementation" → update to `openspec:apply`
- `plugins/workflow-core/README.md`: remove from atomic skills table + attribution table
- `openspec/changes/add-plugin-marketplace/tasks.md`: tasks 2.9–2.11 (historical, mark as superseded)
- `openspec/changes/add-plugin-marketplace/design.md`: Decision 11 table still lists it

---

### 2.2 `test` orchestrator (workflow-core) — REMOVE

**Why:** Its purpose was `test-runner` + `debug-recovery` on failure. Verify is now inside `build`. With `verify` (renamed from `test-runner`) available as a standalone atomic, this orchestrator adds no value and creates confusion about when to use `test` vs `build`.

**Action:** Delete `plugins/workflow-core/skills/test/` entirely.

**Cross-references to clean up:**
- `plugins/workflow-core/README.md`: remove from orchestrators table
- `plugins/workflow-agents/agents/tester.md`: description says "Phase 3/4" — verify no body reference to `workflow-core:test`
- `openspec/changes/add-plugin-marketplace/tasks.md`: tasks 2.30–2.32 (historical)
- `openspec/changes/add-plugin-marketplace/design.md`: Decision 11 table lists `test` as orchestrator

---

## 3. Agents to rename

### 3.1 `planner` → `approver`

**Why:** "Planner" implies creating the plan. The agent reviews and approves a plan already created by `specifier`. Name creates confusion about which agent to use for the "Approve plan" step.

**Files to change:**
- `plugins/workflow-agents/agents/planner.md` → rename to `approver.md`
- `approver.md` frontmatter: `name: planner` → `name: approver`; update description
- `approver.md` body: self-references to "planner"
- `plugins/workflow-agents/README.md`: table row

---

### 3.2 `shipper` → `pr-creator`

**Why:** "Shipper" implies deployment. The agent only creates a PR. Rename aligns with the "PR Create" step and with the `pr-create` skill rename (2.4).

**Files to change:**
- `plugins/workflow-agents/agents/shipper.md` → rename to `pr-creator.md`
- `pr-creator.md` frontmatter: `name: shipper` → `name: pr-creator`; update description
- `pr-creator.md` body: references to `workflow-core:ship` → `workflow-core:pr-create`
- `plugins/workflow-agents/README.md`: table row

---

## 4. Agents to ADD (missing for workflow steps)

### 4.1 `challenger` — for Challenge step

**Why:** Every other golden path step has a specialist agent except Challenge. The challenger runs the relentless interview loop that `challenge` (skill) does, as an agent.

**Spec:**
- `name: challenger`
- `description:` Gate — Challenge agent. Reads the ideation file and interviews relentlessly until all open questions are resolved. One question per message. Does not proceed to spec until gaps are closed.
- `model: claude-sonnet-4-6` (reasoning required for gap detection)
- `tools: [Read, Write, Glob]`

---

### 4.2 `debugger` — for Debug step

**Why:** The `debug` skill has a four-phase investigation process demanding systematic reasoning. An agent version allows it to be triggered by name from the agents panel without invoking the skill manually.

**Spec:**
- `name: debugger`
- `description:` Pre-phase debug agent. Accepts a Jira ticket or freeform description. Runs systematic root-cause investigation (no fixes). Forms a written hypothesis. Produces todo/BUG-{slug}.md for Challenge.
- `model: claude-sonnet-4-6` (investigation reasoning required)
- `tools: [Read, Write, Glob, Grep, Bash, mcp__atlassian__jira_get_issue]`

---

### 4.3 `retrospector` — for Retrospective step

**Why:** No agent for the Retrospective step. The `retrospective` orchestrator has three distinct parts; an agent version allows it to be triggered and guided interactively.

**Spec:**
- `name: retrospector`
- `description:` Post-ship retrospective agent. Runs three parts: (1) extract learnings from commits; (2) audit OpenSpec artefacts for spec drift; (3) doc-lint pass. Produces a retrospective report.
- `model: claude-sonnet-4-6` (semantic drift detection requires reasoning)
- `tools: [Read, Write, Glob, Grep, Bash]`

---

## 5. Agent body updates (stale internal references)

### 5.1 `builder.md`

- Description: "Delegates to workflow-core:incremental-implementation" → "Implements via openspec:apply"
- Body: any reference to `incremental-implementation` → `openspec:apply`

### 5.2 `capturer.md`

- **Thin agent** — do not reimplement the full capture logic; that lives in `capture/SKILL.md`
- Update description to reflect three modes (Jira, file, freeform) and qualify step
- Body: brief summary of the three modes + note that it delegates to `workflow-tools:capture`; no duplication of qualify logic

### 5.3 `specifier.md`

- Description: "Use after grill-me has resolved..." → "Use after challenge has resolved..."
- Body: any `grill-me` reference → `challenge`

### 5.4 `tester.md`

- Description references "test-creator" → `write-tests`
- Body Mode 1 references `test-creator` → `write-tests`
- Clarify role as **execution agent** (runs the TDD steps; invoked by `build`) vs tdd-expert (advisory)

### 5.5 `tdd-expert.md`

- Check body for `test-creator` / `test-runner` references → `write-tests` / `run-tests`
- Clarify role as **advisory agent** (consult when unsure what to test or stuck in Red-Green) vs tester (execution)

### 5.6 `reviewer.md`

- Phase label "Phase 5 review agent" → "PR Review agent" (phase numbering no longer meaningful now that Debug/Capture are pre-steps)

### 5.7 `simplifier.md`

- Phase label "Phase 6 simplification agent" → "Simplify agent"

---

## 6. Plugin README updates

### 6.1 `workflow-core/README.md`

- Atomic skills table: rename rows for `task-to-spec`, `plan-signoff`, `test-creator`, `test-runner`, `pr-reviewer`, `ship`
- Remove `incremental-implementation` from atomic table and attribution table
- Orchestrators table: remove `test`; update `build` composition (already has `openspec:apply` — verify)
- Attribution table: update skill names after renames; note `build` source changes

### 6.2 `workflow-tools/README.md`

- `grill-me` row → `challenge`; add stub `grill-me` row marked deprecated
- Add `## Quality tools` section grouping `doc-lint`, `agent-optimise`, `workflow-lint` — describe as "cross-cutting maintenance skills, not tied to any workflow step"
- Phase labels for new orchestrators (`capture`, `retrospective`) look correct — verify

### 6.3 `workflow-agents/README.md`

- Rename rows for `planner` → `approver`, `shipper` → `pr-creator`
- Add rows for `challenger`, `debugger`, `retrospector`
- Update count (currently Nine; will become Twelve after additions)
- Remove phase numbers from descriptions (they're misleading now that Debug/Capture are pre-steps)

---

## 7. New skill — `workflow-lint` (workflow-tools)

A cross-cutting skill that audits the golden path for coherence. The golden path table in `README.md` is the source of truth; this skill checks everything else is consistent with it.

**What it checks:**
- Every golden path step has a matching skill directory and `SKILL.md` in the correct plugin
- Every golden path step has a corresponding agent (flags missing agents by step name)
- Cross-references inside skill bodies are valid — every `/plugin:skill` invocation names a skill that exists
- Agent descriptions reference current skill names (no stale names like `grill-me`, `ship`, `test-runner`)
- Attribution comments present on all derived skills
- No orphaned skills (skill directory exists but step not in golden path)
- No orphaned agents (agent file exists but no golden path step maps to it)
- Workflow diagram in `README.md` matches the golden path table step names

**Output:** prioritised health report — P1 (broken references), P2 (missing coverage), P3 (naming drift)

**Lives in:** `workflow-tools` — same family as `doc-lint` and `agent-optimise`
**Name:** `workflow-lint`
**Staging:** Change B (additive, alongside new agents)
**Also:** Add as Part 4 of `retrospective/SKILL.md` in Change B — ships together, no broken reference window.

`doc-lint`, `agent-optimise`, and `workflow-lint` form a natural group — cross-cutting maintenance skills. Group them under a `## Quality tools` section in the `workflow-tools` README.

---

## 8. OpenSpec artefact updates

### 7.1 `openspec/changes/add-plugin-marketplace/design.md`

- Decision 5: references "plan" → `approve-plan`
- Decision 9: references "ship" → `pr-create`
- Decision 11 table: all old skill names
- Decision 12: references `test-creator` → `write-tests`, `test-runner` → `verify`

### 7.2 `openspec/changes/add-plugin-marketplace/tasks.md`

- Phase 2 scaffolding tasks reference old skill names throughout
- Task 6.6 lifecycle commands: `grill-me` → `challenge`, `plan` → `approve-plan` (already done), `build` composition references
- Note: historical task descriptions don't need to be rewritten, but task 6.6 (test steps for Phase 6) should use the new names since it's still a future task

### 7.3 `openspec/changes/add-plugin-marketplace/specs/marketplace/spec.md`

- Any remaining `grill-me`, `plan-signoff`, `task-to-spec`, `ship`, `pr-reviewer` references

---

## Summary

| Category | Count | Action |
|---|---|---|
| Skills to rename | 7 | Rename dir + frontmatter + all cross-refs |
| Skills to remove | 2 | Delete dirs + clean cross-refs |
| Agents to rename | 2 | Rename file + frontmatter + cross-refs |
| Agents to add | 3 | Write new agent files |
| Agent body updates | 7 | Stale internal references |
| Plugin READMEs | 3 | Update tables |
| OpenSpec artefacts | 3 | Update decision tables and task commands |
