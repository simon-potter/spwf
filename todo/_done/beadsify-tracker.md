---
source: scratch
created: 2026-05-17
status: ideation
parent: beadsify.md
---

# Beadsify — Tracker layer (Beads as tracker-dispatch backend)

## Context

First of two changes splitting [`todo/beadsify.md`](beadsify.md). This change establishes Beads as the default tracker for this project by adding it as a backend to SPWF's existing `_shared/tracker-dispatch.md` abstraction — alongside the existing YouTrack/Jira/none options. Once installed, capture/tracker-comment/close skills automatically use Beads via the dispatch layer; no skill body rewrites needed.

This change ships **first** because it is lower-risk and builds the `bd` habit at the tracker level before the build-loop integration arrives (see [`beadsify-build-loop.md`](beadsify-build-loop.md)).

## What we know

- **New plugin `spwf-beadsify`.** Third entry in `.claude-plugin/marketplace.json`, opt-in install via `/plugin install spwf-beadsify@spwf`. Users who don't want Beads aren't affected.
- **Tracker-dispatch backend.** `plugins/spwf/skills/_shared/tracker-dispatch.md` (in spwf core) lists `beads` as a known backend pointing to a module inside `plugins/spwf-beadsify/`. Skills (`/spwf:capture`, `/spwf:tracker-comment`, `/spwf:close`) keep dispatching as today — they don't know whether it's Beads or YouTrack.
- **Dispatch fallback behaviour.** If `tracker: beads` is set in `.spwf/tracker.yaml` but `spwf-beadsify` is not installed, dispatch errors with: *"tracker: beads requested but spwf-beadsify plugin not installed. Install: `/plugin install spwf-beadsify@spwf`. Or change tracker in .spwf/tracker.yaml."*
- **Beads operations needed for v1 dispatch.** Roughly: create_issue (`bd write`), get_issue (`bd show`), add_comment (`bd remember bd-N "<text>"` — note: Beads has no native "comment" concept; insights serve as the analogue), transition (`bd close`, `bd reopen`). Full mapping is a spec-phase deliverable.
- **No `bd setup claude`.** SPWF talks to bd via raw CLI only. The plugin README explicitly warns against running `bd setup claude` to avoid opinionated-default conflicts.
- **Beads database location.** Per-project, gitignored `./.beads/`. Plugin's first-run check ensures `.beads/` exists or prompts the user to run `bd init`.

## Open questions

- **Beads "comment" mapping.** Beads has `bd remember` (insights tied to a story) but no first-class comment concept. Does `/spwf:tracker-comment` produce a `bd remember bd-N "<text>"` (treating the comment as an insight), or a distinct concept (e.g. `bd note`)? Investigate `bd` CLI for a closer match before settling.
- **Status vocabulary mapping.** YouTrack and Jira have rich status vocabularies (Open / In Progress / In Review / Done / etc.). Beads ships with a narrower vocab (open / in-progress / blocked / closed per the research notes). What does `/spwf:close` set as the final state? `bd close <id>` only? Or a richer "done with archive reference" state?
- **`bd init` bootstrap.** Should `spwf-beadsify` auto-run `bd init` on first use if `.beads/` is missing, or require the user to do it manually? Auto-init is friendlier; manual is more transparent about what's happening.
- **Dispatch contract for spwf-beadsify backend.** What's the exact file/skill layout in spwf-beadsify that tracker-dispatch.md points at? A single `tracker-backend/SKILL.md`? Multiple per-operation skills? Settle in spec.

## Rough scope

**In scope:**
- New `plugins/spwf-beadsify/` plugin scaffold (`.claude-plugin/plugin.json`, `README.md`, `skills/`).
- Add `spwf-beadsify` as third entry in `.claude-plugin/marketplace.json`.
- Beads backend module under `plugins/spwf-beadsify/skills/tracker-backend/` (or similar — name pinned in spec) implementing the dispatch operations needed by capture/tracker-comment/close.
- Extend `plugins/spwf/skills/_shared/tracker-dispatch.md` to know about the `beads` backend type and its plugin location.
- Document `.spwf/tracker.yaml` `tracker: beads` setting in spwf-beadsify README + project docs.
- Update root `README.md` and `CLAUDE.md` to describe Beadsify as an optional install.
- Add prerequisite note: "do not run `bd setup claude`".
- Tests / acceptance: with `tracker: beads` set and `spwf-beadsify` installed, `/spwf:capture` produces a `bd-N` story id; `/spwf:tracker-comment` posts via `bd remember`; `/spwf:close` transitions the story to closed.

**Out of scope (deferred to `beadsify-build-loop`):**
- `/spwf:build` Beads-mode hook.
- `/spwf-beadsify:remember` skill (as a user-invocable wrapper — though `bd remember` is used internally by tracker-comment).
- `/spwf:close` reconciliation of tasks.md against Beads sub-tasks.
- Insights export to `openspec/changes/{id}/insights.md`.
- `/spwf:learn-from-mistakes` reading insights.md.
- All deferred-from-parent items (`/spwf:start`, `/spwf:propose`, `/spwf:next`, `/spwf:ship`, custom OpenSpec schema).

**Success definition:** an SPWF user can install `spwf-beadsify`, set `tracker: beads` in `.spwf/tracker.yaml`, and run the existing capture → close flow with Beads as the tracker — zero changes to the skill bodies they invoke. YouTrack/Jira/none backends continue to work for projects using them.
