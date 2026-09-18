# Recap: `add-brief-skill`

_Retrospective Part 5, 2026-09-18._

## What changed

`/spwf:brief` is a new optional, non-blocking step between `spec` and
`approve-plan`. It explains a planned change **before** it is built — five
sections, expanding then summarising — and ends in one skippable prompt. On a
mismatch it names the remedy and returns; it never acts, never gates, never
re-runs anything.

Supporting it: `spec` now records `**Type**: bug | change` in every proposal so
`brief` can skip bug fixes without keying off a filename convention;
`_shared/learner-profile.md` gained a `## Covered` section and a
write-permission table; `workflow-lint` gained a documented exemption from its
P1 agent-coverage rule for non-blocking teaching steps.

## Concepts touched

**The todo → plan delta.** Section 3 — "Choices you didn't make" — is the reason
this skill exists. What you asked for is the ideation file; what got planned is
`proposal.md` + `tasks.md` + `design.md`. Anything in the plan with no antecedent
in the ideation file is, by construction, a decision something else made. Two
filters keep it from becoming noise: report only what would change the shape of
the result, and treat `enrich` output as *what you asked for*.

**Declared vs derived.** `design.md` records only decisions someone thought worth
writing down — the ones that never got written down are precisely the dangerous
ones. That is why §3 derives from a delta rather than reading a list.

**Explain-only skills have no evidence.** A skill that explains without checking
knows nothing about whether the developer understood. It may record what it
covered; it may not record what is known.

## Decisions

Seven from challenge, all carried into `design.md`. The load-bearing ones:

| # | Decision |
|---|---|
| 1 | Its own golden-path step, not `approve-plan`'s final step — that fires *after* approval, wasting the cheapest moment to object |
| 2 | `spec` **points at** `brief`; it does not invoke it. Risk accepted and recorded |
| 3 | §3 derives from the delta, not from `design.md` |
| 4 | On a mismatch, name the remedy and do not act — acting turns a teaching step into a control-flow step |
| 7 | Teaching is primary; error-catching is a side effect |

## What surprised us

**The change caught three defects in itself, and they shared one root cause.**

1. **§3 worked on its first real run.** Briefing its own change, §3 independently
   derived an unverified ledger write from the delta — the same defect found by
   reading the diff. Briefing `add-branch-enforcement` (archived, not
   co-designed) it surfaced that a second unrelated concern had been folded in,
   and that `auto_branch`'s two-audience default had silently collapsed to one.
2. **Archived changes resolved the ideation file at the wrong path.** `close`
   moves the file to `todo/_done/` without rewriting `proposal.md`'s `Source`
   link, so §3 would silently have had no left-hand side. Found by dogfooding,
   not by inspection.
3. **`## Known` was written without evidence**, and the README then documented
   the very rule the commit existed to overturn.

The root cause running through all three: **a shared convention changed
underneath artefacts written minutes earlier in the same commit.** The README row
was written before the ledger fix; `brief`'s Step 7 duplicated a rationale that
then moved; `add-understand-skill`'s spec kept calling `## Known` contents
"covered". Nothing caught any of it, because none of that behaviour was
specified — which is why the review added a requirement for it.

**A spec written to prevent unspecified behaviour specified behaviour that did
not exist.** The first version of that requirement put a `SHALL` on every
explain-only skill, which includes `recap` — and `recap` writes nothing. Caught
in re-review.

## Read next

`plugins/spwf/skills/brief/SKILL.md` §3 — the two filters are prose a model can
ignore, and no assertion can verify them. Only real usage calibrates them, and
the first version is probably wrong in one direction.

## Recorded, not fixed

- **`todo/REVIEW-feature-add-brief-skill.md` item 2** — `pr-create`'s semgrep
  pre-flight reports a meaningless pass (`--config=auto` needs telemetry;
  `p/security-audit` ran 48 rules on 0 files). 22 shell scripts have never been
  scanned.
- **`close` runs all seven retrospective parts on the feature branch**, but only
  Parts 1, 5 and 6 need granular history. Parts 3 and 4 are whole-repo sweeps
  that give false results on a stale branch.
- **No project learnings doc exists** for Part 1 to write to, so learnings land
  in per-change recaps and nowhere durable. Three changes have now hit this.
