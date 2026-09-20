# Spec: codebase-research

> Declares the `codebase-research` capability. Change 1 of 5 in the
> `adaptive-research-lean-execution` initiative; changes 2-4 add requirements to
> this same capability, so they archive in order.

## ADDED Requirements

### Requirement: Research is requested as a capability, not a tool

A skill needing codebase research SHALL request a logical operation from
`_shared/research-dispatch.md` and SHALL NOT embed provider-specific instructions.
The dispatcher SHALL define five operations: `orient`, `find`, `history`,
`coverage`, and `verify`.

The native backend — code intelligence / LSP, `rg` / Grep / Glob, direct Read, and
git history — SHALL implement all five and SHALL be sufficient for a fully correct
result without any other provider.

#### Scenario: A skill requests orientation

- **WHEN** a skill calls `orient` for a question about existing behaviour
- **THEN** the dispatcher SHALL resolve it through the configured provider
- **AND** SHALL return a result in the normalised evidence shape

#### Scenario: No configuration exists

- **WHEN** `.spwf/research.yaml` is absent
- **THEN** the dispatcher SHALL behave as `provider: auto`, `depth: adaptive`,
  `fallback: native`
- **AND** SHALL NOT interrupt the workflow to request configuration

#### Scenario: Completeness is claimed

- **WHEN** a conclusion asserts completeness — all callers, every reference, no
  other consumers
- **THEN** it SHALL be established by LSP references, `rg`, or direct file
  inspection
- **AND** semantic retrieval SHALL NOT be treated as proof of completeness

### Requirement: Evidence has a canonical shape and a research base

Persisted codebase evidence SHALL follow the structure in
`_shared/evidence-schema.md` and SHALL record `Research base` as the commit SHA
the research was performed against, together with the provider and depth used.

The research trace SHALL stay compact — enough to assess evidence quality, never a
retrieval dump.

#### Scenario: Evidence is written

- **WHEN** a skill persists codebase evidence
- **THEN** it SHALL record `Research base`, provider and depth
- **AND** SHALL record source locations for consequential claims

### Requirement: Stale evidence is re-verified per entry

A consumer of persisted evidence SHALL compare `Research base` against the current
tree. Entries under `### Important components` and `### Consumers / blast radius`
whose cited files have changed since that SHA SHALL be marked stale and
re-verified against source before being acted on. Entries whose files are unchanged
SHALL remain valid.

Evidence SHALL NOT be invalidated wholesale because one cited file moved.

#### Scenario: Some cited files have moved

- **WHEN** evidence is consumed and some cited files changed since `Research base`
- **THEN** only the affected entries SHALL be marked stale and re-verified
- **AND** unaffected entries SHALL be used as they stand

#### Scenario: Nothing has moved

- **WHEN** no cited file has changed since `Research base`
- **THEN** the evidence SHALL be used without re-verification, regardless of age

### Requirement: A research subagent returns compact evidence to a durable artefact

`research-scout` SHALL return compressed evidence rather than a description of how
the research was performed, and its result SHALL be written into the ideation file
rather than existing only in session.

#### Scenario: A scout completes

- **WHEN** `research-scout` finishes a research task
- **THEN** its compact result SHALL be written into the ideation file
- **AND** the return SHALL contain findings and source locations, not a narrative
  of the search

### Requirement: A subagent must be cheaper than reading the files

`_shared/lean-agent-discipline.md` SHALL state that dispatching a subagent is
justified only when the work is broad, repetitive, or would otherwise read many
files into the main session — and SHALL NOT be used where a small number of
targeted reads would answer the question.

#### Scenario: A narrow question arises

- **WHEN** a question could be answered by a few targeted reads
- **THEN** the skill SHALL read directly rather than dispatch a subagent

### Requirement: Model selection is policy, not per-skill choice

`_shared/model-policy.md` SHALL assign cheap models to deterministic evidence
gathering and Sonnet-class models to synthesis, implementation and consequential
review. Model selection SHALL remain independent of research-provider selection.

Agent definitions SHALL reference model aliases rather than pinned generation IDs.

#### Scenario: An agent is defined

- **WHEN** an agent declares its model
- **THEN** it SHALL use an alias rather than a pinned full model ID

### Requirement: Project capability health is reportable

`/spwf:config-check` SHALL report the health of the project's configured
capabilities — tracker, research backend, code intelligence, model assignments and
forge — and SHALL distinguish what is missing from what is misconfigured.

It SHALL NOT recommend a research provider that this change does not ship.

#### Scenario: A capability is unconfigured

- **WHEN** a capability has no configuration
- **THEN** `config-check` SHALL report it as absent with an actionable next step
- **AND** SHALL NOT halt the workflow

### Requirement: This change alters no golden-path behaviour

This change SHALL NOT modify any golden-path skill, and no golden-path skill
SHALL reference the new shared modules. The golden-path skills are `capture`,
`enrich`, `challenge`, `spec`, `brief`, `approve-plan`, `build`, `write-tests`,
`debug-recovery`, `simplify`, `pr-create`, `pr-review`, `address-review` and
`close`.

#### Scenario: The change is reverted

- **WHEN** this change's commit range is reverted
- **THEN** prior behaviour SHALL be restored exactly
- **AND** no migration or cleanup SHALL be required
