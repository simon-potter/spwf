# plugin-naming Specification

## Purpose
TBD - created by archiving change align-golden-path. Update Purpose after archive.
## Requirements
### Requirement: Skill names match golden path step names

Each workflow-core and workflow-tools skill SHALL be named after the corresponding golden path step it represents. The mapping is: Capture → `capture`, Debug → `debug`, Challenge → `challenge`, Spec → `spec`, Approve plan → `approve-plan`, Build → `build`, Write tests → `write-tests`, Run tests → `run-tests`, Spec sign-off → `opsx:verify` (external), Simplify → `simplify`, PR Create → `pr-create`, PR Review → `pr-review`, Retrospective → `retrospective`.

#### Scenario: Invoke skill by golden path step name

- **WHEN** a user reads the golden path table and types the Command column value
- **THEN** the corresponding skill SHALL exist and execute

#### Scenario: No skills with internal implementation names

- **WHEN** a developer lists all skills across workflow-core and workflow-tools
- **THEN** no skill directory SHALL exist named after an implementation detail (`task-to-spec`, `plan-signoff`, `ship`, `pr-reviewer`, `test-creator`, `test-runner`, `incremental-implementation`)

---

### Requirement: Agent names match golden path step names

Each workflow-agents agent SHALL be named after the golden path step it supports. Every golden path step SHALL have a corresponding agent. The mapping is: Capture → `capturer`, Debug → `debugger`, Challenge → `challenger`, Spec → `specifier`, Approve plan → `approver`, Build → `builder`, Write tests → `tester`, TDD advisory → `tdd-expert`, PR Create → `pr-creator`, PR Review → `reviewer`, Simplify → `simplifier`, Retrospective → `retrospector`.

#### Scenario: Every golden path step has an agent

- **WHEN** a developer runs `workflow-lint` against the agents directory
- **THEN** no golden path step SHALL be flagged as missing a corresponding agent

#### Scenario: No agents with stale step names

- **WHEN** a developer lists all agent files
- **THEN** no agent file SHALL be named after a deprecated step or implementation concept (`planner`, `shipper`)

---

### Requirement: Deprecated skills redirect rather than hard-fail

When a skill is renamed, the old name SHALL continue to exist as a deprecation stub that immediately outputs a redirect message and stops. The stub SHALL have `disable-model-invocation: true` set in frontmatter.

#### Scenario: User invokes old skill name

- **WHEN** a user types `/workflow-tools:grill-me`
- **THEN** the stub skill SHALL output a single message: "⚠ This skill has been renamed. Use /workflow-tools:challenge instead." and stop without executing further

---

### Requirement: `opsx:verify` is the final step of the build cycle

The `build` skill SHALL invoke `opsx:verify` after the test suite passes as a spec alignment sign-off. On `opsx:verify` failure, the build skill SHALL stop and output the alignment failure message; it SHALL NOT invoke `debug-recovery`.

#### Scenario: Build cycle includes spec sign-off

- **WHEN** a user runs `/workflow-core:build` and the test suite passes
- **THEN** `opsx:verify` SHALL run and validate the implementation against OpenSpec artefacts before the build is considered complete

#### Scenario: Spec misalignment stops the build cleanly

- **WHEN** `opsx:verify` returns a failure
- **THEN** the build skill SHALL output the misalignment message and stop; it SHALL NOT proceed to `debug-recovery` or mark the cycle as failed due to a code bug

---

### Requirement: Internal cross-references use current skill names

Skill body text, agent descriptions, and plugin README tables SHALL use current skill names (`opsx:apply`, `write-tests`, `run-tests`, `challenge`, `spec`, `approve-plan`, `pr-create`, `pr-review`). No file SHALL reference `openspec:apply`, `grill-me` (except the deprecation stub), `task-to-spec`, `plan-signoff`, `ship`, `pr-reviewer`, `test-creator`, `test-runner`, or `incremental-implementation` as active skill invocations.

#### Scenario: workflow-lint finds no stale references

- **WHEN** `workflow-lint` is run after Change A is applied
- **THEN** it SHALL report zero P1 (broken references) and zero P3 (naming drift) findings

---

### Requirement: Quality tools are grouped in workflow-tools README

The `workflow-tools/README.md` SHALL contain a `## Quality tools` section listing `doc-lint`, `agent-optimise`, and `workflow-lint` as cross-cutting maintenance skills. These skills SHALL be described as not tied to any specific workflow step.

#### Scenario: Quality tools section exists

- **WHEN** a developer reads `plugins/workflow-tools/README.md`
- **THEN** a `## Quality tools` section SHALL be present containing all three cross-cutting maintenance skills

