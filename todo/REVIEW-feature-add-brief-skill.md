---
source: review
created: 2026-09-18
status: open
---

# Review follow-ups — feature/add-brief-skill

Deferred from the review of PR #7. Neither belonged in that PR.

**Item 1 is resolved.** Item 2 is still open, which is why this file is.

## 1. ~~Vocabulary collision in `add-understand-skill`'s spec~~ — RESOLVED

> **Done, and in time.** Fixed in `7554921` (spec wording) and carried into
> `understand/SKILL.md` Step 8, which now names `## Covered` explicitly instead of
> complying only transitively through the shared convention.
>
> It landed *before* `add-understand-skill` archived, which was the whole point —
> `openspec/specs/comprehension/spec.md:236` now reads "recording concepts
> demonstrated under `## Known`", and `:450` (from `add-brief-skill`) reads
> "SHALL NOT write `## Known`". Both halves of the contract agree in one canonical
> file. Had this slipped, the first wording would have been permanent.
>
> Original description follows, kept for the record.

### Original: vocabulary collision — fix BEFORE it archives

`openspec/changes/add-understand-skill/specs/comprehension/spec.md:233-236` reads:

> ### Requirement: The learner profile records covered concepts and open items
> The skill SHALL maintain `.spwf/learner.md`, recording concepts **covered**
> under `## Known` ...

`add-brief-skill` made `## Covered` a distinct section meaning *explained but not
demonstrated* — the opposite of `## Known`. The requirement's scenario is still
correct ("concepts taught and **confirmed** SHALL move to `## Known`"); only the
prose is now wrong, and only in its choice of the word "covered".

**Why the timing matters.** `add-understand-skill` archives *first* (this change
adds requirements to the same `comprehension` capability, which is not in
`openspec/specs/` until then). So this wording becomes the canonical capability
definition, and `add-brief-skill`'s delta then lands on top of a spec containing a
term that contradicts the shared convention.

Suggested fix — retitle and reword, leaving both scenarios untouched:

- Requirement title → `The learner profile records demonstrated concepts and open items`
- Body → "recording concepts **demonstrated** under `## Known`"

Deferred rather than fixed in PR #7 because it is a different change's artefact.
It is editable from any branch, so this is a scope decision, not a technical
constraint.

**Do this as the first item of `/spwf:close add-understand-skill`.**

## 2. semgrep has no real coverage in `pr-create`'s pre-flight

`/spwf:pr-create` reports a SAST result that means nothing:

- `--config=auto` refuses to run unless telemetry is enabled, so it is skipped
- `--config=p/security-audit --metrics=off` runs, but reported
  *"Ran 48 rules on 0 files"* — no analyzer matches shell or Markdown

The repo has 22 shell scripts (hooks, `scripts/`, skill helpers) that have never
been meaningfully scanned, and every future PR will report the same empty pass.

Options, in preference order:

1. Install `/trailofbits:semgrep`, which `pr-create` already recommends and which
   enforces `--metrics=off` with curated rulesets
2. Allow semgrep metrics and use `--config=auto`
3. Pin a ruleset that actually covers shell, and record it in `.spwf/`

Not a blocker for PR #7 — that diff is Markdown plus one JSON manifest, so there
was no SAST surface either way.
