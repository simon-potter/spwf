---
# Source: https://github.com/addyosmani/agent-skills — MIT licence
name: pr-create
description: Phase 7 — PR / MR Create. Run pre-PR checks then create a pull request (GitHub) or merge request (GitLab) via the active forge's CLI. CI/CD owns deployment after merge. The request is the deliverable. Halts if any pre-flight check fails. Security checks (secret scan, SAST, dependency audit) run if tools are available; high/critical findings halt creation.
disable-model-invocation: true
allowed-tools: [Read, Bash]
---

# pr-create

Run the pre-flight checklist. If all checks pass, create the pull request (GitHub)
or merge request (GitLab). Report the URL.

Forge selection follows `_shared/forge-dispatch.md` — auto-detected from
`git remote get-url origin` unless overridden in `.spwf/forge.yaml`. GitLab
default; GitHub supported.

## Step 1: Pre-PR checklist

Run each check in order. If any blocking check fails, stop and report — do not proceed to PR creation.

```bash
# Resolve the base branch (.spwf/branch.yaml: base, else main)
BASE=$(grep -E '^base:' .spwf/branch.yaml 2>/dev/null | awk '{print $2}'); BASE=${BASE:-main}

# Check 1: Not on base
BRANCH=$(git branch --show-current)
echo "Branch: $BRANCH (base: $BASE)"

# Check 2: Commits exist ahead of base
git log "${BASE}...HEAD" --oneline

# Check 3: No uncommitted changes
git status --short
```

**Check 1 — Not on main (with rescue offer):**

If branch is the base (`main` / `master`, or `.spwf/branch.yaml: base`), do not
halt with a bare error. Detect whether this is the rescuable failure state and,
if so, offer to fix it automatically. Delegates the operation to
[`_shared/branch-management.md` §4](../_shared/branch-management.md#4-rescue-operation)
via the `branch-rescue` skill.

Detect:
- active change: `CHANGE_ID=$(openspec list --json 2>/dev/null | jq -r '.[0].name')`
- commits ahead of the remote base: `git log origin/{base}..HEAD --oneline` non-empty
- pre-spec base commit (subject-line grep, §4)

If an active change exists **and** there are commits ahead, present the rescue
plan inline with the exact commands, then ask:

```
You're on `{base}` with {N} commit(s) for active change `{change-id}`.
I can rescue this — local-only, nothing pushed:

  1. git checkout -b feature/{change-id}              # preserve your work
  2. git checkout {base} && git reset --hard {base-commit}   # reset local base
  3. (verify {base} == origin/{base})

After rescue, local `{base}` is diverged from origin only if commits were
pushed; publish manually when ready:
  git push --force-with-lease origin {base}

Proceed with rescue? [Y/n]
```

- On **Y / enter**: delegate to `/spwf:branch-rescue` for the three local-only
  operations, then continue into **Step 1b** (security pre-flight) on the
  newly-created `feature/{change-id}` branch.
- On **n**: halt with the legacy message so manual handling is not surprised by
  silent skipping:

  ```
  ✗ Cannot ship from main branch.
  Create a feature branch first: git checkout -b {branch-name}
  ```

If no active change is found, fall back to the legacy halt above (nothing to
rescue automatically).

**Check 2 — Commits exist:**
If no commits found ahead of base, halt:
```
✗ No commits to ship.
Implement a task first: /spwf:build
```

**Check 3 — No uncommitted changes:**
If uncommitted changes exist, warn (not halt):
```
⚠ Uncommitted changes present. These will not be included in the PR.
```

## Step 1b: Security pre-flight

Run security checks against the diff about to be shipped. Each check is conditional on the tool being installed. If none of the tools are available, warn once and continue — do not halt.

```bash
# Secret scan — halt on any finding
if command -v gitleaks >/dev/null 2>&1; then
  gitleaks detect --source . --no-banner
fi

# SAST — halt on high or critical severity
if command -v semgrep >/dev/null 2>&1; then
  semgrep --config=auto --severity=ERROR --quiet .
fi

# Dependency audit — prefer dep-audit skill for full ecosystem + Docker coverage;
# fall back to inline host-only checks when tools are not in containers.
DEP_AUDIT_SH="$(find ~/.claude -name 'dep-audit.sh' -path '*/dep-audit/scripts/*' 2>/dev/null | head -1 || true)"
if [ -n "$DEP_AUDIT_SH" ]; then
  bash "$DEP_AUDIT_SH" 2>&1
else
  # Host-only fallback (no Docker awareness)
  if [ -f package.json ] && command -v npm >/dev/null 2>&1; then
    npm audit --audit-level=high --json | \
      jq -e '.metadata.vulnerabilities | (.high + .critical) > 0' && \
      echo "npm audit: high/critical vulnerabilities found" || true
  fi
  if { [ -f requirements.txt ] || [ -f pyproject.toml ]; } && command -v pip-audit >/dev/null 2>&1; then
    pip-audit --severity high
  fi
  if [ -f Cargo.toml ] && command -v cargo-audit >/dev/null 2>&1; then
    cargo audit --deny warnings
  fi
  if [ -f composer.json ] && command -v composer >/dev/null 2>&1; then
    composer audit 2>/dev/null || true
  fi
fi
```

**Secret scan finding (gitleaks):**
Any detected secret is a hard halt:
```
✗ Secret detected in diff. Remove before shipping.
{gitleaks output}
```

**SAST finding (semgrep ERROR severity):**
Halt with findings listed, and recommend deep review:
```
✗ SAST: {N} high/critical finding(s). Review before shipping.
{semgrep output}

For a thorough security review before merge, run:
  /trailofbits:semgrep
(curated rulesets: Trail of Bits + 0xdea + Decurity; SARIF output; Important-only filtering)
```

**Dependency audit — high/critical vulnerability:**
Halt with findings:
```
✗ Dependency: {N} high/critical vulnerability/vulnerabilities found.
Run /spwf:dep-audit for full details and fix commands (Docker-aware).
```

**No tools installed — actionable setup recommendations:**

Do not silently skip. Report each missing tool with its setup path:

```
⚠ Security pre-flight: tools not configured. Recommendations:

── Secret scanning (gitleaks) ──────────────────────────────────
  gitleaks is not installed. Recommended setup:

  1. Install:  brew install gitleaks
  2. Pre-commit hook (catches secrets before commit):
       echo 'gitleaks protect --staged' >> .git/hooks/pre-commit
       chmod +x .git/hooks/pre-commit
  3. CI workflow (catches anything that slips through):
       # GitHub Actions — .github/workflows/security.yml
       - uses: gitleaks/gitleaks-action@v2
         env:
           GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}

       # GitLab CI — .gitlab-ci.yml
       gitleaks:
         stage: test
         image: zricethezav/gitleaks:latest
         script: gitleaks detect --source . --no-banner

── SAST (semgrep) ──────────────────────────────────────────────
  semgrep is not installed. For production-grade SAST with curated
  Trail of Bits rulesets, use the vetted skill instead of raw semgrep:
    /trailofbits:semgrep
  (parallel scanning, SARIF output, --metrics=off enforced, Important-only filtering)

── Dependency audit ────────────────────────────────────────────
  For comprehensive multi-ecosystem coverage (npm, composer, pip, cargo, go, ruby)
  with Docker Compose awareness, use the dedicated skill:
    /spwf:dep-audit
  Install individual tools: pip install pip-audit  |  cargo install cargo-audit
    brew install trivy  (image scanning)
```

## Step 2: Read context for PR content

Read these files to derive the PR title and body:
- `openspec/changes/*/proposal.md` — for the change description
- `git log "${BASE}...HEAD" --oneline` — for commit summary (`BASE` resolved in Step 1)

## Step 3: Resolve forge and create the request

Detect the active forge per `_shared/forge-dispatch.md`. Run `{cli} auth status`
first.

**Fail fast on missing CLI.** If the required CLI (`glab` for GitLab, `gh` for
GitHub) is missing or unauthenticated, halt with:

> *"Forge CLI `{cli}` not installed or not authenticated. Install (`brew install {cli}`) and run `{cli} auth login`. See `plugins/spwf/skills/_shared/forge-dispatch.md`."*

Compose the title and body, then dispatch:

```bash
TITLE="{verb-led title from proposal or commits}"
BODY=$(cat <<'EOF'
## Summary

{bullet points from proposal What Changes section}

## Test plan

- [ ] All tests passing
- [ ] Code simplified
- [ ] No regressions

## OpenSpec change

`{change-id}`
EOF
)

# GitLab (default) — note: --description, not --body; --target-branch, not --base
glab mr create --title "$TITLE" --description "$BODY"

# GitHub
gh pr create --title "$TITLE" --body "$BODY"
```

## Step 4: Report

Use the active forge's vocabulary. GitHub: "PR created". GitLab: "MR created".

Always end with the **Next step** block pointing at `/spwf:close`. This is the
handoff that keeps the golden path from ending at "merge and close the ticket"
— the retrospective lives *inside* close, and an agent that stops here skips it.

```
✓ {PR | MR} created: {URL}

CI/CD will handle deployment after merge.

── Next step ───────────────────────────────────────────────────
After this {PR | MR} merges, run /spwf:close to finish the change:
  • runs the retrospective (learn-from-mistakes, spec audit, doc-lint,
    workflow-lint, recap)
  • archives the OpenSpec change
  • transitions the linked tracker ticket to its done state
  • deletes the local feature branch (with safety checks)

"Merge and close the ticket" is NOT complete until /spwf:close runs —
the retrospective is part of close, not an optional extra.
```

**Do not invoke `/spwf:close` automatically.** pr-create points forward only.
Close is a human-gated, destructive final phase (archives the change,
transitions the ticket, deletes the branch) and must not fire as a side effect
of opening a request — pr-create does not even merge.

## Gotchas

- **`npm audit` exits 1 on any finding.** The pre-flight uses `--audit-level=high` to suppress low/moderate noise — don't remove that flag or every PR with transitive dependencies will halt.
- **Gitleaks false positives on test fixtures.** If the project has test files that embed example keys or mock tokens, gitleaks will halt. Add a `.gitleaksignore` or `[allowlist]` in `.gitleaks.toml` for known fixture paths rather than removing the scan.
- **`semgrep --config=auto` is slow on large repos.** On repos with >10k files the `auto` ruleset can take 3+ minutes. If that's causing timeouts, scope it: `semgrep --config=auto --include="*.py" .` or pin to a specific ruleset. The `/trailofbits:semgrep` skill handles this better than raw semgrep.
- **Security pre-flight runs on the working tree, not the PR diff.** If the repo has pre-existing findings, they will halt the PR creation. First-time installs: run the scan manually, triage the backlog, then proceed.

Do not wait for CI, do not describe deployment steps, do not merge.
