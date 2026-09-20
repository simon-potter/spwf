---
source: scratch
created: 2026-09-18
status: split
---

# SPWF Upgrade Specification

## Change ID

`adaptive-research-lean-execution` — an architectural initiative, not a single
OpenSpec change. See § Split into.

## Status

**Split** (2026-09-20, after `/spwf:challenge`). This file is no longer
implemented directly; it remains the **parent architectural design** that all
children reference.

## Split into

Five sequential changes. **The order is load-bearing** — this is not five
parallel siblings.

| # | Change | Ideation file | Delivers |
|---|---|---|---|
| 1 | `research-infrastructure` | [`todo/research-infrastructure.md`](research-infrastructure.md) | `research-dispatch` (native), `evidence-schema`, `model-policy`, `lean-agent-discipline`, `research-scout`, `config-check` |
| 2 | `pre-build-intelligence` | _not yet written_ | `challenge`, `spec`, `approve-plan` — evidence, acceptance, non-goals, change surface, complexity permissions, coverage gate |
| 3 | `lean-build` | _not yet written_ | `build`, `write-tests`, `debug-recovery` — implementation ladder, precedent lookup, stop conditions, scope-drift guard |
| 4 | `research-aware-review` | _not yet written_ | `simplify`, `reviewer`, `pr-review`, `address-review` |
| 5 | `chunkhound-provider` | _not yet written_ | ChunkHound behind the seam + `config-check`'s recommendation heuristic. Ships after change 2 |

**Later children are deliberately unwritten.** Under the Phase N+1 rule
([`docs/phase-release-contract.md`](../docs/phase-release-contract.md)), a phase
may not be spec'd until its predecessor's trigger has been evaluated. Writing
change 4's ideation file today would mean guessing what four phases of real use
will teach — the same mistake rejected for ChunkHound (§67 decision 9) and for the
`enrich` upgrade (§67 Not doing).

Each child is written when its predecessor's trigger has been evaluated. The
missing files are the gate, not an oversight.

## Purpose

Upgrade SPWF so that it:

1. understands a codebase more reliably before planning changes;
2. benefits from ChunkHound when available without depending on it;
3. uses cheaper isolated agents for evidence gathering and stronger models for decisions;
4. produces substantially less conversational noise;
5. encourages smaller, tighter implementations before `/spwf:simplify`;
6. keeps large exploratory outputs out of the primary Claude Code context;
7. detects weak local project configuration and gives users a clear upgrade path;
8. remains backwards-compatible across existing SPWF installations.

The core design principle is:

> **SPWF state lives in durable artefacts. Agent context is temporary. Research providers are interchangeable. Complexity must justify itself.**

---

# 0. Baseline — what this upgrade starts from

This upgrade is specified against **SPWF 1.21.0**, shipped by the
`add-brief-skill` change. That change is the most recent structural change to
the golden path and the reason several sections below mention `brief`.

## What 1.21.0 added

| Item | Detail |
|---|---|
| `/spwf:brief` | A new **optional, non-blocking** golden-path step between `spec` and `approve-plan`. Explains a planned change before it is built, across five sections, ending in one skippable prompt. Prints and returns; it is not a gate. |
| `**Type**: bug \| change` | A new line in `spec`'s `proposal.md` template, so a downstream skill can tell a feature from a bug fix without keying off a filename convention. |
| `## Covered` | A new section in the `_shared/learner-profile.md` convention, with a write-permission rule: skills that explain but do not check may record what they covered, and may not write `## Known` or `## Open`. |
| Agent-coverage exemption | `workflow-lint` now documents an exemption from its P1 "every golden path step has an agent" rule for non-blocking teaching steps. `brief` is the only member. |

## Why it matters to this upgrade

Four consequences, each handled in the section named:

1. **The golden path is one step longer than this document originally assumed.**
   §32 and §65 include `brief`; it is bracketed in both to mark it optional.
2. **`brief` is a consumer of spec's artefacts.** It reads the ideation file,
   `proposal.md`, `tasks.md` and `design.md` — and is already written to read
   `evidence.md` when that file appears (§31). It is listed in §58's Modify set.
3. **`brief` §3 "Choices you didn't make" overlaps §40's complexity
   permissions**, from the opposite direction: §40 is *declared* by spec, §3 is
   *derived* from the todo → plan delta. §40 records how they compose; neither
   replaces the other.
4. **`brief` is exempt from §53's minimise-narration rule.** Its prose is the
   deliverable, not narration of work performed. §53 states the exemption, so an
   implementer of Phase 2 does not compress it into a status block and delete the
   capability.

## What it did *not* change

`approve-plan` is untouched by 1.21.0. `brief` is opt-in by pointer — `spec`
names it as the next step and does not invoke it — which is a recorded risk in
that change, not a property this upgrade should rely on.

---

# 1. Goals

## 1.1 Primary goals

### G1 — Optional code-intelligence acceleration

SPWF MUST operate correctly with:

* ChunkHound configured;
* ChunkHound installed but unavailable/misconfigured;
* no ChunkHound installed at all.

ChunkHound MUST improve research quality and efficiency without becoming a required dependency.

### G2 — Evidence-backed workflow

For substantial changes, SPWF SHOULD establish a compact representation of:

* current behaviour;
* behavioural invariants;
* important contracts;
* affected consumers;
* analogous existing patterns;
* existing tests;
* uncertainty.

That evidence SHOULD survive from Challenge through Spec, Build and Review.

### G3 — Context control

Exploratory work SHOULD occur outside the main conversation wherever practical.

Subagents MUST return compact results rather than descriptions of how they researched.

### G4 — Lean implementation

SPWF MUST attempt to prevent unnecessary code rather than relying exclusively on `/spwf:simplify` to remove it afterwards.

Every significant implementation SHOULD contain:

* explicit acceptance conditions;
* explicit non-goals;
* an expected change surface;
* a stop condition.

### G5 — Appropriate model use

SPWF SHOULD use:

* cheap models for deterministic evidence gathering;
* Sonnet-class models for synthesis, implementation and consequential review;
* the current/main model only where genuinely difficult reasoning warrants it.

Model selection MUST remain independent of ChunkHound selection.

### G6 — Rollout safety

Existing projects MUST NOT require new configuration merely to continue using SPWF.

---

# 2. Non-goals

This upgrade SHALL NOT:

* make ChunkHound mandatory;
* introduce a proprietary SPWF code index;
* replace LSP, `rg`, Git or direct source reads;
* optimise primarily for minimum raw line count;
* encourage cryptic or “caveman” user prompts;
* require users to compress their requirements;
* create a configurable model-routing framework with dozens of options;
* automatically install external software without confirmation;
* automatically create API keys or tracker credentials;
* make every SPWF phase invoke deep research;
* turn `/spwf:build` into a multi-agent swarm;
* make SPWF dependent on a particular embedding or LLM provider.

---

# 3. Architectural principles

## 3.1 Research is a capability, not a product

Skills SHALL request logical operations such as:

* orient;
* find;
* investigate history;
* establish coverage;
* verify.

They SHALL NOT embed ChunkHound-specific instructions unless executing the ChunkHound backend.

Conceptually:

```text
SPWF skill
    │
    ▼
research-dispatch
    │
    ├── ChunkHound backend
    │
    └── native backend
    │
    ▼
normalised evidence
```

---

## 3.2 Discovery and proof are different

SPWF SHALL distinguish:

### Discovery

Good for answering:

* How does this behaviour work?
* Where might related code exist?
* What other concepts are connected?
* Why might this have been designed this way?

Mechanisms:

* ChunkHound `code_research`;
* ChunkHound semantic search;
* native exploratory search.

### Proof / completeness

Required for claims such as:

* all callers;
* every reference;
* no other consumers;
* every enum use.

Mechanisms:

* LSP references;
* `rg`;
* exact Git/file inspection.

Semantic retrieval SHALL NOT be treated as proof of completeness.

---

## 3.3 Source is authoritative

Research output SHALL identify source locations.

Consequential conclusions SHALL be verified against the current source tree before they become:

* requirements;
* architectural decisions;
* code changes;
* blocking review findings.

The operating pattern is:

```text
ORIENT
code_research / native exploration
       ↓
PINPOINT
semantic or regex search
       ↓
COVER
LSP / rg when completeness matters
       ↓
VERIFY
direct source
       ↓
ACT
```

---

## 3.4 Context is disposable

SPWF SHALL assume that users may use `/clear` or start a new Claude session between major phases.

Anything required downstream MUST therefore live in:

* todo artefacts;
* OpenSpec artefacts;
* Git;
* persisted review/evidence artefacts.

No critical state may exist only in conversation history.

---

# 4. New shared modules

Create:

```text
plugins/spwf/skills/_shared/
├── research-dispatch.md
├── chunkhound-setup.md
├── evidence-schema.md
├── lean-agent-discipline.md
└── model-policy.md
```

Each file owns one concern.

No skill SHOULD duplicate these rules inline.

---

# 5. `research-dispatch.md`

## Purpose

Provide a single abstraction for codebase research.

This SHALL mirror the existing `tracker-dispatch.md` architecture: workflow skills know what capability they need, while the shared dispatcher knows which backend supplies it.

## Configuration

Add optional:

```text
.spwf/research.yaml
```

Minimal schema:

```yaml
# All fields optional.

provider: auto       # auto | chunkhound | native
depth: adaptive      # adaptive | surface | broad | deep
fallback: native     # native | fail
```

No configuration file means:

```yaml
provider: auto
depth: adaptive
fallback: native
```

### Provider semantics

#### `auto`

1. Detect whether ChunkHound is usable.
2. If query-ready, use it.
3. Otherwise use native research.
4. Do not interrupt the workflow merely because ChunkHound is absent.

#### `chunkhound`

1. Require ChunkHound.
2. Verify readiness.
3. If unavailable, halt the research-dependent phase with an actionable setup message.
4. Do not silently substitute native research.

#### `native`

Never attempt ChunkHound.

Use:

* code intelligence/LSP;
* Grep/Glob/`rg`;
* direct Read;
* Git history.

### `fallback`

Normally:

```yaml
fallback: native
```

Explicitly setting:

```yaml
provider: chunkhound
fallback: fail
```

is the strict mode for teams that want semantic research guaranteed.

---

# 6. Research capability contract

`research-dispatch.md` SHALL define five logical operations.

## 6.1 `status`

Returns:

```text
provider
availability
query_ready
semantic_ready
deep_research_ready
warnings
```

Example:

```text
provider: chunkhound
query_ready: yes
semantic_ready: yes
deep_research_ready: yes
warnings: none
```

or:

```text
provider: native
reason: chunkhound not installed
```

---

## 6.2 `orient(question, depth)`

Purpose:

Understand behaviour spanning multiple files/modules.

ChunkHound implementation:

```text
code_research
```

Native implementation:

* targeted LSP/Grep/Glob exploration;
* selected source reads;
* Git where historically relevant.

Output MUST be a compact evidence report rather than exploration logs.

---

## 6.3 `find(query, mode)`

Modes:

```text
semantic
regex
symbol
```

ChunkHound:

* semantic search;
* regex search.

Native:

* LSP symbol navigation;
* `rg`;
* Grep/Glob;
* selected source reads.

---

## 6.4 `history(question, range)`

ChunkHound:

Use Git-aware research where available.

Native:

```text
git log
git show
git blame
git diff
```

---

## 6.5 `coverage(symbol)`

Always deterministic.

Use:

1. LSP references where appropriate;
2. `rg -n -w`;
3. direct verification.

ChunkHound MAY assist discovery but SHALL NOT replace this operation.

---

# 7. Research depth

SPWF SHALL classify research into three levels.

## Surface

Use when the task asks:

* where is this defined?
* find an analogous test;
* find an existing helper;
* locate this constant.

Expected mechanisms:

```text
search / LSP / rg
```

No deep research.

## Broad

Use for:

* ordinary feature grounding;
* medium bug investigation;
* finding existing architectural patterns.

Expected pattern:

```text
one orientation
+
targeted searches
+
verification
```

## Deep

Use for:

* major refactors;
* cross-stack behaviour;
* migration;
* complex regressions;
* security-sensitive architectural changes;
* final cross-cutting diff review.

Expected pattern:

```text
orientation
+
focused follow-up questions
+
targeted searches
+
deterministic coverage where needed
+
verification
```

## Adaptive default

SPWF chooses based on:

* change size;
* number of subsystems;
* existing uncertainty;
* security sensitivity;
* presence of persistent-data/API compatibility concerns.

---

# 8. `chunkhound-setup.md`

## Purpose

Provide one authoritative reference for:

* humans;
* `/spwf:config-check`;
* SPWF research agents;
* installation troubleshooting.

No other SPWF skill SHOULD contain detailed ChunkHound setup instructions.

---

# 9. Recommended ChunkHound installation strategy

## 9.1 Installation

Preferred:

```bash
uv tool install chunkhound
```

Verify:

```bash
chunkhound --version
```

For an existing installation:

```bash
uv tool upgrade chunkhound
```

SPWF SHOULD recommend ChunkHound 6.x or newer for the new research workflow.

---

## 9.2 Prefer machine-global defaults

For a developer using SPWF across many repositories, recommend:

```text
~/.config/chunkhound/chunkhound.json
```

rather than copying full provider configuration into every project.

Example:

```json
{
  "database": {
    "provider": "duckdb"
  },
  "embedding": {
    "provider": "voyageai",
    "model": "voyage-code-4"
  },
  "llm": {
    "provider": "anthropic",
    "utility_model": "claude-haiku-4-5-20251001",
    "synthesis_model": "claude-sonnet-4-5-20250929"
  },
  "research": {
    "algorithm": "v2"
  }
}
```

The exact model identifiers are provider configuration, not an SPWF contract.

SPWF SHOULD explain that:

* `v2` is a cost-conscious balanced default for routine SPWF research;
* `v3` gives broader dual-strategy coverage where missing context is costly;
* users may retain ChunkHound's own defaults instead.

SPWF SHALL NOT rewrite an existing user's ChunkHound model configuration merely because it differs from this recommendation.

---

## 9.3 Provider profiles

The reference SHALL document three supported patterns.

### Recommended hosted profile

```text
Embeddings: Voyage code model
Database: DuckDB
Utility LLM: inexpensive model
Synthesis LLM: stronger model
```

Purpose:

Best quality/cost balance.

### Existing-Claude profile

Use ChunkHound's Claude Code CLI backend when the developer wants to avoid maintaining an additional Anthropic API credential.

### Local/private profile

Use an OpenAI-compatible local service such as:

* Ollama;
* vLLM.

SPWF SHALL remain provider-neutral.

---

# 10. Secrets policy

SPWF SHALL NOT:

* generate API keys;
* write secrets into version-controlled project files;
* copy environment credentials into `.spwf/`.

For multi-project setups, prefer:

* environment variables;
* a secrets manager;
* appropriately protected global configuration.

If a project `.chunkhound.json` contains credentials:

* require it to be ignored by Git;
* flag it in `config-check` if tracked.

---

# 11. Per-project ChunkHound setup

From project root:

```bash
chunkhound index .
```

Then verify independently:

### Layer 1 — index/database

Index completes successfully.

### Layer 2 — regex retrieval

Run a suitable exact/regex search.

### Layer 3 — semantic retrieval

Run a natural-language semantic search.

### Layer 4 — deep research

Run one small research query.

Failure at each layer SHALL produce a distinct diagnostic.

Examples:

```text
regex works, semantic fails
→ embedding configuration problem
```

```text
semantic works, research fails
→ LLM provider problem
```

---

# 12. Claude Code MCP setup

For a developer using ChunkHound across many repositories, recommend user scope:

```bash
claude mcp add --scope user ChunkHound -- chunkhound mcp
```

Project scope MAY be used by teams wanting a shared `.mcp.json`.

SPWF's runtime research backend SHALL NOT depend on MCP presence when the CLI is available.

This is deliberate:

```text
interactive Claude
→ MCP preferred

SPWF orchestration / cheap scouts
→ CLI permitted

research abstraction
→ hides the difference
```

This prevents the SPWF workflow from becoming coupled to:

* a particular MCP server name;
* MCP tool discovery;
* Haiku MCP-tool overhead.

---

# 13. `config-check` skill

Create:

```text
plugins/spwf/skills/config-check/SKILL.md
```

Invocation:

```text
/spwf:config-check
```

Optional:

```text
/spwf:config-check --apply
```

Default mode is advisory/read-only.

---

# 14. Purpose of `config-check`

Answer:

> “Is this repository configured to get the best practical results from SPWF on this machine?”

It is not:

* `workspace-health`;
* `agent-optimise`;
* a security scanner.

It checks the runtime capabilities SPWF depends on or can benefit from.

---

# 15. `config-check` pipeline

## Step 1 — Identify project shape

Detect:

* Git repository;
* primary languages;
* major frameworks where obvious;
* source-file count;
* monorepo / backend+frontend structure;
* package manifests;
* test frameworks;
* rough repository scale.

This informs recommendations but does not change behaviour.

---

## Step 2 — Core SPWF prerequisites

Check:

```text
Claude Code
OpenSpec
Git repository
OpenSpec initialisation
forge CLI
forge authentication
branch config
```

Classify problems:

```text
P1 blocking
P2 recommended
P3 optimisation
```

---

## Step 3 — Tracker capability

Read:

```text
.spwf/tracker.yaml
```

Apply the existing tracker-dispatch logic.

Report one of:

```text
✓ YouTrack ready
✓ Jira ready
✓ Beads ready
ℹ tracker explicitly disabled
⚠ no tracker configured
✗ tracker configured but unavailable
```

### Recommendation logic

If no tracker:

```text
P2: Configure an issue tracker if work is tracked externally or spans sessions.
```

Suggested choices:

* existing YouTrack;
* existing Jira;
* Beads;
* explicit `tracker: none`.

Do NOT force a tracker onto repositories that intentionally do not use one.

---

## Step 4 — Code-research capability

Resolve `.spwf/research.yaml`.

Probe:

```text
chunkhound executable
version
database/index
regex readiness
semantic readiness
deep-research readiness
MCP availability
```

Output:

```text
Research provider: chunkhound
ChunkHound: 6.x
Index: ready
Semantic search: ready
Deep research: ready
MCP: user scope
```

or:

```text
Research provider: native
ChunkHound: not installed

P2 recommendation:
This is a large/multi-stack repository. ChunkHound is likely to improve
cross-file research and reduce exploratory context.
```

For small repositories:

```text
P3 optional:
Native research is probably sufficient. ChunkHound is available as an optimisation.
```

---

# 16. ChunkHound recommendation heuristic

ChunkHound SHOULD be recommended more strongly when any of these are true:

* several hundred source files;
* backend + frontend application;
* multiple primary programming languages;
* significant Git history;
* frequent refactors;
* complex persistence/domain flows;
* agents repeatedly perform broad repository searches.

This is advisory only.

No hard source-file threshold becomes a workflow requirement.

---

# 17. Code-intelligence check

For detected languages, report whether suitable Claude Code code-intelligence/LSP capability appears available.

Examples:

```text
Python → Pyright or equivalent
TypeScript/JavaScript → TypeScript language server
```

If absent:

```text
P2: install code-intelligence support; symbol navigation can replace broad file reads.
```

SPWF SHALL NOT require a particular language server.

---

# 18. Model-policy check

Read:

```text
_shared/model-policy.md
```

Audit:

* SPWF bundled agent assignments;
* project-local agent overrides;
* obviously stale full model IDs;
* inappropriate expensive models for mechanical work;
* weak models assigned consequential synthesis/review work.

Report examples:

```text
P2 reviewer uses haiku but now performs cross-contract architectural review
→ recommend sonnet
```

```text
P3 agent pins claude-sonnet-4-6
→ prefer model alias `sonnet` unless reproducible pinning is intentional
```

The checker MUST distinguish:

```text
intentional exact pin
```

from:

```text
accidental stale generation pin
```

and SHOULD ask before changing one.

---

# 19. Output/context configuration check

Recommend, but do not force:

```text
Claude Code Concise output style
```

Check for:

* excessively large project `CLAUDE.md`;
* huge project-local agent prompts;
* duplicated instructions;
* large tool outputs regularly fed into prompts.

Defer detailed agent quality analysis to:

```text
/spwf:agent-optimise
```

rather than duplicating that skill.

---

# 20. `config-check --apply`

`--apply` SHALL use three action classes.

## Safe automatic fixes

May be applied after one confirmation:

* create `.spwf/research.yaml`;
* update safe `.gitignore` entries;
* create minimal explicit `tracker: none` if user selects it;
* create missing non-secret local SPWF config;
* initialise simple project metadata required by SPWF.

## Guided external changes

Ask before running:

* install/upgrade ChunkHound;
* initialise/index project;
* add ChunkHound MCP server;
* install language server;
* install tracker add-on.

## Never automatically perform

* generate API credentials;
* overwrite an existing provider config;
* replace unknown `.chunkhound.json`;
* store plaintext secrets;
* change tracker state;
* modify user-global Claude settings without confirmation;
* change selected model pins without confirmation.

---

# 21. `config-check` output format

Keep it short.

Example:

```text
SPWF config check

P1 — blocking
none

P2 — recommended
1. ChunkHound unavailable; repo is Python + Vue with 612 source files.
   Benefit: cross-stack research + lower exploration context.
   Setup: /spwf:config-check --apply or see chunkhound setup reference.

2. No issue tracker selected.
   Choose: YouTrack / Jira / Beads / explicit none.

P3 — optimisation
3. reviewer model is pinned to an older Haiku generation.
   SPWF recommendation: sonnet alias.

Ready now: yes
Research backend: native
```

No multi-page environment essay.

---

# 22. `model-policy.md`

## Principle

Use model strength where errors compound.

Default role policy:

| Role                               | Model                          | Effort      |
| ---------------------------------- | ------------------------------ | ----------- |
| Mechanical locator/scout           | `haiku`                        | low/medium  |
| Git/history extraction             | `haiku`                        | low/medium  |
| Test precedent discovery           | `haiku`                        | low         |
| Mechanical simplification          | `haiku`                        | low         |
| Challenge synthesis                | `sonnet`                       | high        |
| Spec synthesis                     | `sonnet`                       | high        |
| Implementation                     | `sonnet`                       | medium/high |
| Non-trivial debugging              | `sonnet`                       | high        |
| Final code review                  | `sonnet`                       | high        |
| Exceptional architectural decision | `inherit` / user-selected Opus | high+       |

SPWF SHOULD prefer model aliases over generation-specific identifiers unless a reproducibility requirement explicitly justifies pinning.

---

# 23. Agent changes

## Add `research-scout`

```text
plugins/spwf-agents/agents/research-scout.md
```

Default:

```yaml
model: haiku
tools: [Read, Grep, Glob, Bash]
```

Purpose:

Collect evidence only.

It SHALL NOT:

* edit code;
* design architecture;
* decide product behaviour;
* produce essays.

### Return contract

Maximum preferred output:

```text
Evidence
- path:line — finding
- path:line — finding

Tests
- path:line — protected behaviour

Risk
- one line

Unknown
- one line
```

Hard guidance:

* no tool narration;
* no recap of search process;
* no recommendations unless requested;
* return uncertainty instead of endlessly exploring.

---

# 24. Existing model changes

Change core agent declarations from version-specific IDs to role aliases.

Examples:

```text
challenger → sonnet
specifier  → sonnet
builder    → sonnet
tester     → sonnet
reviewer   → sonnet
```

Reviewer moves from Haiku to Sonnet because the upgraded review now synthesises:

* diff;
* original invariants;
* research evidence;
* external consumers;
* security/contract implications.

Cheap scouts perform the expensive breadth work.

Reviewer performs the judgement.

---

# 25. `lean-agent-discipline.md`

This becomes a shared behaviour contract.

## Interaction rules

During autonomous work, surface only:

* required user decision;
* blocker;
* material deviation;
* destructive/security warning.

Do not narrate:

* each tool call;
* each file opened;
* routine searches;
* obvious progress.

Completion output:

```text
Outcome
Verification
Material deviation/risk
Next action
```

---

# 26. Implementation ladder

Before creating new code, ask in order:

```text
1. Can existing behaviour be changed/deleted instead?
2. Does the repository already provide this?
3. Does the language/runtime provide this?
4. Does the framework provide this?
5. Can an existing abstraction absorb this cleanly?
6. Only then introduce new surface area.
```

This applies to:

* classes;
* services;
* wrappers;
* configuration;
* dependencies;
* feature flags;
* fallback mechanisms;
* abstraction layers.

---

# 27. Complexity permission

New complexity SHALL require one of:

```text
acceptance requires it
existing repository convention requires it
multiple current consumers justify it
security/correctness requires it
```

Agents SHALL NOT introduce speculative:

* plugin systems;
* provider abstractions;
* future-proof configuration;
* generic repositories;
* compatibility layers;
* fallback paths.

---

# 28. Explicit > compact

Minimality SHALL mean:

* fewer concepts;
* fewer moving parts;
* less maintenance surface.

It SHALL NOT mean:

* clever code golf;
* dense one-liners;
* premature DRY abstractions.

Readable explicit code remains preferable.

---

# 29. Stop conditions

Every implementation task SHALL define when the agent is finished.

Generic rule:

> Once the task's acceptance conditions are demonstrated and required verification passes, stop. Do not add adjacent polish, cleanup, generalisation or future-proofing.

Cleanup belongs to `/spwf:simplify`.

---

# 30. Evidence schema

Create:

```text
_shared/evidence-schema.md
```

Canonical structure:

```markdown
## Codebase evidence

Research base: <SHA>
Provider: chunkhound | native
Depth: surface | broad | deep

### Existing behaviour
- ...

### Invariants / contracts
- ...

### Important components
- path:line — reason

### Consumers / blast radius
- ...

### Existing tests
- ...

### Existing patterns to reuse
- ...

### Uncertainty
- ...

### Research trace
- orient: ...
- searches: ...
- deterministic checks: ...
- verified source: ...
```

Research trace must stay compact.

It records enough to assess evidence quality without storing retrieval dumps.

---

# 31. Evidence lifecycle

## Before Spec

`challenge` writes the compact evidence section into:

```text
todo/{slug}.md
```

## During Spec

`spec` creates:

```text
openspec/changes/{change-id}/evidence.md
```

This becomes the durable baseline for implementation.

## During Build

Build reads relevant evidence.

It does not reproduce it.

## During Review

Review compares implementation against:

```text
proposal
tasks
evidence
actual diff
```

---

# 32. Revised golden path

The visible workflow remains:

```text
wfstatus
→ capture
→ enrich
→ challenge
→ spec
→ [brief]
→ approve-plan
→ build
→ simplify
→ pr-create
→ pr-review
→ address-review
→ close
```

No mandatory new golden-path phase is introduced.

`brief` (added in 1.21.0, bracketed above) is optional and non-blocking: it
explains the plan between `spec` and `approve-plan`, prints, offers one
skippable prompt, and returns. It is not a gate and must not become one.

`config-check` is a maintenance/setup skill.

---

# 33. Capture changes

## Change path

Keep research light.

Use native/semantic search only when needed to correctly classify the change.

Do not perform broad architecture research during Capture.

## Bug path

For non-trivial bugs:

```text
symptom
→ orient failure behaviour
→ identify 2–6 points of interest
→ targeted searches
→ direct verification
→ history when regression suspected
→ hypothesis
```

Persist:

```text
Root cause hypothesis
Evidence
Uncertainty
```

### Acceptance criteria

* trivial bugs remain fast;
* cross-module bugs gain research;
* no fix is attempted during Capture;
* hypothesis names verified source evidence.

---

# 34. Enrich changes

Research depth:

```text
surface or broad
```

Use research to improve:

* reuse lens;
* simplification lens;
* analogous-feature lens;
* expert lens.

Do not perform full architectural archaeology.

### Acceptance criteria

At least one existing repository pattern is considered where relevant.

`Not doing` remains explicit.

---

# 35. Challenge changes — primary pre-build research gate

This is the major upgrade.

## New flow

```text
read todo
→ build question map
→ determine research depth
→ research existing system
→ classify questions
→ ask only genuine decisions
→ premortem/red-team
→ persist evidence
```

Each challenge question becomes:

```text
CODE-ANSWERABLE
USER-DECISION
MIXED
```

### CODE-ANSWERABLE

Resolve from evidence.

Do not ask the user.

### USER-DECISION

Ask normally.

### MIXED

Present repository evidence + recommendation, then ask the remaining decision.

Example:

```text
Existing code has three consumers of the current response shape.
Recommended: preserve compatibility during migration.

Should the migration preserve the existing response until all consumers move?
```

### Acceptance criteria

* Challenge asks fewer factual questions;
* substantial changes produce `Codebase evidence`;
* every major code-derived recommendation has verified source support;
* Challenge does not design the implementation prematurely.

---

# 36. Parallel research in Challenge

For deep work:

1. one orientation investigation;
2. identify 2–6 points of interest;
3. delegate independent evidence gathering to up to 2–3 `research-scout` agents;
4. scouts return compressed evidence;
5. Sonnet Challenger synthesises.

Do NOT run three redundant deep-research calls.

Parallel scouts SHOULD investigate distinct concerns such as:

```text
backend/domain
frontend/consumer
tests/history
```

---

# 37. Spec changes

Create:

```text
evidence.md
```

alongside:

```text
proposal.md
design.md
tasks.md
specs/
```

## Proposal

Continue defining:

* why;
* desired behaviour;
* impact.

Impact now derives from:

```text
user scope
+
codebase evidence
+
verified consumers
```

not rough scope alone.

---

# 38. Acceptance + non-goals

Every non-trivial change SHALL explicitly contain:

```markdown
## Acceptance
...

## Non-goals
...
```

Non-goals should include tempting adjacent features that agents must not build.

---

# 39. Expected change surface

Spec SHOULD record an estimate such as:

```markdown
## Expected change surface

- Backend service + route
- Existing database model
- One migration
- Nuxt composable + page
- Existing tests
- No new dependency
- No new generic abstraction
```

This is not a LOC budget.

It is a scope-drift detector.

---

# 40. Complexity permissions

Spec SHOULD explicitly document any planned new:

* dependency;
* abstraction;
* service;
* config option;
* compatibility layer;
* persistent schema;
* background worker.

Example:

```text
New abstraction permitted:
ReportPresetService

Reason:
Existing ReportService cannot own user-specific saved state without mixing concerns.
```

No permission means Builder SHOULD challenge unexpected complexity before creating it.

**Relationship to `brief` §3 ("Choices you didn't make").** The two cover the
same taxonomy from opposite directions and neither replaces the other:

| | §40 permissions | `brief` §3 |
|---|---|---|
| Source | **Declared** by spec | **Derived** from the todo → plan delta |
| Reader | approve-plan gate, builder | the developer |
| Blind spot | complexity spec never declared | — |

§40 can only police complexity someone chose to write down. The derived delta is
what catches the rest, which is why `brief` keeps deriving rather than reading
the permission list alone.

Phase 2 SHOULD nonetheless feed §39 and §40 into `brief` §3 as the *structured
right-hand side* of that delta. Today it diffs prose against prose; an explicit
change surface and permission list make the same comparison sharper and cheaper.
Treat the derived pass as the audit of the declared list, not its replacement.

---

# 41. Approve-plan changes

Add a blocking **Evidence coverage** section.

Checks:

| Dimension   | Requirement                                                       |
| ----------- | ----------------------------------------------------------------- |
| Invariants  | Every load-bearing invariant is preserved or deliberately changed |
| Consumers   | Known affected consumers are covered or explicitly unaffected     |
| Persistence | Migration/backward compatibility is represented                   |
| Tests       | Important discovered contracts have verification                  |
| Non-goals   | No task violates explicit non-goals                               |
| Complexity  | New abstraction/dependency/config has justification               |
| Scope       | Task list broadly matches expected change surface                 |

Existing Atomic/Testable/Unambiguous/Sized/Ordered checks remain.

### Acceptance criteria

Approval cannot report “ready” while a known affected consumer is absent from the task plan.

---

# 42. Build changes

Build remains intentionally narrow.

Per task:

```text
read task
→ read relevant evidence
→ locate nearest precedent if useful
→ Red
→ smallest coherent implementation
→ Green
→ targeted verification
→ STOP
```

No automatic broad `code_research` per task.

Use surface research when:

* target location unclear;
* repository convention unclear;
* analogous implementation needed.

Escalate to broader research only if implementation evidence contradicts the approved plan.

---

# 43. Scope-drift guard

Before or during a task, if implementation materially exceeds expected change surface, halt.

Examples:

```text
Expected: 4–6 files
Observed plan: 18 files
```

or:

```text
Spec: no dependency
Implementation appears to require new package
```

Output:

```text
Scope drift detected.

Expected:
...

Observed:
...

Reason:
...

Continue / revise plan?
```

No arbitrary numeric threshold automatically fails the build.

The issue is unexplained deviation.

---

# 44. Write-tests changes

Before writing new tests:

1. use surface research;
2. find nearest analogous existing test;
3. directly inspect 1–3 relevant tests;
4. reproduce repository conventions.

Return concise output:

```text
Red: 2 tests failing for expected reason.
```

Do not provide a testing tutorial.

---

# 45. Test/tool output compression

Long command output SHOULD be redirected to recoverable files where practical.

Example:

```bash
pytest ... > .spwf/logs/test-<id>.log 2>&1
```

Success returned to agent:

```text
PASS — 84 tests, 2.9s
log: .spwf/logs/test-<id>.log
```

Failure:

```text
FAIL — tests/foo/test_bar.py::test_baz
AssertionError: ...
log: .spwf/logs/test-<id>.log
```

Only inspect the complete log if needed.

Apply similar handling to:

* npm;
* typecheck;
* lint;
* security scans;
* dependency audits.

### Acceptance criteria

Routine successful commands SHALL NOT insert thousands of lines into agent context.

Full logs remain available.

---

# 46. Debug recovery changes

Attempt 1:

```text
local failure evidence
→ direct source
→ targeted fix
```

If unresolved:

Attempt 2 MAY escalate to broad/deep research:

```text
trace failing invariant
→ verify assumptions
→ attempt corrected fix
```

The existing bounded recovery philosophy remains.

---

# 47. Simplify changes

Retain `/spwf:simplify`, but change Pass 1 ordering to:

```text
DELETE
→ REUSE
→ COLLAPSE
→ CLARIFY
```

## DELETE

What in this diff does not need to exist?

## REUSE

Does the repository/runtime/framework already provide it?

Use semantic search when available, native search otherwise.

## COLLAPSE

What new abstraction/config/indirection has insufficient current justification?

## CLARIFY

What can become clearer without becoming clever?

Existing:

```text
explicit > compact
rule-of-three
no unrelated cleanup
```

remain.

---

# 48. Simplify metrics

Record:

```text
before:
files
additions
deletions

after:
files
additions
deletions
```

Report what was removed conceptually:

```text
wrapper
duplicate validator
unused config
speculative fallback
```

Metrics are diagnostic, not targets.

---

# 49. Review changes

Reviewer becomes Sonnet.

It SHALL receive:

```text
proposal
tasks
evidence
pinned diff range
```

Before detailed review:

```text
research behavioural diff
→ inspect changed shared/public symbols
→ deterministic coverage where needed
→ verify source
→ review
```

Change reviewer scope rule from:

```text
Ignore existing code not in diff
```

to:

> Do not report unrelated pre-existing problems. Inspect code outside the diff when necessary to determine whether the change violates an existing consumer, invariant, contract or established pattern.

This preserves review scope without artificially restricting evidence.

---

# 50. Final review questions

Review SHALL explicitly check:

* original invariants;
* contract drift;
* consumer blast radius;
* API/schema changes;
* persistence/migration;
* state transitions;
* error semantics;
* auth/security boundaries;
* tests;
* unnecessary complexity;
* known non-goals;
* deviations from expected change surface.

Output only actionable findings.

If clean:

```text
No material issues.
```

---

# 51. PR Review consolidation

`/spwf:pr-review` SHOULD delegate to the same Reviewer agent used by Simplify.

Modes:

```text
local-diff
forge
```

One review implementation.

Different input acquisition.

This prevents review methodologies diverging.

---

# 52. Address-review changes

Choose research depth according to the review claim.

Examples:

### Local correctness claim

```text
Read
```

### “Existing helper already does this”

```text
semantic/native search
```

### “This breaks all callers”

```text
search + LSP/rg coverage
```

### Architectural convention claim

```text
orient/research if necessary
```

Do not perform deep research for every comment.

---

# 53. Interaction contract

SPWF skills and agents SHOULD minimise narration.

## During autonomous work

Visible messages only for:

* decisions;
* blockers;
* deviations;
* security/destructive warnings.

## Completion

Preferred shape:

```text
✓ Task 3.2 complete
Changed: 3 files
Verified: 18 tests pass
Deviation: none
```

Not a prose retrospective.

Retrospective belongs to `/spwf:close`.

## Exemption — deliberate human-facing explanation

This section governs **narration of autonomous work**: commentary the agent
emits as a side effect of doing something else. It does not govern skills whose
output *is* the deliverable and whose audience is the developer rather than the
log.

`brief`, `recap` and `understand` are exempt. Their prose is the product, not a
description of work performed. Compressing them to a status block deletes the
capability rather than the noise.

The test: would the developer have asked for this text? Narration fails it.
A brief passes it.

---

# 54. Main-context budget

SPWF SHOULD assume the main session is the scarce resource.

Use subagents when work:

* reads many files;
* performs repetitive searches;
* analyses verbose logs;
* investigates independent concerns.

Return only compressed evidence.

Explicitly recommend:

```text
Challenge
→ /clear permitted

Spec
→ /clear permitted

Build
→ /clear permitted

Review
```

because durable artefacts contain the required state.

---

# 55. Skill-size discipline

New shared references SHALL use progressive disclosure.

`SKILL.md` contains:

* algorithm;
* requirements;
* stop conditions.

Supporting details belong under shared/reference files.

Do not copy the ChunkHound setup guide into Challenge, Config Check, Capture and Review.

One source of truth.

---

# 56. Development-time validation

Extend `workflow-lint` or automated plugin tests to verify:

### Shared-reference integrity

Every reference exists.

### Model policy

Bundled agents match intended aliases.

### Result-contract size

Research agents contain compressed output requirements.

### Research coupling

No core workflow skill except research-dispatch / setup reference contains direct mandatory ChunkHound dependency.

### Evidence consumers

Challenge writes evidence.

Spec persists evidence.

Approve reads evidence.

Review reads evidence.

---

# 57. Runtime validation

`config-check` validates the user's project/machine.

`workflow-lint` validates SPWF itself.

`agent-optimise` audits broader Claude configuration quality.

These SHOULD remain distinct.

---

# 58. Proposed file changes

## New

```text
plugins/spwf/skills/config-check/SKILL.md

plugins/spwf/skills/_shared/
  research-dispatch.md
  chunkhound-setup.md
  evidence-schema.md
  lean-agent-discipline.md
  model-policy.md

plugins/spwf-agents/agents/
  research-scout.md
```

## Modify

```text
capture/SKILL.md
enrich/SKILL.md
challenge/SKILL.md
spec/SKILL.md
brief/SKILL.md
approve-plan/SKILL.md
build/SKILL.md
write-tests/SKILL.md
debug-recovery/SKILL.md
simplify/SKILL.md
pr-review/SKILL.md
address-review/SKILL.md

reviewer.md
challenger.md
specifier.md
builder.md
tester.md

workflow-lint/SKILL.md
agent-optimise/SKILL.md
README.md
```

---

# 59. Rollout plan

## Phase 1 — Infrastructure, zero behavioural disruption

Implement:

```text
research-dispatch
chunkhound-setup
evidence-schema
lean-agent-discipline
model-policy
config-check
research-scout
```

Change agent model pins to aliases.

Do not alter golden-path behaviour yet except optional config reporting.

### Exit criteria

Existing SPWF tests/workflow unchanged.

`/spwf:config-check` works with and without ChunkHound.

---

## Phase 2 — Pre-build intelligence

Upgrade:

```text
challenge
spec
brief
approve-plan
```

`brief` sits between two of these and is a consumer of spec's artefacts, so it
moves with them rather than trailing a phase behind. Its work here is small:
read `evidence.md`, and take §39/§40 as the structured right-hand side of its
§3 delta.

Add:

```text
Codebase evidence
evidence.md
Acceptance
Non-goals
Expected change surface
Complexity permissions
Evidence coverage gate
```

### Exit criteria

A substantial feature can be taken from todo → approved plan with evidence persisted.

A no-ChunkHound project follows the same path successfully.

---

## Phase 3 — Lean build

Upgrade:

```text
build
write-tests
debug-recovery
```

Add:

* implementation ladder;
* precedent lookup;
* explicit stop conditions;
* scope-drift guard;
* quiet tool output.

### Exit criteria

Existing task-per-commit behaviour remains.

Routine successful commands produce compact output.

---

## Phase 4 — Simplification + review

Upgrade:

```text
simplify
reviewer
pr-review
address-review
```

Add:

* DELETE → REUSE → COLLAPSE → CLARIFY;
* diff research;
* evidence comparison;
* blast-radius checking;
* Sonnet reviewer.

### Exit criteria

Local and forge reviews use one methodology.

Findings may inspect external consumers without reporting unrelated legacy defects.

---

## Phase 5 — Secondary research improvements

Upgrade:

```text
capture bug path
enrich
```

Only after the core flow is proven.

---

# 60. Backward compatibility

An existing repository containing only:

```text
todo/
openspec/
.spwf/tracker.yaml
.spwf/branch.yaml
```

MUST continue to work.

No migration command required.

Absent:

```text
.spwf/research.yaml
```

means:

```text
auto + native fallback
```

Existing users gain behaviour incrementally when plugin versions update.

---

# 61. Rollout across many existing sites

Recommended rollout sequence per repository:

```text
1. Update SPWF plugin.
2. Run /spwf:config-check.
3. Fix P1 items.
4. Review P2 recommendations.
5. Decide tracker explicitly if currently ambiguous.
6. Decide whether ChunkHound is worthwhile.
7. If yes, configure machine-global ChunkHound once.
8. Index the repository.
9. Re-run /spwf:config-check.
10. Continue using normal SPWF golden path.
```

Most repositories SHOULD require no checked-in changes unless a project needs:

```text
.spwf/research.yaml
```

to override automatic behaviour.

---

# 62. Acceptance test matrix

## Scenario A — no ChunkHound

Given:

```text
provider: auto
chunkhound absent
```

When:

```text
/spwf:challenge
```

Then:

* native research executes;
* evidence is produced;
* workflow continues;
* no installation prompt interrupts the feature.

---

## Scenario B — ready ChunkHound

Given:

```text
provider: auto
chunkhound semantic + research ready
```

When Challenge researches a cross-cutting feature,

Then:

* ChunkHound orientation is used;
* targeted searches follow;
* key findings are verified from source;
* evidence records `Provider: chunkhound`.

---

## Scenario C — broken ChunkHound in auto mode

Given:

```text
provider: auto
chunkhound executable exists
semantic configuration broken
```

Then:

* dispatcher records warning;
* native backend is selected;
* workflow continues;
* `config-check` reports remediation.

---

## Scenario D — strict ChunkHound

Given:

```yaml
provider: chunkhound
fallback: fail
```

And semantic research is unavailable,

Then:

* research phase halts;
* error identifies failing layer;
* no native fallback occurs.

---

## Scenario E — exhaustive claim

Given Reviewer needs to establish every caller of a changed public symbol,

Then:

* semantic search may discover related concepts;
* deterministic LSP/`rg` coverage is performed;
* review does not claim completeness from semantic retrieval.

---

## Scenario F — context isolation

Given Challenge performs deep research,

Then:

* broad exploration occurs in isolated scout context where practical;
* main Challenger receives compressed evidence;
* scout output contains no research narrative.

---

## Scenario G — model routing

Given routine repository exploration,

Then:

```text
research-scout → haiku
```

Given final architectural/diff synthesis,

Then:

```text
reviewer/challenger → sonnet
```

No task requires a version-specific Claude generation unless intentionally pinned.

---

## Scenario H — overengineering

Given a task requires modifying an existing endpoint,

When Builder attempts to introduce:

```text
provider interface
factory
new config option
```

without requirement or established reuse,

Then Builder must stop or avoid the extra abstraction.

---

## Scenario I — scope drift

Given Spec expects:

```text
existing service
existing endpoint
4–6 affected files
no dependency
```

When implementation discovers a need for:

```text
new package
new service layer
18 files
```

Then:

* Build surfaces scope drift;
* explains reason;
* requests plan revision or confirmation.

---

## Scenario J — stop condition

Given tests and acceptance conditions for the task are green,

Then Builder:

* marks task complete;
* reports concise result;
* stops;
* does not perform opportunistic cleanup.

---

# 63. Overall release acceptance criteria

The upgrade is complete when all of the following are true.

### Compatibility

* Existing repositories run without new config.
* ChunkHound remains optional.
* Tracker behaviour remains unchanged.

### Research

* One shared dispatcher owns provider selection.
* Challenge generates evidence on substantial changes.
* Evidence is persisted to OpenSpec.
* Semantic search is never treated as exhaustive proof.

### Context efficiency

* exploratory research can run in isolated scout contexts;
* scouts return compact evidence;
* successful tool output is summarised;
* main conversation no longer needs to retain prior workflow phases.

### Code minimality

* Spec includes non-goals;
* Build has stop conditions;
* expected change surface is available;
* unexplained scope growth is surfaced;
* Simplify begins with deletion rather than cleanup.

### Model efficiency

* mechanical research uses Haiku-class agents;
* consequential synthesis/review uses Sonnet-class agents;
* full generation IDs are not unnecessarily hard-coded;
* model policy is independently auditable.

### Local setup quality

`/spwf:config-check` can report:

* core SPWF readiness;
* tracker readiness;
* forge readiness;
* ChunkHound readiness;
* LSP/code-intelligence opportunities;
* model-policy issues;
* actionable P1/P2/P3 recommendations.

### Interaction quality

Normal successful workflow messages are short.

Agents do not narrate routine exploration.

---

# 64. Success measures after rollout

Do not initially optimise against arbitrary token targets.

Measure trends across several real changes:

```text
main-session context usage
subagent token usage
number of source files read by main agent
research calls
files changed
additions/deletions before Simplify
additions/deletions after Simplify
scope-drift events
review findings
rework after review
```

Desired direction:

```text
main-context usage ↓
narrative output ↓
unnecessary diff size ↓
Simplify deletion percentage ↓ over time
review regressions ↓
requirements quality same or better
```

A particularly useful long-term metric is:

> **How much code does Simplify remove?**

If Simplify repeatedly removes the same category of AI-generated excess, move that restraint earlier into Spec or Build.

---

# 65. The intended SPWF operating model

The resulting system should behave like this:

```text
CONFIG CHECK
optional capability health
       │
       ▼
CAPTURE
understand the work
       │
       ▼
ENRICH
consider simpler/reused approaches
       │
       ▼
CHALLENGE
research reality
separate facts from decisions
persist evidence
       │
       ▼
SPEC
acceptance
non-goals
change surface
complexity permissions
       │
       ▼
[BRIEF]
explain the plan before it is built
optional, never blocks
       │
       ▼
APPROVE
task quality
evidence coverage
minimality
       │
       ▼
BUILD
one task
nearest precedent
minimal implementation
verify
STOP
       │
       ▼
SIMPLIFY
DELETE
REUSE
COLLAPSE
CLARIFY
       │
       ▼
REVIEW
research actual diff
check invariants + consumers
deterministic blast-radius verification
       │
       ▼
CLOSE
persist lessons
```

ChunkHound accelerates the research boxes.

Haiku scouts absorb noisy evidence collection.

Sonnet agents make consequential decisions.

Git/OpenSpec/todo files carry state.

The workflow remains usable when any optional acceleration layer is absent.

---

# 66. Product-level statement

The upgrade should preserve SPWF's original promise:

> AI coding speed without surrendering engineering discipline.

But strengthen it with a second principle:

> **The workflow should make unnecessary work—unnecessary words, searches, code, abstractions and context—harder to create in the first place.**

That is the governing intent for this change.

---

# 67. Challenge decisions

`/spwf:challenge` pass, 2026-09-20. Eleven questions resolved. The rollout and
measurement half lives in [`docs/phase-release-contract.md`](../docs/phase-release-contract.md),
because it spans all five changes and no single one owns it.

**1. ChunkHound is discovery efficiency, never correctness.** `rg + LSP + Read +
git` must remain capable of a fully correct result. ChunkHound is never
authoritative and never proves completeness. What it improves is *the cost of
reaching the right places*: concept search without knowing repo vocabulary,
cross-layer orientation as one research problem, non-obvious related
implementations, semantic history research, and — the biggest practical benefit —
keeping exploratory reads out of the primary context.

**2. The governing invariant is a deletion test.** *If we deleted the ChunkHound
provider tomorrow, would the architecture still make sense and still be an
upgrade?* The answer must be yes. This replaces G1's wording, because it is
checkable against the design rather than against runtime behaviour.

**3. §4 shrinks.** Four shared modules plus one reference:

```text
_shared/
  research-dispatch.md      generic ops: orient, find, history, coverage, verify
  evidence-schema.md
  lean-agent-discipline.md
  model-policy.md

references/
  chunkhound-setup.md       loaded by config-check or on request only —
                            never enters normal workflow context
```

Native implements the operations first. ChunkHound optionally accelerates
`orient` / `find` / `history`.

**4. `config-check` is broad project capability health** — tracker, research
backend, LSP, model assignments, forge. ChunkHound is one recommendation it may
make, not its purpose.

**5. Rollback is phase revert, not a runtime flag.** An `evidence: false` switch
was rejected: it would make nine skills permanently carry both an old and a new
algorithm, so the upgrade itself becomes lasting complexity. Optional switches
stay for genuinely optional things (`tracker: none`, `provider: native |
chunkhound`, `enforce: false`), not for the core workflow.

**6. Compatibility is handled by "evidence is optional input".** Evidence present
→ incorporate it; absent → continue from existing artefacts. Required regardless
for old changes and for low-yield research, and categorically different from
maintaining a second implementation path.

**7. Implementation is five separate OpenSpec changes**, not one. This document
remains the single architectural design; each phase is spec'd, released, and used
on real work before the next is spec'd. See § Split into.

**8. Phase release contract — eight conditions plus enforcement.** Conditions 1-6
as originally drafted; condition 7 requires a falsifiable keep/revert trigger
stated in advance; condition 8 requires a phase to modify only files it introduces
or that no earlier live phase depends on — shared modules are **append-only** once
shipped, or conditions 4 and 5 fail in practice while appearing satisfied.
Enforcement: **Phase N+1 may not be spec'd until Phase N's trigger has been
evaluated and written down.** Outcomes are keep / revert / **amend**.

**9. ChunkHound is change 5, after Phase 2.** Not part of Phase 1 infrastructure:
the deletion test stays cheap only if the provider is its own boundary; Phase 1
must be validatable without an embedding API key; and the native baseline must
exist first or improvement cannot be attributed. `config-check`'s ChunkHound
recommendation heuristic (§16) travels with this change, not Phase 1.

**10. Research depth: surface by default, escalate per question, trace the
escalation.** §7's adaptive classifier is replaced. Classifying "substantial" up
front is impossible pre-build — there is no diff to measure, which is why
`simplify` can use a numeric threshold and `enrich` and `brief` cannot.
Over-research fails invisibly and accumulates as ceremony; under-research fails
visibly. Optimise against the failure you can see.

**11. Escalation is structural, not introspective.** A `CODE-ANSWERABLE` question
(§35) still unresolved after surface research **is** the trigger. The model never
has to notice it is stuck — the question map either has an unticked item or it
does not. This answers the red-team objection that models are unreliable at
knowing what they do not know.

**12. Success measurement keeps only what committed artefacts yield.** Seven of
§64's ten metrics require session telemetry SPWF cannot capture (context usage,
subagent tokens, files read, narrative volume, cost, latency) — stop claiming
them. Kept: depth escalations, diff size before/after `simplify`, scope-drift
events, review findings and rework. Read against what the change contained: on
`add-brief-skill`, `simplify` removed 0.1% of the diff, which looks like failure
until you notice 74% of it was a planning document.

**13. Phase 1 must produce a durable artefact.** The scout's compact result is
written **into the ideation file**, not merely returned in-session — extending
§23's return contract. Without it Phase 1 leaves nothing behind and its trigger
is a judgement call, which is exactly what condition 7 exists to eliminate.

**14. Evidence staleness is per-entry, and lives in `evidence-schema.md`.** A
consumer compares `Research base` against the current tree; entries under
`### Important components` and `### Consumers / blast radius` whose files have
changed are marked stale and re-verified against source before being acted on.
Unchanged entries stand. All-or-nothing invalidation would push people to skip
evidence gathering entirely. Placed in the schema so every later consumer inherits
it rather than each reinventing it.

## Not doing

**Original §59 Phase 5 — `capture` bug path and `enrich` research upgrades.** The
document already gated these on "only after the core flow is proven", which
concedes they depend on evidence that does not exist yet. Planning them now means
guessing what `capture` and `enrich` will need; after phases 1-4 have run on real
work that will be known rather than guessed.

*Revisit condition:* after phases 1-4 have shipped and been used on real work,
reassess whether bug investigation and divergent ideation benefit from the
research primitive.

# 68. Residual risks

Carried into spec rather than solved. Full detail and the premortem in
[`docs/phase-release-contract.md`](../docs/phase-release-contract.md).

| Risk | Confidence | Note |
|---|---|---|
| **Trigger numbers are guesses** | High | "After 5 real changes" was chosen for plausibility, not evidence. A phase whose benefit appears at change 15 gets reverted at 5, and the revert looks justified |
| **This repo is a weak measurement sample** | High | SPWF is mostly Markdown, solo, self-designed. Metrics premised on code volume may never produce a clean signal here, however well they would work on the large Python/Nuxt codebases this targets. Also a ready-made excuse for ignoring any trigger |
| **Nobody runs the trigger check** | Medium | `brief` shipped with a good trigger that has never been checked. Mitigated by the Phase N+1 gate, which is the only mitigation that does not rely on remembering |
| **A scout may not beat reading the files** | Medium | The one subagent dispatch during this challenge took 165s, 67,669 tokens and 22 tool calls to return a single finding. A scout must beat three direct reads or it is overhead with extra steps |
| **The ChunkHound seam stays empty** | Medium | By the time four phases ship, the native protocol is entrenched and the provider never gets adopted |
| **`config-check` becomes a nag** | Low-Medium | §16-19 define four recommendation heuristics before anyone has run it once |
| **Model aliases drift** | Low | §24 replaces pinned models with aliases; Haiku scouts could silently degrade |
