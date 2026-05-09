# spwf hooks

Five hooks ship with the `spwf` plugin and register automatically on install.
All are **advisory** — they exit 0 and never block tool execution.

| Hook | Event | What it does |
|---|---|---|
| `uncommitted-changes.sh` | `Stop` | Warns at session end if `git status` shows uncommitted changes. |
| `plugin-version-check.sh` | `PostToolUse` (Write\|Edit) | When `plugin.json` is modified, warns if the version field was not incremented. |
| `todo-frontmatter-check.sh` | `PostToolUse` (Write\|Edit) | When a `todo/*.md` file is written, validates that `source`, `status`, `created` are present. |
| `openspec-validate-nudge.sh` | `PostToolUse` (Write\|Edit) | When `openspec/changes/**/tasks.md` is written, prints the `openspec validate {id} --strict` command. |
| `tracker-comment-nudge.sh` | `PreToolUse` (tracker write tools) | When the model is about to write a comment/issue to a tracker MCP, warns if the body looks heavy-technical and suggests `/spwf:tracker-comment` for audience-aware rewriting. |

## Conventions

Every hook in this plugin follows the same conventions. New hooks should
match.

### 1. Advisory only — always `exit 0`

Hooks never block the tool execution. They print to stderr; the call
proceeds regardless. This applies to every event type, including
`PreToolUse`. If a future feature genuinely needs blocking behaviour,
that's a convention break — discuss explicitly before shipping.

### 2. JSON parsing fallback chain

Each hook reads its tool-event JSON from stdin. Use `jq` if available,
fall back to `python3` if not. If both are missing, print a named
warning and skip cleanly:

```bash
if ! command -v jq &>/dev/null && ! command -v python3 &>/dev/null; then
    printf '⚠  spwf hook: jq and python3 both missing — {hook-name} skipped\n' >&2
    exit 0
fi
```

The named-warning pattern lets users see *which* hook skipped, not
just an opaque silent failure.

### 3. Stderr `⚠` prefix for advisories

Every advisory message starts with `⚠  spwf:` and is prefixed/suffixed
with newlines for legibility:

```bash
printf '\n⚠  spwf: {message}\n\n' >&2
```

`stderr` (not stdout) so the advisory doesn't pollute tool output. The
`⚠` prefix gives users a visual signal.

### 4. Naming

`{action}-{domain}-{modifier}.sh` where:
- `{action}` is the verb (check, validate, nudge, …)
- `{domain}` is the target (frontmatter, version, comment, …)
- `{modifier}` is optional tone (nudge, warn, …)

Examples:
- `plugin-version-check.sh` — check the version on plugin.json
- `todo-frontmatter-check.sh` — check the frontmatter on todo files
- `openspec-validate-nudge.sh` — nudge to run validate
- `tracker-comment-nudge.sh` — nudge to use the comment skill

### 5. Hook scripts are bash; complex reasoning is a skill

Hooks are lightweight gates — they apply quick heuristics in shell.
Anything that needs the model's reasoning (audience classification,
content rewriting, multi-step workflows) belongs in a skill. The hook's
role is to detect a condition cheaply and nudge the user toward the
relevant skill.

## Event types in use

The plugin uses three events:

- **`Stop`** — fires when the model stops (end of turn). Read-only by
  nature.
- **`PostToolUse`** — fires after a tool returns. Sees the tool input
  and result; useful for "was that intentional?" checks.
- **`PreToolUse`** — fires before a tool is called. Sees the tool input
  but not the result. Useful when you want to warn *before* an
  operation completes (e.g. before posting a comment to a tracker).
  In this plugin, PreToolUse is **advisory-only by convention** —
  same `exit 0` discipline as every other hook.

## Adding a new hook

1. Create `plugins/spwf/hooks/{name}.sh` following the conventions
   above. Make it executable (`chmod +x`).
2. Register it in `hooks.json` under the right event. Use the
   `${CLAUDE_PLUGIN_ROOT}/hooks/{name}.sh` path so it resolves on any
   user's machine.
3. Add a row to the table in this README documenting what it does.
4. If it's the first hook for a new event type, also document the
   event in the "Event types in use" section above.
5. Test by simulating the event JSON via stdin:
   ```bash
   echo '{"tool_name": "...", "tool_input": {...}}' | bash hooks/{name}.sh
   ```

## Prerequisites

- `git` must be in `PATH` (used by `uncommitted-changes.sh`)
- `jq` or `python3` (one is required for hooks that parse tool-event
  JSON; both-missing produces a named warning and skips)
- `grep` (universal; used by `tracker-comment-nudge.sh` for heuristic
  counts)
