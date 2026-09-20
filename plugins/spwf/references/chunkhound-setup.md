# ChunkHound setup — reference

> **Reference only.** Loaded by `config-check` or on explicit request. This file
> must never be pulled into normal workflow context — no skill reads it as part of
> capture, challenge, spec, build, review or close.
>
> **The provider it describes is not yet shipped.** ChunkHound arrives as the first
> accelerating research provider in **change 5** of the
> `adaptive-research-lean-execution` initiative. Until then SPWF is native-only and
> this document is forward documentation, kept here so the setup story is written
> once rather than rediscovered.

## What it is, and what it is not

ChunkHound is a semantic code-search tool. Within SPWF it would serve the
**discovery** operations — `orient`, `find` with `mode: concept`, and `history` —
defined in [`../skills/_shared/research-dispatch.md`](../skills/_shared/research-dispatch.md).

**It never serves the proof operations.** `coverage` and `verify` remain native
(LSP, `rg`, direct Read) by design. Semantic retrieval is not evidence of
completeness, and a provider that appeared to offer it would be the most dangerous
thing this architecture could acquire.

## What it would improve

Not correctness — `rg` + LSP + Read + git already produce fully correct results.
What it changes is **the cost of reaching the right places** on a large or
unfamiliar codebase:

- concept search when you do not know the repository's vocabulary
- cross-layer orientation as one research problem rather than many greps
- finding behaviourally related code that shares no terminology
- semantic history research
- keeping exploratory reads out of the main session

## Installation

Deferred to change 5, which ships the provider. Writing installation steps for
software the workflow cannot yet dispatch to would be instructions with nothing to
instruct.

When that change lands, this section covers: installing the binary, indexing a
repository, choosing an embedding provider, wiring it as an MCP server, and the
`.spwf/research.yaml` settings that activate it.

## Secrets

Whatever provider profile is chosen, the rule is fixed: **no credential is stored
in the repository.** Keys live in the environment or in the provider's own
configuration outside the project. `config-check` reports whether a key is set and
never what it is.
