# Tasks: align-golden-path

> **Authoritative Reference:** [`todo/Code_spec_drift.md`](../../../todo/Code_spec_drift.md) — sections 0–8 contain the full cross-reference lists for every item below. Consult when making changes to ensure no reference is missed.

## Phase 1 — Change A: Structural cleanup

### 0. opsx command fixes

- [ ] 1.1 Replace all 3 occurrences of `openspec:apply` with `opsx:apply` in `plugins/workflow-core/skills/build/SKILL.md`
- [ ] 1.2 Replace `openspec:apply` with `opsx:apply` in the orchestrators table in `plugins/workflow-core/README.md`
- [ ] 1.3 Replace `openspec:apply` with `opsx:apply` in the golden path Build row in root `README.md`
- [ ] 1.4 Add Phase 4 (`opsx:verify` sign-off step) to `plugins/workflow-core/skills/build/SKILL.md`; include stop-on-failure message; renumber old Phase 4 (completion report) to Phase 5
- [ ] 1.5 Update `plugins/workflow-core/README.md` orchestrators table `build` composition column to include `opsx:verify`
- [ ] 1.6 Update root `README.md` golden path Build row Invokes column to include `opsx:verify`

### 1. Skill renames

- [ ] 1.7 Rename `plugins/workflow-tools/skills/grill-me/` directory to `challenge/`
- [ ] 1.8 Update `challenge/SKILL.md` frontmatter: `name: grill-me` → `name: challenge`; preserve attribution comment
- [ ] 1.9 Update all `grill-me` self-references in `challenge/SKILL.md` body
- [ ] 1.10 Create NEW `plugins/workflow-tools/skills/grill-me/SKILL.md` as a deprecation stub (one-line output, `disable-model-invocation: true`)
- [ ] 1.11 Update `plugins/workflow-tools/skills/capture/SKILL.md` next-step reference: `grill-me` → `challenge`
- [ ] 1.12 Update `plugins/workflow-tools/skills/debug/SKILL.md` next-step reference: `grill-me` → `challenge`
- [ ] 1.13 Update `plugins/workflow-agents/agents/specifier.md`: "after grill-me" → "after challenge"
- [ ] 1.14 Rename `plugins/workflow-core/skills/task-to-spec/` directory to `spec/`
- [ ] 1.15 Update `spec/SKILL.md` frontmatter: `name: task-to-spec` → `name: spec`; update description self-references
- [ ] 1.16 Update `spec/SKILL.md` body Step 5 next-step suggestion: `/workflow-core:plan-signoff` → `/workflow-core:approve-plan`
- [ ] 1.17 Rename `plugins/workflow-core/skills/plan-signoff/` directory to `approve-plan/`
- [ ] 1.18 Update `approve-plan/SKILL.md` frontmatter: `name: plan-signoff` → `name: approve-plan`; update all body self-references
- [ ] 1.19 Rename `plugins/workflow-core/skills/ship/` directory to `pr-create/`
- [ ] 1.20 Update `pr-create/SKILL.md` frontmatter: `name: ship` → `name: pr-create`
- [ ] 1.21 Update `plugins/workflow-core/skills/simplify/SKILL.md` next-step reference: `ship` → `pr-create`
- [ ] 1.22 Rename `plugins/workflow-core/skills/pr-reviewer/` directory to `pr-review/`
- [ ] 1.23 Update `pr-review/SKILL.md` frontmatter: `name: pr-reviewer` → `name: pr-review`
- [ ] 1.24 Rename `plugins/workflow-core/skills/test-creator/` directory to `write-tests/`
- [ ] 1.25 Update `write-tests/SKILL.md` frontmatter: `name: test-creator` → `name: write-tests`; update description ("Use before incremental-implementation" → "Use before build, or let /workflow-core:build invoke it")
- [ ] 1.26 Rename `plugins/workflow-core/skills/test-runner/` directory to `run-tests/`
- [ ] 1.27 Update `run-tests/SKILL.md` frontmatter: `name: test-runner` → `name: run-tests`; update description
- [ ] 1.28 Update all `test-creator`/`test-runner` references in `plugins/workflow-core/skills/build/SKILL.md` to `write-tests`/`run-tests`

### 2. Skill deletions

- [ ] 1.29 Delete `plugins/workflow-core/skills/incremental-implementation/` directory
- [ ] 1.30 Update `plugins/workflow-agents/agents/builder.md`: "Delegates to workflow-core:incremental-implementation" → "Implements via opsx:apply"
- [ ] 1.31 Delete `plugins/workflow-core/skills/test/` directory

### 3. Agent renames

- [ ] 1.32 Rename `plugins/workflow-agents/agents/planner.md` to `approver.md`
- [ ] 1.33 Update `approver.md` frontmatter: `name: planner` → `name: approver`; update description; update body self-references
- [ ] 1.34 Rename `plugins/workflow-agents/agents/shipper.md` to `pr-creator.md`
- [ ] 1.35 Update `pr-creator.md` frontmatter: `name: shipper` → `name: pr-creator`; update description; update body `workflow-core:ship` → `workflow-core:pr-create`

### 5. Agent body updates

- [ ] 1.36 Update `plugins/workflow-agents/agents/specifier.md` body: all `task-to-spec` references → `spec`
- [ ] 1.37 Update `plugins/workflow-agents/agents/tester.md`: rename `test-creator` → `write-tests`, `test-runner` → `run-tests`; add clarification as execution agent vs tdd-expert advisory
- [ ] 1.38 Update `plugins/workflow-agents/agents/tdd-expert.md`: replace any `test-creator` → `write-tests`, `test-runner` → `run-tests`; add clarification as advisory agent vs tester execution
- [ ] 1.39 Update `plugins/workflow-agents/agents/reviewer.md`: remove phase number label → "PR Review agent"
- [ ] 1.40 Update `plugins/workflow-agents/agents/simplifier.md`: remove phase number label → "Simplify agent"
- [ ] 1.41 Update `plugins/workflow-agents/agents/capturer.md`: rewrite as thin wrapper — update description for three modes (Jira/file/freeform); brief body delegating to `workflow-tools:capture`; no logic duplication

### 6. Plugin README updates

- [ ] 1.42 Update `plugins/workflow-core/README.md` atomic skills table: rename rows for spec, approve-plan, write-tests, run-tests, pr-review, pr-create; remove incremental-implementation and test
- [ ] 1.43 Update `plugins/workflow-core/README.md` attribution table: update skill names after renames; remove deleted skills
- [ ] 1.44 Update `plugins/workflow-core/README.md` orchestrators table: remove `test`; update `build` composition to reflect opsx:apply, run-tests, opsx:verify
- [ ] 1.45 Update `plugins/workflow-tools/README.md`: rename `grill-me` row → `challenge`; add deprecated `grill-me` row; update count and any phase labels for capture and retrospective
- [ ] 1.46 Add `## Quality tools` section to `plugins/workflow-tools/README.md` grouping `doc-lint`, `agent-optimise`, `workflow-lint`
- [ ] 1.47 Update `plugins/workflow-agents/README.md`: rename rows for approver and pr-creator; update count; remove phase numbers from all descriptions

### 8. OpenSpec artefact updates

- [ ] 1.48 Update `openspec/changes/add-plugin-marketplace/design.md` Decision 5: `plan-signoff` → `approve-plan`
- [ ] 1.49 Update `openspec/changes/add-plugin-marketplace/design.md` Decision 9: `ship` → `pr-create`
- [ ] 1.50 Update `openspec/changes/add-plugin-marketplace/design.md` Decision 11 table: all old skill names → new names
- [ ] 1.51 Update `openspec/changes/add-plugin-marketplace/design.md` Decision 12: `test-creator` → `write-tests`, `test-runner` → `run-tests`
- [ ] 1.52 Update `openspec/changes/add-plugin-marketplace/tasks.md` task 6.6 lifecycle commands: `grill-me` → `challenge`, `plan-signoff` → `approve-plan`; update build composition references
- [ ] 1.53 Update `openspec/changes/add-plugin-marketplace/specs/marketplace/spec.md`: replace `grill-me`, `plan-signoff`, `task-to-spec`, `ship`, `pr-reviewer` with new names; update skill count/lists to reflect renames and removals

---

## Phase 2 — Change B: Additive changes

### 4. New agents

- [ ] 2.1 Create `plugins/workflow-agents/agents/challenger.md`: name challenger, description "Gate — Challenge agent. Reads the ideation file and interviews relentlessly until all open questions are resolved. One question per message. Does not proceed to spec until gaps are closed.", model claude-sonnet-4-6, tools [Read, Write, Glob]
- [ ] 2.2 Create `plugins/workflow-agents/agents/debugger.md`: name debugger, description "Pre-phase debug agent. Accepts a Jira ticket or freeform description. Runs systematic root-cause investigation (no fixes). Forms a written hypothesis. Produces todo/BUG-{slug}.md for Challenge.", model claude-sonnet-4-6, tools [Read, Write, Glob, Grep, Bash, mcp__atlassian__jira_get_issue]
- [ ] 2.3 Create `plugins/workflow-agents/agents/retrospector.md`: name retrospector, description "Post-ship retrospective agent. Runs three parts: (1) extract learnings from commits; (2) audit OpenSpec artefacts for spec drift; (3) doc-lint pass. Produces a retrospective report.", model claude-sonnet-4-6, tools [Read, Write, Glob, Grep, Bash]
- [ ] 2.4 Update `plugins/workflow-agents/README.md`: add rows for challenger, debugger, retrospector; update total count from Nine to Twelve

### 7. New skill

- [ ] 2.5 Create `plugins/workflow-tools/skills/workflow-lint/SKILL.md`: cross-cutting coherence auditor; checks step↔skill coverage, agent coverage, cross-reference validity, stale names, attribution presence, orphaned skills/agents, diagram↔table consistency; outputs P1/P2/P3 prioritised health report
- [ ] 2.6 Update `plugins/workflow-tools/README.md`: add `workflow-lint` row under `## Quality tools` section
- [ ] 2.7 Update `plugins/workflow-tools/skills/retrospective/SKILL.md`: add Part 4 — `workflow-lint` pass (full sweep, not just changed files)
