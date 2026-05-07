---
name: close
description: Final-phase orchestrator — wraps the full retrospective then permanently closes the change. Invokes /spwf:retrospective (learn-from-mistakes, spec audit, doc-lint, workflow-lint, optional changelog), then — after explicit confirmation — marks the todo file complete, archives the OpenSpec change, and closes the Jira ticket if one is linked.
disable-model-invocation: true
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash, mcp__atlassian__jira_get_issue, mcp__atlassian__jira_update_issue]
---

# close

Final phase of the SPWorkflow golden path. Retrospect, confirm, then permanently close the change.

```
Step 1 → retrospective     (all 5 parts)
Step 2 → confirm closure   (explicit human gate)
Step 3 → mark todo done    (status: complete)
Step 4 → archive OpenSpec  (opsx:archive)
Step 5 → close Jira ticket (if linked)
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
  2. openspec/changes/{id}/  → archived (opsx:archive)
  3. {PROJ-123}              → Jira status: Done   ← only if ticket is linked

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

## Step 5 — Archive OpenSpec change

Run:

```bash
openspec archive --change "{change-id}"
```

If the command fails, report the error and stop — do not proceed to Step 6 until this succeeds (a failed archive leaves artefacts in place, which is recoverable).

---

## Step 6 — Close Jira ticket

Only run this step if the todo file has a `ticket:` field.

Fetch the current issue to verify it exists and check its current status:

```
mcp__atlassian__jira_get_issue(issue_key: "{ticket}")
```

Transition the issue to **Done** using:

```
mcp__atlassian__jira_update_issue(issue_key: "{ticket}", fields: {status transition to Done})
```

Note: Jira transitions vary by project workflow. Use the transition name "Done" or "Closed" — if neither exists, report the available transitions and ask the user which to use.

If no `ticket:` is present: skip this step silently (report "No Jira ticket linked — skipping").

---

## Report

```
## Closed: {change-id}

### Retrospective
{brief summary of retrospective findings — learnings count, drift items, doc issues, workflow issues}

### Closure
✓ todo/{slug}.md              → status: complete
✓ openspec/changes/{id}/      → archived
{✓ PROJ-123                   → Done     | — No Jira ticket linked}

### Recommended actions
{any unresolved items from retrospective that need follow-up}
```
