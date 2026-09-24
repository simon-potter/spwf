---
name: workflow-lint
description: Cross-cutting coherence auditor — checks step↔skill coverage, agent coverage, cross-reference validity, stale names, attribution presence, orphaned skills/agents, and diagram↔table consistency across the full golden path. Outputs a P1/P2/P3 prioritised health report. Called as a step by /spwf:retrospective (Part 4) and the retrospector agent, which is why Claude may invoke it. Do not start it unprompted: run it standalone only when the user asks.
allowed-tools: [Read, Glob, Grep, Bash]
---

# workflow-lint

Audit the coherence of the full golden path. Catch drift before it accumulates.

## What is checked

| Check | Description | Priority |
|---|---|---|
| **Step↔skill coverage** | Every golden path step has a corresponding skill in the spwf plugin | P1 |
| **Agent coverage** | Every golden path step has a corresponding agent in the spwf-agents plugin, unless exempt (see below) | P1 |
| **Cross-reference validity** | All skill/agent name references in SKILL.md bodies, agent bodies, and READMEs resolve to existing files | P1 |
| **Stale names** | No deprecated names (grill-me invocations, plan-signoff, task-to-spec, ship, pr-reviewer, test-creator, test-runner, incremental-implementation, openspec:apply) in active skill/agent bodies | P1 |
| **Successor handoff** | Every phase orchestrator skill names its successor phase in its terminal output (e.g. `pr-create` points at `close`) so an agent following the flow does not stop early | P2 |
| **Attribution presence** | All seeded skills carry the required attribution comment | P2 |
| **Orphaned skills/agents** | Skills or agents not referenced in any README or golden path table | P2 |
| **Diagram↔table consistency** | Workflow diagram in root README matches the golden path table | P2 |
| **Blocked invocation** | No skill or agent tells Claude to invoke (or an agent to preload) a skill that sets `disable-model-invocation: true`. Claude Code blocks that call, and the calling flow stops partway through | P1 |
| **Invocation policy** | Each skill's `disable-model-invocation` setting matches its role (see below) | P2 |
| **Frontmatter completeness** | All SKILL.md and agent files have required frontmatter fields (name, description) | P3 |

### Exemption from Agent coverage — non-blocking teaching steps

A step is exempt when **all** of the following hold:

1. It is non-blocking — it prints, may offer a skippable prompt, and returns
   without gating the next step.
2. Its output is prose addressed to the developer, not a decision, artefact or
   dispatch of work.
3. It neither edits code nor determines what happens next.

Currently exempt: **`brief`** and **`wfstatus`**.

**Why this is a real exemption and not a backlog excuse.** A subagent exists to
keep expensive context out of the main session. A teaching step's entire product
*is* the text the developer reads in the main session — routing it through a
subagent means the explanation either lands in a context nobody sees, or comes
back compressed to a summary, which is the one thing a brief must not be. The
agent would subtract capability rather than isolate cost.

`wfstatus` is exempt on the same grounds. It reads git state, OpenSpec changes and the
todo backlog, prints a dashboard, and returns; it gates nothing and decides nothing — the
suggested next action is a suggestion the developer acts on or ignores. Routing it through a
subagent would put the orienting picture in a context the developer never sees, which is the
one thing an orientation step must not do.

Contrast `enrich`, also optional and also skippable, which **is** agented: it
reads widely, generates and discards variations, and returns a decision written
back into the artefact. That is work worth isolating. `brief` reads four files
already in context and prints.

Do not report an exempt step as a P1. Report a step that *claims* exemption while
failing any of the three conditions — particularly one that has started blocking.

### Invocation policy — who may start a skill

`disable-model-invocation: true` means **only the user** can start a skill.
Claude Code blocks the Skill tool call and tells Claude not to reproduce the steps
another way. Subagents cannot preload such skills either. So the flag belongs on
skills with side effects whose timing the user should control, and nowhere else:

| Role | Flag | Examples |
|---|---|---|
| Entry point that commits, pushes, branches, moves commits or changes the tracker | `true` | `capture`, `spec`, `approve-plan`, `build`, `simplify`, `pr-create`, `pr-review`, `address-review`, `close`, `branch-rescue`, `pause` |
| Step called by another skill or agent | **absent** | `retrospective`, `learn-from-mistakes`, `doc-lint`, `workflow-lint`, `recap`, `understand`, `changelog`, `write-tests`, `run-tests`, `debug-recovery`, `enrich`, `php-code-quality-reviewer`, `php-code-simplifier`, `spwf-beadsify:tracker-backend` |

A skill without the flag says who calls it in its description, and says not to
start it unprompted.

**How to check Blocked invocation.** List the skills whose frontmatter sets
`disable-model-invocation: true`. Then search every SKILL.md body and agent file
for instructions to invoke, delegate to, or preload one of them (`Invoke
\`spwf:X\``, `Skill(spwf:X)`, `delegate to /spwf:X`, `skills: [X]`). A
recommendation to the **user** ("Run `/spwf:X`", "Suggested next step:
`/spwf:X`") is fine, because the user can run it. An instruction for Claude or a
subagent to run it is a P1. Fix it by either:
- removing the flag from the callee, if it has no side effects that need the
  user's timing, or
- having the caller follow the shared `_shared/*.md` procedure directly, as
  `pr-create` does with `branch-management.md` §4 instead of calling
  `branch-rescue`.

---

## Step 1: Discover all skills and agents

```bash
find plugins/ -name "SKILL.md" | sort
find plugins/ -name "*.md" -path "*/agents/*" | sort
```

Build an inventory: skill name → file path, agent name → file path.

---

## Step 2: Read the golden path

Read `README.md` to extract:
- The workflow diagram
- The golden path table (step → command → invokes)
- The "What's included" tables for each plugin

---

## Step 3: Run each check

For each check in the table above, scan the relevant files. Collect findings with:
- **P1** — Golden path is broken or misleading; must fix before next change
- **P2** — Drift present; should fix in the next cleanup pass
- **P3** — Cosmetic or completeness issue; fix when convenient

---

## Step 4: Report

```markdown
## workflow-lint report

### P1 — Must fix

- {finding}: {file or location} — {what is wrong and what it should be}

### P2 — Should fix

- {finding}: {file or location} — {description}

### P3 — Nice to have

- {finding}: {file or location} — {description}

### Clean checks

- {check name}: ✓
```

If no findings:

```
✓ Golden path is coherent. No issues found.
```
