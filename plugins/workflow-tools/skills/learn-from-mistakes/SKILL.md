---
# Renamed from: ~/.claude/skills/commits-to-knowledge/ — original by Simon Potter. Functionally identical; user-facing name changed.
name: learn-from-mistakes
description: Post-ship — Extract learnings from recent commit history and transfer them to project documentation. Based on the "strike while it's hot" principle — knowledge in commit messages should be preserved before context fades. Use after shipping or completing a significant branch.
disable-model-invocation: true
allowed-tools: [Read, Glob, Grep, Bash, Edit, Write]
---

# learn-from-mistakes

Extract learnings from commit history and transfer them to project documentation. Knowledge captured in commit messages should be preserved in long-term docs before context fades.

## Usage

```
/workflow-tools:learn-from-mistakes [base-branch]
```

`base-branch` — the branch to compare against (default: `main`)

## Step 1: Identify commit range

```bash
MERGE_BASE=$(git merge-base HEAD main)
git log --oneline $MERGE_BASE..HEAD
git log --stat $MERGE_BASE..HEAD
```

If on the base branch, compare against the last 10 commits or ask for a range.

## Step 2: Extract commit content

```bash
git log --format="=== COMMIT %h ===\n%B\n" $MERGE_BASE..HEAD
git log --name-status $MERGE_BASE..HEAD
```

## Step 3: Analyse for knowledge

For each commit, extract:

**Issue patterns** — problems discovered and fixed:
- Permission issues, configuration errors, integration problems
- Race conditions, timing issues, edge cases

**Root causes** — why the issue existed

**Solutions** — what fixed it (specific commands, config changes, code patterns)

**Operational learnings** — things that help run the system

**Standards identified** — patterns that should be applied broadly

Skip trivial changes: "fix typo", "update version", formatting.

## Step 4: Categorise by documentation target

Group extracted knowledge by where it belongs:

| Category | Target |
|---|---|
| Operational procedures | `docs/operations/runbook.md` |
| Troubleshooting patterns | `docs/operations/troubleshooting/{topic}-gotchas.md` |
| Deployment issues | `docs/deployment/guide.md` |
| Architecture decisions | `docs/architecture/overview.md` |
| Coding standards | `docs/engineering/standards.md` |

Create a `{topic}-gotchas.md` file when multiple commits address the same non-obvious area.

## Step 5: Check existing documentation

Before writing, read the relevant existing docs to:
- Avoid duplicating content already documented
- Find the right insertion point
- Match existing style

## Step 6: Update or create documentation

**Updating:** Use Edit tool to add new sections. Maintain existing structure.

**Creating:** Only create if there is substantial content that doesn't fit elsewhere. Include a clear purpose statement at the top.

## Step 7: Report

```
## Knowledge Extracted from Commits

### Commits Analysed
- {hash}: {subject}
...

### Knowledge Transferred

**Updated: {file}**
- Added: "{section name}"

**Created: {file}**
- New file covering: {topic}

### Not Documented (manual review needed)
- {commit}: {reason — e.g., trivial change, no extractable knowledge}
```
