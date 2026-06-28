---
name: branch-rescue
description: Recovery skill — moves commits that landed on the base branch onto a proper feature branch and resets local base, without touching origin. Resolves the active OpenSpec change, detects the pre-spec base commit (subject-line grep with manual-confirm fallback), performs three local-only safe git operations, and surfaces the force-push command for the user to run manually. Invoked standalone or by pr-create's rescue offer.
disable-model-invocation: true
allowed-tools: [Read, Bash]
---

# branch-rescue

Move commits that leaked onto the base branch onto `${prefix}${change_id}` and
reset local base — local-only, never force-pushing to the remote. Delegates the
operation logic to [`_shared/branch-management.md` §4](../_shared/branch-management.md#4-rescue-operation).

Use this when work has already accumulated on `main` (the failure mode the
spec/build layers prevent going forward) and you need to recover.

> **Variables.** Step 1 resolves `prefix`, `base`, and `change_id`; Step 2
> derives `SPEC_COMMIT` and `BASE_COMMIT`. Every later step uses these — same
> casing as `_shared/branch-management.md` §4 (lowercase config, uppercase
> derived). Do not reference a variable before its assigning step.

## Step 1 — Resolve config and the active change

Resolve config from `.spwf/branch.yaml` (defaults when the file or a field is
absent) and the active OpenSpec change. See
[§1](../_shared/branch-management.md#1-config-schema-spwfbranchyaml) for the full
schema.

```bash
prefix=$(grep -E '^prefix:' .spwf/branch.yaml 2>/dev/null | awk '{print $2}'); prefix=${prefix:-feature/}
base=$(grep -E '^base:'    .spwf/branch.yaml 2>/dev/null | awk '{print $2}'); base=${base:-main}
change_id=$(openspec list --json 2>/dev/null | jq -r '.[0].name')
```

If no active change is found (`change_id` empty or `null`), halt — do not touch
any branch:

```
No active OpenSpec change found — nothing to rescue.
```

## Step 2 — Resolve the pre-spec base commit

**Validate the change-id before any substitution** (OpenSpec slug rule):

```bash
echo "$change_id" | grep -Eq '^[a-z][a-z0-9-]+$' || { echo "Invalid change-id"; exit 1; }
```

Then grep the base branch for the spec commit and take its parent
([§4 base-commit detection](../_shared/branch-management.md#4-rescue-operation)):

```bash
SPEC_COMMIT=$(git log "${base}" \
    --grep "^spec: add OpenSpec change ${change_id}$" --format=%H | head -1)
BASE_COMMIT=$(git rev-parse "${SPEC_COMMIT}^")
```

**Fallback (no match).** If `SPEC_COMMIT` is empty (edited spec message or
squash-merge), do NOT pick a commit silently. Show the recent history and ask
the user for the SHA, then confirm before using it:

```bash
git log "${base}" --oneline | head -20
```

> *"No `spec:` commit found for `${change_id}`. Enter the SHA of the last commit
> that should stay on `${base}` (the commit BEFORE this change's work began):"*

After the user supplies a SHA, set `BASE_COMMIT` to it, echo it back with its
subject, and require an explicit confirmation before proceeding.

## Step 3 — Perform the three local-only operations

Run atomically, in order ([§4 recipe](../_shared/branch-management.md#4-rescue-operation)):

```bash
git checkout -b "${prefix}${change_id}"            # 1. preserve work on the feature branch
git checkout "${base}" && git reset --hard "${BASE_COMMIT}"   # 2. reset local base
# 3. verify base vs origin (explicit equality — rev-parse with two args only prints, never compares)
if git rev-parse --verify -q "origin/${base}" >/dev/null; then
  [ "$(git rev-parse "${base}")" = "$(git rev-parse "origin/${base}")" ] \
    && echo "origin/${base} unchanged" \
    || echo "⚠ local ${base} diverged from origin/${base}"
fi
```

The verification declares the local-only part clean only when `${base}` equals
`origin/${base}`. If they differ, the leaked commits had been pushed — that is
expected, and Step 4 surfaces the manual force-push. If `origin/${base}` does
not exist locally (never pushed), the check is skipped and there is nothing to
publish.

## Step 4 — Surface the force-push (never execute it)

If local `${base}` diverged from `origin/${base}` because the leaked commits had
been pushed, print exactly (the `${base}` value is substituted in — on the
default it reads `main`):

```
Local ${base} reset to ${BASE_COMMIT}. To publish: git push --force-with-lease origin ${base}
```

**Never run `git push --force` automatically.** Force-pushing to the shared base
is a destructive action that stays in the user's hands.

## Report

```
## Rescue complete: ${change_id}

✓ {N} commit(s) moved to `${prefix}${change_id}`
✓ Local `${base}` reset to ${BASE_COMMIT} ({subject})
✓ origin/${base} untouched

{If base diverged from origin:}
⚠ Local `${base}` now diverges from `origin/${base}`.
  Publish when ready: git push --force-with-lease origin ${base}
```
