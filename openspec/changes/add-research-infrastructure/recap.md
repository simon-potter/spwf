# Recap: `add-research-infrastructure`

_Retrospective Part 5, 2026-09-20._

## What changed

Four shared convention documents, one reference file, one agent and one skill —
and **no golden-path behaviour at all**. `research-dispatch.md` defines five
research operations over a native backend of LSP, `rg`, Read and git.
`evidence-schema.md` defines what persisted research looks like, when it goes
stale, and what must never appear in it. `research-scout` does broad searching
away from the main session and writes a compact result into the ideation file.
`config-check` reports what a project's SPWF capabilities actually are.

Change 1 of 5 in `adaptive-research-lean-execution`.

## Concepts touched

**A seam with one implementation.** `research-dispatch` ships native-only. That
looks like over-abstraction and would be if the second provider were speculative —
it is not, and the ordering buys attribution: the native baseline must exist and be
measured before an accelerator is added, or any improvement is unattributable.

**Discovery is not proof.** `coverage` and `verify` are native-only *by design*, so
no future provider can back a completeness claim. Finding three consumers by
searching is not evidence a fourth does not exist.

**Append-only from today.** Release-contract condition 8 now binds these four
modules. Changes 2-4 may add sections; they may not rewrite. Getting the vocabulary
wrong here is expensive in a way first drafts usually are not.

## Decisions

| Decision | Why |
|---|---|
| Seam ships native-only | The deletion test stays cheap only if the provider is its own boundary |
| Staleness is per-entry | Wholesale invalidation is simpler and worse — it teaches people to skip evidence gathering rather than maintain it |
| Scout writes to the ideation file | Without a durable artefact this change leaves nothing behind and its trigger degrades to an impression |
| A subagent must beat reading the files | Stated with its measurement attached so a later author cannot mistake it for taste |

## What surprised us

**Five assertion bugs, zero implementation bugs.** Every red-phase failure was the
test grepping for wording the file did not use — backtick regex, quote nesting
through `eval`, vocabulary mismatch, scope too broad, and finally an assertion that
failed on text *describing* the thing it forbade. Greppable assertions verify
vocabulary, not meaning. They would catch a missing section and would happily pass
one that said the opposite.

The genuinely useful checks pointed at **the repo**, not at the file being written:
the duplication claim, cross-reference resolution, the revert rehearsal.

**A clean review was wrong.** The Pass 2 reviewer returned 0 Critical / 0 Important
/ 0 Minor and asserted "depth guidance aligns across modules". It did not — the spec
required `depth: adaptive`, a value `research-dispatch.md` does not define. Found by
checking that one sentence. This produced Rule 3 in `lean-agent-discipline.md`: a
subagent's report is a claim, not a result, and a clean report deserves more scrutiny
than one with findings, because a report with findings carries checkable evidence and
a clean one carries only assertions.

**I fabricated a number.** The PR body claimed 12 requirements / 15 scenarios; the
spec has 9 / 12. Asserted three times across a commit message and a PR description
without once running `grep -c`, in documents where every other figure was measured.
Caught at `pr-review` by verifying claims rather than re-reading prose.

**Pins caused the drift they were meant to prevent.** Eight agents sat on
`claude-sonnet-4-6`, a superseded generation, and nothing in the repo surfaced it.
The alias sweep was scoped as a consistency task; the actual payoff was moving two
thirds of the fleet off an old model.

**`config-check` found a real misconfiguration on its first run** — `tracker: beads`
configured with live data in `.beads/`, and `bd` not installed. Silent until
`/spwf:close` would have failed to transition a ticket.

## Read next

`plugins/spwf/skills/_shared/lean-agent-discipline.md` — Rule 3 is stated from three
measured dispatches in one day. Enough to write the rule down, not enough to
calibrate it. Its scheduled review says so.

## Recorded, not fixed

- **`chunkhound-setup.md` documents a provider that ships in change 5.** Raised four
  times. No longer a defect — it has a home under its owning skill and a consumer
  that names it — but still early. Check it aged well when change 5 is spec'd.
- **No project learnings doc exists**, so Part 1 has nowhere durable to write.
  Fourth change in a row.
- **`doc-lint` skipped for lack of `docs/documentation-rules.md`.** Third in a row.
- **semgrep reports a pass over zero scanned files.** Tracked in
  `todo/REVIEW-feature-add-brief-skill.md`.

## The trigger this change now owes

> After 3 real changes, if no scout result written into an ideation file contained a
> fact that shaped the change, **revert**.

One of those three has happened: the scout's evidence on where `evidence.md` would be
read is already shaping change 2's design. **Change 2 may not be spec'd until this is
evaluated and written into `docs/phase-release-contract.md`.**
