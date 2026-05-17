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
- **THEN** tracker-dispatch SHALL route all tracker operations (create_issue, get_issue, add_comment, transition) to the Beads backend module
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

### Requirement: Raw bd CLI is the only Beads interface

The Beads backend module SHALL invoke the `bd` CLI directly for every operation (`bd write`, `bd show`, `bd remember`, `bd close`, `bd reopen`). It SHALL NOT invoke `bd setup claude` or rely on any artefact `bd setup claude` would install.

#### Scenario: No bd setup claude

- **WHEN** a contributor follows the install instructions in `plugins/spwf-beadsify/README.md`
- **THEN** the README SHALL explicitly warn against running `bd setup claude`
- **AND** the warning SHALL include the reasoning that SPWF provides its own Claude Code integration

#### Scenario: Backend uses raw CLI

- **WHEN** any tracker-dispatch operation is routed to the Beads backend
- **THEN** the backend SHALL invoke `bd` as a subprocess
- **AND** SHALL NOT invoke any artefact installed by `bd setup claude`

---

### Requirement: Beads database is per-project and gitignored

The Beads database SHALL live at `./.bd/` in the project root and SHALL be excluded from git via `.gitignore`. OpenSpec change directories remain the durable source-of-truth; Beads is the execution-time scratchpad.

#### Scenario: Missing .bd/ produces a clear error

- **WHEN** a tracker-dispatch operation is routed to the Beads backend
- **AND** `./.bd/` does not exist in the project root
- **THEN** the backend SHALL halt with: `.bd/ not initialised. Run: bd init (in the project root) then retry.`

#### Scenario: .bd/ is gitignored

- **WHEN** a user follows the install instructions
- **THEN** `.gitignore` SHALL include `.bd/`
- **AND** Beads writes SHALL produce zero tracked changes in `git status`

---

### Requirement: Existing skills work unchanged

Skills that already use tracker-dispatch (`/spwf:capture`, `/spwf:tracker-comment`, `/spwf:close`) SHALL acquire Beads behaviour without any change to their SKILL.md bodies.

#### Scenario: capture creates a Beads story

- **WHEN** `/spwf:capture` runs with `source: scratch` (or any input that triggers ticket creation) and `tracker: beads` is configured
- **THEN** the backend SHALL invoke `bd write "<title>"` and return a `bd-NNN` id
- **AND** the ideation file frontmatter SHALL record `ticket: bd-NNN`

#### Scenario: tracker-comment lands in Beads

- **WHEN** `/spwf:tracker-comment` runs against a change whose proposal frontmatter contains `ticket: bd-NNN`
- **AND** `tracker: beads` is configured
- **THEN** the backend SHALL persist the comment to the Beads store (default mapping: `bd remember bd-NNN "<text>"`)
- **AND** `bd show bd-NNN` SHALL surface the comment in its audit trail

#### Scenario: close transitions the Beads story

- **WHEN** `/spwf:close` reaches the tracker-transition step against a change with `ticket: bd-NNN`
- **AND** `tracker: beads` is configured
- **THEN** the backend SHALL invoke `bd close bd-NNN` before the OpenSpec archive step runs
- **AND** `bd show bd-NNN` SHALL report the story as closed
