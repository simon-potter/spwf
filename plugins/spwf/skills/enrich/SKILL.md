---
# Divergent counterpart to challenge. Adapts the divergent→convergent structure of
# addyosmani/agent-skills/idea-refine (HMW reframing, lens-driven variation, converge-on-value,
# assumptions-to-validate, "Not doing") and the "propose 2-3 approaches with trade-offs" +
# early-decompose moves of obra/superpowers/brainstorming — made SPWF-native: file-first,
# one-question-at-a-time, codebase-grounded, writes back into the same todo file for challenge to attack.
name: enrich
description: Divergent gate — grow and re-shape an idea before challenge attacks it. Accepts a todo file path as $ARGUMENTS (defaults to the most recent file in todo/ if omitted). Reframes the problem as "How Might We", generates grounded variations across seven lenses, converges on 2-3 distinct approaches with trade-offs and a recommendation, then writes directions / recommended direction / assumptions-to-validate / not-doing back into the ideation file. Skippable for bugs and trivial/mechanical changes.
disable-model-invocation: true
allowed-tools: [Read, Write, Grep, Glob, Bash]
---

# enrich

`capture` checks an idea is coherent. `challenge` attacks a fixed idea to zero.
Neither ever asks *is this the right shape?* or *what else could this be?*
`enrich` is the divergent step in between: it opens the option space, converges
on the strongest direction, and hands `challenge` a sharper idea to interrogate.

**Divergent then convergent.** Expand before you attack — generating and
interrogating are opposite mental modes, so this runs as its own phase.

## North star — value and the end game come first

Everything below serves an outcome for a real person — the end user, the
operator, the next developer. Hold that line:

- **Every variation must trace to a user/operator outcome.** Internal elegance
  that doesn't move the end game is noise, however clever. `Fit & leverage`
  (Step 4) is how well a direction serves that outcome *durably* — it is a
  servant of value, never a substitute for it.
- **Start from the experience, work back to the mechanism.** What should the
  person be able to *do*, or stop having to do? Design the outcome first, then
  the implementation.
- **Focus is saying no.** The strongest enrichment cuts good-but-off-mission
  ideas — that's what the `## Not doing` list is for.
- **Anchor to *this project's* priorities, not generic ones.** At the start of a
  session, load the project's objectives snapshot per
  [`_shared/project-priorities.md`](../_shared/project-priorities.md) so the
  value/end-game judgements reflect what this project actually cares about. If no
  snapshot exists, that doc explains how to derive one from `docs/`, the README,
  and roadmap/OKR files.

## Step 1 — Identify the target file

**Priorities refresh mode.** If `$ARGUMENTS` contains `--refresh-priorities`,
re-derive `.spwf/priorities.md` per [`../_shared/project-priorities.md`](../_shared/project-priorities.md)
(confirm the draft, write, offer to commit), then stop — this mode only refreshes
the snapshot and does not enrich a file.

Otherwise: if `$ARGUMENTS` contains a file path, read that file. If not, find the
most recently created file in `todo/`:

```bash
ls -t todo/*.md | head -1
```

Read it completely. Then **load the project priorities snapshot** per
[`../_shared/project-priorities.md`](../_shared/project-priorities.md) (read it if
present; offer to derive it if absent) so Steps 3-4 anchor value on this project's
actual mission, users, and non-goals.

## Step 2 — Should this be enriched at all?

Enrich earns its keep when the *shape* of the work is still open. Skip it — say
so in one line and point at `/spwf:challenge` — when the idea is already
single-shaped:

| Skip when | Why |
|---|---|
| The file is `todo/BUG-*.md` | A root-caused bug has one fix shape, not a design space. Go straight to challenge. |
| `Rough scope` says content/config-only or trivial code fix | There is nothing to diverge on. |
| The change is purely mechanical (rename, dependency bump, config toggle) | One obvious approach; divergence is theatre. |
| The user explicitly says the approach is already decided | Respect it — proceed to challenge. |

Otherwise, enrich. When in doubt, run it — a soft idea that survives divergence
reaches challenge stronger; a hard one costs two minutes to confirm.

## Step 3 — Reframe & Expand (divergent)

**Goal: open the idea up, grounded in what actually exists.**

1. **Reframe as "How Might We".** Restate the `## Context` as a crisp
   `How might we …?` problem statement. This forces clarity on the *problem*
   before anyone commits to a *solution*. Show it and confirm it captures the
   real intent before continuing — a wrong frame poisons everything downstream.
   A sharp HMW is narrow enough to act on, broad enough to allow different
   solutions, and carries a tension ("…without …"); if the first feels forced,
   try 2-3 framings. See `frameworks.md` § "How Might We — the quality bar".

2. **Ask up to 3 sharpening questions — one at a time.** Only ask what the file
   and codebase can't already answer. Draw from: *who is this for, specifically?
   what does success look like? what real constraints bind us (time, tech,
   data)? what's been tried before? why now?* Provide your own best answer from
   context with each question; wait for confirmation or override. Stop at three —
   this is enrichment, not the challenge interview.

3. **Scope smell (early).** If the idea describes multiple independent
   subsystems, flag it now — *"this looks like N independent pieces; want to
   enrich just the first?"* Don't spend divergence on something that needs
   decomposing first. (Challenge owns the formal split; this is just an early
   warning.)

4. **Generate 5-8 grounded variations.** Ground every variation in the codebase —
   use `Grep`/`Glob`/`Read` for existing architecture, patterns, and prior art,
   and reference specific files. Push past the user's initial framing using these
   lenses (pick the ones that fit — don't run all seven mechanically):

   - **Inversion** — what if we did the opposite?
   - **Constraint removal** — what if time / budget / a dependency weren't a factor?
   - **Audience shift** — what if this were for a different user or caller?
   - **Combination** — what if we merged this with an adjacent feature or existing helper?
   - **Simplification** — what's the version that's 10× simpler?
   - **10× scale** — what would this look like at much larger scale?
   - **Expert lens** — what would a domain expert find obvious here that an outsider wouldn't?

   Each variation needs a *reason it exists*, not just a bullet — name the lens
   that generated it, so the user learns to think this way too. Present them,
   then let the user react — which resonate, which to drop, what's missing.

   When the idea is stuck, over-familiar, or bigger than one lens can crack,
   reach for the deeper toolkit in `frameworks.md` (SCAMPER, first-principles,
   jobs-to-be-done, constraint-based, analogous inspiration). Use them
   selectively — pick the one that fits; don't run them all.

## Step 4 — Converge

After the user reacts, switch to convergent mode.

1. **Cluster into 2-3 distinct approaches.** Each must feel *meaningfully
   different* — different architecture, boundary, or bet — not three flavours of
   one idea.

2. **Present them as approaches with trade-offs, lead with a recommendation.**
   For each: what it is, what it costs, what it risks. State which you'd pick and
   why *first*, then the alternatives — so the user is reacting to a position,
   not refereeing a survey.

3. **Triage each on three axes** (full rubric, red flags, and the value×feasibility
   decision matrix in `convergence.md`):
   - **Value** — is the pain real and recurring? Painkiller or vitamin? Name who hits it now.
   - **Feasibility** — effort and hardest part; is there a version that delivers value in days, not months?
   - **Fit & leverage** — root-cause vs symptom, reuse (rule of three), durability, and does it run with the grain of the codebase? *(For user-facing ideas, also weigh differentiation — see the sub-note in `convergence.md`.)*

4. **Surface hidden assumptions, sorted by cost-of-being-wrong.** Don't just list
   them — tier them (see `convergence.md` § "Assumption audit"), each with how it
   could be tested, so `challenge` and `spec` inherit which bets are load-bearing:
   - **Must be true** — dealbreakers; if wrong the direction collapses. Validate before building.
   - **Should be true** — important but survivable; you'd adjust the approach.
   - **Might be true** — secondary; don't validate until the core is proven.

   Untested must-be-true assumptions are the number-one killer of good ideas — do
   not skip this.

**Be an honest partner, not a yes-machine.** If the user's original idea is the
weakest of the set, say so with specificity and kindness. Push back on
complexity; name it when the emperor has no clothes.

## What good enrichment looks like

The tells of a session that actually added thinking, rather than restating the
ticket back:

- **The reframe changed the frame.** "Add a cache to `getUser`" became "cut p95 profile-load latency without adding a store to keep warm". If the HMW is just the title reworded, you haven't reframed yet.
- **Questions diagnosed before prescribing.** Each question determined *which kind* of problem this is — and the answer changed which variations were worth generating.
- **Every variation had a reason.** Named its lens, grounded in real files. A variation you can't justify shouldn't be on the list.
- **You had an opinion.** "I'd pick B — A is safe but papers over the root cause." Not a neutral menu.
- **Convergence was honest.** A direction got called out for low leverage or hidden complexity, and the recommendation followed the rubric, not the user's first instinct.
- **The output is actionable, not contemplative.** Assumptions to *test*, a slice to *build*, ideas explicitly *not* doing — not a list of things to "think about".
- **It adapted to the work.** A refactor generated reuse/root-cause variations; a user-facing feature generated audience/UX ones. Same method, output matched the domain.

### A compact worked example (feature inside an existing codebase)

> **Idea:** "add real-time collaboration to our document editor."
>
> **Reframe:** *How might we let 2-5 people work the same document simultaneously without it feeling chaotic — given we have no WebSocket layer today?*
>
> **A grounded variation (Simplification lens):** block-level presence + locking. `src/models/document.ts` already stores independent blocks with flat ordering, so a `locked_by` field + a thin presence channel gives real co-editing with no character-level conflict resolution. *Reason it exists: the existing block model makes the expensive part (merge/CRDT) unnecessary.*
>
> **Converge:** value = high (losing deals to competitors that have it — a painkiller); feasibility = medium (need a presence transport, but no CRDT); fit & leverage = high (rides the existing block boundary rather than fighting it).
>
> **Assumption — Must be true:** block-level granularity keeps real edit-conflicts rare enough that locking doesn't feel obstructive. *Test: instrument current multi-editor sessions for same-block overlap.*
>
> **Not doing:** character-level CRDT (complexity the block model makes unnecessary), offline sync (out of scope for 2-5 live users), AI-mediated merge (premature).

## Step 5 — Write enrichment back to the todo file

Update the source file. **Do not touch the frontmatter** (`source`, `status`,
`created` are load-bearing — the `todo-frontmatter-check` hook enforces them) and
do not delete `## Open questions` or `## Rough scope` — challenge consumes those.

- Update `## Context` to lead with the reframed **How might we …?** line (keep the
  original detail beneath it).
- Insert, after `## What we know`:
  - `## Directions considered` — the 2-3 approaches, each with its one-line trade-off, the rejected ones marked so.
  - `## Recommended direction` — the chosen approach and *why*, in a few sentences. Scope it to the smallest slice that tests the riskiest assumption (see `convergence.md` § "Smallest-slice principles").
  - `## Assumptions to validate` — grouped **Must / Should / Might be true**, each with how it could be tested.
  - `## Not doing` — good ideas deliberately rejected, each with its reason. *(This list is the most valuable output — focus is saying no to good ideas. Make the trade-offs explicit.)*
- Fold anything still unresolved into `## Open questions` so challenge attacks it,
  and align `## Rough scope` with the recommended direction.

## Step 6 — Report and hand off to challenge

```
✓ Enriched: todo/{slug}.md

Reframed:    How might we {…}
Explored:    {N} variations → {2-3} directions
Recommended: {one-line chosen direction}
Not doing:   {count} ideas rejected · {count} assumptions to validate

Recommended next step: /spwf:challenge todo/{slug}.md
```

Challenge now attacks the *chosen* direction — and its "Alternatives considered"
dimension arrives pre-answered by `## Directions considered` and `## Not doing`,
so the interview verifies the rejection rationale instead of starting cold.

## Step 7 — Commit

Show `git diff todo/`, then propose:

```
docs: enrich {slug} — {recommended direction in a few words}

Reframed as: How might we {…}
Recommended: {chosen direction} — {one-line why}
Rejected: {the strongest not-doing, with reason}
{note any surprise surfaced from codebase exploration}
```

Ask: "Ready to commit? Confirm with 'yes' or edit the message first." After
confirming:

```bash
git add todo/{slug}.md
git commit -m "{confirmed message}"
```
