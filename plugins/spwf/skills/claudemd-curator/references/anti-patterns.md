# Anti-patterns: things to remove from CLAUDE.md

Each entry: the pattern, why it's harmful, and where to put the content instead (if anywhere).

## 1. Code-style rules

**Pattern:** "Use 2-space indentation. Prefer named exports. Always use `const` over `let` when not reassigning. Use single quotes for strings."

**Why harmful:** Linters and formatters do this deterministically, faster, and without burning context tokens on every turn. Putting style rules in CLAUDE.md makes the model less attentive to the things only it can do.

**Where it goes instead:** `.eslintrc`, `.prettierrc`, `pyproject.toml`, pre-commit hooks. Optionally: a Stop hook that runs the linter and shows the model errors to fix.

## 2. Inferable facts

**Pattern:** "This is a TypeScript project. We use React. The build tool is Vite. Tests are in Jest."

**Why harmful:** The model can infer all of this from `package.json` and `vite.config.ts` in one or two tool calls. Stating it in CLAUDE.md is paying context tokens every turn for something that costs the model essentially nothing to discover when needed.

**Where it goes instead:** Nowhere. Delete it.

**Test:** Would three `grep`/`ls`/`cat` calls reveal this? Then delete.

## 3. Generic "best practices"

**Pattern:** "Write clean code. Follow SOLID principles. Prefer composition over inheritance. Always handle errors."

**Why harmful:** These are non-actionable. They don't tell the model anything specific about *this* codebase, and frontier models already know them as defaults. The instruction-following budget is wasted on platitudes.

**Where it goes instead:** Nowhere. If you have a specific opinion about, say, error handling in this codebase ("never throw inside event handlers — return a Result type"), state *that* — and put it in `.claude/rules/error-handling.md` with `paths:` frontmatter so it loads only when relevant.

## 4. Style rules disguised as preferences

**Pattern:** "Be concise. Don't be verbose. Avoid unnecessary explanations. Don't write essays."

**Why harmful:** These exist in Claude Code's system prompt already. Repeating them takes up budget and contributes to the "rules that are never followed because they're noise" problem. If the model is being verbose, the fix is usually a hook that detects long replies and asks for a rewrite, not another rule.

**Where it goes instead:** Nowhere. If a specific output format is required, state the format positively in L4 ("for status reports, use the template at `docs/templates/status-report.md`").

## 5. Pasted code snippets

**Pattern:** "Here's how we structure a controller: ```ts // ... 30 lines ... ```"

**Why harmful:** Code snippets in CLAUDE.md become stale instantly and burn budget every turn. The model is an in-context learner — three reads of actual files in the repo teach it the pattern better than a snippet ever will.

**Where it goes instead:** Point to a representative file: "Reference controller: `src/api/users/route.ts`."

## 6. Multi-paragraph "About this project"

**Pattern:** "ProductCo is a B2B SaaS company founded in 2019 that provides enterprise customers with... [600 words] ..."

**Why harmful:** Almost none of this affects code decisions. The agent doesn't need company history; it needs the directory map and the conventions.

**Where it goes instead:** One sentence in L0. Founder backstory, if anyone genuinely needs it, goes in `README.md`.

## 7. Rules that have never been followed

**Pattern:** A rule that the behavioural audit shows has been violated 8 times across 12 sessions and never resulted in different behaviour.

**Why harmful:** The model is treating it as noise. Adding a stronger version of the same rule won't help — by then it's been pattern-matched as "background instruction".

**Where it goes instead:** Either (a) reword it as a more specific, more concrete instruction with an example, (b) move it to a hook that *enforces* rather than asks (PreToolUse / PostToolUse), or (c) delete it. Repeating ignored rules is worse than no rule.

## 8. Conditional rules without conditions

**Pattern:** "When working on the API, follow REST conventions. When working on the database, use the repository pattern. When working on the frontend, use Tailwind classes only."

**Why harmful:** All three rules are loaded into context for *every* task. The frontend rule competes for attention while the agent is editing a Python migration script.

**Where it goes instead:** `.claude/rules/api.md` with `paths: ["src/api/**"]`, `.claude/rules/db.md` with `paths: ["src/db/**", "**/migrations/**"]`, and so on. These auto-load only when the agent touches matching files.

## 9. Two full files instead of one source of truth

**Pattern:** A 250-line CLAUDE.md and a 200-line AGENTS.md, both fully populated, edited independently over weeks.

**Why harmful:** Drift is now mathematically inevitable. The two files will disagree, and which one wins depends on which tool the developer happens to use that day.

**Where it goes instead:** AGENTS.md is canonical. CLAUDE.md is a symlink (`ln -s AGENTS.md CLAUDE.md`) or a small shim (`See @AGENTS.md` + Claude-only additions). Use `scripts/sync-agents-md.sh` to set this up.

## 10. Manually-edited auto-memory entries

**Pattern:** Auto-memory has been generating notes for weeks, the user has never reviewed them, and now there are 40 entries some of which contradict each other.

**Why harmful:** Auto-memory is loaded into context. Contradictory entries make the model less consistent, not more.

**Where it goes instead:** Review monthly. Promote the genuinely-useful patterns into CLAUDE.md (or `.claude/rules/`), delete the rest. The behavioural-audit phase of the curator skill is the natural place to do this review.

## 11. Instructions that are actually requests

**Pattern:** "Please always run tests after making changes." (No hook attached. No verification.)

**Why harmful:** Asking is not enforcing. The agent will sometimes forget. Polite framing makes the rule weaker, not stronger.

**Where it goes instead:** A PostToolUse hook that runs the test command after edits. Or a `--permission-mode` rule. CLAUDE.md is for *information* the agent needs; *enforcement* belongs in hooks and permissions.

## 12. Compaction-hostile content

**Pattern:** Critical operational rules buried in a long bullet list at line 250 of a 300-line file, with no `## Compact Instructions` section telling the compactor to preserve them.

**Why harmful:** When the session compacts, those rules are exactly the kind of content that gets summarised into uselessness ("the file describes various rules"). The agent then drifts mid-session.

**Where it goes instead:** Surface critical rules early in the file. Add a `## Compact Instructions` section in L4 explicitly listing what compaction must preserve verbatim (typically: L0 map, L1 discipline, any safety-critical L2/L4 items).
