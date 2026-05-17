# Tasks: add-beadsify-tracker

> **Authoritative Reference:** [`todo/beadsify-tracker.md`](../../../todo/beadsify-tracker.md)
> **Architecture Reference:** [`design.md`](./design.md) — particularly Decision 4 (dispatch wiring) and Decision 2 (replace-not-coexist).

## Phase 1 — Plugin scaffold

- [ ] 1.1 `plugins/spwf-beadsify/.claude-plugin/plugin.json` exists with valid JSON containing `name: spwf-beadsify`, `version: 0.1.0`, `description`, and `author`
- [ ] 1.2 `plugins/spwf-beadsify/README.md` describes the plugin's purpose, install command, prerequisite list (Beads CLI, `bd init`), and the explicit warning against `bd setup claude`
- [ ] 1.3 `plugins/spwf-beadsify/skills/` directory exists (initially empty apart from the backend skill scaffold added in Phase 2)
- [ ] 1.4 `.claude-plugin/marketplace.json` registers `spwf-beadsify` as a third entry with `source: ./plugins/spwf-beadsify`, `version: 0.1.0`, and an accurate description
- [ ] 1.5 `/plugin marketplace add ./` followed by `/plugin install spwf-beadsify@spwf` succeeds against the local marketplace and the plugin appears in `/plugin list`

## Phase 2 — Dispatch backend module

- [ ] 2.1 `plugins/spwf-beadsify/skills/tracker-backend/SKILL.md` exists with valid frontmatter (name, description, `disable-model-invocation: true`, `allowed-tools` covering Read/Bash)
- [ ] 2.2 The backend module declares the dispatch operations it implements: `create_issue`, `get_issue`, `add_comment`, `transition`
- [ ] 2.3 Backend's first operation invocation checks `.bd/` exists; if missing, emits `.bd/ not initialised. Run: bd init (in the project root) then retry.` and halts cleanly
- [ ] 2.4 Backend's `create_issue` operation invokes `bd write "<title>"` and returns the resulting `bd-NNN` id parsed from stdout
- [ ] 2.5 Backend's `get_issue` operation invokes `bd show bd-NNN` and returns the structured result (title, status, dependencies, recent insights)
- [ ] 2.6 Backend's `add_comment` operation invokes `bd remember bd-NNN "<text>"` (default mapping per design.md open question 1; revise if build-phase investigation finds a closer match)
- [ ] 2.7 Backend's `transition` operation supports close and reopen via `bd close bd-NNN` / `bd reopen bd-NNN`; rejects unknown transition names with a clear error

## Phase 3 — Extend tracker-dispatch.md

- [ ] 3.1 `plugins/spwf/skills/_shared/tracker-dispatch.md` recognises `tracker: beads` as a valid setting alongside `youtrack` / `jira` / `none`
- [ ] 3.2 When `tracker: beads` is set, dispatch resolves the backend at `plugins/spwf-beadsify/skills/tracker-backend/SKILL.md`
- [ ] 3.3 If the backend file is not present (spwf-beadsify not installed), dispatch errors verbatim: `tracker: beads requested but spwf-beadsify plugin not installed. Install: /plugin install spwf-beadsify@spwf. Or change tracker in .spwf/tracker.yaml.`
- [ ] 3.4 Existing `tracker: youtrack`, `tracker: jira`, and `tracker: none` paths through dispatch remain byte-identical (regression check)

## Phase 4 — End-to-end skill integration (no skill body changes)

- [ ] 4.1 With `tracker: beads` set and `spwf-beadsify` installed, running `/spwf:capture` with `source: scratch` produces a story via `bd write` and records `ticket: bd-NNN` in the ideation file frontmatter
- [ ] 4.2 With the same setup, `/spwf:tracker-comment` invocations land in Beads (via the Phase 2.6 mapping) and the audit trail is visible in `bd show bd-NNN`
- [ ] 4.3 With the same setup, `/spwf:close` transitions the Beads story to closed (`bd close bd-NNN`) before the OpenSpec archive step runs
- [ ] 4.4 With `tracker: youtrack` set (existing default), the same skills continue to dispatch to YouTrack with no behavioural change

## Phase 5 — Documentation

- [ ] 5.1 `plugins/spwf-beadsify/README.md` documents: install command, prerequisites (`bd` CLI installed, `bd init` run in the project), `.spwf/tracker.yaml` setting, `.gitignore` entry for `.bd/`
- [ ] 5.2 `plugins/spwf-beadsify/README.md` includes an explicit "Do NOT run `bd setup claude`" section with the reasoning (SPWF provides its own Claude Code integration)
- [ ] 5.3 Root `README.md` lists `spwf-beadsify` in the marketplace contents as an optional plugin
- [ ] 5.4 `CLAUDE.md` mentions Beadsify under the dogfooding section (or links to a new `docs/beadsify.md`) noting the install path and the prerequisite warnings
- [ ] 5.5 `plugins/spwf/.claude-plugin/plugin.json` version bumped (tracker-dispatch.md changed); changelog-style entry recorded in commit message

## Phase 6 — Acceptance

- [ ] 6.1 Full lifecycle on a toy task with `tracker: beads`: capture → challenge → spec → build → close. Beads story created at capture, comments landed during the cycle, story closed at close.
- [ ] 6.2 Regression: same lifecycle with `tracker: youtrack` (or `none`) produces the original behaviour with no Beads activity.
- [ ] 6.3 Missing-plugin error path: with `tracker: beads` set but `spwf-beadsify` uninstalled, `/spwf:capture` errors with the verbatim message from Phase 3.3 and writes no files.
- [ ] 6.4 `.gitignore` includes `.bd/`; `git status` is clean after a Beads-mode lifecycle run (no Beads DB churn tracked).
