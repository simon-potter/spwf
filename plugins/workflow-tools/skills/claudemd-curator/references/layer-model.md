# The L0–L4 Layer Model

Every line in CLAUDE.md fits in exactly one layer. If it doesn't, it isn't a CLAUDE.md line — it's a tooling concern, an inference, a pointer target, or bloat.

## L0 — Identity & map (~5–10 lines)

What this repo is, in one sentence. The directory map of "where things live" so the agent doesn't have to discover it from scratch every session.

**Template:**

```markdown
# <Project Name>

<One-sentence description: what it is, who it's for. No filler.>

## Map
- `<dir>/` — <one-line purpose>
- `<dir>/` — <one-line purpose>
- `docs/agent-guides/` — task-specific guides loaded on demand
- `.claude/rules/` — path-scoped rules (lazy-loaded)
```

**Rules:**
- Never list things the agent can `ls` to discover.
- Annotate only directories whose purpose isn't obvious from the name.
- A monorepo with five apps lists five apps. A single-package repo skips this section if `ls` tells the same story.

## L1 — Discipline (~15 lines)

Karpathy's four. Use the canonical wording in `references/karpathy-block.md`. Do not paraphrase — the wording is dense for a reason and rewording usually loses the binding force.

The four:
1. **Think before coding** — state assumptions, surface tradeoffs, ask when uncertain.
2. **Simplicity first** — minimum code that solves the problem, no speculative abstraction.
3. **Surgical changes** — touch only what you must, match existing style.
4. **Goal-driven execution** — define verifiable success, loop until met.

**Tradeoffs to acknowledge inline:** these guidelines bias toward caution over speed. For trivial tasks, the agent uses judgement.

## L2 — Decision posture (~15–25 lines)

product-mode's contributions, distilled. Use the canonical wording in `references/product-mode-block.md`.

The four:
1. **User and JTBD anchor** — before code, the thread must answer: *who is the user, what is their problem, what is the job to be done.* Solution-first requests get pushed back to problem-first.
2. **Reversibility (one-way vs two-way doors)** — two-way doors decide fast, move on. One-way doors (public APIs, data schemas, pricing, brand, durable UX patterns users learn) require written tradeoffs and explicit sign-off before proceeding.
3. **Written tradeoffs with revisit triggers** — for one-way doors, name the alternative considered, the reason chosen, and a metric/date/condition that would reopen the decision.
4. **"Done" is user-observable** — merged is not done. Tests pass is not done. Done = the user can do the thing, it works, and we can see it working in production.

**Note on scope:** L2 only earns its place in CLAUDE.md if the user is doing product/feature work. For a pure tooling repo (compiler, library), L2 may be replaced or trimmed.

## L3 — Pointers (length varies, but each pointer is one line)

Pointers, not content. The agent reads pointed-to files only when relevant.

**Examples:**

```markdown
## Read on demand
- @docs/agent-guides/build-test-verify.md — exact lint/test/build commands
- @docs/agent-guides/api-conventions.md — when touching `src/api/`
- @docs/agent-guides/migrations.md — before any schema change

## Path-scoped rules (lazy-loaded by .claude/rules/*.md)
- Touching `src/billing/`? `.claude/rules/billing.md` loads automatically.
- Touching `infra/`? `.claude/rules/infra.md` loads automatically.

## Skills available
- `pr-jira-review` — pre-PR cross-reference against Jira
- `humanizer` — clean AI-tells from prose
- `claudemd-curator` — this file's caretaker
```

**Rules:**
- One line per pointer. The agent decides whether to follow it.
- Do **not** paste the contents of pointed-to files into CLAUDE.md "for convenience" — that defeats the entire purpose.
- Use `.claude/rules/*.md` with `paths:` YAML frontmatter for rules that should auto-load when matching files are touched. These don't count against the always-on context budget.

## L4 — Housekeeping (~10–15 lines)

Claude-Code-specific operational tuning. This is the section that doesn't belong in AGENTS.md.

**Common entries:**

```markdown
## Claude Code operational notes
- Compact instructions: preserve the L0 map and L1 discipline block; everything else can be summarised.
- Default model: opus for plan, sonnet for execute (--model opusplan).
- Effort: high for migrations and API design, medium otherwise.
- Subagent routing: use `code-reviewer` after any change >50 lines; use `security-reviewer` (read-only) before any auth/billing change.
- Hooks: pre-commit format-on-save runs ruff. PostToolUse runs `pytest -x` on changed files.
```

**Rules:**
- Anything that depends on Claude Code as the runtime goes here, not in AGENTS.md.
- Subagent and skill names are pointers (L3-style), but their orchestration policy is housekeeping.

## Length budget

| Layer | Target lines | Hard ceiling |
|---|---|---|
| L0 | 5–10 | 15 |
| L1 | ~15 | 20 |
| L2 | 15–25 | 30 |
| L3 | varies — but each pointer is 1 line | n/a |
| L4 | 10–15 | 25 |
| **Total project CLAUDE.md** | **~80–120** | **200** |
| **Total `~/.claude/CLAUDE.md`** | **~50** | **100** |

If you cross the hard ceiling on a layer, the layer needs to be split into pointers.

## Worked example: a 280-line `/init`-generated CLAUDE.md → 95-line refactor

Original (excerpts, paraphrased):

- 90 lines of TypeScript/React style rules → **removed**, linter's job.
- 40 lines describing `package.json` scripts and dependencies → **removed**, inferable.
- 30 lines of "best practices" generic to Next.js → **removed**, model knows.
- 35 lines of API conventions → **moved** to `docs/agent-guides/api-conventions.md`, replaced with one L3 pointer.
- 25 lines of database migration warnings → **moved** to `.claude/rules/migrations.md` with `paths: ["**/migrations/**"]`, removed from CLAUDE.md.
- 15 lines of legitimate L0 map → **kept**, trimmed to 8.
- 20 lines of "communication preferences" (no emojis, terse output, etc.) → **kept**, condensed to 6 lines in L4.
- 25 lines of actual product context (what the app does, key business rules) → **kept**, recast as L2 (user/JTBD + reversibility for the billing model specifically).

Final CLAUDE.md: L0 (8) + L1 (Karpathy block, 15) + L2 (product-mode block + billing-specific tradeoffs, 22) + L3 (6 pointers, 6 lines) + L4 (10) + section headers (4) ≈ **65 lines**.

The 35 lines of API conventions and 25 lines of migration rules now live where they actually need to be — loaded only when the agent touches the relevant files.
