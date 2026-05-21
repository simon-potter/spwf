---
source: scratch
created: 2026-05-07
status: ideation
---

# Jira → YouTrack (with multi-tracker future)

## Context

The marketplace currently assumes Atlassian Jira as the only issue tracker. In practice most
of our work happens in YouTrack, and we may later want to support Linear, GitHub Issues, or
others. We want YouTrack to become the first-class default, Jira to remain a supported
alternative (not removed), and the architecture to be open to additional trackers without
another rewrite.

`todo/optimal-agentic-env.md` already flagged this gap (Gap 6) and proposed Composio's
connect-apps as one path. This document narrows that into a concrete, opinionated proposal
with a full inventory of affected files.

---

## What we know — full inventory of Jira / Atlassian references

### A. Skills that call Atlassian MCP tools

| File | Tools used | Purpose |
|---|---|---|
| `plugins/spwf/skills/capture/SKILL.md` | `mcp__atlassian__jira_get_issue`, `jira_search_issues`, `jira_create_issue`, `jira_update_issue` | Fetches Jira ticket as input; optionally creates a Jira ticket if source was Slack/file/scratch |
| `plugins/spwf/skills/issue-to-task/SKILL.md` | `mcp__atlassian__jira_get_issue`, `jira_search_issues` | Pre-phase atomic skill: fetch Jira ticket → produce `todo/{slug}.md` ideation file |
| `plugins/spwf/skills/close/SKILL.md` | `mcp__atlassian__jira_get_issue`, `jira_update_issue` | Final phase: transition the linked ticket to Done (or Closed) |

### B. Agents that declare Atlassian MCP tools

| File | Tools used | Notes |
|---|---|---|
| `plugins/spwf-agents/agents/capturer.md` | All four `mcp__atlassian__jira_*` tools | Thin wrapper over `spwf:capture`; tool list mirrors capture skill |

### C. Skills that reference Jira semantically (no MCP call) but encode Jira terms

| File | Lines | What it encodes |
|---|---|---|
| `plugins/spwf/skills/capture/SKILL.md` | 22, 23, 28, 37, 43, 114–115, 172–173, 195–199, 203, 216, 232 | Input pattern (`PROJ-123`, `from jira PROJ-123`); Jira `issuetype` classification signals; frontmatter enum `source: jira \| slack \| file \| scratch`; `ticket: PROJ-123` example; "is there a Jira ticket?" prompt; report templates |
| `plugins/spwf/skills/issue-to-task/SKILL.md` | 1–6, 9, 11, 18, 25, 27, 54 | Header comment, description, "Jira wiki markup" parsing assumption, `source: jira` frontmatter |
| `plugins/spwf/skills/close/SKILL.md` | 3, 5, 18, 70, 117, 124, 130, 133, 135, 151 | Step 7 hard-coded as "Close Jira ticket"; transition naming ("Done"/"Closed") tied to Jira workflow vocabulary |
| `plugins/spwf/skills/challenge/SKILL.md` | 100, 107, 151 | Uses `ticket:` field generically; `{PROJ-123}` example only |
| `plugins/spwf/skills/new-task/SKILL.md` | 55 | Sets `source: scratch` — tracker-neutral; safe |

### D. Documentation referencing Jira

| File | Lines |
|---|---|
| `README.md` (root) | 17 (Capture row), 25 (Close row), 116–118 (Prerequisite #4: Atlassian MCP), 169 (issue-to-task row) |
| `plugins/spwf/README.md` | 20 (close row), 27 (issue-to-task row), 83–84 (frontmatter example) |
| `todo/Marketplace_setup.md` | 67–71, 140–141, 155–156, 167, 213, 357–358, 374, 416, 442 |
| `todo/optimal-agentic-env.md` | 20, 38, 48, 95, 125–127, 145, 155, 185, 195, 214 — already discusses tracker-agnosticism |
| `todo/Code_spec_drift.md` | 302, 304, 330 — references debug agent's Jira tool |
| `openspec/changes/add-plugin-marketplace/proposal.md` | 21, 23 |
| `openspec/changes/add-plugin-marketplace/tasks.md` | 86, 87, 88, 116, 134 |
| `openspec/changes/add-plugin-marketplace/design.md` | 19, 58, 75 |
| `openspec/changes/archive/2026-04-25-align-golden-path/tasks.md` | 61, 88 |
| `openspec/changes/archive/2026-04-25-align-golden-path/design.md` | 92 |
| `plugins/spwf/skills/claudemd-curator/references/layer-model.md` | 69 — illustrative `pr-jira-review` example only |

### E. Frontmatter schema (todo/*.md ideation files)

Two fields encode tracker identity in every captured artefact:

- `source:` — currently enum `jira | slack | file | scratch`
- `ticket:` — currently typed as a Jira key (e.g. `PROJ-123`); omitted otherwise

The `todo-frontmatter-check.sh` hook validates only `source`, `status`, `created` presence
— it does not constrain the `source` value, so a schema extension is non-breaking for the
hook.

### F. Things that DON'T need to change

- The `challenge` skill (uses `ticket:` opaquely)
- The `new-task` skill (always `source: scratch`)
- The `todo-frontmatter-check.sh` hook (doesn't enforce enum values)
- The OpenSpec archive directory (historical record — leave alone)

---

## Goal recap

1. **YouTrack becomes first-class default.** All examples, prerequisites, and recommended
   prompts speak YouTrack first.
2. **Jira remains supported.** Existing Atlassian MCP integration is preserved and selectable.
3. **Adding a third tracker (Linear, GitHub Issues, Composio gateway, …) is a one-file change**,
   not a marketplace-wide rewrite.
4. **No breaking change for downstream projects already on Jira.** They keep working until
   they choose to switch.

---

## Architecture options

### Option 1 — Replace Jira with YouTrack

Swap every `mcp__atlassian__jira_*` reference for `mcp__youtrack__*`. Update docs.

- ✅ Smallest diff. No abstraction.
- ❌ Locks us in again. Repeats the same mistake one tracker over.
- ❌ Breaks every downstream project currently using Jira.

### Option 2 — Tracker abstraction (recommended)

Introduce a "tracker" concept that skills consult before any tracker-specific call.
Configuration lives in one place; each skill carries a small dispatch table.

- A new optional file `.spwf/tracker.yaml` (or root `spwf.config.yaml`) declares the
  active tracker and any tracker-specific config (project key/board ID, base URL).
- Skills' `allowed-tools` lists are widened to include the union of supported tracker
  MCP namespaces (`mcp__atlassian__*` + `mcp__youtrack__*`). Tools that aren't actually
  installed are simply unavailable at runtime — a non-issue, since the dispatch reads
  config first.
- Skills contain a small "tracker dispatch" section near the top of each
  tracker-touching step instead of hard-coded Jira tool names.
- Frontmatter `source:` enum widens from `jira | slack | file | scratch` to
  `youtrack | jira | linear | slack | file | scratch`. `ticket:` becomes tracker-agnostic
  (any string identifier).

- ✅ YouTrack becomes the canonical example; Jira is just one branch of the dispatch.
- ✅ Adding Linear later is a new dispatch branch + new MCP entry, no skill rewrites.
- ✅ Backwards-compatible — existing artefacts with `source: jira` keep validating.
- ⚠️ Each tracker-touching skill has slightly more text (3 short branches instead of one).
  Acceptable cost.

### Option 3 — Composio connect-apps gateway

Use Composio's MCP gateway (already mentioned in `optimal-agentic-env.md`) as a single
abstraction layer covering 500+ services including Jira, YouTrack (via REST), Linear,
GitHub Issues.

- ✅ One MCP, many trackers.
- ❌ Adds a third-party dependency to the critical capture/close path.
- ❌ Tool naming under Composio is generic (`composio_*`) — loses the strong typing of
  named tools like `mcp__youtrack__get_issue`.
- ❌ Doesn't help if a team wants direct YouTrack MCP performance/feature parity.

**Verdict:** keep Composio in the toolbox as an *additional* dispatch branch under
Option 2 (`tracker: composio`). Don't make it the primary mechanism.

---

## Recommended approach: Option 2, phased

### Step 1 — Define the tracker contract

Each tracker plugs into the workflow by implementing four logical operations, regardless
of the underlying MCP tool names:

| Operation | Used by | Jira tool | YouTrack tool (JetBrains native, names TBD at discovery) | Linear tool (future) |
|---|---|---|---|---|
| `get_issue(id)` | capture, issue-to-task, close | `mcp__atlassian__jira_get_issue` | `mcp__youtrack__*` (e.g. `get_issue` / `issue_get`) | `mcp__linear__get_issue` |
| `search_issues(query)` | capture, issue-to-task | `mcp__atlassian__jira_search_issues` | `mcp__youtrack__*` (search by query DSL) | `mcp__linear__search_issues` |
| `create_issue(project, title, body)` | capture (non-tracker sources) | `mcp__atlassian__jira_create_issue` | `mcp__youtrack__*` (create in project) | `mcp__linear__create_issue` |
| `update_issue(id, state)` | close | `mcp__atlassian__jira_update_issue` | `mcp__youtrack__*` (state field update; YouTrack uses field-set commands rather than Jira-style transitions) | `mcp__linear__update_issue` |

**Decided:** the YouTrack MCP server is JetBrains' native, in-product MCP endpoint exposed
by the YouTrack instance itself (e.g. `https://projects.spottmedia.com/mcp`).
This is HTTP/SSE-transport, not a `stdio`/`npx` subprocess — it's configured by URL plus
a YouTrack permanent token, not by spawning a local process. Tool names and JSON shapes
are whatever the JetBrains server advertises at runtime; we treat them as the canonical
contract and pin them in `references/tracker-mcp.md` after a one-off discovery pass.

Reference: <https://www.jetbrains.com/help/idea/mcp-server.html> (the IDE-side server is a
separate product; the YouTrack-hosted endpoint is the one that matters for this workflow).

### Step 2 — Configuration (minimal, fail-fast)

Skills rely on the MCP being there. If it isn't and a tracker action is requested,
they fail fast with an actionable message. No silent fallbacks, no auto-substitution.

`.spwf/tracker.yaml` is **optional and minimal** — it exists only to persist defaults
so skills don't ask every time:

```yaml
# .spwf/tracker.yaml (all fields optional)
tracker: youtrack          # youtrack | jira | linear | none
project: ACAD              # default project for create_issue
done_state: Done           # state name for close transition
```

If the file is missing or a field is unset, the skill asks once on first need and
offers to save the answer. URLs, auth tokens, and multi-instance routing live entirely
in user-level Claude Code MCP settings — never in the repo.

Tracker type detection: when `tracker:` is unset, skills probe `mcp__youtrack__*`
first, then `mcp__atlassian__jira_*`. First match wins. If neither is available and a
tracker action is needed: hard error with clear remediation.

### Step 3 — Add a shared reference document

Create `plugins/spwf/skills/_shared/tracker-dispatch.md` (or place it under a single
canonical skill and have others link to it). It contains the dispatch table above and is
the single source of truth. Each tracker-touching skill references it instead of repeating
the table inline.

### Step 4 — Skill changes

For each of `capture`, `issue-to-task`, `close`:

1. Widen `allowed-tools` to include `mcp__youtrack__*` and (optionally) `mcp__linear__*`
   alongside the existing `mcp__atlassian__jira_*` tools.
2. Replace hard-coded tool names in step bodies with a "Step X — Tracker call" section
   that:
   - Reads `.spwf/tracker.yaml` if present (or falls back to interactive prompt)
   - Dispatches to the configured tracker's MCP tool per the table
   - Returns a normalised payload (id, title, description, state, type) regardless of
     source
3. Update example ticket IDs from `PROJ-123` to a YouTrack-style `ACAD-42` in the primary
   examples; keep one Jira example to show the alternative.
4. Update language: "Jira ticket" → "issue tracker ticket" in narrative prose.

### Step 5 — Agent changes

`plugins/spwf-agents/agents/capturer.md`: widen `tools:` to include the YouTrack MCP
namespace; update description to say "issue tracker" instead of "Jira".

### Step 6 — Frontmatter schema

Widen the enum:

```yaml
source: youtrack | jira | linear | slack | file | scratch
ticket: ACAD-42        # tracker-agnostic identifier; omit if not from a tracker
```

Optionally add `tracker: youtrack` as an explicit field for unambiguous parsing in tools
that need it. (Cheap to add; harmless if unused.)

### Step 7 — Documentation

- Root `README.md`: rename Prerequisite #4 from "Atlassian MCP" to "Issue tracker MCP
  (YouTrack recommended; Jira and Linear supported)". Update Capture and Close rows to
  say "issue tracker" instead of Jira.
- `plugins/spwf/README.md`: same rewording; update frontmatter example to YouTrack.
- `todo/Marketplace_setup.md`: footnote — "Original assumed Jira; now tracker-agnostic
  per `todo/Jira_to_youtrack.md`."
- Leave OpenSpec archive untouched (it is historical).

### Step 8 — Migration script (optional, low priority)

A one-shot helper that walks `todo/*.md`, prompts the user to choose a tracker, and
rewrites `source: jira` → `source: {chosen}` where appropriate. Not strictly needed —
Jira artefacts continue to validate.

---

## YouTrack MCP — practical notes

- **Endpoint is per-instance, not global.** Each YouTrack instance serves its own MCP at
  `{instance-url}/mcp` (e.g. `https://projects.spottmedia.com/mcp`). There is no
  shared `youtrack.com/mcp` — every team or client running YouTrack has its own URL,
  and a single workstation may need to address several at once.
- Multiple repos can (and should) share one MCP server entry when they live on the same
  YouTrack instance. The `mcp_server:` field in `.spwf/tracker.yaml` is what links a
  repo to a specific entry — skills resolve tool calls as
  `mcp__{mcp_server}__{operation}`.
- **Server is the JetBrains native YouTrack MCP endpoint**, served by the YouTrack
  instance itself. No npm package, no local subprocess — remote MCP over HTTP/SSE.
- **Auth** is a YouTrack permanent token, scoped to a service account or per-user. Stored
  in the user's Claude Code MCP settings (not in the repo). The `.spwf/tracker.yaml` only
  carries the *base URL* and project shortname; secrets stay out of the repo.
- **Tool names are advertised by the server at handshake**. Before pinning the dispatch
  table we run one discovery session, capture the tool list and JSON schemas, and write
  them into `plugins/spwf/skills/_shared/references/tracker-mcp.md`. The dispatch then
  references this document, not guessed names.
- **YouTrack uses `idReadable`** like `ACAD-42` — these map cleanly to our `ticket:`
  field with no schema change beyond the enum.
- **"Done" state is project-configurable** (often `Done`, `Fixed`, `Verified`, or
  `Closed`). The `done_state` config field handles this; the close skill already has the
  fallback "report available transitions and ask the user".
- **Markdown is native** in YouTrack descriptions — simpler than Jira's wiki markup. The
  `issue-to-task` parsing step gets *easier*, not harder, when YouTrack is the source.
- **Example MCP config** (user-level Claude Code settings, not repo) — one entry per
  YouTrack instance, named distinctly so multiple instances can coexist:

  ```json
  {
    "mcpServers": {
      "youtrack-spm": {
        "url": "https://projects.spottmedia.com/mcp",
        "transport": "sse",
        "headers": { "Authorization": "Bearer ${YOUTRACK_FPC_TOKEN}" }
      },
      "youtrack-clientx": {
        "url": "https://yt.clientx.com/mcp",
        "transport": "sse",
        "headers": { "Authorization": "Bearer ${YOUTRACK_CLIENTX_TOKEN}" }
      }
    }
  }
  ```

  Exact key names follow the Claude Code MCP schema for remote servers; verify against
  current docs at install time.

- **First-time setup is a four-step pass** per YouTrack instance: (1) identify the
  instance URL, (2) mint a permanent token, (3) add a uniquely-named MCP server entry,
  (4) run a discovery session to pin advertised tool names into the dispatch table.
  Documented in `plugins/spwf/skills/_shared/tracker-dispatch.md`.

---

## Migration plan (phased)

**Phase 1 — schema-only, no behavior change** (1 commit, low risk)
- Widen frontmatter enum and update examples in capture, issue-to-task, new-task templates
- No tool changes; existing Jira flows still work
- Bump plugin patch version

**Phase 2 — YouTrack as alternative** (1 commit, additive only)
- Add `mcp__youtrack__*` to `allowed-tools` lists in capture, issue-to-task, close
- Add tracker dispatch sections that branch on `.spwf/tracker.yaml` (default: jira if
  unset, for backwards compatibility)
- Add YouTrack to README Prerequisite #4
- Bump plugin minor version

**Phase 3 — flip the default** (1 commit)
- Default tracker becomes `youtrack` when `.spwf/tracker.yaml` is missing AND there is no
  Atlassian MCP configured
- Reword examples to lead with YouTrack
- Jira retained as a supported branch
- Bump plugin minor version

**Phase 4 — Linear (later, on demand)**
- Add `mcp__linear__*` branch to dispatch
- Add Linear to docs
- No other change needed if Phase 2's abstraction held

---

## Open questions

- ~~Which YouTrack MCP server do we standardise on?~~ **Resolved**: JetBrains native
  in-product MCP endpoint at `{youtrack-base-url}/mcp` (HTTP/SSE, permanent-token auth).
  One remaining sub-question: do we need to capture the tool-name list now (so the
  dispatch table is concrete) or wait until Phase 2 implementation? **Recommendation:** do
  a 10-minute discovery session against the live `https://projects.spottmedia.com/mcp`
  endpoint and write the names into `references/tracker-mcp.md` before Phase 2 starts.
- **Where does `.spwf/tracker.yaml` live — repo root, `.spwf/`, or inside `openspec/`?**
  Leaning toward `.spwf/tracker.yaml` so it's clearly plugin-owned and not confused with
  OpenSpec config.
- **Should `tracker:` be a separate frontmatter field, or derived from `source:`?**
  Adding it is cheap and removes ambiguity (especially for `source: slack` issues that
  also have a tracker ticket attached). Recommendation: add it.
- **Do we keep "Jira" terminology anywhere as a literal?** Only inside the `tracker: jira`
  branch of dispatch tables and in the historical archive. All user-facing prose says
  "issue tracker".
- **Does the `capturer` agent need a description rewrite, or just a tools list update?**
  Rewrite — its description is the discoverable surface for `/agents` and shouldn't say
  "Jira" once YouTrack is the default.
- **Do we ship a migration script in Phase 1 or skip it?** Skip — manual rewrite of any
  active todo files is faster than maintaining a script for a one-shot transition.

## Rough scope

In scope:
- Three skill rewrites (capture, issue-to-task, close) to use tracker dispatch
- One agent update (capturer)
- Frontmatter enum widening + optional `tracker:` field
- Root README + `plugins/spwf/README.md` updates
- New shared reference document for tracker dispatch
- New optional `.spwf/tracker.yaml` config schema

Out of scope (deferred):
- Linear support (Phase 4, on demand)
- Composio gateway integration
- Migration script for legacy todo files
- Touching OpenSpec archive directories
- Changing `challenge` or `new-task` skills (already tracker-neutral)
