---
source: scratch
created: 2026-05-17
status: ideation
parent: beadsify.md
depends_on: beadsify-tracker.md
---

# Beadsify — Build-loop integration (Beads drives execution during /spwf:build)

## Context

Second of two changes splitting [`todo/beadsify.md`](beadsify.md). This change wires Beads into `/spwf:build` so the build loop drives off `bd next` / `bd done` instead of editing `tasks.md` directly. It also adds the `/spwf-beadsify:remember` skill, exports per-change insights at `/spwf:close`, and lets `/spwf:learn-from-mistakes` read those insights.

Depends on [`beadsify-tracker.md`](beadsify-tracker.md) having shipped — the `spwf-beadsify` plugin must exist and the user must already be using Beads as their tracker before the build-loop integration is meaningful. Build-loop integration is the higher-risk piece (it changes how every Beads-mode build runs); shipping the tracker layer first builds the bd habit on lower-risk ground.

## What we know

- **Per-change opt-in.** The build-loop hook only activates when **both** `.beads/` exists in the project **and** the current change's `proposal.md` frontmatter contains `beads_story_id: <prefix>-<hash>`. Changes without that frontmatter run the existing tasks.md-driven flow unchanged.
- **Mechanism: hook in `/spwf:build`, not a custom OpenSpec schema.** Lower blast radius, no dependency on OpenSpec's young custom-schema API. A formal `beads-driven` schema is a possible future change once the model is proven.
- **Source-of-truth during build.** Beads is canonical. `tasks.md` is a best-effort human-readable mirror updated after each `bd done`. Sync failures log a warning and continue — build is never halted by sync drift.
- **Reconciliation points.** `/spwf:close` and `/spwf:pause` both run a mandatory reconciliation pass comparing Beads sub-task state vs `tasks.md` and surface unresolvable conflicts to the user.
- **Insights export.** At `/spwf:close`, before archive, Beads insights for the current change are exported to `openspec/changes/{change-id}/insights.md` (committed, persistent). The file travels with the OpenSpec change into the archive.
- **Learn-from-mistakes hand-off.** `/spwf:learn-from-mistakes` reads commits as today, **plus** `insights.md` when present, when deciding what to promote to project docs. Beads being uninstalled simply means no `insights.md` — backward compatible.
- **New skill `/spwf-beadsify:remember`.** Thin wrapper over `bd remember`. Accepts an insight string; tags it with the current change (via `beads_story_id` from `proposal.md` frontmatter). Disable-model-invocation: true.

## Open questions

- **Build-loop hook implementation.** Where in `/spwf:build`'s skill body does the Beads-mode branch live? Top-level `if` block before the existing OpenSpec apply logic? Sub-skill dispatch (`/spwf-beadsify:build-step`) that `/spwf:build` calls? Settle in spec — both work, latter is cleaner if `/spwf:build` is small enough to refactor.
- **Sync algorithm for tasks.md.** `bd done bd-12` produces a state change. How does the hook map `bd-12` back to a line in `tasks.md` to mark `[x]`? Match by exact task description? Maintain a `bd_task_id` mapping in tasks.md frontmatter? Investigate Beads' ingest format — `bd ingest tasks.md` may already record the mapping.
- **Tasks.md ingest at change start.** When does `bd ingest openspec/changes/{id}/tasks.md` run? At `/spwf:spec` (when tasks.md is first written)? At first `/spwf:build` invocation in a Beads-mode change? Settle in spec.
- **Reconciliation conflict resolution UX.** When `/spwf:close` finds drift it can't auto-resolve, what does it ask the user? Show both states side-by-side and prompt for which is canonical? Hard-block until manually fixed?
- **What if `bd ingest` fails partway through?** If only some tasks make it into the Beads graph, the build loop sees an incomplete picture. Fail-fast behaviour vs partial-success behaviour needs deciding.
- **`/spwf:pause` reconciliation depth.** Full reconciliation, or quick-and-dirty (just mark current task as paused in bd, leave full sync for close)?

## Rough scope

**In scope:**
- Modify `plugins/spwf/skills/build/SKILL.md` to detect Beads mode and route through a new Beads-mode build step (likely a new sub-skill in `spwf-beadsify`).
- New `plugins/spwf-beadsify/skills/build-hook/` (or similar) implementing the Beads-mode build step (`bd next`, implement, `bd done`, sync tasks.md best-effort).
- New skill `plugins/spwf-beadsify/skills/remember/SKILL.md` — `/spwf-beadsify:remember <insight>`.
- Modify `plugins/spwf/skills/close/SKILL.md` to add a reconciliation pass + insights export (only when Beads mode active for the change).
- Modify `plugins/spwf/skills/pause/SKILL.md` to add a reconciliation pass.
- Modify `plugins/spwf/skills/learn-from-mistakes/SKILL.md` to additionally read `openspec/changes/{id}/insights.md` when present (and `openspec/changes/archive/.../insights.md` if surveying history).
- Document the Beads-mode build flow in `plugins/spwf-beadsify/README.md` and `docs/dogfooding.md` (or new `docs/beadsify.md`).
- Tests / acceptance: a change with `beads_story_id` in frontmatter runs `/spwf:build` and the loop consults `bd next` for each task; `/spwf-beadsify:remember "<insight>"` writes to Beads; `/spwf:close` exports insights.md and archives cleanly; `/spwf:learn-from-mistakes` includes captured insights in its analysis.

**Out of scope:**
- Replacing `/spwf:build` for non-Beads changes — the existing tasks.md-driven flow stays as the default path.
- `/spwf:start`, `/spwf:propose`, `/spwf:next`, `/spwf:ship` — the broader epic/story slash command surface from the parent's full vision.
- OpenSpec custom `beads-driven` schema — deferred until the hook-based approach is proven.
- Multi-machine Beads sync.

**Success definition:** for a change tagged with `beads_story_id`, `/spwf:build` consults Beads for the next task, completes it, marks `bd done`, mirrors to `tasks.md` best-effort, and loops. Insights captured via `/spwf-beadsify:remember` (or via internal `bd remember` calls during build) survive into `insights.md` at `/spwf:close`, get archived with the change, and inform `/spwf:learn-from-mistakes`. Non-Beads changes continue running unchanged.
