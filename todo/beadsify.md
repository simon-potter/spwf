---
source: scratch
created: 2026-05-17
status: ideation
---

# Beadsify — Beads + OpenSpec integration

## Context

Long-horizon agentic coding suffers from "context drift": agents lose their place in flat `tasks.md` files, overwrite plans, and miss dependencies between work items. SPWorkflow already pairs `/spwf:capture → challenge → spec → build → close` with OpenSpec as the spec layer, but the spec layer was designed around human-readable Markdown — not the dependency-aware graph that agents actually need to navigate without drift.

[Beads (`bd`)](https://github.com/gastownhall/beads) is an open-source, ultra-lightweight tracker built specifically for agentic coding. It stores issues in a relational, version-controlled graph (Dolt) that lives inside the repo, exposes a CLI (`bd next`, `bd done`, `bd remember`, `bd failure`), and has out-of-the-box setup integrations for Claude Code, Codex, Cursor, and Cline. The user's mental model: **Beads is the epic/story layer (initiator); OpenSpec is the detailed specification layer; SPWorkflow is the orchestrator that hands work between them.**

## What we know

- **Hierarchy.** Beads = epics and stories (high-level, persistent, dependency-aware). OpenSpec = the specs, design decisions, and tasks for one change. One Beads node typically maps to one OpenSpec change.
- **Initiation flow.** A new objective starts in Beads (`bd write "..."` → returns `bd-NNN`). When the work is ready for technical specification, an OpenSpec change is scaffolded under that node and the `bd-NNN` id is recorded in the change's `proposal.md` frontmatter.
- **Execution flow.** During `/opsx:apply`, the agent does not edit `tasks.md` directly. It consults `bd next` for the next dependency-safe task, runs `bd remember "<insight>"` for architectural surprises, and `bd done <task-id>` on completion. A post-execution hook syncs status back into OpenSpec's `tasks.md` (the human-readable surface stays in sync).
- **Custom OpenSpec schema is the integration point.** OpenSpec supports custom schemas via `openspec schema init <name>`. A `beads-driven` schema can require a `beads_story_id` in `proposal.md` frontmatter and rewrite the `apply` instruction so the agent uses `bd next` / `bd done` instead of editing `tasks.md`.
- **Slash command surface.** Five proposed entry points: `/spwf:start` (creates Beads node + git branch + OpenSpec scaffold), `/spwf:propose` (agent fills specs.md, design.md), `/spwf:next` (loop through `bd next`), `/spwf:remember <insight>` (write to Beads memory), `/spwf:ship` (verify all Beads sub-tasks closed, archive OpenSpec change, close Beads story).
- **Two architectural patterns** described in the raw notes: (1) Beads as ephemeral execution engine during `/opsx:apply` only; (2) Beads memory feeding back into OpenSpec design context. They are compatible — Pattern 2 reads from the same store Pattern 1 writes to.
- **Existing SPWF skills overlap.** `/spwf:capture`, `/spwf:close`, `/spwf:learn-from-mistakes` already cover parts of this surface. Beads adds the *dependency graph* and *persistent memory*, not just another tracking layer.

## Open questions

- **Scope of first cut.** Pattern 1 (execution-time Beads) is the smaller commitment and the higher-value win — does it ship first, or do we go for the full schema + slash command surface in one change?
- **Coexistence with existing tracker MCPs.** SPWorkflow already supports YouTrack and Jira via tracker dispatch (`_shared/tracker-dispatch.md`). Beads sits at a different layer (in-repo graph for execution, not external workflow tracker). Is Beads a third dispatch target, or a separate concern entirely?
- **Where does the Beads database live?** Per-project (`./bd/`) committed alongside `openspec/`, or per-machine (`~/.bd/`)? Affects multi-machine workflows and CI.
- **`bd remember` vs `learn-from-mistakes`.** Both capture insights. Beads stores them in a queryable graph; `learn-from-mistakes` writes to project docs. Are they redundant, complementary, or layered (Beads short-term during execution → docs long-term at close)?
- **`bd setup claude` interaction.** Beads ships with a Claude Code setup protocol. Does it install hooks/skills that conflict with SPWorkflow's own hooks?
- **Custom schema risk.** OpenSpec's custom-schema API is still in flux. How stable is `openspec schema init` and the `apply.instruction` field?
- **Sync semantics on failure.** If `bd done` succeeds but the post-execution hook fails to update `tasks.md`, the two systems disagree. Source-of-truth rules need to be explicit.
- **Effort to ship.** Custom schema + 5 new slash commands + sync hooks is non-trivial. Is there a smaller "minimum viable Beads" — e.g. just `/spwf:remember <insight>` wrapping `bd remember`, deferring schema work?

## Rough scope

**In scope (working hypothesis):**
- A `beads-driven` OpenSpec custom schema that requires `beads_story_id` in proposal frontmatter and rewires `apply` to use `bd next` / `bd done`.
- New SPWF skills: `/spwf:start` (Beads node + branch + OpenSpec scaffold), `/spwf:next`, `/spwf:remember`, plus integration of Beads checks into `/spwf:close` (verify Beads sub-tasks closed before archive).
- A sync hook from Beads → OpenSpec `tasks.md` so the human-readable surface stays current.
- Documentation in `docs/` and `CLAUDE.md` describing the Beads + OpenSpec mental model.

**Out of scope (initial cut):**
- Replacing tracker-dispatch with Beads. YouTrack/Jira/Linear stay as external workflow trackers; Beads is the in-repo execution layer.
- Laminar / agent observability integration (the raw notes mention this as a separate tool, not an integrator).
- Multi-machine Beads sync (single-machine first; Dolt's distributed mode is a later phase).

**Decision points to settle in Challenge:**
- Scope of first cut: Pattern 1 only, full slash command surface, or the schema first?
- Beads DB location: per-project or per-machine?
- Relationship to `learn-from-mistakes`.

## Raw research notes

Original research dump preserved at [`todo/_research/beadsify-raw.md`](_research/beadsify-raw.md).
