# Model policy — shared convention

Which class of model runs which kind of work, and why agent definitions name an
alias rather than a pinned generation.

---

## The policy

| Work | Model class | Why |
|---|---|---|
| Deterministic evidence gathering — searching, listing, collecting, checking | **haiku** | Mechanical. The hard part is coverage, not judgement |
| Synthesis, implementation, consequential review | **sonnet** | Someone has to decide what the evidence means |
| Genuinely difficult reasoning, where being wrong is expensive | **opus** | Reserved. Not a default |

The split is about **judgement density**, not importance. Collecting every caller
of a symbol is high-stakes and low-judgement; deciding whether a migration
preserves a contract is the reverse.

**Model selection is independent of research-provider selection.** They are
orthogonal axes and must not be coupled: a project on the native research backend
is not thereby a project that wants cheaper models, and configuring an accelerated
provider says nothing about how much judgement its results need.

---

## Aliases, not pinned generations

Agent definitions declare:

```yaml
model: haiku      # or sonnet, or opus
```

**Not** a pinned generation ID such as `claude-sonnet-4-6`.

### Why — with the evidence

A pin looks safer and is not. It is a bet that a specific generation stays
current, and it loses silently: nothing warns you that an agent is running a
superseded model, and the agent keeps working, slightly worse, indefinitely.

At the time this policy was written, the repository's 14 agents declared:

```text
8 × claude-sonnet-4-6            ← superseded generation, pinned
4 × claude-haiku-4-5-20251001    ← pinned to an exact build
2 × sonnet                       ← alias
```

Two thirds of the fleet had drifted onto an older generation, and nothing surfaced
it. The pins did not prevent drift; they **caused** it, by freezing a choice made
once and never revisited.

The counter-risk is real and smaller: an alias can later resolve to a model that
behaves differently, and a Haiku-class scout could degrade without a diff to show
for it. That is a live risk, recorded in this change's residual risks. The
difference is that alias drift moves the fleet forward and shows up in behaviour,
while pin drift moves it backward and shows up nowhere.

### When a pin is correct

Pin a generation when a change must be reproducible against a specific model —
an evaluation, a benchmark, or a bug being reproduced. Never as a default, and
always with a comment saying why and when to remove it.
