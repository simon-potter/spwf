# Proposal: add-plugin-marketplace

> **Authoritative Reference:** [`todo/Marketplace_setup.md`](../../../todo/Marketplace_setup.md) holds the original setup decisions and acceptance criteria. The architecture pivoted during implementation — see the Reconciliation Note at the bottom.

## Why

Simon's workflow skills and agents were scattered across personal `~/.claude` files with no distribution mechanism. A new machine required manual copying; there was no update path; and team members could not access these conventions at all.

## What Changes

- **NEW** `.claude-plugin/marketplace.json` — marketplace catalog under the name `spwf`
- **NEW** `plugins/spwf/` — the unified skills plugin: every workflow phase plus extended phases and quality tools, all invocable as `/spwf:<name>`
- **NEW** `plugins/spwf-agents/` — the specialist subagents plugin, paired to the workflow phases
- **NEW** `README.md` — installation guide
- **NEW** `docs/dogfooding.md` and a `CLAUDE.md` section — explains how this repo runs SPWF on itself via local marketplace install
- **MIGRATION** Personal `~/.claude/skills/` originals were superseded; archive of those originals is tracked separately as a cross-cutting hygiene task (out of scope for this change)

## Impact

- **Repo:** Public repo `simon-potter/spwf`; users install via `/plugin marketplace add simon-potter/spwf` then install `spwf` and `spwf-agents`
- **Prerequisites:** Claude Code, OpenSpec CLI (`npm install -g openspec`), forge CLI (`glab` default, `gh` supported), plus issue-tracker MCP (YouTrack default, Atlassian Jira supported) for ticket-driven capture
- **No breaking changes** to consuming projects — this repo is additive
- **Dogfooding:** the marketplace is loaded locally from this repo as the canonical way to develop SPWF (`docs/dogfooding.md`)

---

## Reconciliation Note (post-hoc)

The original design (see `design.md` Decision 1, and the early `tasks.md` phase headings) split the work across three plugins — `workflow-core`, `workflow-tools`, `workflow-agents` — under a marketplace named `simon-marketplace`. During implementation the three skill plugins were collapsed into a single `spwf` plugin and the marketplace was renamed to `spwf`. The agents stayed in their own plugin and were renamed `spwf-agents`. The pivot is recorded in [`todo/renamespace.md`](../../../todo/renamespace.md) (status: complete).

Reasons captured at the time:
- Cross-namespace references were the largest source of friction (99 occurrences across 32 files). One unified namespace eliminates that entirely.
- The `core` vs `tools` split was an *implementation* boundary (needs OpenSpec vs doesn't), not a *user* boundary. Users should not need to know which plugin a skill lives in to invoke it.
- Agents stayed separate because some downstream projects may want skills without agents.

Specs in this change (`specs/marketplace/spec.md`) describe the **shipped** state, not the original design. The Phase 0–4 tasks in `tasks.md` reflect the original execution and are left ticked as historical record; Phase 5–7 tasks describe the validation that was actually run.
