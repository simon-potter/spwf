---
# Adapted from: https://github.com/wshobson/agents — skill: code-review-excellence (via npx skills add https://github.com/wshobson/agents --skill code-review-excellence). Extended with PR/MR fetch and forge-agnostic structure.
name: pr-review
description: Phase 5 — PR Review. Fetch and review a specific pull request (GitHub) or merge request (GitLab) using the active forge's CLI. Produces a structured review report. Requires a PR/MR number or URL as the argument. Does not create requests. Use when a request is open and you want a structured review before merge.
disable-model-invocation: true
allowed-tools: [Read, Bash]
---

# pr-review

Fetch and review a pull request (GitHub) or merge request (GitLab). Produce a
structured review report. Does not create requests.

Forge selection follows `_shared/forge-dispatch.md` — auto-detected from
`git remote get-url origin` unless overridden in `.spwf/forge.yaml`. GitLab
default; GitHub supported.

## Step 0: Require a PR/MR reference

`$ARGUMENTS` must contain a request number or URL.

If `$ARGUMENTS` is empty, halt:

```
Usage: /spwf:pr-review <PR/MR number or URL>

Examples:
  /spwf:pr-review 42
  /spwf:pr-review https://gitlab.com/org/repo/-/merge_requests/42
  /spwf:pr-review https://github.com/org/repo/pull/42
```

## Step 1: Resolve forge and fetch request data

Detect the active forge per `_shared/forge-dispatch.md` (auto-detect from
`git remote`, or read `.spwf/forge.yaml`).

**Fail fast on missing CLI.** Run `{cli} auth status`. If the required CLI
(`glab` for GitLab, `gh` for GitHub) is missing or unauthenticated, halt with:

> *"Forge CLI `{cli}` not installed or not authenticated. Install (`brew install {cli}`) and run `{cli} auth login`. See `plugins/spwf/skills/_shared/forge-dispatch.md`."*

Dispatch the fetch:

```bash
# GitLab (default)
glab mr view $ARGUMENTS --output json
glab mr diff $ARGUMENTS

# GitHub
gh pr view $ARGUMENTS --json number,title,body,baseRefName,headRefName,state,author,additions,deletions,changedFiles
gh pr diff $ARGUMENTS
```

Normalise the response into a uniform internal shape per the JSON-field-mapping
table in `_shared/forge-dispatch.md`. For GitLab, if additions/deletions stats
are needed for the report and not present in the initial response, run an
additional `glab mr changes {ref}` call.

If any CLI command fails, report the error verbatim and stop.

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

Use the active forge's reference syntax in the heading: `#{id}` for GitHub,
`!{id}` for GitLab.

```markdown
## {Request type} Review: {ref} — {title}     <!-- "PR Review: #42" or "MR Review: !42" -->

**Author**: {author}
**Base → Head**: {base} ← {head}
**Size**: +{additions} -{deletions} across {files_changed} files

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
