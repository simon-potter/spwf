# Proposal: add-plugin-marketplace

> **Authoritative Reference:** [`todo/Marketplace_setup.md`](../../../todo/Marketplace_setup.md) contains the complete implementation plan, all resolved decisions, code examples, and acceptance criteria. This document summarises key points; consult the source for specifics.

## Why

Simon's workflow skills and agents are scattered across personal `~/.claude` files with no distribution mechanism. A new machine requires manual copying; there is no update path; and new team members on Academy-Plus projects cannot access these conventions at all.

## What Changes

- **NEW** `.claude-plugin/marketplace.json` — marketplace catalog under the name `simon-marketplace`
- **NEW** `plugins/workflow-core/` — 8 skills covering all seven canonical workflow phases (task-to-spec, plan, build, test-creator, test, pr-reviewer, simplify, ship); 5 of these are seeded from `addyosmani/agent-skills` (MIT) and extended
- **NEW** `plugins/workflow-tools/` — 6 skills for extended phases (issue-to-task, new-task, grill-me, doc-lint, agent-optimise, learn-from-mistakes); all original
- **NEW** `plugins/workflow-agents/` — 8 specialist subagents paired to each workflow phase
- **NEW** `README.md` — installation guide for team members
- **MIGRATION** 6 existing personal `~/.claude/skills/` are adapted and moved here; originals archived after validation

## Impact

- **Repo:** Private repo `Academy-Plus/spwf`; team members install via `/plugin marketplace add Academy-Plus/spwf`
- **Prerequisites:** Claude Code, OpenSpec CLI (`npm install -g openspec`), GitHub CLI (`gh`), Atlassian MCP (conditional, `issue-to-task` only)
- **No breaking changes** to any existing project — this repo is additive only
- **Personal skill deprecations (post-validation):** grill-me, ideation-to-openspec, commits-to-knowledge, code-review-excellence, doc-lint, jira-to-openspec from `~/.claude/skills/`
