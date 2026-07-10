# Divergent frameworks — the deep toolkit for `enrich` Step 3

The seven lenses in `SKILL.md` are the quick set. These are the deeper frameworks
to reach for when the idea is stuck, over-familiar, or bigger than one lens can
crack. **Use them selectively** — pick the one that fits, don't run all of them.
The goal is to unlock thinking, not to complete a checklist.

Adapted from addyosmani/agent-skills `idea-refine/frameworks.md`, re-framed for
engineering work (features, refactors, infra, tooling) rather than product
ideation. Where a framework overlaps a step SPWF already owns, it points there
instead of duplicating.

## How Might We (HMW) — the quality bar

The reframe in Step 3 lives or dies on the HMW being *sharp*. A good HMW:

- **Narrow enough to act on** — "…help a first-time contributor get a green test run in under 5 minutes" beats "…improve onboarding".
- **Broad enough to allow different solutions** — it names the outcome, not the mechanism. "…add a setup script" has the answer baked in; that's a task, not an HMW.
- **Carries a tension or constraint** — the "…without …" clause is where creativity comes from: "How might we *X* for *this user* without *the thing that currently makes it hard*?"

Bad HMWs to catch yourself writing:
- **Too broad:** "How might we make the codebase better?"
- **Too narrow / solution-embedded:** "How might we add a caching layer to `getUser`?" — the solution is already chosen; back up to the problem it solves.

Generate **2-3 different HMW framings of the same problem** when the first feels
forced — different framings unlock different directions.

## SCAMPER

Seven transform operations on an existing thing — best for *reimagining
something that already exists* (a refactor, a feature extension, a workflow):

- **Substitute** — swap a component, dependency, algorithm, or data source. What if the store were a queue? The cron a webhook?
- **Combine** — merge this with an adjacent feature or an existing helper. What two paths that don't currently share code should?
- **Adapt** — borrow a solution from another part of the system, another team, or another domain that already solved this shape of problem.
- **Modify (magnify / minimise)** — exaggerate one property (10× the data, 10× the callers) or strip it to the minimum viable version.
- **Put to other uses** — who or what else could call this? Does solving it here solve it in three other places?
- **Eliminate** — remove a step, a config, a flag, a whole layer. What's the zero-configuration version?
- **Reverse / rearrange** — flip the order; push work to the caller instead of the callee (or vice versa); invert the data flow.

## First-principles thinking

Best when every idea feels like a small patch on the status quo. Break the thing
down to what's *actually* true and rebuild:

1. **What do we know is true?** — provably, from the code and constraints, not "how it's always been done".
2. **What are we assuming?** — list every assumption, including the obvious-feeling ones.
3. **Which assumptions are real constraints vs habit?** — "Is this a law of physics, or just legacy?"
4. **Rebuild from the truths** — if you only had the fundamental constraints, what would you build? Often smaller than the incremental version.

## Jobs to be done (JTBD)

Best when you're unsure you're solving the *right* problem. Focus on the job the
change is *hired* to do, not the feature asked for:

- **Functional job** — what task is the user/caller/operator trying to complete?
- **Emotional job** — how do they want to feel? (confident the deploy is safe; unafraid to touch this module)
- **Social / systemic job** — how does it need to look to others / the rest of the system?

Framing: *"When I [situation], I want to [motivation], so I can [outcome]."*
The competing option is usually the current workaround, not another feature —
name the workaround the change has to beat.

## Constraint-based ideation

Deliberately impose a constraint to force a sharper solution — best when the idea
is sprawling or vague:

- **Time:** "What if this had to ship in a day?"
- **Surface:** "What if it could touch only one file / add zero new dependencies?"
- **Tech:** "What if we couldn't use the obvious library?"
- **Scale:** "What if it had to work at 100× the load? At 1/100th?"
- **Actor:** "What if the person running this had never seen the codebase?"

## Analogous inspiration

Best for generating variations that feel genuinely different from the obvious
approach. Find how *other* systems solved this **shape** of problem:

- What part of *this* codebase already solves a structurally similar problem? (Grep for it — reuse beats reinvention.)
- What does a well-known system (git, the compiler, the framework you're on) do here?
- The match must be **structural, not surface** — "an idempotent retry with a dedupe key" is structural; "like feature X but for Y" is surface.

## What NOT to do here (owned elsewhere)

- **Pre-mortem / red-team** — imagining the shipped change failed and working
  backwards is the job of `/spwf:challenge` (its adversarial pass). Don't
  duplicate it in enrich. Enrich *expands and chooses*; challenge *attacks*.
