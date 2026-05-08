---
name: close
description: Final-phase orchestrator — wraps the full retrospective then permanently closes the change. Invokes /spwf:retrospective (learn-from-mistakes, spec audit, doc-lint, workflow-lint, recap teaching summary, optional changelog), then — after explicit confirmation — marks the todo file complete, archives the OpenSpec change, and transitions the linked issue tracker ticket to its done state (YouTrack default; Jira and others supported).
disable-model-invocation: true
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash, mcp__youtrack__*, mcp__atlassian__jira_get_issue, mcp__atlassian__jira_update_issue]
---

# close

Final phase of the SPWorkflow golden path. Retrospect, confirm, then permanently close the change.

```
Step 1 → retrospective       (all 5 parts)
Step 2 → confirm closure     (explicit human gate)
Step 3 → mark todo done      (status: complete)
Step 4 → commit changes      (git commit with confirmation)
Step 5 → archive OpenSpec    (opsx:archive)
Step 6 → close tracker ticket (if linked — dispatches per .spwf/tracker.yaml)
```

---

## Step 1 — Identify the change

Read `$ARGUMENTS`. Accept any of:

| Input | Resolution |
|---|---|
| `todo/BUG-{slug}.md` or `todo/{slug}.md` | Use this todo file directly |
| OpenSpec change id (e.g. `add-plugin-marketplace`) | Derive todo file from context or ask |
| Empty | Detect from context (most recently completed change) or ask |

Read the identified todo file. Extract:
- `status:` field
- `ticket:` field (if present)
- The title

If `status` is already `complete`, report: "This change is already closed." and stop.

Confirm the OpenSpec change id: check `openspec/changes/` for a directory matching the change. If `$ARGUMENTS` provided a change id use it directly. If derived from the todo file, ask the user to confirm the mapping before proceeding.

---

## Step 2 — Run retrospective

Invoke `spwf:retrospective` with the change id.

All five parts run as normal:
1. learn-from-mistakes
2. change spec audit
3. doc-lint
4. workflow-lint
5. changelog (asks user — only if preparing a release)

Wait for retrospective to complete before proceeding.

---

## Step 3 — Closure confirmation gate

Present a summary of what will be permanently changed, then ask for a single yes/no:

```
Retrospective complete. Ready to close this change permanently.

The following will happen:
  1. todo/{slug}.md          → status: complete
  2. git commit              → "chore: close {change-id}" (staged files + todo update)
  3. openspec/changes/{id}/  → archived (opsx:archive)
  4. {ACAD-42}               → tracker state: {done_state}   ← only if ticket is linked

Type "yes" to close, anything else to stop.
```

If the user does not say "yes" (or "y"): stop and report "Closure cancelled — nothing was changed."

---

## Step 4 — Mark todo complete

Edit the todo file. Change the frontmatter field:

```
status: ideation  →  status: complete
```

or whatever the current value is. Set it to `complete`. Do not touch any other frontmatter fields or body content.

---

## Step 5 — Commit closure changes

Run `git status` to show the user what will be committed (includes the todo file update and any retrospective spec/doc edits). Then commit:

```bash
git commit -m "chore: close {change-id}"
```

If there is nothing to commit (`git status` shows a clean tree), skip silently and note "Nothing to commit."

Do not push — that remains the user's explicit action.

---

## Step 6 — Archive OpenSpec change

Run:

```bash
openspec archive --change "{change-id}"
```

If the command fails, report the error and stop — do not proceed to Step 6 until this succeeds (a failed archive leaves artefacts in place, which is recoverable).

---

## Step 7 — Close tracker ticket

Decision tree:

| `ticket:` in frontmatter? | tracker MCP configured? | `tracker: none` set? | Action |
|---|---|---|---|
| no | — | — | Skip silently (no tracker action implied). Report "No tracker ticket linked." |
| yes | — | yes | Skip silently (user has opted out). |
| yes | no | no | **Fail fast.** "Cannot close `{ticket}` — no issue tracker MCP configured. Configure YouTrack or Atlassian MCP, or set `tracker: none` in `.spwf/tracker.yaml`." |
| yes | yes | no | Run the transition. |

Resolve the active tracker and `done_state` from `.spwf/tracker.yaml` (default
YouTrack, default state `Done`). Dispatch via `_shared/tracker-dispatch.md`.

Verify the issue exists, then apply the done state:

```
get_issue(id="{ticket}")
set_state(id="{ticket}", state="{done_state}")
```

Tracker-specific notes:

- **YouTrack** uses field-set commands (`State {done_state}`); the dispatch handles this.
- **Jira** uses named transitions; `done_state` should match an available transition
  ("Done" or "Closed" typically). If neither matches, report the available transitions
  and ask the user which to use.

If the MCP call fails for any reason (auth, network, unknown state): report the error
verbatim and stop. Do not mark the closure as complete in the report — leave the
ticket-transition row as failed.

---

## Report

```
## Closed: {change-id}

### Retrospective
{brief summary of retrospective findings — learnings count, drift items, doc issues, workflow issues}

### Closure
✓ todo/{slug}.md              → status: complete
✓ git commit                  → chore: close {change-id}
✓ openspec/changes/{id}/      → archived
{✓ {ticket}                   → {done_state}     | — No tracker ticket linked}

### Recommended actions
{any unresolved items from retrospective that need follow-up}
```
