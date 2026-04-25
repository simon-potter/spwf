---
# Source: https://github.com/addyosmani/agent-skills — MIT licence
# Adversarial review lenses adapted from: https://skills.sh/poteto/noodle/adversarial-review (poteto/noodle)
name: plan-signoff
description: Phase 2 — Approve plan. Reviews the task list from task-to-spec for quality (atomicity, testability, clarity), then applies three adversarial lenses (Skeptic, Architect, Minimalist) as advisory input for the human reviewer. Quality issues are blocking; adversarial findings are advisory. Presents everything for explicit human go/no-go before building starts.
disable-model-invocation: true
allowed-tools: [Read, Write]
---

# plan-signoff

Review the task list that `task-to-spec` generated. The plan was created by `task-to-spec` — this step does not create or rewrite tasks. It assesses them.

Two layers of review, in order:
1. **Quality check** — blocking issues with atomicity, testability, clarity
2. **Adversarial review** — three lenses that challenge the plan's coherence and scope; advisory, not blocking

The human makes the final call. `grill-me` has already challenged the underlying idea — this step reviews the *plan*, not the idea.

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
Run /workflow-core:task-to-spec first.
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

Apply three lenses to the plan as a whole. Findings from this step are advisory — the human decides whether to act on them. Do not re-litigate the spec or ideation file; `grill-me` has already done that work. Focus on the task list structure and coverage.

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

Mark each finding `ℹ` with the lens name. No suggested fix required — these are prompts for the human reviewer, not prescriptions.

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

---

Approve? → /workflow-core:build
Revise tasks → edit openspec/changes/{change-id}/tasks.md, re-run /workflow-core:plan-signoff
```

If no quality issues and no adversarial findings worth surfacing:

```
## Approve plan: {change-id}

{X} tasks — quality checks passed, no adversarial concerns.

✓ Ready to build.

Run: /workflow-core:build
```

## Step 6: Stop and wait

Stop after presenting. The human decides: approve, revise, or return to spec.
