# Evidence schema — shared convention

Defines what a persisted codebase research result looks like, how long it stays
valid, and what must never appear in it.

Research is expensive and conversations are disposable. A question answered during
`challenge` gets answered again during `build` unless the answer outlives the
session that produced it. This document is what makes that possible.

**Evidence is optional input.** A consumer that finds evidence incorporates it; a
consumer that finds none continues from the existing artefacts. Old changes have
no evidence file, and honest research sometimes yields little. Handling absence is
required, and is not the same thing as maintaining two code paths.

---

## Where it lives

| Stage | Location |
|---|---|
| During ideation | a `## Codebase evidence` section in the `todo/` file |
| From `spec` onward | `openspec/changes/{change-id}/evidence.md` |

Both are **committed and pushed**. That fact drives the redaction rule below.

---

## Canonical structure

```markdown
## Codebase evidence

Research base: <SHA>
Provider: native
Depth: surface | broad | deep

### Existing behaviour
- What the system does today, in the area this change touches

### Invariants / contracts
- What must remain true. The things a change breaks by accident

### Important components
- path:line — why this one matters

### Consumers / blast radius
- path:line — what depends on the above, and how

### Existing tests
- path — what is already pinned by a test

### Existing patterns to reuse
- path:line — the nearest precedent worth following

### Uncertainty
- What research did not establish, stated plainly

### Research trace
- orient: <question asked>
- searches: <queries run>
- deterministic checks: <LSP / rg used for completeness>
- escalations: <question that forced surface → broad | deep>
- verified source: <what was read directly>
```

**Every consequential claim carries its `path:line`.** A claim without a source
location cannot be verified later and cannot be checked for staleness, which makes
it worse than no claim at all.

---

## Compactness is a bound, not an aspiration

"Compact" means nothing unless it has a number attached. These are the bounds:

| Section | Bound |
|---|---|
| Each bullet | **one line** — a location and a reason, not a paragraph |
| Existing behaviour | at most 5 bullets |
| Invariants / contracts | at most 5 bullets |
| Important components | at most 8 bullets |
| Consumers / blast radius | at most 8 bullets |
| Research trace | at most 10 lines total |
| Whole file | **one screen.** If it does not fit, research went too wide |

The trace records enough to judge the *quality* of the evidence — what was asked,
what was searched, what was proved deterministically, what was read. It is never a
retrieval dump. If a reader cannot tell within ten lines whether the research was
any good, more lines will not help.

---

## Staleness is per entry

Evidence is captured against a commit. Code moves. Stale evidence presented as
current is worse than no evidence, because it reads as authoritative.

**The rule.** A consumer compares `Research base` against the current tree:

- Entries under **`### Important components`** and **`### Consumers / blast
  radius`** whose cited files have changed since that SHA are **marked stale and
  re-verified against source** before being acted on.
- Entries whose cited files are unchanged **remain valid**, however old the file is.
- Everything else is advisory context and is read as such.

**Evidence is never invalidated wholesale because one cited file moved.** That
rule would be simpler and it would be worse: a two-week-old evidence file whose
cited code has not moved is still perfectly good, and blanket invalidation teaches
people to skip evidence gathering rather than maintain it. Only the affected
entries are re-verified.

This mirrors the operating pattern in
[`research-dispatch.md`](research-dispatch.md): discovery is cheap and provisional,
proof is deliberate and current.

---

## Redaction — before anything is written

**Evidence is a committed artefact.** Research reads source, and source contains
secrets. Nothing credential-shaped may reach an evidence file, an ideation file, or
any other committed path.

Mask before writing. Credential shapes include:

```text
API keys · tokens · passwords · cookies · session identifiers
connection strings · private keys · bearer headers
```

**A discovered hard-coded credential is a finding, not a quotation.** Report the
file and why it matters; **never the value**:

```markdown
### Uncertainty
- `config/database.py:14` contains what appears to be a hard-coded connection
  string. Not reproduced here. Worth handling before this change ships.
```

This mirrors the `comprehension` capability's existing requirement for
`understand`. Same risk, same route: research quotes source into a file that gets
committed and pushed.

> **Known duplication.** `understand/SKILL.md` § Step 6 states its own redaction
> rule and does not reference this document. Two statements of one rule is exactly
> the drift this `_shared/` directory exists to prevent, and it should collapse to
> one. It is not fixed here because this change may not modify a golden-path skill
> — a constraint of its own spec, and the right one: an infrastructure change that
> quietly edits `understand` is no longer independently revertible. Fold it in when
> a later change touches `understand` for its own reasons.

---

## Scheduled review

> **Reassess after evidence has been consumed by a real build.** This schema is
> written before anything reads it. The bounds above are estimates, and the section
> list is a guess at what a builder actually wants in front of them.
>
> The signal to watch: which sections get read, and which get skipped. A section
> nobody reads should be cut rather than tolerated, and a bound that is routinely
> exceeded for good reason should be raised rather than quietly ignored.
