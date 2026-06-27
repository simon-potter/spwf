---
name: branch-rescue
description: Recovery skill — moves commits that landed on the base branch onto a proper feature branch and resets local base, without touching origin. Resolves the active OpenSpec change, detects the pre-spec base commit (subject-line grep with manual-confirm fallback), performs three local-only safe git operations, and surfaces the force-push command for the user to run manually. Invoked standalone or by pr-create's rescue offer.
disable-model-invocation: true
allowed-tools: [Read, Bash]
---

# branch-rescue

Move commits that leaked onto the base branch onto `{prefix}{change-id}` and
reset local base — local-only, never force-pushing to the remote. Delegates the
operation logic to [`_shared/branch-management.md` §4](../_shared/branch-management.md#4-rescue-operation).

Use this when work has already accumulated on `main` (the failure mode the
spec/build layers prevent going forward) and you need to recover.

## Step 1 — Resolve config and the active change

Read `.spwf/branch.yaml` (defaults: `prefix: feature/`, `base: main`) per
[§1](../_shared/branch-management.md#1-config-schema-spwfbranchyaml).

Resolve the active OpenSpec change:

```bash
CHANGE_ID=$(openspec list --json 2>/dev/null | jq -r '.[0].name')
```

If no active change is found (`CHANGE_ID` empty or `null`), halt — do not touch
any branch:

```
No active OpenSpec change found — nothing to rescue.
```

## Step 2 — Resolve the pre-spec base commit

**Validate the change-id before any substitution** (OpenSpec slug rule):

```bash
echo "$CHANGE_ID" | grep -Eq '^[a-z][a-z0-9-]+$' || { echo "Invalid change-id"; exit 1; }
```

Then grep the base branch for the spec commit and take its parent
([§4 base-commit detection](../_shared/branch-management.md#4-rescue-operation)):

```bash
SPEC_COMMIT=$(git log "${BASE}" \
    --grep "^spec: add OpenSpec change ${CHANGE_ID}$" --format=%H | head -1)
BASE_COMMIT=$(git rev-parse "${SPEC_COMMIT}^")
```

**Fallback (no match).** If `SPEC_COMMIT` is empty (edited spec message or
squash-merge), do NOT pick a commit silently. Show the recent history and ask
the user for the SHA, then confirm before using it:

```bash
git log "${BASE}" --oneline | head -20
```

> *"No `spec:` commit found for `{change-id}`. Enter the SHA of the last commit
> that should stay on `{base}` (the commit BEFORE this change's work began):"*

After the user supplies a SHA, echo it back with its subject and require an
explicit confirmation before proceeding.

## Step 3 — Perform the three local-only operations

Run atomically, in order ([§4 recipe](../_shared/branch-management.md#4-rescue-operation)):

```bash
git checkout -b "${PREFIX}${CHANGE_ID}"            # 1. preserve work on the feature branch
git checkout "${BASE}" && git reset --hard "${BASE_COMMIT}"   # 2. reset local base
git rev-parse "${BASE}" "origin/${BASE}"           # 3. verify base vs origin
```

Verify `${BASE}` now equals `origin/${BASE}` to declare the local-only part
clean. If they differ, the base had unpushed commits that this change did not
create — surface the divergence and let the user resolve it rather than
force-resetting further.

## Step 4 — Surface the force-push (never execute it)

If local `${BASE}` diverged from `origin/${BASE}` because the leaked commits had
been pushed, print exactly (substituting the resolved base for `main`):

```
Local main reset to ${BASE_COMMIT}. To publish: git push --force-with-lease origin main
```

**Never run `git push --force` automatically.** Force-pushing to the shared base
is a destructive action that stays in the user's hands.

## Report

```
## Rescue complete: {change-id}

✓ {N} commit(s) moved to `{prefix}{change-id}`
✓ Local `{base}` reset to {base-commit} ({subject})
✓ origin/{base} untouched

{If base diverged from origin:}
⚠ Local `{base}` now diverges from `origin/{base}`.
  Publish when ready: git push --force-with-lease origin {base}
```
