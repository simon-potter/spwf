# Tracker dispatch — shared reference

Single source of truth for how tracker-touching skills (`capture`, `issue-to-task`,
`close`) and the `capturer` agent talk to issue trackers. Skills reference this
document; they do not repeat the dispatch table inline.

YouTrack is the default. Jira is supported. Linear and other MCP-based trackers slot
in by adding a row to the MCP dispatch table — no skill rewrites required. Skill-based
trackers (where dispatch delegates to a SKILL.md instead of an MCP) plug in by adding
a row to the skill-based dispatch table; see "Backend types" below.

---

## Operating principle: fail fast

Skills do not paper over a missing tracker MCP. They detect intent from the input and
either (a) call the tracker MCP directly or (b) skip the tracker step because no
tracker action was implied.

| Situation | Skill behaviour |
|---|---|
| User invokes a tracker action (e.g. `/spwf:capture ACAD-42`, or `close` runs against a todo with a `ticket:` field) and the relevant MCP is configured | Call it. |
| Same situation, but the MCP is not configured | **Fail fast** with a clear, actionable message. Do not silently fall back. |
| User invokes a freeform action (`/spwf:capture "fix the broken login button"`) | No MCP call attempted. No error if no MCP is configured. |
| `close` runs against a todo with **no** `ticket:` field | No tracker step. Skip silently. |

The mental model: configuring a tracker MCP is the user's responsibility, and using it
is the skill's responsibility. The skill does not try to detect, fall back, or
substitute.

---

## Configuration

`.spwf/tracker.yaml` is **optional and minimal**. It exists only to persist
project-specific defaults so skills don't have to ask every time.

```yaml
# .spwf/tracker.yaml — all fields optional
tracker: youtrack          # youtrack | jira | linear | beads | none
project: ACAD              # default project key for `create_issue`
start_state: In Progress   # state `capture` / `issue-to-task` move a ticket to when work starts
                           #   (kanban / YouTrack boards often use "Doing"; set `none` to disable)
done_state: Done           # state name `close` transitions to
```

Resolution order:

1. If the file exists and has the field, use it.
2. If absent, the skill asks once on first need and offers to save the answer to
   `.spwf/tracker.yaml`.
3. If the user sets `tracker: none`, all tracker steps are skipped silently — useful
   for personal projects, prototypes, or repos where ticketing happens elsewhere.

**Auth, URLs, and MCP server names live entirely in user-level Claude Code MCP
settings.** The repo carries no secrets and no per-instance routing.

---

## Backend types

The dispatch supports two kinds of backend:

| Backend type | How dispatch happens | Examples |
|---|---|---|
| **MCP** | Skills call an MCP tool name (e.g. `mcp__youtrack__*`). The tool is provided by an MCP server configured in user-level Claude Code settings. | YouTrack, Jira, future Linear |
| **Skill** | Skills delegate the operation to a named SKILL.md inside another plugin. That skill invokes whatever CLI / API / store the tracker requires and returns the same five logical operations defined below. | Beads (via `plugins/spwf-beadsify/skills/tracker-backend/SKILL.md`; opt-in plugin install) |

The two types are interchangeable from a skill's perspective — `capture` does not know
which kind it's talking to. The dispatch resolves which backend to use, then routes
the operation appropriately.

## Tracker type detection (default case)

When `.spwf/tracker.yaml` is absent or `tracker:` is unset, skills probe in order:

1. Is `mcp__youtrack__*` available? → use YouTrack (MCP backend).
2. Is `mcp__atlassian__jira_*` available? → use Jira (MCP backend).
3. Neither → **fail fast** with: "No issue tracker MCP configured. Add YouTrack or
   Atlassian MCP in user settings, or set `tracker: none` in `.spwf/tracker.yaml` to
   skip tracker steps."

Setting `tracker:` explicitly skips the probe and forces a single tracker. Skill-based
backends (e.g. `tracker: beads`) are **never auto-probed** — they require explicit
opt-in via `.spwf/tracker.yaml`. This is intentional: a skill-based backend implies
extra installed software (a plugin + a CLI) that no auto-probe should assume.

---

## Operation contract

Every tracker-touching skill needs at most five logical operations.

| Operation | What it returns | Used by |
|---|---|---|
| `get_issue(id)` | id, title, description, type, state, labels, recent commenters | `capture`, `issue-to-task`, `close`, `tracker-comment` |
| `search_issues(query)` | list of `{id, title}` | `capture`, `issue-to-task` |
| `create_issue(project, title, body)` | new issue id | `capture` (when source was not a tracker) |
| `set_state(id, state)` | confirmation of new state | `capture` / `issue-to-task` (→ `start_state` when work begins), `close` (→ `done_state`) |
| `add_comment(id, body)` | new comment id or confirmation | `tracker-comment` |

YouTrack uses **field-set commands** to change state (`State Done`); Jira uses **named
transitions** (`Done`, `Closed`). Both fall under the abstract `set_state` — the
dispatch row hides the difference.

**`start_state` vs `done_state`.** `set_state` serves both ends of the lifecycle:
`capture` / `issue-to-task` move a ticket to `start_state` when work begins;
`close` moves it to `done_state`. They differ in failure handling:

- `close`'s transition is load-bearing (it gates the OpenSpec archive) — it
  **halts** on failure.
- `capture`'s transition is a courtesy flip — the ideation artefact is the
  deliverable, so a failed or unmatched `start_state` is a **soft note, never a
  halt**. It is also **idempotent and forward-only**: skip if the ticket is
  already in `start_state` or any later state (in-review / done / closed) so
  capture never drags a ticket backward. Set `start_state: none` to disable.

`add_comment` posts a comment on an existing issue thread. Distinct from
`create_issue` (which records a new issue) and from `set_state` (which has no
body). Used by `tracker-comment` for audience-aware status updates and feedback
requests.

---

## MCP dispatch table

For MCP-based backends, each operation maps to a concrete tool name. Skills' `allowed-tools` lists include the relevant glob (e.g. `mcp__youtrack__*`); the model picks the right tool when it makes the call.

| Op | YouTrack (JetBrains native MCP) | Jira (Atlassian MCP) |
|---|---|---|
| `get_issue` | `mcp__youtrack__*` (issue lookup by `idReadable`) | `mcp__atlassian__jira_get_issue` |
| `search_issues` | `mcp__youtrack__*` (YouTrack query DSL) | `mcp__atlassian__jira_search_issues` |
| `create_issue` | `mcp__youtrack__*` (create in `project`) | `mcp__atlassian__jira_create_issue` |
| `set_state` | `mcp__youtrack__*` (apply state field command) | `mcp__atlassian__jira_update_issue` (transition by name) |
| `add_comment` | `mcp__youtrack__*` (comment-posting tool advertised at handshake) | `mcp__atlassian__jira_add_comment` |

YouTrack tool names are advertised by the JetBrains MCP server at handshake. The
default approach is **runtime resolution via the `mcp__youtrack__*` glob** in each
skill's `allowed-tools` — the model picks the right tool when it makes the call.
Teams that prefer concrete pins (for stricter `allowed-tools` scoping or for
visibility) can capture names via a one-time discovery session and replace this
column with the pinned values.

---

## Skill-based dispatch table

For skill-based backends, each operation is implemented inside a SKILL.md owned by
another plugin. Skills calling dispatch resolve to the backend module's path and
delegate the operation there. The backend handles any CLI / DB / external-API work
behind a uniform interface that returns the same five logical operations.

| Tracker | Backend module path | Operations supported | Owning plugin (install required) |
|---|---|---|---|
| `beads` | `plugins/spwf-beadsify/skills/tracker-backend/SKILL.md` | `get_issue`, `create_issue`, `set_state` (close only), `add_comment` (no `search_issues` in v1 — defer) | [`spwf-beadsify`](../../../../spwf-beadsify/README.md) — opt-in third plugin; install via `/plugin install spwf-beadsify@spwf` |

### Routing rules

When `.spwf/tracker.yaml` contains `tracker: beads`, dispatch:

1. **Verify the backend module exists** at the path above. If the file is not
   loadable (the spwf-beadsify plugin is not installed in this Claude Code session),
   halt with the verbatim error in the next subsection. Do not silently fall back to
   another tracker.
2. **Delegate the operation** to the backend by reading its SKILL.md and following
   the operation-specific instructions there. The backend invokes the bd CLI on the
   caller's behalf, handles input validation, and returns the result in the same
   shape the MCP backends would.
3. **Surface the backend's stderr verbatim** on non-zero exit. The backend follows
   the Decision 7 safe-invocation pattern (see `openspec/changes/add-beadsify-tracker/design.md`),
   so failures are bounded and the messages are useful.

### Configured-but-not-installed error (verbatim)

When `tracker: beads` is set in `.spwf/tracker.yaml` but `plugins/spwf-beadsify/skills/tracker-backend/SKILL.md` is not loadable:

```
tracker: beads requested but spwf-beadsify plugin not installed. Install: /plugin install spwf-beadsify@spwf. Or change tracker in .spwf/tracker.yaml.
```

This is the only failure mode dispatch raises on its own for skill-based backends —
any other failure surfaces from the backend itself.

---

## YouTrack MCP setup (one-time)

YouTrack's MCP endpoint is **per-instance** — there is no global URL. Each YouTrack
installation serves its own MCP at `{instance-url}/mcp`. Multiple repos can share one
instance; one workstation may need entries for several.

Setup, per instance:

1. **Identify the instance URL** (the URL you point a browser at to reach the project).
2. **Mint a permanent token** in YouTrack profile → Account Security → New token.
   Scope to the projects you need. Store via env var or secrets manager — never commit.
3. **Add an MCP server entry** in user-level Claude Code settings:

   ```json
   {
     "mcpServers": {
       "youtrack": {
         "url": "https://projects.spottmedia.com/mcp",
         "transport": "sse",
         "headers": { "Authorization": "Bearer ${YOUTRACK_TOKEN}" }
       }
     }
   }
   ```

   Name the entry `youtrack` for the default-detection path to work. If you run
   multiple YouTrack instances on the same workstation, name them distinctly
   (`youtrack-spm`, `youtrack-clientx`) and disambiguate per-repo with an `mcp_server:`
   field in `.spwf/tracker.yaml` (rare; documented below).

4. **Run a discovery session** in any repo: ask the model to list tools advertised by
   the new MCP and pin the names into the dispatch table above.

That's it. Skills work from then on — no per-repo MCP config, no `base_url`, no
`mcp_server` field unless multi-instance.

---

## Multi-instance edge case

Workstations addressing several YouTrack instances at once need to disambiguate. Add
one optional field to `.spwf/tracker.yaml`:

```yaml
tracker: youtrack
mcp_server: youtrack-spm      # name of the MCP server entry for this repo's instance
project: ACAD
done_state: Done
```

Skills then resolve tool calls as `mcp__{mcp_server}__{operation}` instead of the
default `mcp__youtrack__{operation}`. This is the only reason to set `mcp_server:`.

---

## Jira MCP — practical notes

- Configure the Atlassian MCP in user-level Claude Code settings. Tools live under
  `mcp__atlassian__*`.
- Issue IDs look like `PROJ-123`.
- Description format is Jira wiki markup (`h1.`, `*bold*`, `{code}`). The
  `issue-to-task` skill does light translation when parsing.
- State changes are named transitions configured per project workflow. `done_state`
  must match an available transition; if it doesn't, the skill reports the available
  transitions and asks the user which to use.

---

## Adding a new tracker

### MCP-based (e.g. Linear)

1. Add a column to the **MCP dispatch table** with the new tool names.
2. Add the tracker name (`linear`) to the enum in skill frontmatter and to the auto-detection probe order if appropriate.
3. Note any tracker-specific quirks (ID format, description format, state model) in its own subsection.
4. No skill body changes required.

### Skill-based (e.g. Beads via spwf-beadsify)

1. Ensure the tracker's backend module exists at a known path inside its plugin (`plugins/<plugin>/skills/<backend>/SKILL.md`) and implements the five logical operations.
2. Add a row to the **skill-based dispatch table** (added by the change that introduces the first skill-based backend) naming the tracker, the backend module path, and any operations it does NOT implement (so dispatch can fail fast for unsupported ops).
3. Add the tracker name to the enum in skill frontmatter — but **not** to the auto-detection probe (skill-based backends are explicit opt-in only).
4. Document the install / prerequisites in the owning plugin's README, not here. tracker-dispatch.md just knows the routing.
