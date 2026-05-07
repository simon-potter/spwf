#!/usr/bin/env bash
# Stop hook — warn if there are uncommitted changes at end of session
#
# Prerequisites: git
cat >/dev/null 2>&1 || true  # drain stdin safely

command -v git &>/dev/null || exit 0

status=$(git status --short 2>/dev/null)
[[ -z "$status" ]] && exit 0

printf '\n⚠  Uncommitted changes in working tree:\n' >&2
printf '%s\n' "$status" >&2
printf '\nConsider committing before ending this session (/spwf:close or a manual commit).\n\n' >&2
exit 0
