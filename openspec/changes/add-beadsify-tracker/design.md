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

### 5. `.beads/` is partially tracked: config shared, DB local

**Decision (revised against bd 1.0.4 reality):** Beads creates `./.beads/` next to `./openspec/`. Bd manages a partial gitignore via `.beads/.gitignore` so that:

- **Committed (shared via git):** `.beads/config.yaml` (issue prefix, backend choice), `.beads/metadata.json` (project_id, dolt_database name), `.beads/README.md`, `.beads/.gitignore` (the internal ignore rules themselves), `.beads/interactions.jsonl` (initially empty)
- **Local-only (gitignored by `.beads/.gitignore`):** `.beads/embeddeddolt/` (the actual Dolt DB), `.beads/dolt/`, `.beads/*.lock`, `.beads/*.sock`, `.beads/bd.sock.startlock`, daemon runtime files, push/sync state

bd init also adds patterns to the project-root `.gitignore`: `.dolt/`, `*.db`, `.beads-credential-key`.

**Rationale:** The original spec said "`.beads/` gitignored entirely". Reality (discovered when `bd init` ran in this project during Phase 5) is that bd's designers chose partial tracking deliberately: the project_id and prefix config must be consistent across machines (so a clone+init produces the same id namespace), while the Dolt DB (mutating with every `bd q`/`bd close`) must stay local to avoid git churn. The spwf-beadsify spec follows bd's design rather than overriding it — fighting upstream conventions would create maintenance friction.

**Trade-off:** Multi-machine workflows now share the *config* but not the *issue data*. Two machines initialised from the same repo see the same prefix and project_id, but each builds its own .dolt/ from scratch. This is bd's intended model; teams that need cross-machine issue data use Beads' Dolt remote / sync features (out of scope here).

**Implication for spwf-beadsify install:** the plugin's README does NOT instruct users to add `.beads/` to `.gitignore`. bd init handles its own ignore policy; the project's `.gitignore` only gains the bd-init-added patterns (`.dolt/`, `*.db`, `.beads-credential-key`) — which bd init does automatically.

---

### 6. Ship the tracker layer before the build-loop integration

**Decision:** This change (`add-beadsify-tracker`) ships first. The build-loop change (`add-beadsify-build-loop`) ships second and depends on this one.

**Rationale:** Tracker layer is mechanical mapping; build-loop changes how every Beads-mode build runs. Lower-risk piece ships first, building the `bd` habit at the tracker level (capture, comment, close) before the higher-risk piece arrives. By the time the build-loop integration lands, the user already has `bd` in their daily workflow and the spwf-beadsify plugin already exists as a destination.

**Trade-off:** The `/spwf-beadsify:remember` skill (a thin wrapper over `bd remember`) is the natural fit for the tracker layer's comment dispatch — but it's deferred to build-loop. For this change, `bd remember` is invoked directly from inside the backend module, not exposed as a user-facing skill.

---

### 7. Safe subprocess-invocation pattern

**Decision:** The Beads backend (a SKILL.md interpreted by Claude as instructions) MUST follow these rules for every `bd` invocation. They are reproduced verbatim in the backend skill body so Claude can apply them mechanically.

**The pattern (bash execution context):**

1. **Always quote substituted variables.** `bd q "$title"`, never `bd q $title`. Quoted parameter expansion in bash prevents word splitting and glob expansion — it is *not* equivalent to shell-string concatenation.

2. **Never use `eval`, `bash -c "..."`, or `sh -c "..."` with substituted user input.** These re-parse the substituted content through the shell, defeating the protection that quoted parameter expansion provides.

3. **Validate ids before invocation.** Every `bd-NNN` id arriving from user input or external systems MUST match `^[a-z0-9]+(-[a-z0-9]+)+$` (Beads' documented hash-based id format) before being passed to a subprocess. Reject non-matching ids with a clear error and halt the operation. No transformation, no normalisation — exact match or reject.

4. **Prefer stdin for multi-line or special-character content.** When a value (comment body, story title) may contain newlines, quotes, or other shell-significant content, use bd's stdin / `--file` mechanisms instead of inlining the string. Example: `echo "$comment_body" | bd comment "$id" --stdin` instead of `bd comment "$id" "$comment_body"`.

5. **Capture exit codes; fail loudly.** Every `bd` invocation must check `$?` and abort the dispatch operation on non-zero — never silently continue or assume success. A failed `bd` call is a hard halt with the bd stderr surfaced verbatim.

**What this pattern excludes:**

- No id "cleaning" that might smuggle a payload past validation (e.g. `id=$(echo "$id" | tr -d ' ')` is forbidden — validate the original).
- No pipe-to-`bash` of any bd output (`bd show … | bash` is forbidden).
- No string interpolation of titles or comments into command-substitution paths (`$(bd q "$title")` is fine; `eval "bd q \"$title\""` is forbidden).

**Rationale:** All four dispatch operations pass user-controlled content to a subprocess (titles, comment bodies, ids). The class of risk is command injection — Phase 5.5 specifically tests with adversarial inputs containing shell metacharacters. The pattern is designed to be mechanically applicable (a few rules a Claude reading the skill body can follow without judgement calls) and *narrow* (it forbids classes of construct, not specific commands — easier to audit).

**Alternative considered:** Pre-write a shared `_shared/bd-helpers.sh` with vetted helper functions (`bd_q_safe`, `bd_close_safe`, etc.) and require the backend to call those. Rejected because (a) SKILL.md execution doesn't include a "source helper library" step naturally; (b) the helpers would themselves need this pattern; (c) auditing one rule list is easier than auditing a helper library *plus* a rule list saying "use the helpers."

---

## Risks and Trade-offs

| Risk | Mitigation |
|---|---|
| `bd` CLI surface changes in a breaking way (young tool) | Pin the backend module to a documented `bd` version range in its README; bump explicitly when upgrading |
| `bd setup claude` already installed on a contributor machine | Plugin README detects via documented marker file and warns; manual cleanup instructions provided |
| Operator forgets `bd init` and gets cryptic errors | Backend's first dispatch attempt checks `.beads/` exists and emits a clear "run `bd init` then retry" message |
| Beads' Dolt-based store grows large | Out of scope for v1; documented as a known limitation in the plugin README |
| Cross-plugin path coupling in tracker-dispatch.md breaks if spwf-beadsify reorganises | Pin the backend module path; treat any future move as a coordinated change touching both plugins |

---

## Key File Formats

Configuration:

- `.spwf/tracker.yaml` — `tracker: beads` (alongside existing `youtrack` / `jira` / `none`)
- `.gitignore` — projects using Beads add `.beads/`

Beads database:

- `./.beads/` — Beads' on-disk store (Dolt format, opaque). Created by `bd init`, populated by `bd create` (or `bd q`) / `bd close` / `bd comment` / `bd remember`.

Spec artefacts: standard SPWF / OpenSpec conventions, no new formats.

---

## bd CLI mapping (resolved 2026-05-17 against bd 1.0.4)

The mapping below is established by reading `bd --help` against the installed bd 1.0.4. The build phase's Phase 2.1 task confirms it still holds at implementation time.

| Dispatch operation | bd CLI command | Notes |
|---|---|---|
| `create_issue` | `bd q "<title>"` | Quick capture; outputs only the issue id (e.g. `bd-a1b2`). Safer than `bd create` for programmatic dispatch — minimal output to parse. |
| `get_issue` | `bd show <id>` | Returns issue details: title, status, dependencies, comments, labels. |
| `add_comment` | `bd comment <id> "<text>"` | First-class command — earlier plan to use `bd remember` was based on incorrect research. `bd remember` is project-level persistent agent memory (loaded at `bd prime`), not per-issue commentary. |
| `transition` (close) | `bd close <id>` | Confirmed. Reopen (`bd reopen <id>`) deferred — no v1 success criterion needs it. |

Out-of-scope for this change but worth recording for `add-beadsify-build-loop`: `bd remember` is the **insights store** (loaded at session prime); it fits the build-loop change's `openspec/changes/{id}/insights.md` export story naturally. `bd note` is a per-issue append-only note, distinct from `bd comment` — its role in the workflow is TBD.

Issue id format observed: `bd-<hash>` (alphanumeric, not `bd-<digit>`). Input validation in Phase 2.2 should use a permissive regex such as `^[a-z0-9]+(-[a-z0-9]+)+$` rather than `^bd-\d+$`.

---

## `bd init` safety (resolved 2026-05-18 against bd 1.0.4)

Critical finding from Phase 2.1 preflight: **plain `bd init` is opinionated and invasive.** Running it without flags in a project root:

- Creates `.beads/` (correct — the Beads database)
- Creates project-root `AGENTS.md` and `CLAUDE.md` (overwrites if absent; behaviour on existing files unverified — assume destructive)
- Creates `.claude/settings.json` and **registers SessionStart + PreCompact hooks** of Beads' own design
- Modifies `.gitignore` (adds `.dolt/`, `*.db`, `.beads-credential-key`)
- **Auto-commits** all of the above

This is functionally equivalent to running `bd setup claude` — which the spec explicitly forbids (see Decision 3 above). The earlier "Do NOT run `bd setup claude`" guidance was necessary but **incomplete**: plain `bd init` does the same thing.

**Decision:** spwf-beadsify mandates the safe init flags:

```bash
bd init --skip-agents --skip-hooks --non-interactive
```

Verified behaviour with these flags (against bd 1.0.4):

- ✓ Creates `.beads/`
- ✓ No `CLAUDE.md` / `AGENTS.md` / `.claude/settings.json` polluted
- ⚠ Still modifies `.gitignore` (adds 3 patterns) — acceptable; correct patterns
- ⚠ Still makes one auto-commit at init time — acceptable; clearly labelled `bd init: initialize beads issue tracking`

**Bootstrap UX (open question 1 resolved):** the backend's first failed dispatch SHALL halt with a message containing the exact safe init command, not just `bd init`. Manual init by the user is required — same reasoning as Decision 3 (we don't let Beads make opinionated decisions on the user's behalf inside an SPWF project). Auto-init from the backend is explicitly rejected: even with safe flags, init has irreversible side effects (`.gitignore` mutation + auto-commit) that the user should approve consciously the first time.

## Open questions (carried from Challenge, to settle during build)

These do not block spec validation. Three of the four original open questions (comment mapping, status vocab, bd init UX) are now resolved; one remains:

1. **Dispatch backend file layout.** Default plan: single `plugins/spwf-beadsify/skills/tracker-backend/SKILL.md` with branching logic per operation. Revisit if it grows past 300 lines.
