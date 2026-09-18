# comprehension Specification

## Purpose
TBD - created by archiving change add-understand-skill. Update Purpose after archive.
## Requirements
### Requirement: The skill teaches before it checks

`/spwf:understand` SHALL explain each topic before asking anything about it. It
SHALL work through 3–4 topics drawn from the change, and for each one follow the
cycle **explain → check → deepen**, announcing position ("Topic 2 of 4") so the
developer always knows where they are.

The skill SHALL NOT open a topic with a question. Explanation is the first move
at every level, for every topic.

The skill SHALL accept an empty argument (detect from the current branch or most
recent change), a change-id, a todo path, or a branch name / commit range,
resolving each the way `close` and `recap` do. It SHALL declare
`disable-model-invocation: true` and SHALL NOT include `AskUserQuestion` in
`allowed-tools`, because that tool is structurally multiple-choice.

#### Scenario: A topic is opened

- **WHEN** the skill begins a topic
- **THEN** it SHALL first explain what changed, why, and what now depends on it,
  in prose pitched at the developer's recorded level
- **AND** the explanation SHALL name the files or areas involved
- **AND** only after the explanation SHALL it ask its check question

#### Scenario: Standalone run against an archived change

- **WHEN** the change-id resolves only under `openspec/changes/archive/{id}/`
- **THEN** the skill SHALL proceed using the archived artefacts
- **AND** SHALL NOT fail because no `recap` output is present in session

#### Scenario: Change cannot be resolved

- **WHEN** the argument matches no change in `openspec/changes/` or
  `openspec/changes/archive/`
- **THEN** the skill SHALL halt naming both searched locations
- **AND** SHALL NOT fall back to interviewing on an unrelated change

### Requirement: Uncertainty triggers further teaching, never a recorded gap

The skill SHALL respond to any signal of uncertainty — "I don't know", hedging,
a wrong answer, or an answer that restates the question — by explaining the
topic again from a different angle. It SHALL NOT record the gap and move on.

The second explanation SHALL differ in approach from the first: tracing the
actual code, working a concrete example, or reasoning from consequence rather
than structure. Repeating the first explanation in different words does not
satisfy this.

A topic SHALL be recorded as open only after a second explanation has been given
and the developer still reports it hasn't landed.

#### Scenario: Developer answers "I don't know"

- **WHEN** the developer answers a check question with "I don't know" or
  equivalent
- **THEN** the skill SHALL treat that as the point of the exercise and explain
  the topic again by a different route
- **AND** SHALL confirm the second explanation landed before moving on
- **AND** SHALL NOT express disapproval, assign a score, or move to the next
  topic leaving the gap open

#### Scenario: Developer gives a thin or hedged answer

- **WHEN** an answer restates the question, appeals to what the agent said, or
  hedges
- **THEN** the skill SHALL treat it as uncertainty and teach again rather than
  accept it

#### Scenario: Second explanation also fails to land

- **WHEN** the developer reports after a second explanation that the topic still
  hasn't landed
- **THEN** the skill SHALL record it under the orientation note's open items
  with a concrete suggestion for what would close it
- **AND** SHALL move on without further re-explanation in this session

### Requirement: Check questions are answerable from what was just explained

Every check question SHALL be answerable using the explanation just given plus
ordinary reasoning. The skill SHALL NOT ask questions requiring information the
developer has not been given, nor questions with a single gradable answer it is
holding.

Prediction questions about hypothetical future scenarios are permitted **only**
when the preceding explanation supplies everything needed to answer them.

#### Scenario: Candidate question requires ungiven information

- **WHEN** a candidate check question could only be answered by someone who had
  read code or artefacts not covered in the explanation
- **THEN** the skill SHALL discard it and ask one grounded in what was explained

#### Scenario: Question would function as a puzzle

- **WHEN** a candidate question invites the developer to guess at a scenario
  rather than reason from what they were told
- **THEN** the skill SHALL discard it

### Requirement: Level governs explanation depth, never question rigour

The skill SHALL read `.spwf/learner.md` and use the recorded level to set how
much scaffolding each explanation carries. Explanation SHALL occur at every
level; no level results in no explanation.

Level SHALL NOT reduce the rigour of check questions.

#### Scenario: Level new

- **WHEN** the recorded level for an area is `new`
- **THEN** explanations SHALL name concepts before using them and SHALL offer an
  analogy or worked example where one genuinely clarifies

#### Scenario: Level fluent

- **WHEN** the recorded level is `fluent`
- **THEN** explanations SHALL be terser and assume vocabulary
- **AND** SHALL still occur before every check question
- **AND** check questions SHALL be no easier than at any other level

#### Scenario: First run with no profile

- **WHEN** `.spwf/learner.md` does not exist
- **THEN** the skill SHALL ensure the `.gitignore` entry exists, ask a single
  calibration question, create the file, and never ask that question again

### Requirement: Topics are structure-anchored at orientation depth

Topics SHALL be derived from what changed structurally — new modules, new
dependencies, changed interfaces, altered data flow, newly-wired connections —
using `design.md` and `proposal.md` as supporting material only. The skill SHALL
read `git diff --stat` and selective reads of significant changed files rather
than the complete diff.

Both explanations and check questions SHALL sit at a depth answerable by someone
who understands the change without having written it.

#### Scenario: Agent-made decision absent from design.md

- **WHEN** the change introduced a structural element present in the diff but in
  no design artefact
- **THEN** the skill SHALL cover it as a topic

#### Scenario: Detail below the fidelity target

- **WHEN** a candidate topic or question concerns null-check placement, guard
  clauses, individual error branches, or naming
- **THEN** the skill SHALL discard it as below orientation depth

#### Scenario: Trivial change

- **WHEN** the change contains no structural change worth navigating later
- **THEN** the skill SHALL say so plainly and stop, without manufacturing topics

### Requirement: The skill complements rather than repeats recap

When invoked as Retrospective Part 6, the skill SHALL cover consequence and
navigation, where `recap` covers what changed and why. It SHALL NOT re-explain
material `recap` supplied in Part 5.

The two differ in mode as well as subject: `recap` prints and is read;
`understand` teaches and checks.

#### Scenario: Candidate topic duplicates recap content

- **WHEN** a candidate topic's substance appears in the recap output already
  shown this session
- **THEN** the skill SHALL narrow it to the consequence and navigation angle
  that `recap` did not cover, or drop it for another topic

### Requirement: The session closes with a navigation question

The skill SHALL end every session by asking where the developer would look first
if the change misbehaves later, and what they would expect to see.

#### Scenario: Session ends

- **WHEN** all topics are covered, or the developer exits early
- **THEN** the skill SHALL ask the navigation question before producing output

#### Scenario: Navigation question is not answerable

- **WHEN** the developer cannot answer the closing navigation question
- **THEN** the skill SHALL walk through the answer explicitly rather than
  recording it as an open gap, since it summarises material already taught

### Requirement: The skill produces an orientation note

Output SHALL be an orientation note recording what the developer now knows: the
shape of the change, where to look when things go wrong, anything still open
after two explanations, and the concepts covered. It SHALL NOT contain a merge
verdict, a readiness recommendation, or a score.

#### Scenario: Note offered for saving

- **WHEN** the note has been produced
- **THEN** the skill SHALL offer to save it to
  `openspec/changes/{change-id}/understanding.md`

#### Scenario: Session abandoned partway

- **WHEN** the developer exits before all topics are covered
- **THEN** the skill SHALL produce a note covering the topics reached
- **AND** SHALL NOT discard the partial session

### Requirement: Quoted source is redacted before it reaches a committed artefact

The skill SHALL mask any credential-shaped value before writing it to the
orientation note, printing it in an explanation or question, or recording it in
`.spwf/learner.md`. Credential-shaped values include API keys, tokens,
passwords, cookies, connection strings, and private keys.

This matters because the skill reads source files to build its explanations, and
the orientation note may be saved to
`openspec/changes/{change-id}/understanding.md` — a committed, pushed path.

#### Scenario: Changed file contains a hard-coded credential

- **WHEN** the skill quotes from a file containing a credential-shaped value
- **THEN** it SHALL mask the value before including it anywhere in its output
  (e.g. `api_key="sk-…REDACTED…"`)

#### Scenario: Credential discovered while reading

- **WHEN** the skill encounters a hard-coded credential while reading changed
  files
- **THEN** it SHALL surface that in the note's open items, naming the file but
  not the value

### Requirement: The learner profile records demonstrated concepts and open items

The skill SHALL maintain `.spwf/learner.md`, recording concepts demonstrated
under `## Known`, items still open after two explanations under `## Open`, and
areas appearing under `## Open` more than twice under `## Recurring blind spots`.
The file SHALL be gitignored.

`## Known` means demonstrated, not merely explained. A skill that explains
without checking records under `## Covered` instead and SHALL NOT write
`## Known` — see the `learner-profile` convention's write-permission table.

#### Scenario: Session completes

- **WHEN** a session ends
- **THEN** concepts taught and confirmed SHALL move to `## Known` with the
  change-id and date
- **AND** only items that survived two explanations SHALL be recorded under
  `## Open`

#### Scenario: Level adjustment

- **WHEN** the developer reasons through consequences without prompting across
  several topics
- **THEN** the skill MAY promote their level for that area and SHALL say so
  rather than changing it silently
- **AND** SHALL NOT demote on a single weak answer

### Requirement: Retrospective offers the session as Part 6

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
- **THEN** the retrospective SHALL continue to Part 7, note "Part 6 skipped" in
  its report, and surface that `/spwf:understand {change-id}` works later

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

