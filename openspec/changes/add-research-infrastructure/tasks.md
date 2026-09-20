# Tasks: add-research-infrastructure

> **Authoritative Reference:** [`todo/research-infrastructure.md`](../../../todo/research-infrastructure.md)
> **Parent design:** [`todo/chunkhound_simplify_upgrade.md`](../../../todo/chunkhound_simplify_upgrade.md) §67
> **Release rules:** [`docs/phase-release-contract.md`](../../../docs/phase-release-contract.md)

> **On testing.** Skill and documentation artefacts, not executable code. There is
> no behavioural assertion to write about a Markdown convention, so "tests" are
> **structural assertions** — greppable checks that each artefact declares what the
> spec requires — plus `workflow-lint` and a dogfood. See `design.md` § Testability.
>
> **Phase 5 (dogfood) runs before Phase 6 (docs and release)** deliberately, as on
> the two previous changes: structural assertions can all pass while the scout is
> useless, and bumping a version before that check publishes a number for something
> still liable to be rewritten.

> **Release-contract condition 8 applies from the moment this ships.** Later phases
> may add sections to these shared modules but may not rewrite existing ones, or
> reverting change 1 stops being clean.

## Phase 1 — The research seam

Ordered first: every other module and the scout reference its vocabulary.

- [x] 1.1 `_shared/research-dispatch.md` exists and defines the five operations
      (`orient`, `find`, `history`, `coverage`, `verify`), each with its inputs,
      its normalised return shape, and which backend serves it
- [x] 1.2 The native backend (LSP → `rg` → Read → git) is specified as sufficient
      for a fully correct result on its own, with no other provider present
- [x] 1.3 Discovery and proof are separated: completeness claims (all callers,
      every reference, no other consumers) route to LSP / `rg` / direct inspection,
      and semantic retrieval is stated as never constituting proof
- [x] 1.4 `.spwf/research.yaml` schema documented — `provider`, `depth`,
      `fallback`, all optional; an absent file behaves as `provider: auto`,
      `depth: adaptive`, `fallback: native` and never interrupts the workflow
- [x] 1.5 No ChunkHound-specific instruction appears anywhere in the module. The
      deletion test holds: remove the (not yet existing) provider and the document
      still stands

## Phase 2 — The evidence schema

- [ ] 2.1 `_shared/evidence-schema.md` defines the canonical structure — existing
      behaviour, invariants / contracts, important components, consumers / blast
      radius, existing tests, patterns to reuse, uncertainty, research trace
- [ ] 2.2 Every evidence file records `Research base` (SHA), provider and depth;
      consequential claims carry source locations
- [ ] 2.3 The research trace is bounded — enough to judge evidence quality, never
      a retrieval dump. States what "compact" means concretely rather than
      asserting it
- [ ] 2.4 **The per-entry staleness rule.** A consumer compares cited files against
      `Research base`; entries under `### Important components` and
      `### Consumers / blast radius` whose files changed are marked stale and
      re-verified against source. Unchanged entries stand. States explicitly that
      evidence is never invalidated wholesale for one moved file, and why —
      wholesale invalidation teaches people to skip evidence gathering rather than
      maintain it
- [ ] 2.5 **Redaction.** Credential-shaped values (API keys, tokens, passwords,
      cookies, connection strings, private keys) are masked before reaching
      persisted evidence or any committed artefact; a discovered hard-coded
      credential is surfaced as a finding naming the file, never the value.
      Load-bearing: `evidence.md` is committed and pushed. Mirrors the
      `comprehension` capability's existing requirement for `understand`

## Phase 3 — Agent discipline and model policy

- [ ] 3.1 `_shared/lean-agent-discipline.md` states the dispatch bar — a subagent
      is justified when work is broad, repetitive, or would otherwise read many
      files into the main session, and not when a few targeted reads would answer
      the question — and cites its evidence (165s / 67,669 tokens / 22 tool calls
      for one finding) so a later author cannot mistake it for taste
- [ ] 3.2 Return contracts: subagents return findings and source locations, not a
      narrative of how the search was performed
- [ ] 3.3 `_shared/model-policy.md` assigns cheap models to deterministic evidence
      gathering and Sonnet-class to synthesis, implementation and consequential
      review; states that model selection is independent of provider selection

## Phase 4 — The research scout

- [ ] 4.1 `plugins/spwf-agents/agents/research-scout.md` exists with a return
      contract conforming to 3.2
- [ ] 4.2 **The scout writes its compact result into the ideation file**, not only
      into the session. This is the durable artefact the keep/revert trigger is
      evaluated against
- [ ] 4.3 Scout output passes through the redaction rule from 2.5 before it is
      written — the ideation file is committed

## Phase 5 — config-check

Split from a single task: this is a whole new skill, and the precedent from
`add-brief-skill` is seven tasks for one `SKILL.md`, not one.

- [ ] 5.1 `plugins/spwf/skills/config-check/SKILL.md` exists with frontmatter,
      `disable-model-invocation: true`, and resolves what it inspects from the
      project rather than assuming a fixed layout
- [ ] 5.2 Per-domain checks: tracker, research backend, code intelligence, model
      assignments, forge. Each reports its own state independently — one
      unconfigured domain never suppresses the others
- [ ] 5.3 **Reports presence, never values.** Configuration inspection touches
      `.spwf/*.yaml` and MCP setup, where API keys live. Asserts a key is set
      without printing it
- [ ] 5.4 Distinguishes **absent** from **misconfigured**, gives an actionable next
      step for each, and never halts the workflow
- [ ] 5.5 Makes **no** ChunkHound recommendation — that heuristic ships with change
      5. Asserted by grep, since the temptation to add it early is the whole reason
      it is called out
- [ ] 5.6 `plugins/spwf/references/chunkhound-setup.md` exists as reference only —
      loaded by `config-check` or on explicit request, never pulled into normal
      workflow context

## Phase 6 — Model alias sweep

Its own phase: mechanical editing of existing files, unlike the authoring work
above, and it touches 14 agents.

- [ ] 6.1 Every file in `plugins/spwf-agents/agents/` references a model alias
      rather than a pinned generation ID
- [ ] 6.2 Verified by command — no pinned generation ID remains
      (`grep -rE 'claude-[a-z]+-[0-9]' plugins/spwf-agents/agents/` returns nothing)

## Phase 7 — Dogfood

Judgement-based; the only check on whether the scout is worth dispatching.

> **Precondition:** `/reload-plugins` after Phase 6, or nothing new is loadable.
> This blocked the dogfood on both previous changes.

- [ ] 7.1 Run `/spwf:config-check` against this repo. Confirm it reports real
      capability state (Beads tracker, GitHub forge, no research backend),
      recommends nothing that does not exist, and prints no configuration values
- [ ] 7.2 Dispatch `research-scout` on a genuine question about this codebase.
      Confirm the compact result lands in an ideation file with source locations
- [ ] 7.3 **Compare against the direct-read baseline.** For the same question,
      estimate the cost of answering by targeted reads. If the scout is not
      cheaper, record it — that is the trigger firing early, not a failed dogfood
- [ ] 7.4 **Exercise the absent-config path.** With no `.spwf/research.yaml`,
      confirm dispatch behaves as `provider: auto` / `depth: adaptive` /
      `fallback: native` and never interrupts. The headline property of this change
      is "works with no configuration"; documenting the defaults is not proving them
- [ ] 7.5 Confirm no golden-path skill references the new modules
      (`grep -rl "research-dispatch\|evidence-schema\|lean-agent-discipline\|model-policy" plugins/spwf/skills/` returns only `_shared/`)
- [ ] 7.6 **Revert rehearsal.** Verify the commit range reverts cleanly and prior
      behaviour is restored with no migration. Condition 4 is claimed by every
      phase and tested by none unless it is done here

## Phase 8 — Document and release

- [ ] 8.1 `README.md` — `config-check` row in the skill table; noted as
      cross-cutting, not a golden-path step
- [ ] 8.2 `plugins/spwf/README.md` — `config-check` row; the four shared modules
      documented in the conventions section
- [ ] 8.3 `plugins/spwf-agents/README.md` — `research-scout` row
- [ ] 8.4 `plugins/spwf/.claude-plugin/plugin.json` minor bump (new skill);
      `plugins/spwf-agents/.claude-plugin/plugin.json` minor bump (new agent)
- [ ] 8.5 `workflow-lint` passes with no P1 findings. `config-check` is
      cross-cutting and `research-scout` is a cross-cutting agent — neither is a
      golden-path step, so step↔skill and agent-coverage checks do not apply to
      them; confirm neither is flagged as orphaned
- [ ] 8.6 `openspec validate add-research-infrastructure --strict` passes
