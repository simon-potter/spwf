---
# Source: https://github.com/addyosmani/agent-skills — MIT licence
# Adversarial review lenses adapted from: https://skills.sh/poteto/noodle/adversarial-review (poteto/noodle)
name: approve-plan
description: Phase 2 — Approve plan. Reviews the task list from spec for quality (atomicity, testability, clarity), then applies four adversarial lenses (Skeptic, Architect, Minimalist, Security) as advisory input for the human reviewer. Quality issues are blocking; adversarial findings are advisory. Security lens identifies tasks touching auth, billing, user input, or secrets so the builder has explicit awareness before writing those tasks. Presents everything for explicit human go/no-go before building starts.
disable-model-invocation: true
allowed-tools: [Read, Write]
---

# approve-plan

Review the task list that `spec` generated. The plan was created by `spec` — this step does not create or rewrite tasks. It assesses them.

Two layers of review, in order:
1. **Quality check** — blocking issues with atomicity, testability, clarity
2. **Adversarial review** — three lenses that challenge the plan's coherence and scope; advisory, not blocking

The human makes the final call. `challenge` has already challenged the underlying idea — this step reviews the *plan*, not the idea.

---

## Step 1: Identify the active change

If `$ARGUMENTS` contains a change-id, use it. Otherwise:

```bash
openspec list --json
```

If multiple active changes exist, list them and ask which to review.

## Step 2: Read the artefacts

Read:
- `openspec/changes/{change-id}/tasks.md`
- `openspec/changes/{change-id}/proposal.md` — the intent and success criteria

If `tasks.md` does not exist, halt:

```
No tasks.md found for change: {change-id}
Run /spwf:spec first.
```

---

## Step 3: Quality check (blocking)

For each task, check:

| Dimension | Good | Flag |
|---|---|---|
| **Atomic** | One outcome per task | Task contains "and" implying two things |
| **Independently testable** | Verifiable without running the full system | Completion only visible when several tasks are done |
| **Unambiguous** | Clear deliverable, no interpretation | Vague verbs: "handle", "update", "improve" with no object |
| **Appropriately sized** | Completable in one focused session | Multiple phases compressed into one task |
| **Well-ordered** | No uncompleted dependency above it | Implicit dependency not reflected in ordering |

Mark each issue `⚠` with a specific suggested fix. These are the only findings that warrant holding up approval.

---

## Step 4: Adversarial review (advisory)

Apply three lenses to the plan as a whole. Findings from this step are advisory — the human decides whether to act on them. Do not re-litigate the spec or ideation file; `challenge` has already done that work. Focus on the task list structure and coverage.

### Skeptic — will this plan actually deliver the goal?

- Do the tasks collectively fulfil the success criteria in `proposal.md`?
- Is anything needed for the goal that appears in no task?
- Could any task complete successfully while the real problem remains unfixed?

### Architect — does the plan hold together structurally?

- Are there hidden dependencies between tasks that the ordering doesn't reflect?
- Does each phase leave the system in a coherent, deployable state?
- Are cross-cutting concerns (error handling, auth, migrations, config) covered somewhere, or assumed to happen "around" the tasks?

### Minimalist — is there anything that shouldn't be here?

- Can any tasks be removed without affecting the success criteria?
- Is any task gold-plating or scope creep beyond what the proposal requires?
- Are any tasks duplicates of each other under different names?

### Security — which tasks need extra care during build?

Identify any task that touches a security-sensitive surface. Flag it as `⚠ Security` with the specific surface. This is not a blocker — it is advance notice so the builder agent and human reviewer know which tasks warrant closer attention.

Security-sensitive surfaces:
- Authentication or authorisation logic (login, session, tokens, permissions, roles)
- Payment or billing flows
- User-supplied input entering a query, shell command, or file path
- Secrets, credentials, API keys, or environment variables
- File system access outside of the project directory
- External API calls where response data enters the codebase
- Schema changes on tables holding personal data (PII, health, financial)
- Cryptography or hashing

Mark each finding `⚠ Security: {surface}`. No suggested fix — the note is a heads-up, not a prescription. A task with no security surfaces needs no entry.

If any security-sensitive tasks are identified, add a reminder at the bottom of the security section:
```
Before merging, consider running /trailofbits:semgrep for a thorough SAST review
against curated Trail of Bits rulesets (SARIF output, Important-only filtering).
```

Mark each finding `ℹ` with the lens name for Skeptic/Architect/Minimalist. No suggested fix required — these are prompts for the human reviewer, not prescriptions.

---

## Step 5: Present for sign-off

```
## Approve plan: {change-id}

{X} tasks across {Y} phases

### Phase 1 — {name}
  [ ] 1.1 {task}
  [ ] 1.2 {task}  ⚠ vague — "update" with no specified target
  [ ] 1.3 {task}

### Phase 2 — {name}
  [ ] 2.1 {task}
  [ ] 2.2 {task}

---

### Quality issues (resolve before building)

- 1.2: {specific issue and suggested fix}

### Adversarial findings (advisory)

- ℹ Skeptic: {finding}
- ℹ Architect: {finding}
- ℹ Minimalist: {finding}

### Security-sensitive tasks (heads-up for builder)

- ⚠ Security: 2.1 — user input enters SQL query (injection surface)
- ⚠ Security: 3.2 — adds environment variable for external API key

---

Approve? → /spwf:build
Revise tasks → edit openspec/changes/{change-id}/tasks.md, re-run /spwf:approve-plan
```

If no quality issues and no adversarial findings worth surfacing and no security-sensitive tasks:

```
## Approve plan: {change-id}

{X} tasks — quality checks passed, no adversarial concerns, no security-sensitive surfaces.

✓ Ready to build.

Run: /spwf:build
```

## Step 6: Stop and wait

Stop after presenting. The human decides: approve, revise, or return to spec.
