# Design: add-beadsify-tracker

## Context

SPWF's existing tracker-dispatch abstraction (`plugins/spwf/skills/_shared/tracker-dispatch.md`) routes tracker operations to a configured backend per `.spwf/tracker.yaml`. Today the supported backends are `youtrack` (default), `jira`, and `none`. Skills (`/spwf:capture`, `/spwf:tracker-comment`, `/spwf:close`) call dispatch operations without knowing which backend handles them — that's the whole point of the abstraction.

This change adds `beads` as a fourth supported backend, but the backend implementation lives in a separate optional plugin (`spwf-beadsify`) so users who don't want Beads don't carry the integration weight.

## Goals

- Beads becomes a fully-supported tracker-dispatch backend with no skill-body changes elsewhere in SPWF.
- Beadsify is opt-in: users who don't install `spwf-beadsify` see exactly today's behaviour.
- Cross-plugin coupling is one-way and explicit: spwf core's `tracker-dispatch.md` knows the *name* `beads` and the *expected location* of the backend module; spwf-beadsify provides the actual operations.
- Failure mode (configured but plugin not installed) produces a clear error that names the fix.

## Non-Goals

- Build-loop integration (`/spwf:build` driven off `bd next` / `bd done`) — that's `add-beadsify-build-loop`, the follow-up change.
- `/spwf-beadsify:remember` as a user-invocable skill — also build-loop.
- Insights export (`openspec/changes/{id}/insights.md`) — also build-loop.
- Custom OpenSpec `beads-driven` schema — explicitly deferred until the hook-based build approach is proven.
- Multi-machine Beads sync, Beads remote (Dolt distributed mode), Beads observability.

---

## Decisions

### 1. Separate plugin (`spwf-beadsify`) rather than bundling into spwf core

**Decision:** All Beads integration lives in a new third plugin `spwf-beadsify` in the marketplace. spwf core stays unchanged for users who don't install it (apart from the small tracker-dispatch extension described in Decision 4).

**Rationale:** Beads adds a binary prerequisite (`bd` CLI). Bundling it into spwf core would force every installer to know about Beads even if they use YouTrack/Jira/nothing. Keeping it separate preserves the lightweight install story for spwf core and matches the existing `spwf` + `spwf-agents` pattern of selective install.

**Alternative rejected:** Skills like `/spwf:remember` in spwf core gated by runtime detection of `bd`. Rejected because gating skills by environment is a documentation nightmare and obscures what's actually available.

---

### 2. Beads replaces YouTrack/Jira (does not coexist)

**Decision:** When `.spwf/tracker.yaml` is set to `tracker: beads`, Beads is the *sole* tracker for the project. Tickets created during `/spwf:capture`, comments via `/spwf:tracker-comment`, and transitions at `/spwf:close` all dispatch to Beads exclusively.

**Rationale:** This is Simon's project; he's the only stakeholder for SPWorkflow itself. In-repo Beads gives him everything an external tracker would (story tracking, comments-as-insights, dependency graph) without the external service overhead. For client work where Jira is mandated, `tracker: jira` continues to be the right setting. Coexistence (a change in YouTrack AND Beads) introduces a sync problem this change explicitly avoids.

**Alternative rejected:** "Beads alongside external tracker, sync at well-defined boundaries." Rejected because the two layers have different state models (Beads has dependency edges; Jira has sprints/swimlanes) and bidirectional sync is a project unto itself.

---

### 3. Raw `bd` CLI; no `bd setup claude`

**Decision:** The spwf-beadsify backend invokes `bd` as a subprocess for every operation. The plugin README explicitly warns against running `bd setup claude` and documents why.

**Rationale:** `bd setup claude` installs Beads' opinionated Claude Code integration (per the research notes, likely MCP servers, hooks, or skills — we don't know exactly without running it). SPWF already has strong opinions on Claude Code integration (32 skills, 13 agents, 5 hooks). Layering Beads' opinions on top is a recipe for unpredictable interactions and being whipsawed by Beads' release cycle. The raw CLI is the stable contract; setup scripts evolve aggressively in young tools.

If `bd setup claude` ever has features SPWF needs (e.g. an MCP for graph queries), we audit and adopt selectively in a future change.

---

### 4. tracker-dispatch.md knows the `beads` name; spwf-beadsify provides the operations

**Decision:** `plugins/spwf/skills/_shared/tracker-dispatch.md` (spwf core) gains a branch for `tracker: beads` that:
- Resolves the backend module at a known path inside spwf-beadsify (`plugins/spwf-beadsify/skills/tracker-backend/SKILL.md` — pinned during build phase if needed).
- If that path is not loadable (plugin not installed), errors with: `tracker: beads requested but spwf-beadsify plugin not installed. Install: /plugin install spwf-beadsify@spwf. Or change tracker in .spwf/tracker.yaml.`

**Rationale:** Cross-plugin coupling is unavoidable when adding a backend. The cleanest form is: spwf core knows the *name* of the backend and the *contract* (which operations to call); spwf-beadsify provides the implementation. spwf core is not required to import or know about Beads-specific behaviour — only that "beads" is a valid value with a known module location.

**Alternative considered:** Plugin-extension API where spwf-beadsify registers itself with spwf core via some manifest. Rejected for v1 because no such API exists in Claude Code's plugin system today.

**Alternative considered:** Parallel namespace — provide `/spwf-beadsify:capture`, `/spwf-beadsify:tracker-comment` etc. that mirror the spwf versions but route to Beads. Rejected because the user must then remember which namespace to invoke, defeating the abstraction's whole purpose.

---

### 5. Per-project, gitignored `.bd/`

**Decision:** Beads database lives at `./.bd/` next to `./openspec/`. The spwf-beadsify install instructions add `.bd/` to `.gitignore`. OpenSpec remains source-of-truth for the project's specs; Beads is the execution-time scratchpad.

**Rationale:** Committing the Beads DB would produce per-`bd done` git diffs and merge churn. Per-machine (`~/.bd/`) conflates projects. The OpenSpec change directory + commits to `tasks.md` retain the durable record; Beads enriches but doesn't supplant it. Insights captured via `bd remember` are preserved by the build-loop change's `insights.md` export at close (out of scope here).

**Trade-off:** Multi-machine workflows lose Beads state across machine switches. Acceptable for solo single-machine usage; revisit if/when relevant.

---

### 6. Ship the tracker layer before the build-loop integration

**Decision:** This change (`add-beadsify-tracker`) ships first. The build-loop change (`add-beadsify-build-loop`) ships second and depends on this one.

**Rationale:** Tracker layer is mechanical mapping; build-loop changes how every Beads-mode build runs. Lower-risk piece ships first, building the `bd` habit at the tracker level (capture, comment, close) before the higher-risk piece arrives. By the time the build-loop integration lands, the user already has `bd` in their daily workflow and the spwf-beadsify plugin already exists as a destination.

**Trade-off:** The `/spwf-beadsify:remember` skill (a thin wrapper over `bd remember`) is the natural fit for the tracker layer's comment dispatch — but it's deferred to build-loop. For this change, `bd remember` is invoked directly from inside the backend module, not exposed as a user-facing skill.

---

## Risks and Trade-offs

| Risk | Mitigation |
|---|---|
| `bd` CLI surface changes in a breaking way (young tool) | Pin the backend module to a documented `bd` version range in its README; bump explicitly when upgrading |
| `bd setup claude` already installed on a contributor machine | Plugin README detects via documented marker file and warns; manual cleanup instructions provided |
| Operator forgets `bd init` and gets cryptic errors | Backend's first dispatch attempt checks `.bd/` exists and emits a clear "run `bd init` then retry" message |
| Beads' Dolt-based store grows large | Out of scope for v1; documented as a known limitation in the plugin README |
| Cross-plugin path coupling in tracker-dispatch.md breaks if spwf-beadsify reorganises | Pin the backend module path; treat any future move as a coordinated change touching both plugins |

---

## Key File Formats

Configuration:

- `.spwf/tracker.yaml` — `tracker: beads` (alongside existing `youtrack` / `jira` / `none`)
- `.gitignore` — projects using Beads add `.bd/`

Beads database:

- `./.bd/` — Beads' on-disk store (Dolt format, opaque). Created by `bd init`, populated by `bd write` / `bd done` / `bd remember`.

Spec artefacts: standard SPWF / OpenSpec conventions, no new formats.

---

## Open questions (carried from Challenge, to settle during build)

These do not block spec validation — they're decisions the build phase resolves by reading the `bd` CLI documentation or by running small experiments:

1. **`bd remember` vs other for comments.** Does `bd` have a closer match than `bd remember` for a "comment on a story" concept? Default plan: use `bd remember bd-N "<text>"`. Verify against `bd --help` during build; revise if a better match exists.
2. **Status vocabulary mapping table.** What Beads state does `/spwf:close` set? Default plan: `bd close <id>`. Confirm Beads has no richer "done with archive reference" state we should use.
3. **`bd init` bootstrap UX.** Auto-init from the backend on first failed dispatch, or require manual `bd init`? Default plan: manual with a clear error. Revisit if friction is high.
4. **Dispatch backend file layout.** Default plan: single `plugins/spwf-beadsify/skills/tracker-backend/SKILL.md` with branching logic per operation. Revisit if it grows past 300 lines.
