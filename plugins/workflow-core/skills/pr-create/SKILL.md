---
# Source: https://github.com/addyosmani/agent-skills — MIT licence
name: pr-create
description: Phase 7 — PR Create. Run pre-PR checks then create a pull request via gh pr create. CI/CD owns deployment after merge. The PR is the deliverable. Halts if any pre-flight check fails. Security checks (secret scan, SAST, dependency audit) run if tools are available; high/critical findings halt PR creation.
disable-model-invocation: true
allowed-tools: [Read, Bash]
---

# pr-create

Run the pre-PR checklist. If all checks pass, create the PR. Report the URL.

## Step 1: Pre-PR checklist

Run each check in order. If any blocking check fails, stop and report — do not proceed to PR creation.

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
Run /workflow-tools:dep-audit for full details and fix commands (Docker-aware).
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
  3. GitHub Actions (catches anything that slips through):
       # .github/workflows/security.yml
       - uses: gitleaks/gitleaks-action@v2
         env:
           GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}

── SAST (semgrep) ──────────────────────────────────────────────
  semgrep is not installed. For production-grade SAST with curated
  Trail of Bits rulesets, use the vetted skill instead of raw semgrep:
    /trailofbits:semgrep
  (parallel scanning, SARIF output, --metrics=off enforced, Important-only filtering)

── Dependency audit ────────────────────────────────────────────
  For comprehensive multi-ecosystem coverage (npm, composer, pip, cargo, go, ruby)
  with Docker Compose awareness, use the dedicated skill:
    /workflow-tools:dep-audit
  Install individual tools: pip install pip-audit  |  cargo install cargo-audit
    brew install trivy  (image scanning)
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

## Gotchas

- **`npm audit` exits 1 on any finding.** The pre-flight uses `--audit-level=high` to suppress low/moderate noise — don't remove that flag or every PR with transitive dependencies will halt.
- **Gitleaks false positives on test fixtures.** If the project has test files that embed example keys or mock tokens, gitleaks will halt. Add a `.gitleaksignore` or `[allowlist]` in `.gitleaks.toml` for known fixture paths rather than removing the scan.
- **`semgrep --config=auto` is slow on large repos.** On repos with >10k files the `auto` ruleset can take 3+ minutes. If that's causing timeouts, scope it: `semgrep --config=auto --include="*.py" .` or pin to a specific ruleset. The `/trailofbits:semgrep` skill handles this better than raw semgrep.
- **Security pre-flight runs on the working tree, not the PR diff.** If the repo has pre-existing findings, they will halt the PR creation. First-time installs: run the scan manually, triage the backlog, then proceed.

Do not wait for CI, do not describe deployment steps, do not merge.
