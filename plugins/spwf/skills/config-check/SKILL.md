---
name: config-check
description: Cross-cutting — report the health of this project's SPWF capabilities. Detects and reports on tracker, research backend, code intelligence, model assignments and forge; distinguishes what is absent from what is misconfigured, and gives an actionable next step for each. Reports presence, never configuration values. Advisory only — never halts, never edits, never installs. Run when onboarding a project to SPWF, when a capability behaves unexpectedly, or periodically alongside workspace-health.
disable-model-invocation: true
allowed-tools: [Read, Glob, Grep, Bash]
---

# config-check

**Report what this project's SPWF capabilities actually are, not what they were
meant to be.**

SPWF degrades gracefully by design — an absent tracker, forge or research backend
is a supported state, not an error. The cost of that is silence: a capability can
be misconfigured for months and the only symptom is work quietly not happening.
This skill breaks the silence.

> **Advisory only.** It reports. It does not edit configuration, install anything,
> create credentials, or halt a workflow. Every finding ends in something the
> developer can choose to do.

## Step 1 — Detect, don't assume

Resolve what this project actually is before checking anything. Do not assume a
fixed layout.

```bash
ls .spwf/ 2>/dev/null                    # which config files exist at all
git remote get-url origin 2>/dev/null    # forge, if any
ls openspec/ 2>/dev/null                 # is the workflow even initialised
```

A project with no `.spwf/` directory is a valid project. Report it as
unconfigured, not broken.

## Step 2 — Check each domain independently

**Each domain reports its own state. One unconfigured domain never suppresses the
others** — a project with no tracker still deserves to know its forge is
misconfigured. Run all five, always.

### Tracker

Read `.spwf/tracker.yaml` per
[`_shared/tracker-dispatch.md`](../_shared/tracker-dispatch.md). Report the
configured backend, whether it is reachable, and whether `tracker: none` is a
deliberate opt-out.

### Research backend

Read `.spwf/research.yaml` per
[`_shared/research-dispatch.md`](../_shared/research-dispatch.md). Report the
provider, the depth default, and the fallback. **An absent file is the normal
case** — report it as native-by-default, not as a gap.

### Code intelligence

Is an LSP available for this project's languages? This underpins the `coverage`
and `verify` operations, which are the only ones permitted to back a completeness
claim. Without it, `coverage` falls back to `rg` — still valid, less precise.

### Model assignments

Read `plugins/spwf-agents/agents/*.md` (or the installed equivalent) and report
which declare a **pinned generation** rather than an alias, per
[`_shared/model-policy.md`](../_shared/model-policy.md). A pin is not an error; an
unnoticed pin is how a fleet drifts onto a superseded model.

### Forge

Detect from `git remote` per
[`_shared/forge-dispatch.md`](../_shared/forge-dispatch.md). Report the forge, the
CLI it needs, and whether that CLI is installed and authenticated.

## Step 3 — Report presence, never values

**Configuration inspection touches the places credentials live** — `.spwf/*.yaml`,
MCP server configuration, environment variables, CLI auth state.

> **Assert that a key is set. Never print it.**
>
> ✓ `CONTEXT7_API_KEY` is set
> ✗ `CONTEXT7_API_KEY=sk-...`
>
> This holds for partial values too. A masked prefix is still a disclosure, and a
> report is a thing people paste into issues.

If a credential appears to be committed to the repository, report **the file and
why it matters — never the value**, exactly as
[`_shared/evidence-schema.md`](../_shared/evidence-schema.md) requires of research
output. Same risk, same rule.

## Step 4 — Distinguish absent from misconfigured

The two need different responses, and conflating them is how a report becomes
noise.

| State | Meaning | Response |
|---|---|---|
| **Absent** | Never configured. Often correct | State the capability is unused and what configuring it would buy |
| **Misconfigured** | Configured, but wrong — unreachable backend, missing CLI, unauthenticated | State what is wrong and the one command that would fix it |
| **Healthy** | Working | One line. Do not elaborate |

Report format:

```
## Capability health: {project}

  tracker             ✓ beads — reachable
  research backend    — absent (native by default)
  code intelligence   ⚠ no LSP detected for Python — coverage falls back to rg
  model assignments   ⚠ 12 of 15 agents pin a generation
  forge               ✓ github — gh installed, authenticated

Next steps:
  • {one actionable line per ⚠, nothing for ✓ or —}
```

**Never halt.** This skill has no failure state. A project where every capability
is absent gets a clean report saying so.

## Deferred: research provider recommendations

This skill does **not** recommend a research provider. The heuristic for
suggesting one — repository size, language mix, whether semantic search would pay
for itself — ships with **change 5** of the `adaptive-research-lean-execution`
initiative, alongside the provider it would recommend.

Recommending something the workflow cannot yet install is how a health report
becomes a nag.

If a developer asks how a provider *would* be configured, the setup story lives in
[`references/chunkhound-setup.md`](references/chunkhound-setup.md) — load it on
request only. Naming where documentation lives is not recommending the thing it
documents.

## Tone

A status report, not a sales pitch. Every ⚠ earns its place by naming something
the developer can act on. If everything is healthy, say so in five lines and stop.
