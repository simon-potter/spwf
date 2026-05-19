---
name: tracker-backend
description: Internal Beads tracker-dispatch backend for spwf-beadsify. Implements the dispatch operations (create_issue, get_issue, add_comment, transition) by invoking the bd CLI. Routed to by plugins/spwf/skills/_shared/tracker-dispatch.md when .spwf/tracker.yaml sets tracker: beads. Never user-invoked — disable-model-invocation prevents accidental activation; users always call /spwf:capture, /spwf:tracker-comment, /spwf:close which dispatch through tracker-dispatch.md.
disable-model-invocation: true
allowed-tools: [Read, Bash]
---

# tracker-backend (spwf-beadsify)

Internal dispatch module. Implements the tracker-dispatch contract using the [Beads](https://github.com/gastownhall/beads) (`bd`) CLI as the in-repo tracker for this project.

> This skill is **never invoked directly by the user**. `disable-model-invocation: true` is set so the model cannot auto-activate it. Routing happens via `plugins/spwf/skills/_shared/tracker-dispatch.md` when `.spwf/tracker.yaml` contains `tracker: beads`.

## Operations declared

This backend implements the four dispatch operations the spwf core skills need (capture / tracker-comment / close). Each is a thin wrapper over one `bd` subcommand, with input validation and the safe-invocation pattern from `openspec/changes/add-beadsify-tracker/design.md` § Decision 7 applied verbatim.

| Operation | bd CLI command | Purpose | Notes |
|---|---|---|---|
| `create_issue` | `bd q "<title>"` | Create a new story; return its `<prefix>-<hash>` id | Used by `/spwf:capture`. Title is user input — validated and quoted. |
| `get_issue` | `bd show <id>` | Fetch a story's current state | Used by anything that needs status / dependencies / comments. Id is format-validated. |
| `add_comment` | `bd comment <id> "<text>"` (or stdin) | Append a comment to an existing story | Used by `/spwf:tracker-comment`. Both id and body validated; prefer stdin for multi-line content. |
| `transition` | `bd close <id>` (v1) | Move a story to closed state | Used by `/spwf:close`. Only `close` is supported in v1 — `reopen` and richer transitions are deferred. |

**Out of scope for this skill:** `bd remember`, `bd init`, `bd setup *`, any command that installs Claude Code integration. See `plugins/spwf-beadsify/README.md` § "Forbidden commands" for why.

## Safe invocation pattern (mandatory)

Every `bd` subprocess invocation in this skill MUST follow the rules below. These reproduce Decision 7 from `openspec/changes/add-beadsify-tracker/design.md` so they can be applied without leaving this file:

1. **Always quote substituted variables.** `bd q "$title"`, never `bd q $title`.
2. **Never `eval` / `bash -c` / `sh -c` with substituted user input.** Re-parsing through the shell defeats quoting.
3. **Validate ids against `^[a-z0-9]+(-[a-z0-9]+)+$` before invocation.** Exact match or reject — no cleaning, no normalisation. The pattern is intentionally prefix-agnostic: bd uses the project directory name as the issue prefix by default, so ids look like `<prefix>-<hash>` where `<prefix>` is project-specific (e.g. `spwf-a3f2dd` in this repo, `auth-92ff01` in an "auth" project). The regex requires at least one hyphen and only lowercase alphanumeric+hyphen — shell-injection-safe regardless of prefix.
4. **Prefer stdin for multi-line or special-character content.** `echo "$body" | bd comment "$id" --stdin` rather than inlining `$body` as an arg.
5. **Capture exit codes; fail loudly.** Non-zero from `bd` halts the dispatch operation with bd's stderr surfaced verbatim.

**Shell-portability note:** the bash below runs in whatever interactive shell Claude Code is configured with (commonly bash or zsh). Avoid zsh-readonly variable names when capturing values — most notably **`$status`** (zsh refuses assignment). Use `$rc` for return codes throughout.

## Implementation

> Filled in by tasks 2.5 (preflight `.beads/` check) and 2.6–2.9 (per-operation implementation) of the `add-beadsify-tracker` OpenSpec change.

### Preflight (.beads/ existence check)

Before invoking any dispatch operation, verify that Beads is initialised in this project. Run:

```bash
if [ ! -d "./.beads" ]; then
  cat >&2 <<'EOF'
Error: Beads not initialised in this project.

To fix, run in the project root:

  bd init --skip-agents --skip-hooks --non-interactive

IMPORTANT: do not run plain `bd init`. It writes CLAUDE.md and AGENTS.md
to the project root, creates .claude/settings.json, and registers
SessionStart + PreCompact hooks of Beads' own design — all of which
conflict with SPWorkflow's existing Claude Code integration. The
--skip-agents and --skip-hooks flags prevent this.

After running the safe init, re-run the operation.
EOF
  exit 1
fi
```

If the check fails (non-zero exit), the operation halts immediately and the error reaches the user via tracker-dispatch.md. **Do not auto-initialise** — this is a conscious user decision per `openspec/changes/add-beadsify-tracker/design.md` § "`bd init` safety". No files are modified by this preflight; it is read-only.

### Operation: create_issue

**Inputs:** `title` (string from user — e.g. ideation-file slug, `/spwf:capture`'s captured title)

**Behaviour:** invoke `bd q "$title"` and return the resulting `<prefix>-<hash>` id.

```bash
title="$1"

# Validate: title must be non-empty.
if [ -z "$title" ]; then
  echo "Error: create_issue requires a non-empty title" >&2
  exit 1
fi

# Invoke. Title is passed as a single quoted argument — bd receives it
# verbatim. No shell re-parsing.
id=$(bd q "$title")
rc=$?
if [ "$rc" -ne 0 ]; then
  echo "Error: bd q failed with exit "$rc"" >&2
  exit "$rc"
fi

# Validate the returned id matches Beads' documented format. If bd ever
# changes id shape, we want to fail loudly here rather than propagate
# a malformed id to the caller.
if [[ ! "$id" =~ ^[a-z0-9]+(-[a-z0-9]+)+$ ]]; then
  echo "Error: bd q returned unexpected id format: $id" >&2
  exit 1
fi

echo "$id"
```

### Operation: get_issue

**Inputs:** `id` (string — `<prefix>-<hash>` form)

**Behaviour:** invoke `bd show <id>` and return its stdout. Issue not found is a non-zero bd exit and surfaces verbatim.

```bash
id="$1"

# Validate id format before any subprocess invocation. Decision 7 rule 3:
# exact match or reject — no cleaning.
if [[ ! "$id" =~ ^[a-z0-9]+(-[a-z0-9]+)+$ ]]; then
  echo "Error: invalid bd id format: $id" >&2
  exit 1
fi

bd show "$id"
rc=$?
if [ "$rc" -ne 0 ]; then
  echo "Error: bd show $id failed with exit "$rc"" >&2
  exit "$rc"
fi
```

### Operation: add_comment

**Inputs:** `id` (string — `<prefix>-<hash>` form), `body` (string — may contain newlines, shell metacharacters)

**Behaviour:** invoke `bd comment <id> --stdin` and pipe `body` in. Stdin is used (Decision 7 rule 4) so the body's content cannot accidentally re-enter the shell.

```bash
id="$1"
body="$2"

if [[ ! "$id" =~ ^[a-z0-9]+(-[a-z0-9]+)+$ ]]; then
  echo "Error: invalid bd id format: $id" >&2
  exit 1
fi

if [ -z "$body" ]; then
  echo "Error: add_comment requires a non-empty body" >&2
  exit 1
fi

# Use stdin to avoid any shell-injection surface for $body. printf %s
# prevents trailing newline issues and doesn't interpret escapes inside
# $body. (Compare echo, which on some shells interprets backslash escapes.)
printf '%s' "$body" | bd comment "$id" --stdin
rc=$?
if [ "$rc" -ne 0 ]; then
  echo "Error: bd comment $id --stdin failed with exit "$rc"" >&2
  exit "$rc"
fi
```

### Operation: transition

**Inputs:** `id` (string — `<prefix>-<hash>` form), `transition` (string — `close` in v1; any other value is rejected)

**Behaviour:** invoke `bd close <id>`. v1 supports `close` only; `reopen` and richer transitions are deferred (no v1 success criterion requires them).

```bash
id="$1"
transition="$2"

if [[ ! "$id" =~ ^[a-z0-9]+(-[a-z0-9]+)+$ ]]; then
  echo "Error: invalid bd id format: $id" >&2
  exit 1
fi

case "$transition" in
  close)
    bd close "$id"
    rc=$?
    if [ "$rc" -ne 0 ]; then
      echo "Error: bd close $id failed with exit $rc" >&2
      exit "$rc"
    fi
    ;;
  '')
    echo "Error: transition operation requires a transition name (e.g. 'close')" >&2
    exit 1
    ;;
  *)
    echo "Error: unsupported transition '$transition' (v1 supports 'close' only)" >&2
    exit 1
    ;;
esac
```
