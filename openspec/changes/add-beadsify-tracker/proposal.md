# Proposal: Beadsify — tracker layer (Beads as tracker-dispatch backend)

**Change ID**: `add-beadsify-tracker`
**Status**: Draft
**Created**: 2026-05-17
**Source**: [todo/beadsify-tracker.md](../../../todo/beadsify-tracker.md)

---

## Why

SPWorkflow currently dispatches to external workflow trackers (YouTrack default, Jira supported) for ticket creation, comments, and status transitions. Solo and agentic workflows want a tracker that lives **in the repo** — agent-native, dependency-aware, low-overhead — without losing the existing tracker-dispatch abstraction that keeps skills tracker-agnostic.

[Beads (`bd`)](https://github.com/gastownhall/beads) provides exactly this: an in-repo graph tracker with a stable CLI surface (`bd write`, `bd show`, `bd remember`, `bd close`). Adding Beads as a tracker-dispatch backend lets every existing skill (capture, tracker-comment, close) use it automatically via `.spwf/tracker.yaml`, with zero skill body rewrites.

## What Changes

- **NEW plugin** `plugins/spwf-beadsify/` — third entry in `.claude-plugin/marketplace.json`, opt-in install (`/plugin install spwf-beadsify@spwf`). Holds the Beads tracker backend and is the future home of the Beads build-loop integration (a separate change).
- **NEW dispatch backend** in `plugins/spwf-beadsify/skills/tracker-backend/` (final name pinned in design) implementing the operations the existing dispatch abstraction needs: create_issue, get_issue, add_comment, transition.
- **MODIFIED** `plugins/spwf/skills/_shared/tracker-dispatch.md` — gains a `beads` branch alongside the existing `youtrack`/`jira`/`none` options; routes to the spwf-beadsify backend module when configured.
- **NEW** `.spwf/tracker.yaml` `tracker: beads` setting documented in the spwf-beadsify README and the root project docs.
- **MODIFIED** root `README.md` and `CLAUDE.md` — describe Beadsify as an optional install and the dogfooding configuration for this project.
- **DOCUMENTED** prerequisite: do not run `bd setup claude` — SPWF provides its own Claude Code integration; running Beads' setup would inject conflicting opinionated defaults.
- **VERSION BUMP** `plugins/spwf/.claude-plugin/plugin.json` (because tracker-dispatch.md changes), and `plugins/spwf-beadsify/.claude-plugin/plugin.json` introduced at `0.1.0`.

## Impact

- **Affected areas**: marketplace catalog (`.claude-plugin/marketplace.json`), spwf core's `_shared/tracker-dispatch.md`, new `plugins/spwf-beadsify/` plugin, project docs.
- **No breaking changes** — Beads is opt-in. Projects with `tracker: youtrack` / `jira` / `none` are unaffected. spwf core continues to work without spwf-beadsify installed.
- **Dependencies on consumers** — projects that want to use Beads must (a) install Beads (`bd` CLI), (b) install the spwf-beadsify plugin, (c) set `tracker: beads` in `.spwf/tracker.yaml`. All three are documented in the new plugin's README.

---

## Decisions

Settled during Challenge:

- **New plugin** `spwf-beadsify` (third in marketplace), not bundled into spwf core. Users who don't want Beads aren't affected.
- **Tracker layer replacement**, not coexistence. With `tracker: beads`, Beads is the canonical tracker for the project. YouTrack/Jira backends remain selectable for projects with external requirements (e.g. client work where Jira is mandated).
- **Raw CLI only.** SPWF calls `bd q`, `bd show`, `bd comment`, `bd close` directly (mapping verified against bd 1.0.4 — see `design.md` § "bd CLI mapping"). `bd setup claude` is explicitly disallowed in the prerequisite docs.
- **Per-project gitignored `.bd/`.** Beads database lives at `./.bd/` and is in `.gitignore`. OpenSpec remains source-of-truth; Beads is the execution-time scratchpad.
- **Tracker layer ships first** (this change), build-loop integration ships next (`add-beadsify-build-loop`, separate change, depends on this one).

Open (TBD — settle during design.md / build):

- **Beads "comment" mapping.** Beads has no first-class `comment` concept. Options: (a) use `bd remember bd-N "<text>"` (treats comment as an insight); (b) check `bd` CLI for a closer match like `bd note` or `bd attach`. Resolve by reading `bd --help` during design.
- **Status vocabulary mapping.** Beads' status vocab (open / in-progress / blocked / closed per the research notes) is narrower than YouTrack's. Pin the exact mapping table during design — particularly what `/spwf:close` sets as the final state.
- **`bd init` bootstrap UX.** Should the plugin auto-run `bd init` when `.bd/` is missing, or require manual setup? Auto is friendlier; manual is more transparent. Decide during design — defer if not blocking the first acceptance test.
- **Dispatch backend file layout.** Exact files inside `plugins/spwf-beadsify/skills/tracker-backend/`: single SKILL.md with branching logic, or one skill per operation? Pin during design once we know the operation surface.

## Success Criteria

With this change shipped:

1. `/plugin install spwf-beadsify@spwf` succeeds against the local marketplace.
2. With `.spwf/tracker.yaml` containing `tracker: beads` and `bd init` already run:
   - `/spwf:capture` (source: scratch) produces a `bd-NNN` story id and records it in the ideation file frontmatter.
   - `/spwf:tracker-comment` lands the comment in Beads (via the resolved mapping).
   - `/spwf:close` transitions the Beads story to closed before archive.
3. With `.spwf/tracker.yaml` containing `tracker: beads` but `spwf-beadsify` not installed, dispatch errors with: *"tracker: beads requested but spwf-beadsify plugin not installed. Install: `/plugin install spwf-beadsify@spwf`. Or change tracker in .spwf/tracker.yaml."*
4. Existing `tracker: youtrack`, `tracker: jira`, and `tracker: none` configurations continue to work unchanged (regression check).
5. The root README and CLAUDE.md describe Beadsify install as opt-in and warn against `bd setup claude`.
6. **Multi-session braindump works.** A second Claude Code session in the same project can run `bd q "<title>"` (or any other tracker-touching `/spwf:*` skill) to land new stories into the graph while a first session is actively running `/spwf:build` against an unrelated change. The build session's `bd next` remains scoped to its `beads_story_id` subtree; the braindump session's writes land at the top level (or under their own parent) and don't perturb the build. The concurrency smoke test in Phase 5.6 validates this against the installed bd version.
