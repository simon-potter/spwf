---
# Source: https://github.com/addyosmani/agent-skills — MIT licence
name: ship
description: Phase 7 — Ship. Run pre-PR checks then create a pull request via gh pr create. CI/CD owns deployment after merge. The PR is the deliverable. Halts if any pre-flight check fails.
disable-model-invocation: true
allowed-tools: [Read, Bash]
---

# ship

Run the pre-PR checklist. If all checks pass, create the PR. Report the URL.

## Step 1: Pre-PR checklist

Run each check. If any fails, stop and report — do not proceed to PR creation.

```bash
# Check 1: Not on main
BRANCH=$(git branch --show-current)
echo "Branch: $BRANCH"

# Check 2: Commits exist ahead of base
git log main...HEAD --oneline

# Check 3: No uncommitted changes
git status --short
```

**Check 1 — Not on main:**
If branch is `main` or `master`, halt:
```
✗ Cannot ship from main branch.
Create a feature branch first: git checkout -b {branch-name}
```

**Check 2 — Commits exist:**
If no commits found ahead of base, halt:
```
✗ No commits to ship.
Implement a task first: /workflow-core:build
```

**Check 3 — No uncommitted changes:**
If uncommitted changes exist, warn (not halt):
```
⚠ Uncommitted changes present. These will not be included in the PR.
```

## Step 2: Read context for PR content

Read these files to derive the PR title and body:
- `openspec/changes/*/proposal.md` — for the change description
- `git log main...HEAD --oneline` — for commit summary

## Step 3: Create the PR

```bash
gh pr create \
  --title "{verb-led title from proposal or commits}" \
  --body "$(cat <<'EOF'
## Summary

{bullet points from proposal What Changes section}

## Test plan

- [ ] All tests passing
- [ ] Code simplified
- [ ] No regressions

## OpenSpec change

`{change-id}`
EOF
)"
```

## Step 4: Report

```
✓ PR created: {URL}

CI/CD will handle deployment after merge.
```

Do not wait for CI, do not describe deployment steps, do not merge.
