# Recap: add-beadsify-tracker — Beads as optional tracker-dispatch backend

## What changed

`spwf-beadsify` shipped as a third optional plugin. With `tracker: beads`
in `.spwf/tracker.yaml` and the plugin installed, every existing
`/spwf:*` skill that touches a tracker (capture, tracker-comment,
issue-to-task, close) now reads/writes
[Beads](https://github.com/gastownhall/beads) stories in `./.beads/`
instead of an external service — with zero changes to those skills'
bodies. Routing happens entirely inside `_shared/tracker-dispatch.md`,
which gained a new "skill backend" type alongside the existing MCP
backends.

## Concepts touched

- **Dispatch abstraction** — `tracker-dispatch.md` is a contract
  (`create_issue / get_issue / add_comment / set_state`) with two
  implementation flavours: MCP backends (tool-name probe) and skill
  backends (delegate to another plugin's SKILL.md). Adding a new
  tracker means adding a row to a dispatch table, not rewriting
  callers.
- **Skill-as-library** — `plugins/spwf-beadsify/skills/tracker-backend/SKILL.md`
  has `disable-model-invocation: true` and is never user-invoked. It's
  a dispatch target, not a slash command. SKILL.md as a *library*
  surface rather than a *command* surface.
- **Backend-availability gating** — each caller had its own inline
  preflight check ("Fail fast on missing MCP"). When the backend set
  changes, every gate needs auditing — the round-by-round review
  surfaced misses in 6 separate places.
- **Per-project id prefix** — Beads derives the issue-id prefix from
  the project directory name at `bd init` time. For this repo, ids are
  `spwf-<hash>`; for an `auth` project they'd be `auth-<hash>`.
  Validation regex must be prefix-agnostic:
  `^[a-z0-9]+(-[a-z0-9]+)+$`.
- **Recoverability asymmetry** — for irreversible-action ordering,
  run the *recoverable* step last. Close's tracker-transition runs
  **before** OpenSpec archive: a failed transition is retryable; a
  failed un-archive (after the change directory has moved) is not.

## Decisions (why this, not that)

- **Separate `spwf-beadsify` plugin → optional install** — instead of
  bundling Beads into spwf core. Rejected: gating skills inside spwf
  core by runtime `bd` detection. Reason: gating-by-environment
  obscures what's actually available; separate plugin keeps the
  install story honest.
- **Raw `bd` CLI only; `bd setup claude` forbidden** — instead of
  adopting Beads' Claude Code integration. Rejected: `bd setup claude`
  and plain `bd init` both write `CLAUDE.md`, `AGENTS.md`, and
  `.claude/settings.json` hooks of Beads' own design — they would
  collide with SPWF's 32 skills / 13 agents / 5 hooks. The raw CLI is
  the stable contract.
- **Beads replaces (not coexists with) external trackers** —
  `tracker: beads` is exclusive. Rejected: bidirectional sync with
  Jira/YouTrack. Reason: dependency graphs and sprint boards have
  incompatible state models; sync is a project unto itself.
- **Decision 7 safe-subprocess pattern reproduced inline in the
  backend SKILL.md** — rather than a shared `_shared/bd-helpers.sh`.
  Rejected: a helper library. Reason: SKILL.md execution has no
  natural "source helper library" step; auditing five rules in one
  file is easier than auditing helpers plus a "use the helpers" rule.

## What surprised us

- Assumed Beads ids would be `bd-<hash>`. **Turned out** bd uses the
  project directory name as the prefix (`spwf-<hash>` here). Caught
  at Phase 5 integration when `bd init` first ran — respec across
  design/spec/tasks/SKILL.md was a single regex swap to
  `^[a-z0-9]+(-[a-z0-9]+)+$`.
- Assumed `$status=$?` would work in skill bash snippets. **Turned
  out** `$status` is read-only in zsh; the assignment silently fails.
  Caught by the Phase 5 smoke test. Renamed to `$rc` throughout and
  added a portability note.
- Assumed "host skills work unchanged via dispatch" implied dispatch
  routing was enough. **Turned out** every caller had its own inline
  backend-availability preflight that gated on MCP-only presence. The
  reviewer surfaced the misses in 5 separate rounds (capture input-side,
  capture output-side, tracker-comment, close, issue-to-task, capturer
  agent description). One unified caller sweep would have caught them
  all.

## Read next

- `plugins/spwf/skills/_shared/tracker-dispatch.md` — the canonical
  dispatch contract; both backend types documented side-by-side
- `docs/handover/2026-05-beadsify-tracker.md` — the lessons from this
  cycle, written for the next person doing a dispatch-abstraction
  change
- The spec: `openspec/changes/add-beadsify-tracker/`
