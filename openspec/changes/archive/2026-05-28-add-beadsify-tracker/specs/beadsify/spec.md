# Spec: beadsify

## ADDED Requirements

### Requirement: Optional plugin install

The Beads integration SHALL be packaged as a separate optional plugin `spwf-beadsify` listed as a third entry in `.claude-plugin/marketplace.json`. Users who do not install the plugin SHALL see exactly the existing SPWF behaviour with no Beads-related side effects.

#### Scenario: Install Beadsify

- **WHEN** a user runs `/plugin install spwf-beadsify@spwf` after `/plugin marketplace add` for this repo
- **THEN** the plugin SHALL be listed by `/plugin list`
- **AND** the spwf-beadsify skills SHALL be discoverable

#### Scenario: Beadsify uninstalled is invisible

- **WHEN** `spwf-beadsify` is not installed and `.spwf/tracker.yaml` is unset or set to a non-`beads` backend
- **THEN** no Beads CLI invocation SHALL be attempted
- **AND** the existing tracker-dispatch behaviour SHALL be byte-identical to today

---

### Requirement: tracker.yaml selects the Beads backend

The `.spwf/tracker.yaml` configuration SHALL accept `tracker: beads` as a valid value alongside the existing `youtrack`, `jira`, and `none` options.

#### Scenario: Beads selected

- **WHEN** `.spwf/tracker.yaml` contains `tracker: beads` and `spwf-beadsify` is installed
- **THEN** tracker-dispatch SHALL route all tracker operations (create_issue, get_issue, add_comment, set_state) to the Beads backend module
- **AND** no YouTrack or Jira API calls SHALL occur

#### Scenario: Other backends unchanged

- **WHEN** `.spwf/tracker.yaml` is set to `tracker: youtrack`, `tracker: jira`, or `tracker: none`
- **THEN** dispatch SHALL behave exactly as today
- **AND** the presence or absence of `spwf-beadsify` SHALL have no effect

---

### Requirement: Configured-but-not-installed errors clearly

When `.spwf/tracker.yaml` sets `tracker: beads` but `spwf-beadsify` is not installed, tracker-dispatch SHALL halt with a verbatim error naming the fix.

#### Scenario: Beads configured without plugin

- **WHEN** `.spwf/tracker.yaml` contains `tracker: beads`
- **AND** the file `plugins/spwf-beadsify/skills/tracker-backend/SKILL.md` is not present in the loaded plugin set
- **THEN** the next tracker-dispatch invocation SHALL halt with: `tracker: beads requested but spwf-beadsify plugin not installed. Install: /plugin install spwf-beadsify@spwf. Or change tracker in .spwf/tracker.yaml.`
- **AND** no files SHALL be modified

---

### Requirement: Raw bd CLI is the only Beads interface; Beads-installed Claude integration is forbidden

The Beads backend module SHALL invoke the `bd` CLI directly for the operations the dispatch needs (`bd create`, `bd show --json`, `bd comment`, `bd close`). It SHALL NOT invoke, depend on, or assume the presence of any Beads-installed Claude Code integration. Two Beads commands install such integration and are explicitly forbidden as install steps for an SPWF project:

- `bd setup claude` — installs Beads' opinionated Claude Code integration.
- **Plain `bd init`** — has the same side effects as `bd setup claude`: it writes `CLAUDE.md` and `AGENTS.md` to the project root, creates `.claude/settings.json`, and registers `SessionStart` + `PreCompact` hooks of Beads' own design.

The only safe way to initialise Beads inside an SPWF project is `bd init --skip-agents --skip-hooks --non-interactive`.

#### Scenario: README warns against both bd setup claude and plain bd init

- **WHEN** a contributor reads `plugins/spwf-beadsify/README.md`
- **THEN** the README SHALL include an explicit warning against running both `bd setup claude` and plain `bd init`
- **AND** the warning SHALL state the reasoning (SPWF provides its own Claude Code integration; both commands would install a conflicting one)
- **AND** the README SHALL present the safe init command `bd init --skip-agents --skip-hooks --non-interactive` as the only sanctioned way to initialise Beads in an SPWF project

#### Scenario: Backend uses raw CLI only

- **WHEN** any tracker-dispatch operation is routed to the Beads backend
- **THEN** the backend SHALL invoke `bd` as a subprocess
- **AND** SHALL NOT invoke any Beads command that installs Claude Code integration
- **AND** SHALL NOT depend on any file Beads' Claude integration would have created

---

### Requirement: Beads database is per-project and gitignored

The Beads database SHALL live under `./.beads/` in the project root. `.beads/` itself is partially tracked per bd's design: the config / metadata / project_id are committed (shared across machines via git); the Dolt DB and runtime files are gitignored via `.beads/.gitignore` (managed by bd). The project-root `.gitignore` SHALL contain the patterns bd init adds (`.dolt/`, `*.db`, `.beads-credential-key`). OpenSpec change directories remain the durable source-of-truth for spec content; Beads is the execution-time scratchpad for issue tracking.

#### Scenario: Missing .beads/ produces a clear error pointing at the safe init flags

- **WHEN** a tracker-dispatch operation is routed to the Beads backend
- **AND** `./.beads/` does not exist in the project root
- **THEN** the backend SHALL halt with a message that names the safe init command `bd init --skip-agents --skip-hooks --non-interactive` (not plain `bd init`) and explains that the skip flags prevent the Beads-installed Claude Code integration from conflicting with SPWorkflow
- **AND** no files SHALL be modified

#### Scenario: Dolt DB is local; JSONL audit log is tracked

- **WHEN** a user follows the install instructions and `bd init --skip-agents --skip-hooks --non-interactive` has run
- **THEN** the project-root `.gitignore` SHALL contain `.dolt/`, `*.db`, and `.beads-credential-key`
- **AND** `.beads/.gitignore` SHALL exist and ignore the Dolt DB (`embeddeddolt/`, `dolt/`), runtime files (`*.lock`, `*.sock`, daemon files), `export-state.json`, and `last-touched`

#### Scenario: JSONL auto-export evolves with bd usage

- **WHEN** routine bd operations (`bd create`, `bd close`, `bd comment`) run
- **THEN** `.beads/issues.jsonl` and `.beads/interactions.jsonl` SHALL be auto-exported by bd and SHALL show as tracked changes in `git status`
- **AND** these files are intentionally tracked (not in `.beads/.gitignore`) so the issue audit trail travels via git
- **AND** users commit these alongside other work in their normal workflow (no special handling required by spwf-beadsify)
- **AND** users who want strict "git status clean" semantics MAY disable auto-export via `bd config set export.auto false` (documented in the plugin README) at the cost of losing the JSONL audit view

---

### Requirement: Existing skills work unchanged

Skills that already use tracker-dispatch (`/spwf:capture`, `/spwf:tracker-comment`, `/spwf:close`) SHALL acquire Beads behaviour without any change to their SKILL.md bodies.

#### Scenario: capture creates a Beads story

- **WHEN** `/spwf:capture` runs with `source: scratch` (or any input that triggers ticket creation) and `tracker: beads` is configured
- **THEN** the backend SHALL invoke `bd create --silent` (piping `body` via `--body-file -` if non-empty) and return a `<prefix>-<hash>` id
- **AND** the ideation file frontmatter SHALL record `ticket: <prefix>-<hash>`

#### Scenario: tracker-comment lands in Beads

- **WHEN** `/spwf:tracker-comment` runs against a change whose proposal frontmatter contains `ticket: <prefix>-<hash>`
- **AND** `tracker: beads` is configured
- **THEN** the backend SHALL persist the comment to the Beads store (`bd comment <id> --stdin`, body piped in — verified against bd 1.0.4)
- **AND** `bd show <prefix>-<hash>` SHALL surface the comment in its audit trail

#### Scenario: close transitions the Beads story

- **WHEN** `/spwf:close` reaches the tracker-transition step against a change with `ticket: <prefix>-<hash>`
- **AND** `tracker: beads` is configured
- **THEN** the backend SHALL invoke `bd close <id>` before the OpenSpec archive step runs
- **AND** `bd show <prefix>-<hash>` SHALL report the story as closed

---

### Requirement: Concurrent sessions are supported

A second Claude Code session in the same project SHALL be able to create, comment on, or query Beads stories via the spwf-beadsify backend while another session is running a build, without corrupting the Beads store or perturbing the active build's task selection.

#### Scenario: Braindump while building

- **WHEN** Session A is running a build loop against a change whose `proposal.md` contains `beads_story_id: bd-A`
- **AND** Session B concurrently invokes `/spwf:capture` (or any tracker-touching skill) producing a new story `bd-B` not in `bd-A`'s subtree
- **THEN** Session A's `bd next` calls SHALL continue returning items from `bd-A`'s subtree only and SHALL NOT surface `bd-B`
- **AND** the Beads store SHALL contain both `bd-A` (and its children, in their pre-existing states) and `bd-B`
- **AND** no `.beads/` corruption SHALL be observable via `bd list` / `bd show`

#### Scenario: Concurrent writers don't corrupt the store

- **WHEN** two `bd create --silent` invocations execute simultaneously against the same `.beads/`
- **THEN** both stories SHALL be created with distinct hash-based ids
- **AND** `bd list` SHALL show both
