---
name: workflow-lint
description: Cross-cutting coherence auditor — checks step↔skill coverage, agent coverage, cross-reference validity, stale names, attribution presence, orphaned skills/agents, and diagram↔table consistency across the full golden path. Outputs a P1/P2/P3 prioritised health report.
disable-model-invocation: true
allowed-tools: [Read, Glob, Grep, Bash]
---

# workflow-lint

Audit the coherence of the full golden path. Catch drift before it accumulates.

## What is checked

| Check | Description | Priority |
|---|---|---|
| **Step↔skill coverage** | Every golden path step has a corresponding skill in workflow-core or workflow-tools | P1 |
| **Agent coverage** | Every golden path step has a corresponding agent in workflow-agents | P1 |
| **Cross-reference validity** | All skill/agent name references in SKILL.md bodies, agent bodies, and READMEs resolve to existing files | P1 |
| **Stale names** | No deprecated names (grill-me invocations, plan-signoff, task-to-spec, ship, pr-reviewer, test-creator, test-runner, incremental-implementation, openspec:apply) in active skill/agent bodies | P1 |
| **Attribution presence** | All seeded skills carry the required attribution comment | P2 |
| **Orphaned skills/agents** | Skills or agents not referenced in any README or golden path table | P2 |
| **Diagram↔table consistency** | Workflow diagram in root README matches the golden path table | P2 |
| **disable-model-invocation** | All workflow-core and workflow-tools skills set `disable-model-invocation: true` | P2 |
| **Frontmatter completeness** | All SKILL.md and agent files have required frontmatter fields (name, description) | P3 |

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
