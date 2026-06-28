# Branch management — shared reference

Single source of truth for how branch-touching skills (`spec`, `build`,
`pr-create`, `branch-rescue`, `capture`, `wfstatus`) decide when to branch,
how to auto-branch, and how to rescue commits that landed on the base branch.
Skills reference this document; they do not repeat the logic inline.

Mirrors the `forge-dispatch.md` / `tracker-dispatch.md` shared-module pattern:
one source of truth, each skill delegates to the relevant section.

## Sections

1. [Config schema (`.spwf/branch.yaml`)](#1-config-schema-spwfbranchyaml)
2. [Detect-state decision table](#2-detect-state-decision-table)
3. [Auto-branch operation](#3-auto-branch-operation)
4. [Rescue operation](#4-rescue-operation)
5. [Reading order — which skill consumes which section](#5-reading-order--which-skill-consumes-which-section)

---

## 1. Config schema (`.spwf/branch.yaml`)

`.spwf/branch.yaml` is **optional**. Absent, every field takes its default and
enforcement is on. It exists only to override the base branch, rename the
branch prefix, change the prompting behaviour, or opt out entirely.

```yaml
# .spwf/branch.yaml — all fields optional
prefix: feature/        # branch-name prefix
base: main              # integration branch the workflow protects
auto_branch: always     # always | ask | never
enforce: true           # master switch for all three layers
```

| Field | Type | Default | Valid values | When it takes effect |
|---|---|---|---|---|
| `prefix` | string | `feature/` | any git-legal ref prefix | Used wherever a branch name is computed: `{prefix}{change-id}`. Layer 1 (spec) auto-branch, Layer 2 (build) offer, Layer 3 (pr-create / branch-rescue) rescue target. |
| `base` | string | `main` | any existing local branch | The branch the workflow treats as "must stay clean". Every detect-state comparison, the rescue reset target, and the wfstatus drift check use this value (e.g. `master`, `develop`). |
| `auto_branch` | enum | `always` | `always`, `ask`, `never` | Consumed by Layer 1 (spec) only. `always`: branch silently with one confirmation line. `ask`: prompt before branching. `never`: skip Layer 1 entirely (Layer 2 still catches at build). |
| `enforce` | bool | `true` | `true`, `false` | Master switch. `false` bypasses **all three layers** — spec, build, and pr-create behave as the pre-change baseline. No warnings are emitted when off (the user opted out explicitly). |

Resolution: read `.spwf/branch.yaml` if it exists; otherwise use the defaults
above. A missing file is equivalent to all-defaults (enforcement on).

---

## 2. Detect-state decision table

Given the current branch and the resolved `base`, every layer classifies the
state into one of three rows. `{branch}` is `{prefix}{change-id}`.

| State | Condition | Action | Consumed by |
|---|---|---|---|
| **On base** | `CURRENT == base` | Auto-branch (Layer 1) / offer-to-switch (Layer 2) / offer-rescue (Layer 3) | spec, build, pr-create |
| **On target** | `CURRENT == {prefix}{change-id}` | No-op — already on the right branch; emit a confirmation line and proceed | spec, build |
| **On other** | `CURRENT` is neither `base` nor `{prefix}{change-id}` | Ask once: branch here or create `{prefix}{change-id}`? Proceed per the answer | spec |

```bash
CURRENT=$(git branch --show-current)
# base, prefix from .spwf/branch.yaml (defaults: main, feature/)
TARGET="${prefix}${change_id}"
```

---

## 3. Auto-branch operation

The forward-guard operation used by Layer 1 (spec) and Layer 2 (build).

**Preconditions:**
- Working tree must be clean *of changes that would be carried onto the new
  branch unintentionally*. Untracked OpenSpec artefacts that are about to be
  committed are expected and allowed. A dirty tree with unrelated modifications
  halts (see failure handling).
- `enforce: true` (else skip silently).
- For Layer 1, `auto_branch` is `always` or `ask` (not `never`).

**Action:**

```bash
# target does not yet exist
git checkout -b "${prefix}${change_id}"

# target already exists (interrupted prior attempt) — switch, do not recreate
git checkout "${prefix}${change_id}"
```

If the target branch already exists, switch to it with `git checkout`
(not `-b`). If the existing branch is *behind* HEAD (the base has commits the
branch tip lacks), halt rather than auto-merge:

```
branch exists but is behind HEAD — manual merge or rebase required
```

**Output — exactly one visible confirmation line per invocation:**

| Situation | Line |
|---|---|
| Created from base | `✓ Branched to {prefix}{change-id} (auto)` |
| Switched to existing | `✓ Switched to existing {prefix}{change-id}` |
| Already on target | `✓ Already on {prefix}{change-id}` |

**Failure handling:** if the working tree carries uncommitted changes
unrelated to the imminent commit, halt with:

```
✗ Uncommitted changes present — commit or stash before branching.
  Branching aborted to avoid carrying unrelated work onto {prefix}{change-id}.
```

---

## 4. Rescue operation

The recovery operation used by Layer 3 (pr-create) and the standalone
`branch-rescue` skill, for when commits have already landed on `base`.

**Three-step recipe (local-only, safe):**

```bash
# 1. Preserve all current work by branching HEAD as the feature branch
git checkout -b "${prefix}${change_id}"        # from current HEAD (on base)

# 2. Reset local base back to the pre-spec commit
git checkout "${base}" && git reset --hard "${BASE_COMMIT}"

# 3. Verify local base now matches origin (nothing leaked remotely yet)
if git rev-parse --verify -q "origin/${base}" >/dev/null; then
  [ "$(git rev-parse "${base}")" = "$(git rev-parse "origin/${base}")" ] \
    && echo "origin/${base} unchanged" \
    || echo "⚠ local ${base} diverged from origin/${base} — see force-push note below"
fi
```

**Force-push is never executed.** Step 2 diverges local `base` from
`origin/base` only when commits had been pushed. The rescue surfaces the
publish command as plain text for the user to run manually — exactly:

```
Local main reset to ${BASE_COMMIT}. To publish: git push --force-with-lease origin main
```

(Substitute the resolved `base` for `main` when `base` is overridden.)

**Base-commit detection (subject-line grep, with manual fallback):**

Validate `${change_id}` against the OpenSpec slug rule `^[a-z][a-z0-9-]+$`
*before* substitution. OpenSpec slugs use regex-literal hyphens, so the pattern
is safe given that validation (Beadsify Decision 7 safe-subprocess pattern).

```bash
SPEC_COMMIT=$(git log "${base}" \
    --grep "^spec: add OpenSpec change ${change_id}$" --format=%H | head -1)
BASE_COMMIT=$(git rev-parse "${SPEC_COMMIT}^")
```

If the grep returns no match (edited spec message, squash-merge), fall back to
interactive selection — never silently pick a commit:

```bash
git log "${base}" --oneline | head -20
# prompt the user for the pre-spec SHA, then confirm before using it
```

---

## 5. Reading order — which skill consumes which section

Cross-references resolve to specific sections, not just this file.

| Skill / layer | Reads section(s) |
|---|---|
| `spec` (Layer 1) | §1 (config), §2 (detect-state), §3 (auto-branch) |
| `build` (Layer 2) | §1 (config), §2 (detect-state — On base / On target rows), §3 (auto-branch) |
| `pr-create` (Layer 3) | §1 (config), §4 (rescue) |
| `branch-rescue` (standalone) | §1 (config), §4 (rescue) |
| `capture` | §1 (config) — for the Step 0 soft note wording only |
| `wfstatus` | §1 (config — `base`, `prefix`) — for the drift check |
