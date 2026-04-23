# Spec: marketplace

> **Authoritative Reference:** [`todo/Marketplace_setup.md`](../../../../../todo/Marketplace_setup.md) contains the full skill inventory, agent table, workflow coverage map, and acceptance criteria.

## ADDED Requirements

### Requirement: Marketplace catalog

The repo SHALL contain a `.claude-plugin/marketplace.json` at its root that is valid JSON conforming to the Claude Code marketplace schema, with name `simon-marketplace`, three plugins (workflow-core, workflow-tools, workflow-agents), and `pluginRoot` set to `./plugins`.

#### Scenario: Install from GitHub

- **WHEN** a user with Academy-Plus org access runs `/plugin marketplace add Academy-Plus/plugin-marketplace-simon`
- **THEN** Claude Code SHALL read `.claude-plugin/marketplace.json` and register `simon-marketplace` as an available source

#### Scenario: Install from local path

- **WHEN** a developer runs `/plugin marketplace add ./` from the repo root
- **THEN** Claude Code SHALL read the local `marketplace.json` and register it identically

---

### Requirement: workflow-core covers all seven phases

The `workflow-core` plugin SHALL provide exactly 8 skills: `task-to-spec`, `plan`, `build`, `test-creator`, `test`, `pr-reviewer`, `simplify`, `ship`. Each SHALL be invocable as `/workflow-core:<name>`.

#### Scenario: Invoke a phase skill

- **WHEN** a user types `/workflow-core:plan`
- **THEN** the plan skill SHALL execute and read the current OpenSpec `tasks.md`

#### Scenario: All eight skills listed

- **WHEN** a user runs `/plugin list workflow-core`
- **THEN** exactly 8 skills SHALL appear: task-to-spec, plan, build, test-creator, test, pr-reviewer, simplify, ship

---

### Requirement: workflow-tools covers all extended phases

The `workflow-tools` plugin SHALL provide exactly 6 skills: `issue-to-task`, `new-task`, `grill-me`, `doc-lint`, `agent-optimise`, `learn-from-mistakes`. Each SHALL be invocable as `/workflow-tools:<name>`.

#### Scenario: Invoke a tools skill

- **WHEN** a user types `/workflow-tools:grill-me todo/my-feature.md`
- **THEN** the grill-me skill SHALL read the specified file and begin the challenge interview

#### Scenario: All six skills listed

- **WHEN** a user runs `/plugin list workflow-tools`
- **THEN** exactly 6 skills SHALL appear: issue-to-task, new-task, grill-me, doc-lint, agent-optimise, learn-from-mistakes

---

### Requirement: workflow-agents provides all eight agents

The `workflow-agents` plugin SHALL provide exactly 8 agents: capturer, specifier, planner, builder, tester, reviewer, simplifier, shipper. Each SHALL appear in `/agents` with a trigger description matching its phase.

#### Scenario: Agents appear in list

- **WHEN** a user opens `/agents`
- **THEN** all eight agents SHALL be listed with their phase labels and brief descriptions

---

### Requirement: Phase skills do not auto-invoke

All skills in `workflow-core` and `workflow-tools` SHALL set `disable-model-invocation: true` in their SKILL.md frontmatter. No workflow skill SHALL activate unless the user explicitly invokes it by name.

#### Scenario: Skill does not auto-trigger

- **WHEN** Claude Code is processing a response without an explicit skill invocation
- **THEN** no workflow skill SHALL activate

---

### Requirement: task-to-spec halts without OpenSpec

`task-to-spec` SHALL check for the presence of an `openspec/` directory in the project root before executing. If the directory is absent, it SHALL halt and output exactly: `OpenSpec not initialised. Run: openspec init`

#### Scenario: OpenSpec missing

- **WHEN** a user runs `/workflow-core:task-to-spec` in a project without `openspec/`
- **THEN** execution SHALL halt with the message `OpenSpec not initialised. Run: openspec init`
- **AND** no files SHALL be modified

#### Scenario: OpenSpec present

- **WHEN** `openspec/` exists at the project root
- **THEN** `task-to-spec` SHALL proceed normally with the provided ideation file

---

### Requirement: pr-reviewer requires explicit PR reference

`pr-reviewer` SHALL require a PR number or URL as `$ARGUMENTS`. If no argument is provided, it SHALL halt with a usage hint. It SHALL NOT create PRs.

#### Scenario: No argument given

- **WHEN** a user runs `/workflow-core:pr-reviewer` with no argument
- **THEN** execution SHALL halt with: `Usage: /workflow-core:pr-reviewer <PR-number-or-URL>`

#### Scenario: Valid PR number given

- **WHEN** a user runs `/workflow-core:pr-reviewer 42`
- **THEN** the skill SHALL fetch PR #42 via `gh pr view 42` and `gh pr diff 42`
- **AND** produce a structured review with no edits to any file

---

### Requirement: grill-me defaults to most recent todo file

`grill-me` SHALL accept an optional file path as `$ARGUMENTS`. If no argument is given, it SHALL find the most recently modified file in `todo/` and use that as the interview target.

#### Scenario: File path argument provided

- **WHEN** a user runs `/workflow-tools:grill-me todo/my-feature.md`
- **THEN** grill-me SHALL read `todo/my-feature.md` and begin the challenge interview

#### Scenario: No argument provided

- **WHEN** a user runs `/workflow-tools:grill-me` with no argument
- **THEN** grill-me SHALL identify the most recently modified file in `todo/`
- **AND** use that file as the interview target

---

### Requirement: agent-optimise audits both scopes

`agent-optimise` SHALL always audit both the project-level `.claude/` directory and the personal `~/.claude/` directory in a single pass. No flag or argument SHALL be required to include either scope.

#### Scenario: Full audit runs

- **WHEN** a user runs `/workflow-tools:agent-optimise`
- **THEN** the skill SHALL scan both `.claude/` and `~/.claude/`
- **AND** produce a single prioritised fix list covering CLAUDE.md scope/length, agent descriptions, skill frontmatter, and settings.json conflicts across the combined surface

---

### Requirement: ship creates PR only

`ship` SHALL create a PR via `gh pr create` and report the PR URL. It SHALL NOT trigger deployment, wait for CI, or include deployment steps in its output.

#### Scenario: Ship completes

- **WHEN** a user runs `/workflow-core:ship`
- **THEN** a PR SHALL be created and its URL SHALL be reported
- **AND** no deployment action SHALL be taken

---

### Requirement: Ideation file format is shared

Both `issue-to-task` and `new-task` SHALL produce files at `todo/{slug}.md` with YAML frontmatter (`source`, `ticket` [omit if scratch], `created`, `status: ideation`) and exactly four sections: Context, What we know, Open questions, Rough scope.

#### Scenario: new-task output consumed by grill-me

- **WHEN** `/workflow-tools:new-task` creates `todo/my-idea.md`
- **AND** a user runs `/workflow-tools:grill-me todo/my-idea.md`
- **THEN** grill-me SHALL read the file successfully without requiring adaptation

#### Scenario: issue-to-task output consumed by task-to-spec

- **WHEN** `/workflow-tools:issue-to-task` creates `todo/proj-123.md`
- **AND** a user runs `/workflow-core:task-to-spec todo/proj-123.md`
- **THEN** task-to-spec SHALL read the file successfully and begin OpenSpec generation

---

### Requirement: Seeded skills carry attribution

Each skill in `workflow-core` seeded from `addyosmani/agent-skills` SHALL include `# Source: https://github.com/addyosmani/agent-skills — MIT licence` as a comment in its SKILL.md frontmatter. Affected skills: `plan`, `build`, `test`, `simplify`, `ship`.

#### Scenario: Attribution present in plan skill

- **WHEN** a developer reads `plugins/workflow-core/skills/plan/SKILL.md`
- **THEN** the frontmatter SHALL contain: `# Source: https://github.com/addyosmani/agent-skills — MIT licence`

---

### Requirement: Fresh machine install in four commands

A user with Academy-Plus org access and prerequisites installed (Claude Code, OpenSpec CLI, GitHub CLI) SHALL be able to install the complete marketplace with exactly four commands, after which all 14 skills and 8 agents are available.

#### Scenario: Fresh install sequence

- **WHEN** a user runs the four install commands:
  - `/plugin marketplace add Academy-Plus/plugin-marketplace-simon`
  - `/plugin install workflow-core@simon-marketplace`
  - `/plugin install workflow-tools@simon-marketplace`
  - `/plugin install workflow-agents@simon-marketplace`
- **THEN** all 14 skills SHALL be invocable via their namespaced commands
- **AND** all 8 agents SHALL appear in `/agents`
- **AND** no additional steps SHALL be required
