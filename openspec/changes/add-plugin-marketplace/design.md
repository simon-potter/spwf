# Design: add-plugin-marketplace

> **Authoritative Reference:** [`todo/Marketplace_setup.md`](../../../todo/Marketplace_setup.md) contains all resolved decisions, the full skill inventory table, attribution policy, and ideation file format. This document captures the architectural decisions and their rationale.

## Context

The Claude Code plugin system allows skills and agents to be installed from a GitHub repo via `/plugin marketplace add`. This design governs how Simon's extended workflow is packaged for distribution.

## Goals

- One command to get the full workflow on a new machine
- All seven canonical phases covered, plus extended phases (capture, challenge, retrospect)
- Skills are attribution-honest — seeded content from agent-skills is credited per SKILL.md
- Self-maintaining — `/agent-optimise` and `/doc-lint` keep the tooling itself healthy

## Non-Goals

- Deployment automation — `/ship` creates a PR only; CI/CD owns actual deployment
- Full Jira/OpenSpec pipeline — `issue-to-task` stops at a lightweight ideation file; OpenSpec generation is a separate step (`task-to-spec`)
- Public distribution (for now) — private to Academy-Plus org

---

## Decisions

### 1. Two skill plugins, not one

**Decision:** `workflow-core` (seven canonical phases) and `workflow-tools` (extended phases + cross-cutting) are separate installable plugins.

**Rationale:** Team members may want only the canonical phases without Simon-specific tooling. Separate plugins allow selective installation. The agents plugin is also separate for the same reason.

**Alternative rejected:** Single `workflow` plugin — would bundle everything and prevent selective adoption.

---

### 2. agent-skills content seeded into workflow-core, not a separate plugin

**Decision:** The five `workflow-core` phase skills that derive from `addyosmani/agent-skills` (MIT) live directly in `workflow-core` as Simon's extended versions, with attribution in SKILL.md frontmatter.

**Rationale:** These are the canonical workflow phases — plan, build, test, simplify, ship. Putting them in a separate `workflow-reference` plugin creates a confusing two-plugin install just to get one coherent workflow. Attribution is handled per-file, not per-plugin.

**Attribution format (in each seeded SKILL.md):**
```
# Source: https://github.com/addyosmani/agent-skills — MIT licence
```

---

### 3. Extended workflow structure

The workflow extends the agent-skills seven phases with pre and post steps:

```
Capture ─► Challenge ─► Spec ─► Plan sign-off ─► Build ─► Test ─► Review ─► Simplify ─► Ship ─► Retrospective
  (pre)      (gate)     (1)          (2)           (3)     (4)     (5)       (6)         (7)      (post)
```

**Capture** (pre-phase): `issue-to-task` (from Jira) or `new-task` (from scratch) — both produce a lightweight ideation file at `todo/{slug}.md`.

**Challenge** (gate): `grill-me` — reads the ideation file, interviews relentlessly until gaps are resolved. No agent-skills equivalent. This gate is required before `/spec`.

**Retrospective** (post-ship): `learn-from-mistakes` — reads recent commit history and extracts learnings while context is still warm.

---

### 4. Ideation file is the pre-OpenSpec artefact

**Decision:** `issue-to-task` and `new-task` both produce a lightweight `todo/{slug}.md` with YAML frontmatter and four sections (Context, What we know, Open questions, Rough scope). They do NOT produce OpenSpec output.

**Rationale:** OpenSpec is the formalisation step. Forcing it before the idea has been challenged (`/grill-me`) and refined results in premature structure. The ideation file is intentionally lightweight — it holds the raw thinking until it is ready to be formalised.

**Ideation file format:**
```markdown
---
source: jira | scratch
ticket: PROJ-123          # omit if scratch
created: YYYY-MM-DD
status: ideation
---

# {Title}

## Context
## What we know
## Open questions
## Rough scope
```

---

### 5. Plan format = OpenSpec tasks.md

**Decision:** The canonical plan is `openspec/changes/{change-id}/tasks.md` produced by `approve-plan`. `/build` finds the first unchecked item in it.

**Rationale:** OpenSpec is already the spec layer. Keeping the task list there means one place to look for both the spec and the plan.

---

### 6. disable-model-invocation on all phase skills

**Decision:** All workflow phase skills set `disable-model-invocation: true`. The user must explicitly invoke them.

**Rationale:** Workflow gates are intentional checkpoints, not suggestions. A skill that auto-triggers at the wrong moment breaks the discipline the workflow is designed to enforce.

---

### 7. pr-reviewer requires explicit PR reference

**Decision:** `pr-reviewer` requires a PR number or URL as `$ARGUMENTS`. It halts with a usage hint if no argument is given. It never creates PRs.

**Rationale:** Automatic PR creation by a review skill would be dangerous (wrong base branch, wrong title). The reviewer's job is to read and report, not to act.

---

### 8. agent-optimise always audits both scopes

**Decision:** `agent-optimise` always audits both the project-level `.claude/` and the personal `~/.claude/` — no flag or argument needed.

**Rationale:** Agent bloat accumulates across both locations. Seeing only one scope produces a misleading picture. The combined surface is always small enough to audit in one pass.

---

### 9. pr-create = PR creation only

**Decision:** `pr-create` creates a pull request via `gh pr create`. It does not trigger, wait for, or describe deployment steps.

**Rationale:** CI/CD owns deployment. Mixing deployment steps into a skill creates a false sense of completeness and obscures what actually happened. The PR is the atomic artefact the skill can guarantee.

---

### 10. OpenSpec is a documented prerequisite, not auto-installed

**Decision:** `task-to-spec` checks for the `openspec/` directory and halts with a clear message if it is missing. It does not run `openspec init`.

**Rationale:** Auto-initialisation could clobber an existing openspec setup in a parent directory. The prerequisite is simple to satisfy; the error message includes the exact command to run.

---

### 11. Two-tier skill architecture: atomics and orchestrators

**Decision:** `workflow-core` uses two named tiers within the single `skills/` directory:

- **Atomic skills** — single-responsibility capabilities with descriptive names. Can be invoked directly or composed by orchestrators. Examples: `incremental-implementation`, `test-runner`, `debug-recovery`, `test-creator`.
- **Orchestrator skills** — user-facing entry points with short action names. Explicitly compose one or more atomic skills in their body. Examples: `build`, `test`.

Both tiers use SKILL.md format. No separate `commands/` directory is used.

**Rationale:** The `addyosmani/agent-skills` reference repo separates orchestration (`.claude/commands/`) from atomic capabilities (`skills/`). However, Claude Code and Codex are unifying slash commands into the skills system (SKILL.md format), making the `commands/` directory a deprecated path. This decision achieves the same separation of concerns — orchestrators compose atomics — without building on the deprecated layer.

An orchestrator skill's body explicitly names the atomic skills it invokes:

```markdown
To implement the current task:
1. Invoke `workflow-core:incremental-implementation` — finds the first unchecked task,
   implements it, marks it complete.
2. Next, run `workflow-core:test-creator` to write behaviour tests for the new code.
3. If tests fail, invoke `workflow-core:debug-recovery`.
```

**What composes vs what stays atomic:**

| Skill | Tier | Composes |
|---|---|---|
| `spec` | Atomic | — single OpenSpec action |
| `approve-plan` | Atomic | — single review + sign-off action |
| `write-tests` | Atomic | — |
| `run-tests` | Atomic | — |
| `debug-recovery` | Atomic | — |
| `pr-review` | Atomic | — single review action |
| `simplify` | Atomic | — single scan action |
| `pr-create` | Atomic | — single PR creation |
| `build` | **Orchestrator** | `write-tests` (Red) → `opsx:apply` (Green) → `run-tests` (Verify) → `debug-recovery` on failure → `opsx:verify` (spec sign-off) → recommends `simplify` |

**Why not all stages are orchestrators:** Only `build` and `test` have meaningful composition — they sequence two sub-steps and have a conditional failure branch. All other stages are single-responsibility actions and need no decomposition.

**Alternative rejected:** Monolithic skills per stage (all logic in one SKILL.md, named after the command). This conflates the user-facing interface with the implementation, prevents reuse of `test-runner` across `build` and `test`, and makes the `build` stage unable to conditionally branch to `debug-recovery` cleanly.

---

### 12. `build` orchestrates the full Red-Green-Refactor cycle; `write-tests` is its first composed step

**Decision:** `build` invokes `write-tests` (Red: write failing tests) first, then `opsx:apply` (Green: make them pass), then `run-tests` (Verify: confirm full suite green), then `debug-recovery` on failure, then `opsx:verify` (spec sign-off). It recommends `simplify` (Refactor) on completion.

**Rationale:** Red-Green-Refactor is the canonical TDD discipline. Tests must be written before implementation — not after — so the contract is defined before the code. `build` enforces this order: you cannot reach the Green phase without first completing Red. The `disable-model-invocation: true` constraint (Decision 6) still applies — the user explicitly invokes `/workflow-core:build` as the entry point, and the orchestrator directs the sub-steps declaratively. The user retains the option to invoke each atomic step individually for granular control.

**Composition in `build/SKILL.md`:**
```
Red          → write-tests      (write failing tests for the current task)
Green        → opsx:apply       (implement only what makes those tests pass)
Verify       → run-tests        (confirm the full suite is green)
Spec sign-off → opsx:verify     (check implementation against artefacts)
Refactor     → recommend simplify (clean up with tests as a safety net)
```

---

## Risks and Trade-offs

| Risk | Mitigation |
|---|---|
| Plugin format undocumented — marketplace.json/plugin.json schema may change | Keep skills as readable SKILL.md files; format changes are low-cost to adapt |
| agent-skills seeded content may drift from source | Attribution comment in SKILL.md makes provenance clear; upstreaming is optional |
| Private repo limits team discoverability | README in relevant project repos can link to install instructions |
| Personal skill originals in `~/.claude` may conflict with installed plugin versions | Phase 5 migration plan: keep originals until validated, then archive |

---

## Key File Formats

See `todo/Marketplace_setup.md → Quick Reference` for the canonical format reference. Reproduced here for navigation:

- **marketplace.json** — `.claude-plugin/marketplace.json` at repo root
- **plugin.json** — `<plugin-dir>/.claude-plugin/plugin.json`
- **SKILL.md** — `<plugin-dir>/skills/<skill-name>/SKILL.md` — YAML frontmatter + markdown body
- **Agent file** — `<plugin-dir>/agents/<agent-name>.md` — YAML frontmatter + system prompt
- **Ideation file** — `todo/{slug}.md` — YAML frontmatter + four sections
