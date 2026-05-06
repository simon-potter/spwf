---
name: workspace-health
description: Periodic workspace health check — runs agentlint structural scan, behavioural audit from session transcripts, and AGENTS.md sync check, then produces a single P1/P2/P3 action report. Read-only and advisory: it never edits files, just surfaces what needs fixing and which tool to use. Designed for a monthly cadence. When agentlint is available, provides richer coverage than agent-optimise; falls back to a manual scan when it is not. Use this instead of running claudemd-curator, agent-optimise, and agentlint separately.
disable-model-invocation: true
allowed-tools: [Read, Bash, Glob, Grep, Agent]
---

# workspace-health

Single-invocation periodic health check for Claude Code workspaces. Runs three passes — structural scan, behavioural audit, sync check — and merges findings into one prioritised report.

This skill does not edit any files. Every finding points to the specific tool that can fix it.

## When to use

- Monthly cadence: "how is this project's agent configuration holding up?"
- Before a quarterly planning session where you're about to add new skills or agents
- After a new developer joins and you want to verify the workspace is well-configured
- When you notice Claude drifting mid-session — behavioural audit will surface violated rules quickly

Do **not** use this for one-off cleanups. Use the specific tool instead:
- Editing CLAUDE.md or AGENTS.md → `/workflow-tools:claudemd-curator`
- Agent/skill quality issues → `/workflow-tools:agent-optimise` (or fix manually)
- Doc drift → `/workflow-tools:doc-lint`
- Dependency vulnerabilities → `/workflow-tools:dep-audit`

## Prerequisites

**agentlint** — strongly recommended; provides the structural scan in Phase 1. Install via:
```bash
npm install -g @agent-lint/cli
# or: npx @agent-lint/cli --version  (on-demand, no global install)
```

If agentlint is unavailable, Phase 1 falls back to a manual inventory scan equivalent to `agent-optimise`. Quality scores will be absent.

**jq** — required for Phase 2 transcript parsing. Install with `brew install jq` or `apt-get install jq`.

**Scripts** — `claudemd-curator`'s `mine-conversations.sh` is used for Phase 2 if available.

## Phase 1 — Structural scan

### Step 1a: Attempt agentlint scan

```bash
# Detect agentlint availability
AGENTLINT=""
command -v agentlint 2>/dev/null && AGENTLINT="agentlint"
npx @agent-lint/cli --version &>/dev/null 2>&1 && AGENTLINT="npx @agent-lint/cli"

if [ -n "$AGENTLINT" ]; then
    echo "agentlint available: $AGENTLINT"
    $AGENTLINT scan --json 2>/dev/null
else
    echo "agentlint not found — falling back to manual scan"
fi
```

If agentlint is available, run it and parse the JSON output for:
- **Artifact inventory** — all discovered CLAUDE.md, AGENTS.md, agents, skills, settings files
- **Missing types** — expected artifact types absent from the project
- **Stale references** — file paths that no longer exist
- **Placeholder content** — template strings not filled in (e.g., `<your project name>`, `TODO:`)
- **Platform contamination** — Claude-specific instructions accidentally in tool-agnostic files

Then score each key file:
```bash
for f in CLAUDE.md AGENTS.md .claude/agents/*.md ~/.claude/agents/*.md; do
    [ -f "$f" ] && $AGENTLINT score "$f" --json 2>/dev/null
done
```

agentlint scores 12 dimensions (0–10 each). Flag any file scoring below 5 on any dimension as P2, below 3 as P1.

### Step 1b: Manual fallback (when agentlint unavailable)

Run the same checks as `agent-optimise` Steps 1–5:

```bash
# Full artifact inventory
find .claude/ ~/.claude/ -type f 2>/dev/null | sort
ls -la CLAUDE.md AGENTS.md 2>/dev/null

# CLAUDE.md length check
wc -l CLAUDE.md ~/.claude/CLAUDE.md 2>/dev/null

# Agent frontmatter check (description, model, allowed-tools)
for f in .claude/agents/*.md ~/.claude/agents/*.md; do
    [ -f "$f" ] && echo "=== $f ===" && head -8 "$f"
done

# Skill frontmatter check (disable-model-invocation, allowed-tools)
for f in .claude/skills/*/SKILL.md ~/.claude/skills/*/SKILL.md; do
    [ -f "$f" ] && echo "=== $f ===" && head -6 "$f"
done

# settings.json
cat .claude/settings.json ~/.claude/settings.json 2>/dev/null
```

In fallback mode, apply the same quality tests as `agent-optimise`:
- CLAUDE.md > 200 lines → P2; > 400 lines → P1
- Agent missing `description` or `model` → P2
- Skill missing `disable-model-invocation` → P2; missing `allowed-tools` → P2
- Conflicting settings between project and personal → P1

## Phase 2 — Behavioural audit

Mine recent session transcripts to find where instructions are being violated or ignored in practice.

Locate the transcript mining script:
```bash
MINE_SCRIPT="$(find ~/.claude -name 'mine-conversations.sh' \
    -path '*/claudemd-curator/scripts/*' 2>/dev/null | head -1 || echo '')"
```

If found, run it and spawn a Sonnet subagent with the same prompt as claudemd-curator Phase 2, but scoped to the **top 3 findings per category** (this is a health check, not a full audit):

```
Read:
1. ~/.claude/CLAUDE.md (global, if exists)
2. Project CLAUDE.md and AGENTS.md (if they exist)
3. Transcripts: <paths from mine-conversations.sh>

Find the top 3 findings in each category:
- VIOLATED: existing rules broken in practice — quote the rule and the violation
- CANDIDATE: patterns the project repeatedly needed that aren't documented
- OUTDATED: rules that were never followed or no longer apply

One sentence per finding. No preamble. Include transcript citation.
```

If the transcript script is not found, locate transcripts inline:
```bash
PROJECT_SLUG=$(pwd | sed 's|/|-|g')
ls ~/.claude/projects/ 2>/dev/null | grep -i "$(basename $(pwd))" | head -3
```

If fewer than 3 transcripts exist, do the analysis inline without a subagent.

## Phase 3 — Sync check

Check the AGENTS.md ↔ CLAUDE.md relationship in one pass:

```bash
# Sync state
[ -L CLAUDE.md ] && echo "OK_SYMLINK: CLAUDE.md → $(readlink CLAUDE.md)"
[ -f CLAUDE.md ] && [ ! -L CLAUDE.md ] && head -3 CLAUDE.md
[ -f AGENTS.md ] && wc -l AGENTS.md
[ -f CLAUDE.md ] && wc -l CLAUDE.md

# Drift check (only if both files exist as full content)
[ -f CLAUDE.md ] && [ -f AGENTS.md ] && [ ! -L CLAUDE.md ] && \
    diff <(grep -v "^#\|^$" CLAUDE.md) <(grep -v "^#\|^$" AGENTS.md) | wc -l
```

Classify sync state as one of: `OK_SYMLINK`, `OK_SHIM`, `DUAL_DRIFT`, `CLAUDE_ONLY`, `AGENTS_ONLY`.

Any state other than `OK_SYMLINK` or `OK_SHIM` is P2. `DUAL_DRIFT` with > 10 differing lines is P1.

## Phase 4 — Health report

Merge all findings into a single prioritised report. Do not repeat findings — if agentlint and the manual check both surface the same issue, cite it once.

```
## Workspace Health Report

**Date**: {YYYY-MM-DD}
**Project**: {cwd}
**Structural scan**: {agentlint vX.Y.Z | manual fallback}
**Transcripts analysed**: {N} sessions

### Overall health: {A–F}

| Area | Signal | Status |
|---|---|---|
| Structural quality (agentlint / manual) | {avg score or manual grade} | ✓ / ⚠ / ✗ |
| Behavioural alignment | {N violations, M candidates} | ✓ / ⚠ / ✗ |
| AGENTS.md sync | {OK_SYMLINK | OK_SHIM | DUAL_DRIFT | ...} | ✓ / ⚠ / ✗ |

---

### P1 — Fix now

- [ ] `{file}:{line}` — {issue} — Fix with: {/skill or command}
- [ ] ...

### P2 — Fix this sprint

- [ ] `{file}` — {issue} — Fix with: {/skill or command}
- [ ] ...

### P3 — Nice to have

- [ ] `{file}` — {issue} — Fix with: {/skill or command}
- [ ] ...

---

### Fix routing

| Issue type | Tool |
|---|---|
| CLAUDE.md bloat, stale refs, rule drift | `/workflow-tools:claudemd-curator` |
| Agent descriptions, model assignment, tool scope | `/workflow-tools:agent-optimise` or edit directly |
| Doc staleness, broken doc links | `/workflow-tools:doc-lint` |
| Dependency vulnerabilities | `/workflow-tools:dep-audit` |
| Deep security review | `/workflow-tools:security-scan` |
| PHP code quality | `/workflow-tools:php-code-quality-reviewer` |

---

### Next scheduled run

Recommended cadence: monthly. Suggested reminder:
  git log --oneline --since="1 month ago" | wc -l  # low activity → skip; high activity → run
```

### Health grade calculation

| Grade | Criteria |
|---|---|
| A | No P1 findings; ≤ 2 P2 findings; sync OK |
| B | No P1 findings; ≤ 5 P2 findings |
| C | 1–2 P1 findings OR > 5 P2 findings |
| D | 3+ P1 findings OR sync state DUAL_DRIFT |
| F | Critical behavioural violations + P1 structural issues + sync drift simultaneously |

## Relationship to other tools

| Tool | Scope | When to use instead |
|---|---|---|
| `workspace-health` (this) | Full periodic sweep; advisory | Monthly cadence or on suspicion of drift |
| `claudemd-curator` | Deep CLAUDE.md refactor; proposes + applies | When you want to actually fix the file |
| `agent-optimise` | Lightweight agent/skill audit; no dependencies | Quick check without agentlint; CI-friendly |
| `workflow-lint` | Golden path coherence (phase coverage, cross-refs) | After adding or removing skills/agents from the workflow |
| `doc-lint` | Documentation drift | When docs specifically are the concern |
| agentlint standalone | Raw scan/score output | Debugging a specific file's quality score |

When agentlint is available, workspace-health provides richer coverage than `agent-optimise` alone. `agent-optimise` remains useful as a zero-dependency fallback.

## Gotchas

- **agentlint only scans `.claude/` trees.** Skills and agents in `plugins/` or custom directories are invisible to it. The manual fallback (`agent-optimise`-style) covers these. Both scans run in sequence — do not skip the manual fallback just because agentlint ran.
- **`npx @agent-lint/cli scan` can be slow on first run** while npm downloads the package. Use `npm install -g @agent-lint/cli` if the project runs this frequently.
- **Behavioural audit is only as good as the transcripts available.** On a fresh machine or after clearing `~/.claude/projects/`, Phase 2 produces no findings. Note this explicitly rather than reporting "no violations" — absence of evidence is not evidence of absence.
- **Sync state `DUAL_DRIFT` does not mean CLAUDE.md is wrong.** It may be intentionally different (Claude-specific content). The diff line count is a proxy for intentionality — a 3-line diff is a shim; a 100-line diff is unmanaged duplication.
- **agentlint false positives on template placeholder paths.** Strings like `<name>`, `<capability>` in skill files are intentional syntax. Filter these from the structural scan findings before including them in the report.
- **Grade is a snapshot.** It reflects the state at the time of the run, not a trend. Two runs a month apart with the same grade could represent very different codebases. Encourage users to run on a consistent cadence to build a comparable baseline.
- **This skill runs longer than most.** Transcript mining with subagents, agentlint scan, and a full file inventory take several minutes. Do not run during an active task.
