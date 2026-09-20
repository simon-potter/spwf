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

- [ ] 1.1 `_shared/research-dispatch.md` exists and defines the five operations
      (`orient`, `find`, `history`, `coverage`, `verify`), each with its inputs,
      its normalised return shape, and which backend serves it
- [ ] 1.2 The native backend (LSP → `rg` → Read → git) is specified as sufficient
      for a fully correct result on its own, with no other provider present
- [ ] 1.3 Discovery and proof are separated: completeness claims (all callers,
      every reference, no other consumers) route to LSP / `rg` / direct inspection,
      and semantic retrieval is stated as never constituting proof
- [ ] 1.4 `.spwf/research.yaml` schema documented — `provider`, `depth`,
      `fallback`, all optional; an absent file behaves as `provider: auto`,
      `depth: adaptive`, `fallback: native` and never interrupts the workflow
- [ ] 1.5 No ChunkHound-specific instruction appears anywhere in the module. The
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
      re-verified against source. Unchanged entries stand
- [ ] 2.5 The rule states explicitly that evidence is never invalidated wholesale
      because one cited file moved, and says why — wholesale invalidation teaches
      people to skip evidence gathering rather than maintain it

## Phase 3 — Agent discipline and model policy

- [ ] 3.1 `_shared/lean-agent-discipline.md` states the dispatch bar: a subagent is
      justified when work is broad, repetitive, or would otherwise read many files
      into the main session — and not when a few targeted reads would answer the
      question
- [ ] 3.2 The bar cites its evidence (165s / 67,669 tokens / 22 tool calls for one
      finding) so a later author cannot mistake it for taste
- [ ] 3.3 Return contracts: subagents return findings and source locations, not a
      narrative of how the search was performed
- [ ] 3.4 `_shared/model-policy.md` assigns cheap models to deterministic evidence
      gathering and Sonnet-class to synthesis, implementation and consequential
      review; states that model selection is independent of provider selection
- [ ] 3.5 Existing agent definitions in `plugins/spwf-agents/agents/` use model
      aliases rather than pinned generation IDs

## Phase 4 — The scout and capability health

- [ ] 4.1 `plugins/spwf-agents/agents/research-scout.md` exists with a return
      contract conforming to 3.3
- [ ] 4.2 **The scout writes its compact result into the ideation file**, not only
      into the session. This is the durable artefact the keep/revert trigger is
      evaluated against
- [ ] 4.3 `plugins/spwf/references/chunkhound-setup.md` exists as reference only —
      loaded by `config-check` or on explicit request, never pulled into normal
      workflow context
- [ ] 4.4 `plugins/spwf/skills/config-check/SKILL.md` reports capability health
      across tracker, research backend, code intelligence, model assignments and
      forge; distinguishes absent from misconfigured; never halts the workflow
- [ ] 4.5 `config-check` makes **no** ChunkHound recommendation — that heuristic
      ships with change 5. Asserted by grep, since the temptation to add it early
      is the whole reason it is called out

## Phase 5 — Dogfood

Judgement-based; the only check on whether the scout is worth dispatching.

> **Precondition:** `/reload-plugins` after Phase 4, or nothing new is loadable.
> This blocked the dogfood on both previous changes.

- [ ] 5.1 Run `/spwf:config-check` against this repo. Confirm it reports real
      capability state (Beads tracker, GitHub forge, no research backend) and
      recommends nothing that does not exist
- [ ] 5.2 Dispatch `research-scout` on a genuine question about this codebase.
      Confirm the compact result lands in an ideation file and contains source
      locations
- [ ] 5.3 **Compare against the direct-read baseline.** For the same question,
      estimate the cost of answering by targeted reads. If the scout is not
      cheaper, record it — that is the trigger firing early, not a failed dogfood
- [ ] 5.4 Confirm no golden-path skill references the new modules
      (`grep -rl "research-dispatch\|evidence-schema\|lean-agent-discipline\|model-policy" plugins/spwf/skills/` returns only `_shared/`)
- [ ] 5.5 **Revert rehearsal.** Verify the commit range reverts cleanly and prior
      behaviour is restored with no migration. Condition 4 is claimed by every
      phase and tested by none unless it is done here

## Phase 6 — Document and release

- [ ] 6.1 `README.md` — `config-check` row in the skill table; note that it is
      cross-cutting, not a golden-path step
- [ ] 6.2 `plugins/spwf/README.md` — `config-check` row; the four shared modules
      documented in the conventions section
- [ ] 6.3 `plugins/spwf-agents/README.md` — `research-scout` row
- [ ] 6.4 `plugins/spwf/.claude-plugin/plugin.json` minor bump (new skill);
      `plugins/spwf-agents/.claude-plugin/plugin.json` minor bump (new agent)
- [ ] 6.5 `workflow-lint` passes with no P1 findings; `config-check` is not flagged
      as orphaned; `research-scout` is exempt from golden-path agent coverage as a
      cross-cutting agent
- [ ] 6.6 `openspec validate add-research-infrastructure --strict` passes
- [ ] 6.7 Record the keep/revert trigger evaluation date in
      `docs/phase-release-contract.md` — **change 2 may not be spec'd until it is
      evaluated and written down**
