---
source: scratch
created: 2026-05-17
status: split
---

# Beadsify — Beads + OpenSpec integration

## Context

Long-horizon agentic coding suffers from "context drift": agents lose their place in flat `tasks.md` files, overwrite plans, and miss dependencies between work items. SPWorkflow already pairs `/spwf:capture → challenge → spec → build → close` with OpenSpec as the spec layer, but the spec layer was designed around human-readable Markdown — not the dependency-aware graph that agents actually need to navigate without drift.

[Beads (`bd`)](https://github.com/gastownhall/beads) is an open-source, ultra-lightweight tracker built specifically for agentic coding. It stores issues in a relational, version-controlled graph (Dolt) that lives inside the repo, exposes a CLI (`bd next`, `bd done`, `bd remember`, `bd failure`), and has out-of-the-box setup integrations for Claude Code, Codex, Cursor, and Cline. The user's mental model: **Beads is the epic/story layer (initiator) and replaces external trackers (YouTrack/Jira) as SPWorkflow's default tracker; OpenSpec is the detailed specification layer; SPWorkflow is the orchestrator that hands work between them.**

## What we know

- **Hierarchy.** Beads = epics and stories (high-level, persistent, dependency-aware). OpenSpec = the specs, design decisions, and tasks for one change. One Beads node typically maps to one OpenSpec change.
- **Initiation flow.** A new objective starts in Beads (`bd write "..."` → returns `bd-NNN`). When the work is ready for technical specification, an OpenSpec change is scaffolded under that node and the `bd-NNN` id is recorded in the change's `proposal.md` frontmatter.
- **Execution flow.** During `/opsx:apply`, the agent does not edit `tasks.md` directly. It consults `bd next` for the next dependency-safe task, runs `bd remember "<insight>"` for architectural surprises, and `bd done <task-id>` on completion. A post-execution hook syncs status back into OpenSpec's `tasks.md` (the human-readable surface stays in sync).
- **Beads replaces external trackers** as SPWF's default tracker layer for this project. `_shared/tracker-dispatch.md` gains a `beads` backend alongside the existing YouTrack/Jira/none options. `.spwf/tracker.yaml` selects which is active.
- **Slash command surface (full vision).** Five proposed entry points: `/spwf:start` (creates Beads node + git branch + OpenSpec scaffold), `/spwf:propose` (agent fills specs.md, design.md), `/spwf:next` (loop through `bd next`), `/spwf:remember <insight>` (write to Beads memory), `/spwf:ship` (verify all Beads sub-tasks closed, archive OpenSpec change, close Beads story). **v1 ships only `/spwf-beadsify:remember`**; the rest are deferred.
- **Existing SPWF skills overlap.** `/spwf:capture`, `/spwf:close`, `/spwf:learn-from-mistakes` already cover parts of this surface. Beads adds the *dependency graph* and *persistent memory*, not just another tracking layer. Skills talk to tracker-dispatch.md, not directly to a tracker — so adding Beads as a dispatch backend lights up Beads in every existing skill without rewrites.

## Resolved questions

**Scope of first cut.** Pattern 1 (execution-time Beads during build) plus a single new `/spwf-beadsify:remember` skill — the smallest cut that validates the dependency-graph value. Full epic/story surface (`/spwf:start` and friends) is deferred to a later change once the model is felt out. Scope expanded during Challenge to also include tracker-dispatch integration (Beads as default tracker layer for this project).

**Coexistence with external trackers.** Beads *replaces* YouTrack/Jira as SPWF's default tracker for this project, rather than coexisting separately. Added as a new tracker-dispatch backend; YouTrack/Jira backends remain available for projects that need them (e.g. client work where Jira is mandated). `.spwf/tracker.yaml` selects the active backend.

**Where the Beads database lives.** Per-project, gitignored — `./.bd/` next to `./openspec/`. OpenSpec stays source-of-truth for the spec; Beads is the execution-time scratchpad. Insights captured via `bd remember` survive the gitignored DB by being exported to a committed file at `/spwf:close` (see next answer).

**`bd remember` vs `/spwf:learn-from-mistakes`.** Layered with explicit hand-off. `bd remember` is the build-time capture surface (fast, frictionless, gitignored). At `/spwf:close`, before archive, Beads insights for the current change are exported to `openspec/changes/{change-id}/insights.md` (committed, persistent). `/spwf:learn-from-mistakes` reads commits + `insights.md`, so durable insights bubble up from bd → openspec → project docs.

**`bd setup claude` interaction.** Skip entirely. SPWF talks to Beads via raw CLI (`bd write`, `bd next`, `bd done`, `bd remember`, `bd export`, `bd show`, `bd close`). The Beadsify spec includes a prerequisite note: "do not run `bd setup claude` — SPWF provides its own Claude Code integration." Avoids opinionated-default conflicts and keeps the integration contract stable as Beads evolves.

**Custom schema risk.** N/A. v1 uses a hook inside `/spwf:build` (per-change opt-in via `beads_story_id` in `proposal.md` frontmatter), not an OpenSpec custom schema. Lower blast radius, no dependency on OpenSpec's young custom-schema API. A formal `beads-driven` schema is a possible future change once the model is proven and the API stabilises.

**Sync semantics on failure.** Beads is source-of-truth during build. `tasks.md` is a best-effort human-readable mirror updated after each `bd done`. If sync fails, log a warning and continue — build is never halted by sync drift. Reconciliation runs at `/spwf:close` (mandatory, before archive) and `/spwf:pause` (when context-switching). Unresolvable conflicts surface to the user before archive.

**Effort to ship.** Split into two sequential changes (see "Split into" below). The full v1 scope is too broad for one coherent change (5/5 split signals fired at Challenge: independent deployability, natural system boundary, different risk profiles, >2 phases, different "done" definitions).

## Challenge decisions

- **New plugin `spwf-beadsify`** — third entry in the marketplace, opt-in install. Both child changes ship into this plugin. Users who don't want Beads integration don't install it; `spwf` core is unaffected.
- **Tracker-dispatch wiring.** `_shared/tracker-dispatch.md` in spwf core lists `beads` as a known backend pointing to a module inside `plugins/spwf-beadsify/`. If `tracker: beads` is set in `.spwf/tracker.yaml` but `spwf-beadsify` is not installed, dispatch errors with a clear message ("install spwf-beadsify or change tracker").
- **Plugin name `spwf-beadsify` confirmed** (matches existing `spwf-agents` naming). Slash commands under the namespace become `/spwf-beadsify:<name>`.
- **Per-change opt-in via frontmatter.** The build-loop hook only activates when both `.bd/` exists AND `proposal.md` frontmatter contains `beads_story_id: bd-NNN`. Changes without that frontmatter run the normal tasks.md-driven flow.
- **Insights file location.** `openspec/changes/{change-id}/insights.md` — travels with the OpenSpec change into the archive automatically.
- **Order of delivery.** `beadsify-tracker` first (lower risk, mechanical mapping, builds the bd habit at the tracker level), then `beadsify-build-loop` (higher risk, changes how every build runs).

## Split into

- [`todo/beadsify-tracker.md`](beadsify-tracker.md) — Beads as tracker-dispatch backend; new `spwf-beadsify` plugin scaffold; `.spwf/tracker.yaml` default. **Ships first.**
- [`todo/beadsify-build-loop.md`](beadsify-build-loop.md) — Build-loop hook driving `/spwf:build` off `bd next`/`bd done`; new `/spwf-beadsify:remember` skill; `/spwf:close` reconciliation + insights export; `/spwf:learn-from-mistakes` reads `insights.md`. **Ships second.**

## Rough scope (now superseded by children)

Reference only — the actionable scope lives in the child todos.

**In scope (working hypothesis):**
- A `beads-driven` OpenSpec custom schema that requires `beads_story_id` in proposal frontmatter and rewires `apply` to use `bd next` / `bd done`.
- New SPWF skills: `/spwf:start` (Beads node + branch + OpenSpec scaffold), `/spwf:next`, `/spwf:remember`, plus integration of Beads checks into `/spwf:close` (verify Beads sub-tasks closed before archive).
- A sync hook from Beads → OpenSpec `tasks.md` so the human-readable surface stays current.
- Documentation in `docs/` and `CLAUDE.md` describing the Beads + OpenSpec mental model.

**Out of scope (initial cut):**
- Replacing tracker-dispatch with Beads. YouTrack/Jira/Linear stay as external workflow trackers; Beads is the in-repo execution layer.
- Laminar / agent observability integration (the raw notes mention this as a separate tool, not an integrator).
- Multi-machine Beads sync (single-machine first; Dolt's distributed mode is a later phase).

## Raw research notes

Original research dump preserved at [`todo/_research/beadsify-raw.md`](_research/beadsify-raw.md).
