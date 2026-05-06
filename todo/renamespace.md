---
source: scratch
created: 2026-05-06
status: complete
---

# SPWorkflow renamespace plan

Rename the marketplace from "Simon's Plugin Marketplace" to **SPWorkflow** (`spwf`), consolidate three plugins into one, and collapse two skill namespaces into a single `/spwf:` namespace.

---

## Decision

### Is `/workflow-tools:` needed as a separate namespace?

**No.** The `workflow-core` / `workflow-tools` split was an _implementation_ boundary (skills that need OpenSpec vs skills that work in any repo), not a _user_ boundary. It leaks internal architecture into the public API. A user should not need to know which plugin a skill lives in to invoke it — the skill name already carries that meaning (`build` is obviously a core phase; `doc-lint` is obviously a quality tool).

Evidence: 99 cross-namespace references across 32 files. Every time a skill invokes another, it must know and hard-code which namespace to use. Collapsing to one namespace eliminates this friction entirely.

### Recommendation: single `spwf` plugin

Merge all three current plugins into one plugin named `spwf`:

| Current | New |
|---|---|
| `workflow-core` (9 skills) | → `spwf` |
| `workflow-tools` (19 skills) | → `spwf` (merged in) |
| `workflow-agents` (14 agents) | → `spwf` (agents subdir) |

**Install story before:**
```bash
/plugin install workflow-core@simon-marketplace
/plugin install workflow-tools@simon-marketplace
/plugin install workflow-agents@simon-marketplace
```

**Install story after:**
```bash
/plugin install spwf@spwf
```

**Skill invocation before/after:**
```
/workflow-core:build        →  /spwf:build
/workflow-tools:doc-lint    →  /spwf:doc-lint
/workflow-tools:dep-audit   →  /spwf:dep-audit
```

---

## New structure

```
.claude-plugin/
  marketplace.json          ← update name, plugins array

plugins/
  spwf/
    README.md               ← merge workflow-core/README + workflow-tools/README
    skills/
      # 28 skills (9 from workflow-core + 19 from workflow-tools)
      approve-plan/
      build/
      debug-recovery/
      pr-create/
      pr-review/
      run-tests/
      simplify/
      spec/
      write-tests/
      agent-optimise/
      capture/
      challenge/
      changelog/
      claudemd-curator/
      debug/
      dep-audit/
      doc-lint/
      grill-me/
      issue-to-task/
      learn-from-mistakes/
      new-task/
      php-code-quality-reviewer/
      php-code-simplifier/
      retrospective/
      security-scan/
      workflow-lint/
      workflow-status/
      workspace-health/
    agents/
      # 14 agents (from workflow-agents)
      approver.md
      builder.md
      capturer.md
      challenger.md
      debugger.md
      php-code-quality-reviewer.md
      php-code-simplifier.md
      pr-creator.md
      retrospector.md
      reviewer.md
      simplifier.md
      specifier.md
      tdd-expert.md
      tester.md

  workflow-core/            ← DELETE after migration verified
  workflow-tools/           ← DELETE after migration verified
  workflow-agents/          ← DELETE after migration verified
```

---

## File change matrix

### 1. `.claude-plugin/marketplace.json`

Full rewrite:
- `"name": "simon-marketplace"` → `"name": "spwf"`
- `"description"` → update product name to SPWorkflow
- `"plugins"` array: replace three entries with one `{ "name": "spwf", "source": "./plugins/spwf", ... }`

### 2. `plugins/workflow-core/README.md`

Merge into new `plugins/spwf/README.md`. Remove the plugin-boundary rule paragraph (no longer relevant). Keep the two-tier atomic/orchestrator architecture description.

### 3. `plugins/workflow-tools/README.md`

Merge remaining sections (quality tools table, ideation file format, recommended external skills) into `plugins/spwf/README.md`.

### 4. Symlinks — must be recreated with new paths

`php-code-quality-reviewer/references/` contains 5 symlinks and `scripts/` contains 2, all pointing to absolute paths under `plugins/workflow-tools/skills/php-code-simplifier/`. After move, these paths change to `plugins/spwf/skills/php-code-simplifier/`.

New symlink targets (after move):
```
plugins/spwf/skills/php-code-quality-reviewer/references/laravel-patterns.md
  → /var/www/spottmedia/academyplus/plugin-marketplace-simon/plugins/spwf/skills/php-code-simplifier/references/laravel-patterns.md

(same pattern for: php-smell-catalog.md, php-version-capabilities.md,
 symfony-patterns.md, wordpress-patterns.md)

plugins/spwf/skills/php-code-quality-reviewer/scripts/analyse-php.sh
  → /var/www/spottmedia/academyplus/plugin-marketplace-simon/plugins/spwf/skills/php-code-simplifier/scripts/analyse-php.sh

plugins/spwf/skills/php-code-quality-reviewer/scripts/php-quality-baseline.sh
  → /var/www/spottmedia/academyplus/plugin-marketplace-simon/plugins/spwf/skills/php-code-simplifier/scripts/php-quality-baseline.sh
```

### 5. Namespace text replacement — 99 occurrences across 32 files

All files that need `/workflow-core:` → `/spwf:` and `/workflow-tools:` → `/spwf:`:

**Agents (7 files):**
- `plugins/workflow-agents/agents/approver.md`
- `plugins/workflow-agents/agents/builder.md`
- `plugins/workflow-agents/agents/challenger.md`
- `plugins/workflow-agents/agents/debugger.md`
- `plugins/workflow-agents/agents/php-code-quality-reviewer.md`
- `plugins/workflow-agents/agents/php-code-simplifier.md`
- `plugins/workflow-agents/agents/specifier.md`
- `plugins/workflow-agents/agents/tester.md`

**workflow-core skills (7 files):**
- `plugins/workflow-core/skills/approve-plan/SKILL.md`
- `plugins/workflow-core/skills/build/SKILL.md`
- `plugins/workflow-core/skills/pr-create/SKILL.md`
- `plugins/workflow-core/skills/pr-review/SKILL.md`
- `plugins/workflow-core/skills/run-tests/SKILL.md`
- `plugins/workflow-core/skills/spec/SKILL.md`
- `plugins/workflow-core/skills/write-tests/SKILL.md`

**workflow-tools skills (17 files):**
- `plugins/workflow-tools/skills/capture/SKILL.md`
- `plugins/workflow-tools/skills/challenge/SKILL.md`
- `plugins/workflow-tools/skills/changelog/SKILL.md`
- `plugins/workflow-tools/skills/debug/SKILL.md`
- `plugins/workflow-tools/skills/dep-audit/SKILL.md`
- `plugins/workflow-tools/skills/doc-lint/SKILL.md`
- `plugins/workflow-tools/skills/grill-me/SKILL.md`
- `plugins/workflow-tools/skills/issue-to-task/SKILL.md`
- `plugins/workflow-tools/skills/learn-from-mistakes/SKILL.md`
- `plugins/workflow-tools/skills/new-task/SKILL.md`
- `plugins/workflow-tools/skills/php-code-quality-reviewer/SKILL.md`
- `plugins/workflow-tools/skills/retrospective/SKILL.md`
- `plugins/workflow-tools/skills/security-scan/SKILL.md`
- `plugins/workflow-tools/skills/workflow-status/SKILL.md`
- `plugins/workflow-tools/skills/workspace-health/SKILL.md`

**Note:** `claudemd-curator/SKILL.md` and `workflow-lint/SKILL.md` have no cross-namespace references — no changes needed to their bodies, only their directory location changes.

**Root README (1 file):**
- `README.md` — all invocation examples, install commands, product name, plugin tables

### 6. `README.md` (root) — structural changes beyond namespace substitution

- `# Simon's Plugin Marketplace` → `# SPWorkflow`
- Marketplace description paragraph → rewrite to reflect SPWorkflow brand
- Install block: three install commands → one
- Prerequisites §6 (security tools) — no change needed
- What's included tables: remove the three-plugin split, show one unified skills table under `spwf`
- Agent count remains 14

### 7. `todo/` files — leave as historical record

`todo/optimal-agentic-env.md`, `todo/agent-lint-claude.md`, and similar planning files contain old namespace references but are working documents, not user-facing content. They do not need updating — they serve as historical record. Exception: if any todo file is still an active spec being worked from, update it.

---

## Execution plan

Execute in this order. Each phase is independently committable.

### Phase 0: Verify plugin name resolution

Before moving files, confirm: is the plugin name (which becomes the namespace) determined solely by the `"name"` field in `marketplace.json`, or does the directory name also matter? Test by checking Claude Code plugin documentation or by examining how a skill is resolved at install time.

**If directory name must match plugin name:** rename `plugins/workflow-core/` to `plugins/spwf/` directly and update `marketplace.json` source path.

**If only `marketplace.json` matters:** directory can be named anything, rename freely.

### Phase 1: Create new directory structure

```bash
mkdir -p plugins/spwf/skills plugins/spwf/agents
```

Copy all skills (preserve directory trees including scripts/, references/):
```bash
cp -r plugins/workflow-core/skills/* plugins/spwf/skills/
cp -r plugins/workflow-tools/skills/* plugins/spwf/skills/
cp -r plugins/workflow-agents/agents/* plugins/spwf/agents/
```

### Phase 2: Fix symlinks

Delete the copied (now broken) symlinks and recreate pointing to new paths:

```bash
SPWF_ROOT="/var/www/spottmedia/academyplus/plugin-marketplace-simon/plugins/spwf"

# References symlinks (5)
cd "$SPWF_ROOT/skills/php-code-quality-reviewer/references"
rm laravel-patterns.md php-smell-catalog.md php-version-capabilities.md \
   symfony-patterns.md wordpress-patterns.md

for f in laravel-patterns.md php-smell-catalog.md php-version-capabilities.md \
          symfony-patterns.md wordpress-patterns.md; do
    ln -s "$SPWF_ROOT/skills/php-code-simplifier/references/$f" "$f"
done

# Scripts symlinks (2)
cd "$SPWF_ROOT/skills/php-code-quality-reviewer/scripts"
rm analyse-php.sh php-quality-baseline.sh
ln -s "$SPWF_ROOT/skills/php-code-simplifier/scripts/analyse-php.sh" analyse-php.sh
ln -s "$SPWF_ROOT/skills/php-code-simplifier/scripts/php-quality-baseline.sh" php-quality-baseline.sh
```

Verify all symlinks resolve:
```bash
find plugins/spwf -type l | while read l; do
    [ -e "$l" ] && echo "OK: $l" || echo "BROKEN: $l"
done
```

### Phase 3: Batch namespace replacement

Run in `plugins/spwf/` (not the old directories — replace before verifying):
```bash
find plugins/spwf -name "*.md" -not -type l | \
    xargs sed -i \
        -e 's|/workflow-core:|/spwf:|g' \
        -e 's|/workflow-tools:|/spwf:|g' \
        -e 's|workflow-core:|spwf:|g' \
        -e 's|workflow-tools:|spwf:|g'
```

Also replace descriptive references (plugin name in prose):
```bash
find plugins/spwf -name "*.md" -not -type l | \
    xargs sed -i \
        -e 's|workflow-core plugin|spwf plugin|g' \
        -e 's|workflow-tools plugin|spwf plugin|g'
```

Verify nothing was missed:
```bash
grep -r "workflow-core\|workflow-tools" plugins/spwf --include="*.md" | grep -v ".git"
```

### Phase 4: Update marketplace.json

```json
{
  "name": "spwf",
  "owner": {
    "name": "Simon Potter",
    "email": "simon@academypl.us"
  },
  "metadata": {
    "description": "SPWorkflow — engineering workflow toolkit: capture, challenge, spec, plan, build, review, simplify, ship, learn",
    "pluginRoot": "./plugins"
  },
  "plugins": [
    {
      "name": "spwf",
      "source": "./plugins/spwf",
      "description": "28 workflow skills and 14 specialist agents covering the full engineering cycle",
      "version": "1.0.0"
    }
  ]
}
```

### Phase 5: Write plugins/spwf/README.md

Merge `plugins/workflow-core/README.md` and `plugins/workflow-tools/README.md` into a single `plugins/spwf/README.md`. Remove the plugin-boundary rule (no longer relevant). Keep:
- Two-tier atomic/orchestrator architecture description
- Full skills table (all 28 skills, unified)
- Agents table (all 14 agents)
- Quality tools section
- Ideation file format
- Recommended external skills (Trail of Bits semgrep)

### Phase 6: Update root README.md

- Rename title and description
- Replace all `/workflow-core:` and `/workflow-tools:` invocations
- Replace three-plugin install block with single `/plugin install spwf@spwf`
- Remove plugin split from "What's included" — show one unified table

### Phase 7: Verify and commit

```bash
# No broken symlinks
find plugins/spwf -type l | xargs -I{} sh -c '[ -e "{}" ] && echo "OK: {}" || echo "BROKEN: {}"'

# No old namespace references remaining
grep -r "/workflow-core:\|/workflow-tools:" plugins/spwf --include="*.md" | wc -l
# Expected: 0

# Skill count
ls plugins/spwf/skills/ | wc -l   # expected: 28
ls plugins/spwf/agents/ | wc -l   # expected: 14
```

Commit as a single atomic commit (easier to revert if needed).

### Phase 8: Delete old directories

Only after Phase 7 verification passes:
```bash
rm -rf plugins/workflow-core plugins/workflow-tools plugins/workflow-agents
```

### Phase 9 (optional, separate PR): Marketplace rename

- Update `marketplace.json` `"name"` from `"spwf"` to match any new handle
- Rename GitHub repo from `plugin-marketplace-simon` → `spwf` (GitHub handles redirect)
- Update root README install URL accordingly

---

## Risks and mitigations

| Risk | Likelihood | Mitigation |
|---|---|---|
| Plugin name resolution unknown — namespace may come from directory name, not manifest | Medium | Phase 0 verification before any file moves |
| Symlinks break during `cp -r` | High (they become broken copies) | Phase 2 explicitly recreates them after copy |
| Sed replaces text inside code fences (example output) | Medium | Review diff after Phase 3; restore intentional examples |
| Scripts that `find ~/.claude -name 'SKILL.md'` still work post-rename | Low — scripts find by filename, not path | Scripts use `-name` not path; skill filenames don't change |
| Existing installs of `workflow-core`/`workflow-tools` in other projects break | High — this is a breaking API change | Coordinate with any consuming projects before merge; ssa-lms will need `/plugin install spwf@spwf` |

---

## Testing checklist

After execution, before deleting old directories:

- [ ] All 28 skills present in `plugins/spwf/skills/`
- [ ] All 14 agents present in `plugins/spwf/agents/`
- [ ] All symlinks in `php-code-quality-reviewer/references/` resolve
- [ ] All symlinks in `php-code-quality-reviewer/scripts/` resolve
- [ ] Zero `/workflow-core:` references in `plugins/spwf/`
- [ ] Zero `/workflow-tools:` references in `plugins/spwf/`
- [ ] `marketplace.json` validates as valid JSON
- [ ] Root README install commands reference `spwf@spwf`
- [ ] Run `workflow-status` skill (reads openspec + git — good integration test)
- [ ] Confirm with Simon that ssa-lms (or any other consuming project) is updated before deleting old plugin directories
