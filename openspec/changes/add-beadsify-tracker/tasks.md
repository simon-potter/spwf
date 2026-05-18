# Tasks: add-beadsify-tracker

> **Authoritative Reference:** [`todo/beadsify-tracker.md`](../../../todo/beadsify-tracker.md)
> **Architecture Reference:** [`design.md`](./design.md) — particularly Decision 4 (dispatch wiring) and Decision 2 (replace-not-coexist).
>
> **Revisions from approve-plan:** Phase 2 / Phase 3 each gained a preflight investigation step; `reopen` dropped from 2.9 (out of v1 scope); old Phase 4 (per-skill verification) merged into Phase 5 acceptance to remove overlap with the full-lifecycle test.

## Phase 1 — Plugin scaffold

- [x] 1.1 `plugins/spwf-beadsify/.claude-plugin/plugin.json` exists with valid JSON containing `name: spwf-beadsify`, `version: 0.1.0`, `description`, and `author`
- [x] 1.2 `plugins/spwf-beadsify/README.md` describes the plugin's purpose, install command, prerequisite list (Beads CLI, `bd init`), and the explicit warning against `bd setup claude`
- [x] 1.3 `plugins/spwf-beadsify/skills/` directory exists (initially empty apart from the backend skill scaffold added in Phase 2)
- [x] 1.4 `.claude-plugin/marketplace.json` registers `spwf-beadsify` as a third entry with `source: ./plugins/spwf-beadsify`, `version: 0.1.0`, and an accurate description
- [x] 1.5 `/plugin marketplace add ./` followed by `/plugin install spwf-beadsify@spwf` succeeds against the local marketplace and the plugin appears in `/plugin list` (verified 2026-05-18: `/reload-plugins` reports `4 plugins · 7 skills · 45 agents · 11 hooks` — count rose from 3 to 4; skills stays at 7 because spwf-beadsify skills/ is still empty, Phase 2.3 adds the first one)

## Phase 2 — Dispatch backend module

**Preflight investigation (resolves design.md open questions before any operation is implemented):**

- [x] 2.1 Confirm the dispatch mapping in `design.md` § "bd CLI mapping" still holds against the installed bd version (resolved against bd 1.0.4 on 2026-05-17 — see design.md). Specifically: run `bd q --help`, `bd show --help`, `bd comment --help`, `bd close --help`; if any subcommand has moved, gained required flags, or changed output format, update the mapping table and the corresponding Phase 2.6–2.9 tasks before implementing them. Also resolve the remaining open question on `bd init` bootstrap UX (auto-init vs manual prerequisite). (Done 2026-05-18: all four subcommands verified; mapping confirmed. `bd init` UX resolved → manual init mandatory, with safe flags `--skip-agents --skip-hooks --non-interactive` to prevent the opinionated Claude Code integration that bd installs by default. Database directory is `.beads/` not `.bd/` as originally specced — corrected across all artefacts. See design.md § "`bd init` safety".)
- [x] 2.2 Pin the safe subprocess-invocation pattern and document it in `design.md` Decision 7. Pattern: always quote substituted variables (`"$var"`); never `eval` / `bash -c` with substituted content; validate ids against `^bd-[a-z0-9]+$` before invocation; prefer stdin for multi-line/special content; capture exit codes and fail loudly. All Phase 2 operations below use this pattern verbatim — the backend skill body reproduces the rules so Claude applies them mechanically.

**Backend skill scaffold:**

- [x] 2.3 `plugins/spwf-beadsify/skills/tracker-backend/SKILL.md` exists with valid frontmatter (name, description, `disable-model-invocation: true`, `allowed-tools` covering Read/Bash)
- [x] 2.4 The backend module declares the dispatch operations it implements: `create_issue`, `get_issue`, `add_comment`, `transition` (close only in v1)

**Per-operation implementation (each uses the Phase 2.2 invocation pattern):**

- [x] 2.5 Backend's first operation invocation checks `.beads/` exists; if missing, emits a clear error pointing the user at the **safe** init command — NOT plain `bd init`. Required message form: `Beads not initialised in this project. Run in the project root: bd init --skip-agents --skip-hooks --non-interactive   (Plain 'bd init' would create CLAUDE.md, AGENTS.md, and register Claude Code hooks that conflict with SPWorkflow — the skip flags prevent this.)` Halts cleanly without writing any files. (Auto-init was rejected at Phase 2.1 — see design.md § "`bd init` safety".)
- [x] 2.6 Backend's `create_issue` operation invokes `bd q "<title>"` and returns the resulting `bd-<hash>` id parsed from stdout (per design.md § "bd CLI mapping"). Title passes through input validation before subprocess invocation.
- [x] 2.7 Backend's `get_issue` operation invokes `bd show <id>` and returns the structured result (title, status, dependencies, comments). The id is format-validated (`^bd-[a-z0-9]+$`) before subprocess invocation.
- [x] 2.8 Backend's `add_comment` operation invokes `bd comment <id> --stdin` with body piped in via `printf '%s' "$body" | …` (per Decision 7 rule 4: stdin avoids shell-injection surface for special characters in `$body`). NOT `bd remember`, which is project-level persistent memory used elsewhere. Both the id and the comment body pass through input validation.
- [x] 2.9 Backend's `transition` operation supports `close` only (`bd close <id>`). Unknown transition names are rejected with a clear error. The id is format-validated (`^bd-[a-z0-9]+$`) before subprocess invocation. (`reopen` and richer transitions are deliberately deferred — no v1 success criterion requires them.)

## Phase 3 — Extend tracker-dispatch.md

**Preflight refactor:**

- [x] 3.1 Refactored `plugins/spwf/skills/_shared/tracker-dispatch.md` to support both MCP-based and skill-based backends. Added "Backend types" classification section (MCP backends speak via `mcp__X__*` tool names; skill backends delegate to a SKILL.md in another plugin). Renamed "Dispatch table" to "MCP dispatch table" — actual rows unchanged. Split "Adding a new tracker" into MCP-based and skill-based subsections. Mental regression check: existing youtrack / jira / none paths through dispatch find the same MCP rows / same probe order / same fail-fast behaviour. Byte-identical for the three existing backends; verified at integration level in Phase 5.3.

**Extension:**

- [ ] 3.2 `plugins/spwf/skills/_shared/tracker-dispatch.md` recognises `tracker: beads` as a valid setting alongside `youtrack` / `jira` / `none`
- [ ] 3.3 When `tracker: beads` is set, dispatch resolves the backend at `plugins/spwf-beadsify/skills/tracker-backend/SKILL.md` and invokes the operation defined there
- [ ] 3.4 If the backend file is not present (spwf-beadsify not installed), dispatch errors verbatim: `tracker: beads requested but spwf-beadsify plugin not installed. Install: /plugin install spwf-beadsify@spwf. Or change tracker in .spwf/tracker.yaml.`
- [ ] 3.5 Existing `tracker: youtrack`, `tracker: jira`, and `tracker: none` paths through dispatch remain byte-identical (regression check — see Phase 5.3 for the integration-level verification)

## Phase 4 — Documentation

- [ ] 4.1 `plugins/spwf-beadsify/README.md` documents: install command; prerequisites — `bd` CLI installed (point at `scripts/install-beads.sh`), the SAFE init command `bd init --skip-agents --skip-hooks --non-interactive` (not plain `bd init` — see 4.2), `.spwf/tracker.yaml` setting, `.gitignore` entry for `.beads/`
- [ ] 4.2 `plugins/spwf-beadsify/README.md` includes a "Forbidden commands" section covering BOTH `bd setup claude` AND plain `bd init`. Both install Beads' opinionated Claude Code integration that conflicts with SPWF — verified against bd 1.0.4 (Phase 2.1). The section SHALL include a recovery sub-section for users who accidentally ran either command (revert the auto-commit, restore CLAUDE.md, delete AGENTS.md, remove hook entries from .claude/settings.json, re-run with safe flags).
- [ ] 4.3 Root `README.md` lists `spwf-beadsify` in the marketplace contents as an optional plugin
- [ ] 4.4 `CLAUDE.md` mentions Beadsify under the dogfooding section (or links to a new `docs/beadsify.md`) noting the install path and the prerequisite warnings
- [ ] 4.5 `plugins/spwf-beadsify/README.md` includes a "Multi-session workflow" section explaining the supported pattern: open a second Claude Code session in the same project for braindump capture; use `bd q "<thought>"` (or `bd q "<thought>" --parent <id>`) to land stories into the graph while another session runs `/spwf:build` against an unrelated change; stories created by the braindump session don't perturb the active change because the build hook scopes `bd next` to the active change's `beads_story_id` subtree. Document the one known sharp edge (adding a blocker edge into an in-flight task is "you broke your own kneecap" territory — bd graph mutates mid-execution, build loop will surface it on the next `bd next`).
- [ ] 4.6 `plugins/spwf/.claude-plugin/plugin.json` version bumped (tracker-dispatch.md changed in Phase 3); the version-bump and a one-line summary land in the commit message. This task SHALL run after Phase 3 completes.

## Phase 5 — Acceptance (full-lifecycle + per-operation + regression + safety)

- [ ] 5.1 Full lifecycle on a toy task with `tracker: beads`: capture → challenge → spec → build → close. Beads story created at capture, comments landed during the cycle, story closed at close, OpenSpec change archived.
- [ ] 5.2 Per-operation sanity check (failure here pinpoints which operation is broken before the full lifecycle masks it): with `tracker: beads`, each of `/spwf:capture` (exercising create_issue), `/spwf:tracker-comment` (exercising add_comment), and `/spwf:close`'s tracker-transition step (exercising transition) is invoked in isolation and produces the expected Beads state change visible via `bd show`.
- [ ] 5.3 Regression: same lifecycle with `tracker: youtrack` (or `tracker: none`) produces the original behaviour with no Beads CLI activity. Verify by snapshotting tracker-dispatch.md behaviour before and after Phase 3 (Phase 3.1's preflight + Phase 3.5's check both feed this).
- [ ] 5.4 Missing-plugin error path: with `tracker: beads` set but `spwf-beadsify` uninstalled, `/spwf:capture` errors with the verbatim message from Phase 3.4 and writes no files.
- [ ] 5.5 `.gitignore` includes `.beads/`; `git status` is clean after a Beads-mode lifecycle run (no Beads DB churn tracked). Input-validation paths from Phase 2.2 hold for adversarial inputs (titles or comments containing shell metacharacters); `bd show` output reflects the literal input rather than interpreting it as shell.
- [ ] 5.6 Concurrent-writer smoke test: from two terminals (or one terminal with `&` backgrounding), invoke `bd q "<title-A>"` and `bd q "<title-B>"` simultaneously and verify both stories are created with distinct ids and no `.beads/` corruption (`bd list` shows both, `bd show` works on both). Then with one session running a long-ish operation (e.g. `bd show <id>` in a loop), invoke `bd q` from another session and verify it succeeds. This task validates the upstream "zero-conflict hash-based IDs / multi-agent workflows" claim against the version of bd we ship against — failure here is a blocker for the multi-session workflow documented in Phase 4.5.
