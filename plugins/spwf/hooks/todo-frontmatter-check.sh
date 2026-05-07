#!/usr/bin/env bash
# PostToolUse (Write|Edit) — validate required frontmatter on todo/*.md files
#
# Prerequisites: jq OR python3 (one must be present for JSON parsing), grep (universal)
input=$(cat)

if ! command -v jq &>/dev/null && ! command -v python3 &>/dev/null; then
    printf '⚠  spwf hook: jq and python3 both missing — todo-frontmatter-check skipped\n' >&2
    exit 0
fi

if command -v jq &>/dev/null; then
    file_path=$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty')
else
    file_path=$(printf '%s' "$input" | python3 -c \
        "import json,sys; d=json.load(sys.stdin); print(d.get('tool_input',{}).get('file_path',''))" 2>/dev/null)
fi

# Match todo/*.md — Claude Code passes absolute paths so check for /todo/ segment
[[ "$file_path" == *"/todo/"*".md" || "$file_path" == "todo/"*".md" ]] || exit 0
[[ -f "$file_path" ]] || exit 0

missing=()
grep -q "^source:" "$file_path" || missing+=("source")
grep -q "^status:" "$file_path" || missing+=("status")
grep -q "^created:" "$file_path" || missing+=("created")

if [[ ${#missing[@]} -gt 0 ]]; then
    printf '\n⚠  %s: missing frontmatter field(s): %s\n' "$file_path" "${missing[*]}" >&2
    printf '   Required by capture: source, status, created\n\n' >&2
fi
exit 0
