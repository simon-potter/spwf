# Tasks: add-brief-skill

> **Authoritative Reference:** [`todo/teach-early-brief.md`](../../../todo/teach-early-brief.md)

> **On testing.** Skill and documentation artefacts, not executable code. There is
> no behavioural assertion that proves a briefing taught anything, so "tests" here
> are **structural assertions** — greppable checks that each artefact declares what
> the spec requires — plus `workflow-lint` and a manual dogfood. See `design.md`
> § Testability.
>
> **Phase 3 (dogfood) runs before Phase 4 (docs and release) deliberately.** That
> ordering caught a fundamental failure in `add-understand-skill` before its
> version bump. Do not reorder it.
>
> Tasks are grouped by coherent artefact section rather than split per assertion —
> a SKILL.md is written in one pass, and eighteen tick-boxes over one file is
> ceremony rather than progress. Learned from the same change.

## Phase 1 — `spec` records the change type

Ordered first, and alone: `brief` reads the `Type` line, so it must exist before
the skill that consumes it. `spec`'s *pointer* change is deliberately **not** here
— see Phase 4.

- [x] 1.1 `spec/SKILL.md`'s `proposal.md` template gains a
      `**Type**: bug | change` line, positioned with the other header fields, with
      guidance on which value to use

## Phase 2 — The `brief` skill

- [x] 2.1 **Frontmatter.** `plugins/spwf/skills/brief/SKILL.md` exists with
      `name: brief`, a description, `disable-model-invocation: true`, and
      `allowed-tools` covering read, glob, grep, bash and the edit needed for
      first-run `.spwf/learner.md` creation

- [x] 2.2 **Change resolution.** Resolves an empty argument, a change-id, or a
      todo path to a change
      - Falls back to `openspec/changes/archive/`; halts naming both locations
      - Reports what is missing and stops when `proposal.md` or `tasks.md` is
        absent, rather than briefing from partial artefacts
      - Names `/spwf:approve-plan` as the next step on every exit path

- [x] 2.3 **Bug detection.** Reads `**Type**` from `proposal.md`; skips changes
      recorded as `bug`, stating that it has; treats an absent line as a change
      and proceeds

- [x] 2.4 **Level calibration.** Reads `.spwf/learner.md` per
      `_shared/learner-profile.md`; on first run **ensures the `.gitignore` entry
      before writing the file** — a first run in a fresh project must not commit
      personal comprehension data — then asks the single calibration question and
      never asks again
      - Level sets background depth per section, never which sections appear
      - Copy `understand`'s ordering rather than reinventing it; it already gets
        this right

- [x] 2.5 **The five sections, expand then summarise.** Emits what will be built /
      why this way / choices you didn't make / what this touches / summary, in
      that order, with the summary last
      - Section 1 describes substance in plain language and does not reproduce
        the task list
      - Length cap reduces depth in sections 1, 2 and 4 — never section 3
      - Trivial change: says so plainly and stops without padding

- [x] 2.6 **Section 3 derivation.** Derives candidates from the ideation file
      against `proposal.md` + `tasks.md` + `design.md`, with `design.md` as
      supporting detail only
      - **Consequence filter**: reports a candidate only if choosing differently
        would change the shape of the result; excludes naming, file paths and
        mechanical task decomposition
      - **`enrich` output counts as asked-for**: `## Directions considered`,
        `## Recommended direction` and `## Not doing` are decisions the developer
        made and are never reported as unasked-for
      - Empty filtered delta: says so and omits the section, never inventing
        decisions
      - Works with no `design.md` present
      - ⚠ **The filter is prose a model can ignore.** A structural assertion can
        only verify the words are present, not that the filter is applied. Task
        3.2 is the only real check — treat it as load-bearing, not confirmatory

- [x] 2.7 **Non-blocking guarantee and the prompt.** Prints, offers one skippable
      prompt, returns; never halts or gates `approve-plan`
      - On a reported mismatch, classifies it and names the remedy
        (`approve-plan` / re-run `spec` / `challenge`) and performs none of them
      - The guarantee is stated in the skill body so a later edit cannot turn it
        into a gate without contradicting the file

## Phase 3 — Dogfood

Judgement-based; the only check on whether the brief teaches. Cannot be
automated.

> **Precondition:** `brief` must be loadable before any of this runs — the local
> marketplace resolves skills from the working tree, so a `/reload-plugins` is
> needed after Phase 2. This blocked the dogfood on the previous change; it is
> stated here so it doesn't again.

- [x] 3.1 Run `/spwf:brief add-brief-skill` — the change briefs itself. Confirms
      resolution, the five sections, and that `spec`'s Type line is read.
      Weak on teaching value, since the developer co-designed this change
- [x] 3.2 Run `/spwf:brief` against a change the developer did **not** co-design.
      Pass condition, in priority order: (a) the developer could explain the plan
      to someone else afterwards; (b) section 3 contains consequential decisions
      rather than banal elaboration; (c) no `enrich` decision was re-surfaced as
      unasked-for
- [x] 3.3 Confirm the non-blocking path: report a mismatch at the prompt and
      verify the remedy is named and nothing is re-run
- [x] 3.4 If any dogfood fails, revise the section-3 derivation or the section
      content (not the prompt wording) and re-run before Phase 4

## Phase 4 — Announce the step, document, release

`spec`'s pointer change lands here, not in Phase 1. Repointing it before `brief`
exists would leave a window where `spec` tells you to run a skill that isn't
there — the pointer is an *announcement* of the new step, and belongs with the
other announcements.

- [x] 4.1 `spec/SKILL.md`'s terminal next-step pointer moves from
      `/spwf:approve-plan` to `/spwf:brief`; its frontmatter description is
      updated to match
- [x] 4.2 `README.md` — golden path table gains a `brief` row between Spec and
      Approve plan; the workflow diagram gains the step; the skill table gains a
      row
- [x] 4.3 `plugins/spwf/README.md` — skill table gains a row; the Spec row is
      updated to point at `brief`; the "Learning modes" section is extended, since
      it currently describes only the two post-hoc skills
- [x] 4.4 `plugins/spwf/.claude-plugin/plugin.json` bumped 1.20.0 → 1.21.0
- [x] 4.5 `workflow-lint` passes with no P1 findings; `brief` is not flagged as
      orphaned; the `spec` → `brief` → `approve-plan` successor chain resolves
- [x] 4.6 `openspec validate add-brief-skill --strict` passes
