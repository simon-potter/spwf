# Spec: comprehension

## ADDED Requirements

### Requirement: The understand skill runs a post-ship comprehension interview

`/spwf:understand` SHALL interview the developer about a completed change, one
question at a time, and produce an orientation note. It SHALL accept an empty
argument (detect from the current branch or most recent change), a change-id, a
todo path, or a branch name / commit range, resolving each to a change the same
way `close` and `recap` do.

The skill SHALL declare `disable-model-invocation: true` and SHALL NOT include
`AskUserQuestion` in `allowed-tools`, because that tool is structurally
multiple-choice and would reintroduce the rejected quiz format.

#### Scenario: Standalone run against an active change

- **WHEN** `/spwf:understand add-user-export` runs and
  `openspec/changes/add-user-export/` exists
- **THEN** the skill SHALL read the change's structural shape via
  `git diff --stat` and `git log` over the change's commit range
- **AND** SHALL select 3–5 structural changes to interview on, stating which
  were selected and why
- **AND** SHALL ask questions one at a time, waiting for an answer before the
  next
- **AND** SHALL produce an orientation note containing a "Where to look when
  things go wrong" section

#### Scenario: Standalone run against an archived change

- **WHEN** the change-id resolves only under
  `openspec/changes/archive/{change-id}/`
- **THEN** the skill SHALL proceed using the archived artefacts
- **AND** SHALL NOT fail because no `recap` output is present in session

#### Scenario: Change cannot be resolved

- **WHEN** the supplied argument matches no change in `openspec/changes/` or
  `openspec/changes/archive/`
- **THEN** the skill SHALL halt with a message naming both searched locations
- **AND** SHALL NOT fall back to interviewing on an unrelated change

### Requirement: The interview operates at orientation depth

Questions SHALL be answerable by someone who understands the shape and
consequences of the change without having written it. The skill SHALL NOT ask
questions answerable only by the person who typed the code.

#### Scenario: Question rejected for excessive fidelity

- **WHEN** the skill derives a candidate question about null-check placement, a
  specific guard clause, an individual error branch, or a variable name
- **THEN** it SHALL discard that question as below the fidelity target
- **AND** SHALL derive a replacement at structural level (a new dependency, a
  changed interface, an altered data flow, a new integration point)

#### Scenario: Trivial change

- **WHEN** the change contains no structural change a developer would need to
  navigate later
- **THEN** the skill SHALL decline to interview, state that plainly, and stop
- **AND** SHALL NOT manufacture questions to fill the session

### Requirement: The interview is structure-anchored

Questions SHALL be derived from what changed structurally — new modules, new
dependencies, changed interfaces, altered data flow, newly-wired connections —
using `design.md` and `proposal.md` as supporting material only. The skill SHALL
read `git diff --stat` and selective reads of significant changed files rather
than the complete diff.

#### Scenario: Agent-made decision absent from design.md

- **WHEN** the change introduced a structural element that appears in the diff
  but in no design artefact
- **THEN** the skill SHALL interview on that element
- **AND** SHALL NOT restrict its questions to decisions recorded in `design.md`

#### Scenario: Large diff

- **WHEN** the change's diff exceeds what can be read in full
- **THEN** the skill SHALL work from `--stat` plus selective file reads
- **AND** SHALL NOT halt or truncate the interview for diff size alone

### Requirement: The interview does not repeat recap

When invoked as Retrospective Part 6, the skill SHALL NOT ask questions whose
answers `recap` supplied in Part 5. `recap` covers what changed and why;
`understand` covers consequence and navigation.

#### Scenario: Candidate question duplicates recap content

- **WHEN** a candidate question's answer appears in the recap output already
  shown in this session
- **THEN** the skill SHALL discard that question
- **AND** SHALL substitute one probing consequence or navigation instead

### Requirement: The interview closes with a navigation question

Every interview SHALL end by asking where the developer would look first if the
change misbehaves later, and what they would expect to see — regardless of how
the preceding questions went.

#### Scenario: Interview ends

- **WHEN** the selected structural changes have been covered, or the developer
  exits early, or the question cap is reached
- **THEN** the skill SHALL ask the navigation question before producing output

#### Scenario: Developer answers "I don't know"

- **WHEN** the developer answers any question with "I don't know" or equivalent
- **THEN** the skill SHALL record it as a finding, without grade or penalty
- **AND** SHALL note what would close the gap
- **AND** SHALL NOT re-ask the same question or express disapproval

### Requirement: The skill produces an orientation note

Output SHALL be an orientation note for the developer's future self containing:
the shape of the change, where to look when things go wrong, what remains
fuzzy, and concepts touched. It SHALL NOT contain a merge verdict or a
readiness recommendation.

#### Scenario: Note offered for saving

- **WHEN** the orientation note has been produced
- **THEN** the skill SHALL offer to save it to
  `openspec/changes/{change-id}/understanding.md`
- **AND** on acceptance SHALL write that file so it travels into the OpenSpec
  archive with the change

#### Scenario: Interview abandoned partway

- **WHEN** the developer exits before all selected changes are covered
- **THEN** the skill SHALL produce an orientation note covering what was
  discussed
- **AND** SHALL NOT discard the partial session

### Requirement: A learner profile persists level and gaps

The skill SHALL read and maintain `.spwf/learner.md` in the target project,
recording a coarse level, concepts demonstrated (`Known`), gaps still open
(`Open`), and recurring blind spots. The file SHALL be gitignored.

Level SHALL govern explanation depth and vocabulary only. It SHALL NOT reduce
the rigour of questions at any level.

#### Scenario: First run with no profile

- **WHEN** `.spwf/learner.md` does not exist
- **THEN** the skill SHALL ask a single calibration question, create the file,
  and SHALL NOT ask that question again on later runs
- **AND** SHALL ensure `.spwf/learner.md` is present in `.gitignore`

#### Scenario: Level affects framing, not rigour

- **WHEN** the profile records level `new` for an area
- **THEN** the skill SHALL add scaffolding and name concepts before probing them
- **AND** SHALL ask questions of the same difficulty it would ask at `fluent`

#### Scenario: Profile updated after a session

- **WHEN** an interview completes
- **THEN** demonstrated concepts SHALL move to `Known` with the change-id and
  date, and unresolved gaps SHALL be recorded under `Open` with what would close
  them

### Requirement: Retrospective offers the interview as Part 6

`/spwf:retrospective` SHALL invoke `understand` as Part 6, after `recap`, with
`changelog` renumbered to Part 7. The prompt SHALL default to yes (`[Y/n]`) and
SHALL name something specific about the change rather than making a generic
offer.

#### Scenario: Part 6 accepted

- **WHEN** the developer accepts at the Part 6 prompt
- **THEN** the skill SHALL run with the change-id passed explicitly, rendering
  its sections nested under the Part 6 heading

#### Scenario: Part 6 declined

- **WHEN** the developer answers "n" at the Part 6 prompt
- **THEN** the retrospective SHALL continue to Part 7 and note "Part 6 skipped"
  in its report
- **AND** SHALL surface that `/spwf:understand {change-id}` remains available
  later
