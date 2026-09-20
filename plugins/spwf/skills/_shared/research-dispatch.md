# Research dispatch — shared reference

Single source of truth for how skills and agents research an existing codebase.
Skills reference this document; they do not repeat the dispatch table inline, and
they do not embed provider-specific instructions.

**Native is the default and the baseline.** LSP, `rg`, direct Read and git are
sufficient for a fully correct result on their own. Other providers are
accelerators — they may make research cheaper, never more authoritative.

---

## Operating principle: a capability, not a tool

A skill requests a **logical operation**. The dispatcher decides which backend
serves it. That is the whole point of the seam: a skill that hard-codes a tool has
to be rewritten when the tool changes.

| Situation | Behaviour |
|---|---|
| A skill requests an operation | Dispatch to the configured provider; return the normalised shape |
| The configured provider is unavailable and `fallback: native` | Use native. Do not interrupt the workflow |
| The configured provider is unavailable and `fallback: fail` | Halt the research-dependent phase with an actionable setup message |
| No configuration exists | Behave as `provider: auto`, `depth: surface`, `fallback: native` |

> **The deletion test.** If every provider other than native were deleted
> tomorrow, this document and every skill referencing it must still make sense and
> still be an upgrade. Any instruction that fails that test belongs in a provider's
> own reference file, not here.

---

## Discovery and proof are different

The single most important distinction in this document.

**Discovery** — good for *"how does this work?"*, *"where might related code
live?"*, *"why was it built this way?"*. Served by semantic search, exploratory
reads, and history inspection. Fast, broad, and **never conclusive**.

**Proof / completeness** — required for any claim of the form *all callers*,
*every reference*, *no other consumers*, *every enum use*. Served only by LSP
references, `rg`, and direct file inspection.

**Semantic retrieval SHALL NOT be treated as proof of completeness.** A semantic
search that returns three consumers has found three consumers; it has not
established that a fourth does not exist. When a conclusion becomes a requirement,
an architectural decision, a code change, or a blocking review finding, it is
verified against the current source tree first.

The operating pattern:

```text
ORIENT      broad understanding
   ↓
PINPOINT    narrow to candidates
   ↓
COVER       LSP / rg, when completeness matters
   ↓
VERIFY      read the source
   ↓
ACT
```

---

## Operation contract

Five operations. Each names its inputs, its normalised return shape, and the
native implementation that backs it.

### `orient(question, depth)`

Build a broad understanding of how something works across files.

- **Inputs** — a natural-language question; a depth (see below)
- **Returns** — a prose summary plus `source locations` (path:line), and an
  `uncertainty` list naming what remains unknown
- **Native** — targeted `rg` for likely vocabulary, then Read on the files that
  match, following imports and references outward
- **Not proof.** Orientation output never settles a completeness claim

### `find(query, mode)`

Locate specific code.

- **Inputs** — a query; `mode` of `exact` or `concept`
- **Returns** — a list of `path:line` with one line of context each
- **Native** — `exact` is `rg` / Glob. `concept` has no native equivalent, so the
  native backend degrades it to a vocabulary-guess `rg` and **says so in the
  return** rather than implying semantic coverage it does not have

### `history(question, range)`

Understand why code is the way it is.

- **Inputs** — a question; a commit range or path
- **Returns** — relevant commits with subject, SHA and the reasoning found in the
  message body
- **Native** — `git log`, `git show`, `git blame` scoped to the range

### `coverage(symbol)`

Establish the complete set of references to something.

- **Inputs** — a symbol, export, route, or string
- **Returns** — an exhaustive list of `path:line`, and a statement of the method
  used to establish exhaustiveness
- **Native** — LSP references where available, `rg` otherwise
- **This is a proof operation.** It is the only one whose result may back a
  completeness claim

### `verify(claim)`

Confirm a specific claim against current source before acting on it.

- **Inputs** — a claim, with the `path:line` it rests on
- **Returns** — confirmed / refuted / moved, with the current source
- **Native** — direct Read at the cited location

---

## The native backend

```text
LSP        symbol references, definitions, implementations
rg         exact search, and the fallback for concept search
Read       direct file inspection — the authority for verify
git        log / show / blame for history
```

**Sufficient alone.** Every operation above has a native implementation, and the
proof operations (`coverage`, `verify`) are native-only by design. No other
provider is required for a fully correct result.

---

## Research depth

**Surface by default. Escalate per question. Record the escalation.**

| Depth | Scope |
|---|---|
| `surface` | The immediate question. A few targeted operations |
| `broad` | The question plus its neighbours — related modules, obvious consumers |
| `deep` | Cross-layer tracing, history, and completeness on the symbols that matter |

**Escalation is structural, not introspective.** A skill does not escalate because
it feels uncertain — models are unreliable at knowing what they do not know.
Escalation is triggered by an unresolved item on an explicit question map: a
question classified as answerable from the codebase that surface research did not
answer **is** the trigger.

Every escalation is recorded in the evidence research trace (see
[`evidence-schema.md`](evidence-schema.md)). That record is what makes depth
tunable later: if escalation never happens, the default is right and deeper modes
are not earning their place; if it happens constantly, the default is too shallow.

**Why not classify up front.** Pre-build there is no diff to measure, so
"substantial change" cannot be computed the way `simplify` computes triviality.
Over-research fails invisibly and accumulates as ceremony; under-research fails
visibly and announces itself as an unanswered question. Optimise against the
failure you can see.

---

## Configuration

`.spwf/research.yaml` is **optional and minimal**.

```yaml
# .spwf/research.yaml — all fields optional
provider: auto        # auto | native
depth: surface        # surface | broad | deep
fallback: native      # native | fail
```

**No configuration file** means exactly:

```yaml
provider: auto
depth: surface
fallback: native
```

A project that never creates this file gets working research and is never
interrupted to ask for configuration.

### Provider semantics

**`auto`** — detect whether an accelerating provider is usable; if it is, use it
for discovery operations; otherwise use native. Never interrupt the workflow
merely because an optional provider is absent.

**`native`** — never attempt any other provider. Use LSP, `rg`, Read and git only.

### `fallback`

`fallback: native` is the normal setting. `fallback: fail` is strict mode, for
teams who would rather halt than silently research with less capability than they
configured.

**No credentials live in this file.** A provider that needs authentication carries
that in its own configuration, and this repo holds no secrets.

---

## Adding a provider

A new provider supplies discovery operations — `orient`, `find`, `history` — and
inherits native for the proof operations. To add one:

1. Add a row to the dispatch table below.
2. Put its setup, installation and authentication in its own file under
   `plugins/spwf/references/`, loaded only by `config-check` or on explicit
   request. It must never enter normal workflow context.
3. Change no skill. If adding a provider requires editing a skill, the seam has
   failed.

| Provider | Serves | Proof operations | Setup reference |
|---|---|---|---|
| `native` | all five | `coverage`, `verify` | — (no setup) |

Providers other than native are added by later changes in the
`adaptive-research-lean-execution` initiative.
