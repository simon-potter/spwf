# Spec: comprehension

> Adds to the `comprehension` capability declared by `add-understand-skill`,
> which was archived first so this capability existed to add to.

## ADDED Requirements

### Requirement: brief runs as a golden-path step between spec and approve-plan

`/spwf:brief` SHALL explain a planned change before it is built, running after
`spec` and before `approve-plan`. `spec` SHALL name `brief` as its next step, and
`brief` SHALL name `approve-plan` as its next step, so the successor chain is
unbroken.

`brief` SHALL NOT be invoked automatically by `spec`. It SHALL declare
`disable-model-invocation: true` and SHALL be runnable standalone against any
change with OpenSpec artefacts.

#### Scenario: Run after spec

- **WHEN** `/spwf:brief` runs and `openspec/changes/{change-id}/` contains
  `proposal.md` and `tasks.md`
- **THEN** the skill SHALL read the ideation file and the plan artefacts and
  produce the five-section brief
- **AND** SHALL end by naming `/spwf:approve-plan` as the next step

#### Scenario: Change cannot be resolved

- **WHEN** the argument matches no change in `openspec/changes/` or
  `openspec/changes/archive/`
- **THEN** the skill SHALL halt naming both searched locations

#### Scenario: Plan artefacts are incomplete

- **WHEN** `proposal.md` or `tasks.md` is absent for the resolved change
- **THEN** the skill SHALL report what is missing and stop, rather than briefing
  from partial artefacts

### Requirement: The brief expands, then summarises

The brief SHALL present five sections in order: what will be built; why this way;
choices you didn't make; what this touches; and a closing two-to-three line
summary. Detail SHALL precede the summary, so the summary lands as a takeaway
rather than a heading.

Section 1 SHALL describe the substance in plain language and SHALL NOT reproduce
the task list.

#### Scenario: Brief is produced

- **WHEN** the skill has read the plan artefacts
- **THEN** it SHALL emit the five sections in the specified order
- **AND** the summary SHALL come last

#### Scenario: Brief would run long

- **WHEN** the change is large enough that a full brief would exceed the length
  cap
- **THEN** the skill SHALL reduce depth in sections 1, 2 and 4
- **AND** SHALL NOT reduce or omit section 3, which has no substitute elsewhere in
  the workflow

#### Scenario: Trivial change

- **WHEN** the plan contains nothing worth briefing
- **THEN** the skill SHALL say so plainly and stop, without padding the sections

### Requirement: Choices you didn't make derives from the todo to plan delta

Section 3 SHALL be derived by comparing the ideation file against the plan
artefacts (`proposal.md`, `tasks.md`, and `design.md` where it exists). Anything
in the plan with no antecedent in the ideation file is a candidate. `design.md`
SHALL be supporting detail only, never the primary source.

A candidate SHALL be reported only if choosing differently would change the shape
of the result — an approach, a dependency, a boundary, or an ordering that
constrains later work.

The ideation file SHALL be located by the filename in `proposal.md`'s `Source`
line, trying `todo/` and then `todo/_done/`, because `close` moves the file
without rewriting that link.

#### Scenario: Mechanical elaboration is filtered out

- **WHEN** the delta contains naming choices, file paths, or mechanical task
  decomposition
- **THEN** the skill SHALL exclude them from section 3
- **AND** SHALL report only decisions that change the shape of the result

#### Scenario: Change went through enrich

- **WHEN** the ideation file contains `## Directions considered`,
  `## Recommended direction`, or `## Not doing` sections written by `enrich`
- **THEN** the skill SHALL treat those as decisions the developer made
- **AND** SHALL NOT report them as choices the developer didn't make

#### Scenario: No consequential unasked-for decisions

- **WHEN** the filtered delta is empty
- **THEN** the skill SHALL say so and omit section 3
- **AND** SHALL NOT invent decisions to fill it

#### Scenario: design.md is absent

- **WHEN** the change has no `design.md`
- **THEN** the skill SHALL still produce section 3 from the ideation file against
  `proposal.md` and `tasks.md`

#### Scenario: The ideation file cannot be found

- **WHEN** neither `todo/{slug}.md` nor `todo/_done/{slug}.md` resolves, as on an
  archived change whose `Source` link was never rewritten
- **THEN** the skill SHALL say so and omit section 3
- **AND** SHALL NOT derive the delta from `design.md` alone

### Requirement: brief never blocks

The skill SHALL print its brief, offer one skippable prompt, and return. It SHALL
NOT halt the workflow, gate progression to `approve-plan`, or require an answer.

On a reported mismatch the skill SHALL name the remedy and SHALL NOT act on it —
it SHALL NOT re-run `spec`, reopen `challenge`, or edit any artefact.

#### Scenario: Prompt is dismissed

- **WHEN** the developer presses enter at the prompt
- **THEN** the skill SHALL return, naming `approve-plan` as the next step

#### Scenario: Developer reports a mismatch

- **WHEN** the developer describes something that isn't what they expected
- **THEN** the skill SHALL classify it and name the remedy — `approve-plan` for a
  task-level problem, re-running `spec` for a plan-level problem, `challenge` for
  a wrong-idea problem
- **AND** SHALL return without performing any of them

### Requirement: brief runs on changes, not bugs

`spec` SHALL record the change type in `proposal.md` as `**Type**: bug | change`.
`brief` SHALL read that line and SHALL skip changes recorded as bugs, stating that
it has done so.

When the line is absent, `brief` SHALL treat the change as a change and run.

#### Scenario: Type is bug

- **WHEN** `proposal.md` records `**Type**: bug`
- **THEN** the skill SHALL state that briefs cover changes rather than bug fixes,
  and stop

#### Scenario: Type is absent

- **WHEN** `proposal.md` has no `Type` line, as on changes spec'd before this
  capability existed
- **THEN** the skill SHALL treat it as a change and produce the brief

### Requirement: Level governs the brief's explanation depth

The skill SHALL read `.spwf/learner.md` per the `learner-profile` convention and
use the recorded level to set how much background each section carries. Level
SHALL NOT change which sections appear.

#### Scenario: No profile exists

- **WHEN** `.spwf/learner.md` does not exist
- **THEN** the skill SHALL ensure the `.gitignore` entry exists, ask the single
  calibration question, create the file, and never ask again

#### Scenario: Profile exists

- **WHEN** a level is recorded
- **THEN** `new` SHALL receive more background and concepts named before use, and
  `fluent` SHALL receive terser sections
- **AND** all five sections SHALL appear at every level

### Requirement: An explain-only skill records what it covered, and nothing more

A skill that explains without checking comprehension SHALL NOT write `## Known`,
SHALL NOT write `## Open`, and SHALL NOT adjust the recorded level in
`.spwf/learner.md`. Those require evidence that the developer understood
something, which an explain-only skill does not have. This holds whether or not
the skill records anything at all.

Where such a skill does record to the profile, it SHALL record the concepts it
covered under `## Covered`, with the change-id and date.

`## Covered` SHALL NOT suppress later explanation of the same concept. A reader
may use it to vary how a topic is framed on a second pass; it is not a signal to
skip one.

#### Scenario: brief finishes a session

- **WHEN** `/spwf:brief` has produced a brief
- **THEN** the concepts it covered SHALL be recorded under `## Covered` with the
  change-id and date
- **AND** `## Known`, `## Open` and the recorded level SHALL be unchanged

#### Scenario: A later skill reads the profile

- **WHEN** a skill that explains and checks runs on a change whose concepts
  appear under `## Covered`
- **THEN** it SHALL still explain and check those concepts rather than treating
  them as already demonstrated
