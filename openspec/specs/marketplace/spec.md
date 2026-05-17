# marketplace Specification

## Purpose

Defines the shape of the SPWorkflow plugin marketplace: how the catalog is named and structured, which plugins it ships, how those plugins are invoked, and the install path for both downstream users and local dogfooding. The marketplace is the distribution mechanism for the workflow skills and agents; this spec is what consumers can rely on remaining stable.

## Requirements

### Requirement: Marketplace catalog

The repo SHALL contain a `.claude-plugin/marketplace.json` at its root that is valid JSON conforming to the Claude Code marketplace schema, with name `spwf`, two plugins (`spwf`, `spwf-agents`), and `pluginRoot` set to `./plugins`.

#### Scenario: Install from GitHub

- **WHEN** a user runs `/plugin marketplace add simon-potter/spwf`
- **THEN** Claude Code SHALL read `.claude-plugin/marketplace.json` and register `spwf` as an available source

#### Scenario: Install from local path

- **WHEN** a developer runs `/plugin marketplace add ./` from the repo root
- **THEN** Claude Code SHALL read the local `marketplace.json` and register it identically

---

### Requirement: spwf plugin covers the engineering cycle

The `spwf` plugin SHALL provide the skills that implement the full SPWorkflow engineering cycle. Every skill SHALL be invocable as `/spwf:<name>`. The plugin description in `plugin.json` SHALL state the skill count accurately.

#### Scenario: Invoke a phase skill

- **WHEN** a user types `/spwf:approve-plan`
- **THEN** the approve-plan skill SHALL execute, read the current OpenSpec `tasks.md`, assess task quality, and present the plan for human approval

#### Scenario: Skill discovery after install

- **WHEN** a user runs `/plugin list` after installing `spwf@spwf`
- **THEN** the plugin SHALL be listed
- **AND** every skill directory under `plugins/spwf/skills/` containing a `SKILL.md` SHALL be available as `/spwf:<name>`

---

### Requirement: spwf-agents plugin provides paired subagents

The `spwf-agents` plugin SHALL provide specialist subagents paired to the workflow phases. Each agent SHALL appear in `/agents` with a trigger description that explains when the agent fires.

#### Scenario: Agents appear in list

- **WHEN** a user opens `/agents` after installing `spwf-agents@spwf`
- **THEN** all agent `.md` files under `plugins/spwf-agents/agents/` SHALL be listed with their descriptions

---

### Requirement: Phase skills do not auto-invoke

Every skill in `plugins/spwf/skills/` whose role is a workflow phase SHALL set `disable-model-invocation: true` in its SKILL.md frontmatter. Phase skills SHALL NOT activate unless the user explicitly invokes them by name.

#### Scenario: Skill does not auto-trigger

- **WHEN** Claude Code is processing a response without an explicit skill invocation
- **THEN** no `/spwf:<phase>` skill SHALL activate

---

### Requirement: spec halts without OpenSpec

`/spwf:spec` SHALL check for the presence of an `openspec/` directory in the project root before executing. If the directory is absent, it SHALL halt and output exactly: `OpenSpec not initialised. Run: openspec init`

#### Scenario: OpenSpec missing

- **WHEN** a user runs `/spwf:spec` in a project without `openspec/`
- **THEN** execution SHALL halt with the message `OpenSpec not initialised. Run: openspec init`
- **AND** no files SHALL be modified

#### Scenario: OpenSpec present

- **WHEN** `openspec/` exists at the project root
- **THEN** `/spwf:spec` SHALL proceed normally with the provided ideation file

---

### Requirement: pr-review requires explicit PR reference

`/spwf:pr-review` SHALL require a PR or MR reference as `$ARGUMENTS`. If no argument is provided, it SHALL halt with a usage hint. It SHALL NOT create PRs or MRs.

#### Scenario: No argument given

- **WHEN** a user runs `/spwf:pr-review` with no argument
- **THEN** execution SHALL halt with a usage hint that names the expected argument

#### Scenario: Valid PR reference given

- **WHEN** a user runs `/spwf:pr-review 42`
- **THEN** the skill SHALL fetch the PR via the active forge CLI (`glab` by default, `gh` supported)
- **AND** produce a structured review with no edits to any file other than the review report

---

### Requirement: challenge defaults to most recent todo file

`/spwf:challenge` SHALL accept an optional file path as `$ARGUMENTS`. If no argument is given, it SHALL find the most recently modified file in `todo/` and use that as the interview target.

#### Scenario: File path argument provided

- **WHEN** a user runs `/spwf:challenge todo/my-feature.md`
- **THEN** challenge SHALL read `todo/my-feature.md` and begin the challenge interview

#### Scenario: No argument provided

- **WHEN** a user runs `/spwf:challenge` with no argument
- **THEN** challenge SHALL identify the most recently modified file in `todo/`
- **AND** use that file as the interview target

---

### Requirement: pr-create creates a request only

`/spwf:pr-create` SHALL create a pull request or merge request via the active forge CLI and report the resulting URL. It SHALL NOT trigger deployment, wait for CI, or include deployment steps in its output.

#### Scenario: pr-create completes

- **WHEN** a user runs `/spwf:pr-create`
- **THEN** a PR or MR SHALL be created on the auto-detected forge and its URL SHALL be reported
- **AND** no deployment action SHALL be taken

---

### Requirement: Ideation file format is shared

Skills that produce ideation files (including `/spwf:capture`, `/spwf:new-task`, `/spwf:issue-to-task`) SHALL produce files at `todo/{slug}.md` with YAML frontmatter (`source`, `ticket` if applicable, `created`, `status: ideation` or `status: proposed`) and the four canonical sections: Context, What we know, Open questions, Rough scope.

#### Scenario: capture output consumed by challenge

- **WHEN** `/spwf:capture` creates `todo/my-idea.md`
- **AND** a user runs `/spwf:challenge todo/my-idea.md`
- **THEN** challenge SHALL read the file successfully without requiring adaptation

#### Scenario: capture output consumed by spec

- **WHEN** `/spwf:capture` creates `todo/proj-123.md`
- **AND** a user runs `/spwf:spec todo/proj-123.md`
- **THEN** spec SHALL read the file successfully and begin OpenSpec generation

---

### Requirement: Seeded skills carry attribution

Each skill seeded from `addyosmani/agent-skills` SHALL include `# Source: https://github.com/addyosmani/agent-skills — MIT licence` as a comment in its SKILL.md frontmatter.

#### Scenario: Attribution present in a seeded skill

- **WHEN** a developer reads a SKILL.md known to derive from `addyosmani/agent-skills`
- **THEN** the frontmatter SHALL contain the attribution comment

---

### Requirement: Fresh machine install in three commands

A user with the prerequisites installed (Claude Code, OpenSpec CLI, forge CLI) SHALL be able to install the complete marketplace with three commands, after which all skills and agents are available.

#### Scenario: Fresh install sequence

- **WHEN** a user runs the three install commands:
  - `/plugin marketplace add simon-potter/spwf`
  - `/plugin install spwf@spwf`
  - `/plugin install spwf-agents@spwf`
- **THEN** every skill in `plugins/spwf/skills/` SHALL be invocable as `/spwf:<name>`
- **AND** every agent in `plugins/spwf-agents/agents/` SHALL appear in `/agents`
- **AND** no additional steps SHALL be required

#### Scenario: Local dogfooding install

- **WHEN** a developer runs the install commands from the repo root with the marketplace path `./` instead of the GitHub source
- **THEN** the install SHALL succeed identically
- **AND** edits to `plugins/**` SHALL take effect after `/reload-plugins` without publishing
