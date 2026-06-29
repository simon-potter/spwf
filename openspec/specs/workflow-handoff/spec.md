# workflow-handoff Specification

## Purpose
TBD - created by archiving change add-branch-enforcement. Update Purpose after archive.
## Requirements
### Requirement: pr-create points forward to close

`/spwf:pr-create` SHALL end its run by naming `/spwf:close` as the
canonical post-merge action, and SHALL state that the retrospective runs
inside close. It SHALL NOT invoke `/spwf:close` automatically.

#### Scenario: Next-step block on successful PR creation

- **WHEN** `/spwf:pr-create` completes and a PR/MR URL has been printed
- **THEN** the final output SHALL include a "Next step" block naming
  `/spwf:close` as the post-merge action
- **AND** the block SHALL state that close runs the retrospective
  (learn-from-mistakes, spec audit, doc-lint, workflow-lint, recap) and
  then archives the change and transitions the tracker ticket
- **AND** the block SHALL state that "merge and close the ticket" is not
  complete until `/spwf:close` runs

#### Scenario: close is not auto-invoked

- **WHEN** `/spwf:pr-create` completes
- **THEN** the skill SHALL NOT execute `/spwf:close` or any of its
  destructive steps (archive, tracker transition, branch deletion)
- **AND** the handoff SHALL be a textual pointer only

#### Scenario: workflow-lint flags a missing successor pointer

- **WHEN** `/spwf:workflow-lint` runs and `pr-create`'s body contains no
  forward pointer to `close`
- **THEN** workflow-lint SHALL emit a P2 finding identifying the missing
  pr-create → close handoff
- **AND** the check SHALL generalise to "every phase orchestrator names
  its successor phase," not be hard-coded to this single pair

---

### Requirement: Spec carries the tracker ticket into the proposal

`/spwf:spec` SHALL copy the ideation file's `ticket:` frontmatter into the
generated `proposal.md` as a `**Tracker**:` header line when present, and
SHALL omit it entirely when absent. `/spwf:close` SHALL read the proposal
as a fallback source for the ticket.

#### Scenario: Ideation file has a ticket

- **WHEN** `/spwf:spec` runs against an ideation file whose frontmatter
  contains `ticket: ACAD-42`
- **THEN** the generated `proposal.md` header block SHALL contain a line
  `**Tracker**: ACAD-42` alongside `**Change ID**`, `**Status**`,
  `**Created**`, and `**Source**`

#### Scenario: Ideation file has no ticket

- **WHEN** `/spwf:spec` runs against an ideation file with no `ticket:`
  field (e.g. a freeform `new-task` capture)
- **THEN** the generated `proposal.md` SHALL NOT contain a `**Tracker**:`
  line
- **AND** the skill SHALL NOT prompt for a ticket or invent one

#### Scenario: close resolves the ticket from the proposal fallback

- **WHEN** `/spwf:close` runs and the todo file has no `ticket:` field
- **AND** the change's `proposal.md` contains a `**Tracker**:` line
- **THEN** close SHALL use the proposal's tracker value to transition the
  ticket
- **AND** the todo file SHALL remain the primary source when it does carry
  a `ticket:` (proposal is consulted only as a fallback)

