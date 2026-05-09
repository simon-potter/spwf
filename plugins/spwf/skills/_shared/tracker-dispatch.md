# Tracker dispatch — shared reference

Single source of truth for how tracker-touching skills (`capture`, `issue-to-task`,
`close`) and the `capturer` agent talk to issue trackers. Skills reference this
document; they do not repeat the dispatch table inline.

YouTrack is the default. Jira is supported. Linear and others slot in by adding a row
to the dispatch table — no skill rewrites required.

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
tracker: youtrack          # youtrack | jira | linear | none
project: ACAD              # default project key for `create_issue`
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

## Tracker type detection (default case)

When `.spwf/tracker.yaml` is absent or `tracker:` is unset, skills probe in order:

1. Is `mcp__youtrack__*` available? → use YouTrack.
2. Is `mcp__atlassian__jira_*` available? → use Jira.
3. Neither → **fail fast** with: "No issue tracker MCP configured. Add YouTrack or
   Atlassian MCP in user settings, or set `tracker: none` in `.spwf/tracker.yaml` to
   skip tracker steps."

Setting `tracker:` explicitly skips the probe and forces a single tracker.

---

## Operation contract

Every tracker-touching skill needs at most five logical operations.

| Operation | What it returns | Used by |
|---|---|---|
| `get_issue(id)` | id, title, description, type, state, labels, recent commenters | `capture`, `issue-to-task`, `close`, `tracker-comment` |
| `search_issues(query)` | list of `{id, title}` | `capture`, `issue-to-task` |
| `create_issue(project, title, body)` | new issue id | `capture` (when source was not a tracker) |
| `set_state(id, state)` | confirmation of new state | `close` |
| `add_comment(id, body)` | new comment id or confirmation | `tracker-comment` |

YouTrack uses **field-set commands** to change state (`State Done`); Jira uses **named
transitions** (`Done`, `Closed`). Both fall under the abstract `set_state` — the
dispatch row hides the difference.

`add_comment` posts a comment on an existing issue thread. Distinct from
`create_issue` (which records a new issue) and from `set_state` (which has no
body). Used by `tracker-comment` for audience-aware status updates and feedback
requests.

---

## Dispatch table

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
         "url": "https://projects.firstpartycapital.com/mcp",
         "transport": "sse",
         "headers": { "Authorization": "Bearer ${YOUTRACK_TOKEN}" }
       }
     }
   }
   ```

   Name the entry `youtrack` for the default-detection path to work. If you run
   multiple YouTrack instances on the same workstation, name them distinctly
   (`youtrack-fpc`, `youtrack-clientx`) and disambiguate per-repo with an `mcp_server:`
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
mcp_server: youtrack-fpc      # name of the MCP server entry for this repo's instance
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

To add Linear (or any other tracker) later:

1. Add a column to the dispatch table with the Linear MCP tool names.
2. Add `linear` to the enum in skill frontmatter and the detection probe order.
3. Note any Linear-specific quirks (ID format, description format, state model).
4. No skill body changes required.
