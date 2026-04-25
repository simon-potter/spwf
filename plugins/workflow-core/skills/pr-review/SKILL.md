---
# Adapted from: https://github.com/wshobson/agents — skill: code-review-excellence (via npx skills add https://github.com/wshobson/agents --skill code-review-excellence). Extended with gh pr view/diff and PR-specific structure.
name: pr-review
description: Phase 5 — PR Review. Fetch and review a specific PR using gh pr view and gh pr diff. Produces a structured review report. Requires a PR number or URL as the argument. Does not create PRs. Use when you have a PR open and want a structured review before merge.
disable-model-invocation: true
allowed-tools: [Read, Bash]
---

# pr-review

Fetch and review a pull request. Produce a structured review report. Does not create PRs.

## Step 0: Require a PR reference

`$ARGUMENTS` must contain a PR number or URL.

If `$ARGUMENTS` is empty, halt:

```
Usage: /workflow-core:pr-review <PR number or URL>

Examples:
  /workflow-core:pr-review 42
  /workflow-core:pr-review https://github.com/org/repo/pull/42
```

## Step 1: Fetch PR data

```bash
gh pr view $ARGUMENTS --json number,title,body,baseRefName,headRefName,state,author,additions,deletions,changedFiles
gh pr diff $ARGUMENTS
```

If the `gh` command fails, report the error and stop.

## Step 2: Context gathering

Before reviewing code:

1. Read the PR description — understand the stated intent
2. Note the base and head branches
3. Check PR size: if additions + deletions > 400, note this
4. Read any linked issues mentioned in the description

## Step 3: High-level review

**Architecture and design:**
- Does the solution fit the stated problem?
- Are there simpler approaches?
- Is it consistent with existing patterns in the codebase?

**File organisation:**
- Are new files in appropriate locations?
- Are there any unexpected deletions?

**Testing:**
- Are tests present for new behaviour?
- Do tests cover edge cases?

## Step 4: Code review

For each changed file in the diff:

**Correctness:**
- Edge cases handled (empty input, nulls, boundaries)?
- Error handling present where expected?

**Security:**
- Input validation at trust boundaries?
- No hardcoded secrets or credentials?
- No SQL injection or XSS vectors?

**Performance:**
- No N+1 queries or unnecessary loops?

**Maintainability:**
- Clear naming?
- Functions doing one thing?

## Step 5: Produce the review report

```markdown
## PR Review: #{number} — {title}

**Author**: {author}
**Base → Head**: {baseRefName} ← {headRefName}
**Size**: +{additions} -{deletions} across {changedFiles} files

---

### Strengths

- {what was done well}

### Required Changes

🔴 [blocking] {file}:{line} — {issue and recommended fix}

### Suggestions

💡 {suggestion with rationale}

### Questions

❓ {clarifying question}

---

### Verdict

{✅ Approve | 🔄 Request changes | 💬 Comment}

{One-sentence summary of the verdict rationale}
```

Use severity labels:
- 🔴 `[blocking]` — must fix before merge
- 🟡 `[important]` — should fix
- 🟢 `[nit]` — nice to have, not blocking
- 💡 `[suggestion]` — alternative approach
