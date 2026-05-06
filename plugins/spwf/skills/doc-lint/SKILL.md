---
# Copied from: ~/.claude/skills/doc-lint/ — Simon Potter (original inspired by an unattributed source, provenance not recoverable)
name: doc-lint
description: Cross-cutting — Validate project documentation against governance rules and naming conventions. Supports --fix mode for interactive fixes and --auto-fix for automatic safe fixes. Use when checking docs for naming violations, missing metadata, staleness, or structural issues.
disable-model-invocation: true
allowed-tools: [Read, Glob, Grep, Bash, Edit, Write, AskUserQuestion]
---

# Documentation Linter

Validate project documentation against governance rules and naming conventions.

## Usage

```bash
# Report only (no fixes)
/spwf:doc-lint

# Interactive fix mode (asks before each fix)
/spwf:doc-lint --fix

# Automatic fix mode (applies safe fixes without prompting)
/spwf:doc-lint --auto-fix

# Quick validation (naming + metadata + staleness only)
/spwf:doc-lint --quick

# Scoped validation (specific directory)
/spwf:doc-lint docs/deployment/
```

## Fix Mode Capabilities

| Issue Type | Auto-Fix | Interactive Fix |
|------------|----------|-----------------|
| Naming conventions (kebab-case) | ✅ Yes | ✅ Yes |
| Missing metadata headers | ❌ No | ✅ Yes (asks for values) |
| Missing READMEs | ✅ Yes (template) | ✅ Yes |
| Stale documents | ❌ No | ✅ Yes (archive or update) |
| Banned directories | ❌ No | ✅ Yes (move or delete) |
| Component folder violations | ❌ No | ✅ Yes (rename or move) |
| CLAUDE.md scope | ❌ No | ⚠️ Suggestions only |

---

## Instructions

You are a documentation linter. Validate the `docs/` folder against the canonical rules in `docs/documentation-rules.md`.

### Purpose

Ensure documentation:
- Follows naming conventions (kebab-case, ALL CAPS only for root special files)
- Has required metadata headers
- Respects structural constraints
- Stays current (not stale)

---

## Step 1: Load Governance Rules

**CRITICAL: `docs/documentation-rules.md` is REQUIRED.**

**Load order:**
1. Read `docs/documentation-rules.md` (project-specific governance - MUST exist)
2. If missing: **FAIL validation immediately** with error message

**If `docs/documentation-rules.md` doesn't exist:**
```
ERROR: docs/documentation-rules.md is REQUIRED but not found.

This file is the single source of truth for documentation governance.

Action required:
1. Create it manually using the template, OR
2. Copy from another project and customize

Until this file exists, documentation validation cannot proceed.
```

### Fallback Rules (Only if docs/documentation-rules.md missing)

| Rule | Description |
|------|-------------|
| Naming | kebab-case for docs, ALL CAPS only for root special files (README.md, CLAUDE.md, etc.) |
| Metadata | Every doc has Status, Owner, Last Reviewed headers |
| READMEs | Required at docs/, components/*, top-level buckets |
| Depth | No path exceeds 4 levels below docs/components/<component>/ |
| Banned dirs | No misc/, notes/, temp/, scratch/, old/, backup/ |
| Component allowlist | Only specs/, api/, runbooks/, assets/ in component folders |

---

## Step 2: Run Checks

Use Glob, Read, and Bash tools to validate each rule:

### Check 1: Naming Conventions

```bash
find docs/ -name "*.md" -type f | grep -E "[A-Z]{2,}" | grep -v "README.md\|CLAUDE.md\|AGENTS.md"
find docs/ -name "*_*" -type f
```

### Check 2: Metadata Headers

For each .md file in docs/, check first 10 lines for:
```markdown
> **Status**: Canonical | Operational | Investigative | Archived
> **Owner**: [team name]
> **Last Reviewed**: YYYY-MM
```

### Check 3: README Coverage

Check existence:
- [ ] `docs/README.md`
- [ ] `docs/components/README.md` (if components/ exists)
- [ ] `docs/[bucket]/README.md` for each top-level bucket
- [ ] `docs/components/[name]/README.md` for each component

### Check 4: Staleness Detection

Parse `Last Reviewed:` dates and flag:
- **Warning**: Last reviewed > 6 months ago
- **Error**: Last reviewed > 12 months ago

### Check 5: Depth Limits

```bash
find docs/components -mindepth 5 -type f
```

### Check 6: Banned Directories

```bash
find docs/ -type d \( -name "misc" -o -name "notes" -o -name "temp" -o -name "scratch" -o -name "old" -o -name "backup" \)
```

### Check 7: Component Folder Allowlist

For each `docs/components/[name]/`, allowed subdirectories: `specs/`, `api/`, `runbooks/`, `assets/`.

### Check 8: CLAUDE.md Scope

For each `*/CLAUDE.md`, warn if > 150 lines for component CLAUDE.md.

### Check 9: Troubleshooting File Cap

Check `docs/operations/troubleshooting/` — only `README.md`, `common-issues.md`, `[component]-issues.md` expected.

---

## Step 3: Generate Report

```markdown
# Documentation Lint Report

**Project**: [name]
**Date**: [current date]
**Files Scanned**: [count]
**Overall**: [🟢 Pass | 🟡 Warnings | 🔴 Errors]

## Summary

| Check | Status | Issues |
|-------|--------|--------|
| Naming Conventions | [✅/⚠️/❌] | [count] |
| Metadata Headers | [✅/⚠️/❌] | [count] |
| README Coverage | [✅/⚠️/❌] | [count] |
| Staleness | [✅/⚠️/❌] | [count] |
| Depth Limits | [✅/⚠️/❌] | [count] |
| Banned Directories | [✅/⚠️/❌] | [count] |
| Component Allowlist | [✅/⚠️/❌] | [count] |
| CLAUDE.md Scope | [✅/⚠️/❌] | [count] |
| Troubleshooting Cap | [✅/⚠️/❌] | [count] |

## Errors (Must Fix)
[List errors]

## Warnings (Should Fix)
[List warnings]
```

---

## Step 4: Fix Mode (--fix or --auto-fix)

Detect flags from skill invocation args. Set:
- `--fix` → Interactive mode (ask before each fix)
- `--auto-fix` → Automatic mode (apply safe fixes without prompting)
- No flag → Report-only mode

### Auto-fixable

- **Naming conventions**: Rename files to kebab-case using Bash `mv`
- **Missing READMEs**: Create template README with Write tool

### Interactive-only

- **Missing metadata**: Ask for Status and Owner per file via AskUserQuestion
- **Stale documents**: Ask whether to update Last Reviewed or archive to `_archive/`
- **Banned directories**: Ask what to do with content before removing

---

## Step 5: Offer Fixes (Report-Only Mode)

When NOT in fix mode, end with:

```
Run /spwf:doc-lint --fix to fix interactively
Run /spwf:doc-lint --auto-fix for safe automatic fixes (naming, READMEs)
```
