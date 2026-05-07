#!/usr/bin/env bash
# PostToolUse (Write|Edit) — nudge to run openspec validate after tasks.md is written
#
# Prerequisites: jq OR python3 (one must be present for JSON parsing), sed (universal)
input=$(cat)

if ! command -v jq &>/dev/null && ! command -v python3 &>/dev/null; then
    printf '⚠  spwf hook: jq and python3 both missing — openspec-validate-nudge skipped\n' >&2
    exit 0
fi

if command -v jq &>/dev/null; then
    file_path=$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty')
else
    file_path=$(printf '%s' "$input" | python3 -c \
        "import json,sys; d=json.load(sys.stdin); print(d.get('tool_input',{}).get('file_path',''))" 2>/dev/null)
fi

[[ "$file_path" == *"openspec/changes/"*"/tasks.md" ]] || exit 0

change_id=$(printf '%s' "$file_path" | sed 's|.*openspec/changes/||; s|/tasks\.md$||')

printf '\n  Run: openspec validate %s --strict\n\n' "$change_id" >&2
exit 0
