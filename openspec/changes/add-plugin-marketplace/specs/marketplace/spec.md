# Spec: marketplace

> **Authoritative Reference:** [`todo/Marketplace_setup.md`](../../../../../todo/Marketplace_setup.md) contains the full skill inventory, agent table, workflow coverage map, and acceptance criteria.

## ADDED Requirements

### Requirement: Marketplace catalog

The repo SHALL contain a `.claude-plugin/marketplace.json` at its root that is valid JSON conforming to the Claude Code marketplace schema, with name `simon-marketplace`, three plugins (workflow-core, workflow-tools, workflow-agents), and `pluginRoot` set to `./plugins`.

#### Scenario: Install from GitHub

- **WHEN** a user with Academy-Plus org access runs `/plugin marketplace add Academy-Plus/spwf`
- **THEN** Claude Code SHALL read `.claude-plugin/marketplace.json` and register `simon-marketplace` as an available source

#### Scenario: Install from local path

- **WHEN** a developer runs `/plugin marketplace add ./` from the repo root
- **THEN** Claude Code SHALL read the local `marketplace.json` and register it identically

---

### Requirement: workflow-core covers all seven phases

The `workflow-core` plugin SHALL provide exactly 8 skills: `spec`, `approve-plan`, `build`, `write-tests`, `pr-review`, `simplify`, `pr-create`, `debug-recovery`. Each SHALL be invocable as `/workflow-core:<name>`.

#### Scenario: Invoke a phase skill

- **WHEN** a user types `/workflow-core:approve-plan`
- **THEN** the approve-plan skill SHALL execute, read the current OpenSpec `tasks.md`, assess task quality, and present the plan for human approval

#### Scenario: All eight skills listed

- **WHEN** a user runs `/plugin list workflow-core`
- **THEN** exactly 8 skills SHALL appear: spec, approve-plan, build, write-tests, pr-review, simplify, pr-create, debug-recovery

---

### Requirement: workflow-tools covers all extended phases

The `workflow-tools` plugin SHALL provide skills including: `issue-to-task`, `new-task`, `challenge`, `doc-lint`, `agent-optimise`, `learn-from-mistakes`, `workflow-lint`. Each SHALL be invocable as `/workflow-tools:<name>`. A deprecated `grill-me` stub SHALL redirect to `challenge`.

#### Scenario: Invoke the challenge skill

- **WHEN** a user types `/workflow-tools:challenge todo/my-feature.md`
- **THEN** the challenge skill SHALL read the specified file and begin the challenge interview

#### Scenario: Deprecated grill-me stub redirects

- **WHEN** a user types `/workflow-tools:grill-me todo/my-feature.md`
- **THEN** a one-line deprecation message SHALL appear directing the user to use `/workflow-tools:challenge`

---

### Requirement: workflow-agents provides all twelve agents

The `workflow-agents` plugin SHALL provide exactly 12 agents: capturer, debugger, challenger, specifier, approver, builder, tester, tdd-expert, reviewer, simplifier, pr-creator, retrospector. Each SHALL appear in `/agents` with a trigger description matching its phase.

#### Scenario: Agents appear in list

- **WHEN** a user opens `/agents`
- **THEN** all twelve agents SHALL be listed with their phase labels and brief descriptions

---

### Requirement: Phase skills do not auto-invoke

All skills in `workflow-core` and `workflow-tools` SHALL set `disable-model-invocation: true` in their SKILL.md frontmatter. No workflow skill SHALL activate unless the user explicitly invokes it by name.

#### Scenario: Skill does not auto-trigger

- **WHEN** Claude Code is processing a response without an explicit skill invocation
- **THEN** no workflow skill SHALL activate

---

### Requirement: spec halts without OpenSpec

`spec` SHALL check for the presence of an `openspec/` directory in the project root before executing. If the directory is absent, it SHALL halt and output exactly: `OpenSpec not initialised. Run: openspec init`

#### Scenario: OpenSpec missing

- **WHEN** a user runs `/workflow-core:spec` in a project without `openspec/`
- **THEN** execution SHALL halt with the message `OpenSpec not initialised. Run: openspec init`
- **AND** no files SHALL be modified

#### Scenario: OpenSpec present

- **WHEN** `openspec/` exists at the project root
- **THEN** `spec` SHALL proceed normally with the provided ideation file

---

### Requirement: pr-review requires explicit PR reference

`pr-review` SHALL require a PR number or URL as `$ARGUMENTS`. If no argument is provided, it SHALL halt with a usage hint. It SHALL NOT create PRs.

#### Scenario: No argument given

- **WHEN** a user runs `/workflow-core:pr-review` with no argument
- **THEN** execution SHALL halt with: `Usage: /workflow-core:pr-review <PR-number-or-URL>`

#### Scenario: Valid PR number given

- **WHEN** a user runs `/workflow-core:pr-review 42`
- **THEN** the skill SHALL fetch PR #42 via `gh pr view 42` and `gh pr diff 42`
- **AND** produce a structured review with no edits to any file

---

### Requirement: challenge defaults to most recent todo file

`challenge` SHALL accept an optional file path as `$ARGUMENTS`. If no argument is given, it SHALL find the most recently modified file in `todo/` and use that as the interview target.

#### Scenario: File path argument provided

- **WHEN** a user runs `/workflow-tools:challenge todo/my-feature.md`
- **THEN** challenge SHALL read `todo/my-feature.md` and begin the challenge interview

#### Scenario: No argument provided

- **WHEN** a user runs `/workflow-tools:challenge` with no argument
- **THEN** challenge SHALL identify the most recently modified file in `todo/`
- **AND** use that file as the interview target

---

### Requirement: agent-optimise audits both scopes

`agent-optimise` SHALL always audit both the project-level `.claude/` directory and the personal `~/.claude/` directory in a single pass. No flag or argument SHALL be required to include either scope.

#### Scenario: Full audit runs

- **WHEN** a user runs `/workflow-tools:agent-optimise`
- **THEN** the skill SHALL scan both `.claude/` and `~/.claude/`
- **AND** produce a single prioritised fix list covering CLAUDE.md scope/length, agent descriptions, skill frontmatter, and settings.json conflicts across the combined surface

---

### Requirement: pr-create creates PR only

`pr-create` SHALL create a PR via `gh pr create` and report the PR URL. It SHALL NOT trigger deployment, wait for CI, or include deployment steps in its output.

#### Scenario: pr-create completes

- **WHEN** a user runs `/workflow-core:pr-create`
- **THEN** a PR SHALL be created and its URL SHALL be reported
- **AND** no deployment action SHALL be taken

---

### Requirement: Ideation file format is shared

Both `issue-to-task` and `new-task` SHALL produce files at `todo/{slug}.md` with YAML frontmatter (`source`, `ticket` [omit if scratch], `created`, `status: ideation`) and exactly four sections: Context, What we know, Open questions, Rough scope.

#### Scenario: new-task output consumed by challenge

- **WHEN** `/workflow-tools:new-task` creates `todo/my-idea.md`
- **AND** a user runs `/workflow-tools:challenge todo/my-idea.md`
- **THEN** challenge SHALL read the file successfully without requiring adaptation

#### Scenario: issue-to-task output consumed by spec

- **WHEN** `/workflow-tools:issue-to-task` creates `todo/proj-123.md`
- **AND** a user runs `/workflow-core:spec todo/proj-123.md`
- **THEN** spec SHALL read the file successfully and begin OpenSpec generation

---

### Requirement: Seeded skills carry attribution

Each skill in `workflow-core` seeded from `addyosmani/agent-skills` SHALL include `# Source: https://github.com/addyosmani/agent-skills — MIT licence` as a comment in its SKILL.md frontmatter. Affected skills: `approve-plan`, `build`, `simplify`, `pr-create`.

#### Scenario: Attribution present in approve-plan skill

- **WHEN** a developer reads `plugins/workflow-core/skills/approve-plan/SKILL.md`
- **THEN** the frontmatter SHALL contain: `# Source: https://github.com/addyosmani/agent-skills — MIT licence`

---

### Requirement: Fresh machine install in four commands

A user with Academy-Plus org access and prerequisites installed (Claude Code, OpenSpec CLI, GitHub CLI) SHALL be able to install the complete marketplace with exactly four commands, after which all skills and agents are available.

#### Scenario: Fresh install sequence

- **WHEN** a user runs the four install commands:
  - `/plugin marketplace add Academy-Plus/spwf`
  - `/plugin install workflow-core@simon-marketplace`
  - `/plugin install workflow-tools@simon-marketplace`
  - `/plugin install workflow-agents@simon-marketplace`
- **THEN** all workflow skills SHALL be invocable via their namespaced commands
- **AND** all twelve agents SHALL appear in `/agents`
- **AND** no additional steps SHALL be required
