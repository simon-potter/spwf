---
source: scratch
created: 2026-04-25
status: ideation
---

# Optimal agentic development environment

## Context

A review of the broader Claude Code plugin ecosystem (ComposioHQ/awesome-claude-plugins, r/ClaudeCode, and secondary aggregators) against our current marketplace. The goal: identify what high-value tools or mechanics we are missing, what we have that is redundant with the ecosystem, and what the optimal configuration looks like across skills, MCP servers, hooks, and CLAUDE.md mechanics.

Research base: 50+ tools catalogued, 135+ agents in the broader ecosystem, developer sentiment from r/ClaudeCode (4,200+ weekly contributors). Core finding from practitioners: "Tested 60–70 tools over 6 months, kept only 10. Most tools people write about don't earn their keep." That is the filter to apply here.

---

## What we have (and what it covers)

The marketplace currently handles the full feature development loop well:
- **Pre-phase:** capture, debug, challenge — three entry points, Jira-integrated
- **Core cycle:** spec → approve-plan → build (TDD-enforced) → simplify → pr-create → pr-review
- **Post-ship:** retrospective (learnings + spec audit + doc-lint + workflow-lint)
- **Quality:** claudemd-curator, workflow-lint, agent-optimise, doc-lint

What the marketplace explicitly does NOT do, by design:
- CI/CD deployment (skills hand off at PR creation; CI owns the rest)
- Linting/formatting (assumed to be IDE/pre-commit enforced)
- Infrastructure/environment setup

---

## Ecosystem tools reviewed

### Tier A — Production-quality, widely used, clearly scoped

| Tool | What it does | Install |
|---|---|---|
| **connect-apps** (Composio) | MCP gateway to 500+ services: Slack, Notion, Gmail, GitHub, Linear, HubSpot, Asana, Jira. One MCP, many tools. | `npx @composio/mcp@latest` |
| **Context7** (Upstash) | MCP that injects version-pinned library documentation on demand — prevents the "hallucinated API" problem in build phase | `npx -y @upstash/context7-mcp` |
| **GitHub MCP** (official) | Deep GitHub integration: issue management, PR control, CI/CD triggering, commit analysis, branch ops | `npx @modelcontextprotocol/server-github` |
| **Playwright MCP** | Live Chrome window control for real-time UI testing; allows agent to interact with the browser during build | `npx @playwright/mcp` |
| **Sequential Thinking MCP** | Forces methodical reasoning chains; structures complex problem-solving into explicit numbered steps | `npx @modelcontextprotocol/server-sequential-thinking` |
| **agentlint** | Structural quality scoring (12 dimensions) + workspace scan across all artifacts | `npx @agent-lint/cli` (also MCP) |
| **Firecrawl MCP** | Turn any URL into clean LLM-readable content; handles JS rendering and anti-bot; useful in spec/research phase | `npx firecrawl-mcp` |
| **security-sweep** (Composio) | OWASP Top 10 + AI-specific vulnerability detection in code | Plugin |
| **test-writer-fixer** (Composio) | Write and fix unit tests (Jest, Vitest, Pytest); can repair broken tests, not just write new ones | Plugin |
| **changelog-generator** (Composio) | Customer-friendly release notes from git history, conventional commits | Plugin |
| **Linear MCP** | Direct Linear issue tracking integration — for teams not on Jira | MCP |
| **Figma MCP** | Design-to-code generation from Figma frames | MCP |

### Tier B — Useful, but overlaps with what we've built

| Tool | Overlaps with | Verdict |
|---|---|---|
| **code-review** (Composio) | pr-review skill, agentlint | Skip — we have better |
| **pr-review** (Composio) | pr-review skill | Skip — we have better |
| **debugger** (Composio) | debug skill, debug-recovery | Skip — we have this |
| **bug-fix** (Composio) | debug + debug-recovery | Skip — we have this |
| **feature-dev** | workflow-core (7-phase) | Skip — ours is stronger (TDD, OpenSpec) |
| **maestro-orchestrate** | workflow-agents (12 agents) | Skip — more specific than ours |
| **backlog** | OpenSpec tasks.md | Skip — OpenSpec is more rigorous |
| **ship** (Composio) | pr-create | Skip — we have this |

### Tier C — Interesting mechanics, not yet production-ready or too narrow

| Tool | Why interesting | Why not now |
|---|---|---|
| **context-mode** | Claims 98% context savings by sandboxing subprocess output in separate processes | Architecture change; needs validation |
| **Manifest** | Real-time token cost tracking per session | Nice-to-have; not workflow-critical |
| **codebase-graph** | AST parsing for 42 languages; code intelligence beyond grep | High complexity; unclear integration point |
| **claude-mem** / **Beads** | SQLite/vector memory across sessions | Competes with our file-based memory system |
| **mcp-builder** | Builds MCP servers with assistance | Too narrow (MCP developer tool) |
| **ralph-loop** | Autonomous multi-hour coding with git reset pattern | Dangerous without our approval gates |

---

## Gaps in our current workflow

### Gap 1 — Security (critical)

We have zero security tooling in the build or PR creation path. The closest is `pr-review`'s general awareness of OWASP issues, but it doesn't scan. A professional team needs:
- **SAST** (static analysis): Semgrep, Bandit, ESLint security rules
- **Secret scanning**: no hardcoded credentials in commits
- **Dependency vulnerability audit**: npm audit, pip-audit, Snyk

This is the highest-risk gap. A green test suite with a hardcoded API key in a commit is a production incident waiting to happen.

**Options:**
1. New `security-scan` skill: wraps `semgrep --config=auto`, `gitleaks`, `npm audit --audit-level=high`. Runs as a pre-PR-create gate.
2. Use the `security-sweep` Composio plugin (OWASP Top 10 + AI vulns) as a standalone complement.
3. Both — security-sweep for interactive advisory, security-scan for automated gate.

### Gap 2 — MCP coverage (high value, low cost)

Our only MCP integration is Atlassian Jira. We're leaving significant value on the table:

**GitHub MCP** — we use `gh` CLI but GitHub MCP gives agents the ability to:
- Query CI/CD run status (did the pipeline pass after PR creation?)
- Manage issues directly (create follow-up tasks from retrospective)
- Trigger workflow re-runs without leaving the session

**Context7** — during the build phase, agents frequently hallucinate API signatures for libraries. Context7 injects the actual, version-pinned docs. This would make write-tests and the build skill materially more accurate. Straightforward MCP add, zero skill changes needed.

**Sequential Thinking MCP** — during debug and challenge phases, agents sometimes skip steps or jump to conclusions. Sequential Thinking enforces explicit reasoning chains. Would be most useful as a tool available to the debugger and challenger agents.

**Playwright MCP** — our test coverage is unit/integration only. Playwright MCP allows agents to actually interact with a running app in a browser. This would be transformative for the build phase if the codebase has any UI component.

### Gap 3 — Changelog / release notes (moderate)

The retrospective skill mines commits for learnings but doesn't produce a customer-facing changelog. Teams publishing releases need:
- Conventional commit → human-readable changelog
- Semantic version bump recommendation (patch/minor/major from commit types)
- Breaking change detection

This is a one-skill addition to the post-ship phase (`changelog` skill in workflow-tools, atomic, called optionally from retrospective orchestrator).

### Gap 4 — Dependency management (moderate)

No skill covers adding, upgrading, or auditing dependencies. In the build loop, an agent might add a dependency without checking for known vulnerabilities or semver compatibility. A lightweight `dep-audit` skill (runs `npm audit` / `pip-audit` / `cargo audit`, surfaces high/critical findings) would close this.

### Gap 5 — Pre-commit hook integration (low cost, high leverage)

The build skill assumes linting/formatting is handled externally. But agents frequently write code that fails pre-commit hooks, then the user gets a confusing error at commit time. A simple hook configuration review in `setup-env` or as a note in pr-create would close this.

### Gap 6 — Broader integrations (connect-apps / Linear)

We assume Jira. A growing number of teams use Linear, Notion, or GitHub Issues as their primary tracker. Connect-apps (Composio) provides a single MCP that covers 500+ services including all of these. Adding it as a recommended MCP (with capture skill updated to detect and adapt to the active tracker) would make the marketplace tracker-agnostic.

### Gap 7 — Context efficiency (ongoing)

This is a mechanics concern, not a skill gap. Several patterns would improve session efficiency:
- **Compact instructions** in CLAUDE.md (claudemd-curator addresses this, but only once it's been run)
- **Path-scoped rules** in `.claude/rules/` — currently underused; any skill-specific guidance that goes into CLAUDE.md should be here instead
- **Model routing** — our agents are correctly sized (Haiku/Sonnet), but there's no explicit guidance in CLAUDE.md about when to invoke which agent for non-golden-path work

---

## What the optimal configuration looks like

### MCP servers (recommended stack)

```json
{
  "mcpServers": {
    "atlassian": { ... },
    "github": { "command": "npx", "args": ["@modelcontextprotocol/server-github"] },
    "context7": { "command": "npx", "args": ["-y", "@upstash/context7-mcp"] },
    "sequential-thinking": { "command": "npx", "args": ["@modelcontextprotocol/server-sequential-thinking"] },
    "agentlint": { "command": "npx", "args": ["-y", "@agent-lint/mcp"] },
    "playwright": { "command": "npx", "args": ["@playwright/mcp"] }
  }
}
```

Playwright is optional (only add if the project has UI). Connect-apps replaces the individual MCPs above if the team uses Linear/Notion/GitHub Issues instead of Jira.

### Skills to add

| Skill | Plugin | Phase | Priority |
|---|---|---|---|
| `security-scan` | workflow-tools | Pre-PR gate | P1 |
| `changelog` | workflow-tools | Post-ship | P2 |
| `dep-audit` | workflow-tools | Pre-build or pre-PR | P2 |
| `workspace-health` | workflow-tools | Quality — orchestrator over agentlint + claudemd-curator | P3 |

### Hooks to add

Pre-commit: format + lint. This doesn't need a skill — it needs a Claude Code hook configuration in CLAUDE.md that ensures the agent runs the project's pre-commit check before considering any edit "done." The `pr-create` skill should verify the pre-commit hook exists and is passing before creating the PR.

### CLAUDE.md/AGENTS.md mechanics improvements

1. **Path-scoped rules** — any guidance that only applies to specific directories (API conventions, migration rules, billing logic) should be in `.claude/rules/{topic}.md` with `paths:` frontmatter. These are lazy-loaded and don't burn always-on context. Currently, most CLAUDE.md files include these inline.
2. **Compact instructions section** — explicitly tell the compactor what to preserve verbatim (L0 map, L1 discipline block). Without this, long sessions drift as context compacts.
3. **Skill pointer in L3** — list available skills in CLAUDE.md as L3 pointers so the agent knows what tools it has. Currently, skill availability is implicit.
4. **Context7 pointer** — once Context7 MCP is installed, add a note in L4: "Use Context7 MCP when writing code against any external library to get version-accurate documentation."

---

## What we know

- **MCP is the high-leverage addition** — four MCPs (GitHub, Context7, Sequential Thinking, agentlint) add meaningful capability without any skill changes. These are the first things to add.
- **Security is the most dangerous gap** — we ship PRs with no automated security checking. This is the highest-priority new skill.
- **The ecosystem has a lot of noise** — 50+ tools reviewed, roughly 10 are genuinely additive to our workflow. The rest overlap with what we've built or are too narrow.
- **Context7 directly improves build quality** — hallucinated API signatures are a real problem in write-tests and build. Context7 eliminates this for any well-known library.
- **connect-apps is a force multiplier if we're multi-tracker** — if teams use Linear or Notion, it replaces the Atlassian-only capture flow with one MCP that handles 500+ services.
- **Playwright MCP unlocks E2E testing** — the only way to test UI changes without leaving the agent session. This is a step change in build loop completeness for frontend projects.
- **agentlint scoring our own SKILL.md files** — we haven't run agentlint against the marketplace itself. Before building workspace-health, we should run the scan to see what it finds.

## Open questions

- Does Context7 support the specific libraries this project uses? (It covers npm/PyPI/major OSS but may not cover niche internal packages)
- Is Sequential Thinking MCP stable for production use or still experimental?
- Should `security-scan` be a hard gate (build fails if high-severity found) or advisory? A hard gate adds friction; advisory risks being ignored.
- Should `changelog` be an atomic skill called by retrospective, or a standalone? — Likely atomic, added as Part 5 of retrospective orchestrator.
- Should connect-apps replace the Atlassian MCP or coexist? — Coexist initially; connect-apps as an opt-in for non-Jira teams.
- Does the `capture` skill need updating to detect which tracker is active and route accordingly?

## Rough scope

### Immediate (MCP configuration, zero skill changes)
- Add GitHub MCP, Context7, Sequential Thinking MCP to recommended MCP stack in root README
- Add agentlint MCP to recommended stack (feeds into todo/agent-lint-claude.md integration plan)
- Update root README Prerequisites with the recommended MCP server block
- Run agentlint scan against the marketplace itself — baseline quality report

### Short-term (new skills)
- `security-scan` skill in workflow-tools — wraps semgrep/gitleaks/npm audit; P1 pre-PR gate
- `dep-audit` skill in workflow-tools — lightweight dependency vulnerability check
- `changelog` atomic skill — conventional commits → release notes; add as Part 5 of retrospective

### Medium-term (mechanics)
- Playwright MCP integration — document in README as optional for UI projects; update `write-tests` to reference it for browser-based tests
- `workspace-health` orchestrator — combines agentlint scan/score with claudemd-curator phases (see todo/agent-lint-claude.md)
- Connect-apps MCP — document as alternative to Atlassian MCP; update `capture` skill to be tracker-agnostic

### CLAUDE.md improvements (any project using this marketplace)
- Add compact instructions section to template CLAUDE.md guidance
- Add path-scoped rules pattern to claudemd-curator reference material
- Add L3 skill pointer template to layer-model.md
