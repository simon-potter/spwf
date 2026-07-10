# Convergence rubric — the criteria for `enrich` Step 4

Use this to stress-test the 2-3 directions and choose one. Not every criterion
applies to every change — use judgement about which dimensions matter for *this*
work. A one-file refactor and a user-facing feature weight these very differently.

Adapted from addyosmani/agent-skills `idea-refine/refinement-criteria.md`. The
third axis is re-framed from product "differentiation" to engineering **fit &
leverage** (per project decision) so internal refactors and infra aren't forced
through a marketplace lens; a differentiation sub-note is kept for user-facing work.

## The three axes

### 1. Value — is the pain real?

The most important axis. If the value isn't clear, nothing else matters.

**Painkiller vs vitamin:**
- **Painkiller** — removes an acute, recurring pain or a live risk. People have built workarounds; they describe it with feeling; it blocks or slows real work today.
- **Vitamin** — marginally nicer. People nod, say "that'd be good", and don't change behaviour.

**Questions:**
- Name the specific people/systems that hit this *now*. If you can't, the value is unproven.
- What are they doing today instead? (The real competitor is the current workaround.)
- How often does the pain occur? (Daily friction ≫ once-a-quarter annoyance.)
- Is this *pull* (someone's actually asking) or *push* (we think they should want it)?

**Red flags:** "everyone would benefit"; "it's like X but a bit better"; the problem is real but rare (high intensity, low frequency rarely justifies the work).

### 2. Feasibility — can we actually build it?

- **Technical:** does the approach rest on things that already work? What's the single hardest part — known-hard or novel-hard? Any dependency on code/data/APIs you don't control?
- **Effort:** minimum change to deliver the core value. Does it need expertise or access the team lacks?
- **Time-to-value:** is there a version that delivers value in a day or two, not a month? What's on the critical path?

**Red flags:** "we just need to solve [hard research problem] first"; several dependencies that all must land together; the "minimum" version is still weeks — it isn't minimal enough.

### 3. Fit & leverage — does it earn its place in the system?

The engineering counterpart to differentiation. A direction with high fit &
leverage pays back beyond the immediate ask:

- **Root cause vs symptom** — does it fix the underlying cause, or paper over it? (Symptom fixes are sometimes right — but name it as one.)
- **Reuse** — does it solve the problem *once* for several call sites, or add a fourth bespoke copy? (Rule of three.)
- **Durability** — will this still be the right shape after the next change, or is it scaffolding you'll rip out?
- **Grain of the codebase** — does it follow existing patterns and boundaries, or fight them? Fighting the grain is sometimes correct, but it's a cost to name, not hide.
- **Blast radius** — how much does it touch, and how reversible is it if wrong? (Small, reversible, high-leverage wins.)

> **Differentiation sub-note (user-facing / product ideas only).** When the change
> *is* a product feature, also rank the difference it makes, strongest to weakest:
> new capability (was impossible) > 10× improvement on a dimension users feel >
> reaches a newly-included audience > works in a context where the current thing
> fails > cleaner UX for the same capability > cheaper. Differentiation that's
> purely technical, or on a feature users don't care about, doesn't count.

## Assumption audit — three tiers

For the recommended direction, sort assumptions by what it costs to be wrong.
This replaces a flat "assumptions to validate" list and tells `challenge` (and
`spec`) exactly which bets are load-bearing.

- **Must be true (dealbreakers)** — if wrong, the direction collapses. *Validate before building.* e.g. "the upstream API returns X within the timeout".
- **Should be true (important)** — significantly affects success but survivable; you'd adjust the approach. e.g. "callers can tolerate an extra async hop".
- **Might be true (nice-to-have)** — secondary optimisations; don't spend validation on these until the core is proven.

Write each with **how it could be tested** (a spike, a query, a quick prototype,
one question to a person who'd know).

## Decision matrix

Rank the directions on value × feasibility, then use **fit & leverage** as the
tiebreaker within a quadrant:

|              | High feasibility        | Low feasibility        |
|--------------|-------------------------|------------------------|
| **High value** | Do this first          | Worth the risk — de-risk the hard part first |
| **Low value**  | Only if genuinely trivial | Don't                 |

## Smallest-slice principles (feeds `## Recommended direction` + `## Not doing`)

When scoping the recommended direction down to what to actually build first:

1. **One job, done well** — nail exactly one outcome, not three half-done.
2. **Riskiest assumption first** — the first slice should test the *Must-be-true* most likely to be wrong.
3. **Time-box, not feature-list** — "what can we build and verify this week?" beats "what features does it need?".
4. **The "Not doing" list is mandatory** — name what you're deliberately cutting *and why*. It's the highest-signal output: it prevents scope creep and forces honest prioritisation.
5. **Prefer reversible** — a first slice you can undo cheaply is worth more than a perfect one you can't.
