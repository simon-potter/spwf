#!/usr/bin/env bash
# status-scan.sh — collect workflow signals for the workflow-status skill
# Outputs labeled sections of raw signal data; SKILL.md interprets them.
# Fast: no network calls, no subagents, no npm.
set -uo pipefail

# ── Git state ─────────────────────────────────────────────────────────────────

echo "=== GIT STATE ==="
echo "Branch: $(git branch --show-current 2>/dev/null || echo '(detached HEAD)')"
echo ""

echo "Uncommitted changes:"
git status --short 2>/dev/null | head -20 || echo "(none)"
echo ""

echo "Stash:"
git stash list 2>/dev/null | head -5 || echo "(none)"
echo ""

echo "Recent commits (last 10):"
git log --oneline -10 2>/dev/null || echo "(no commits)"
echo ""

echo "Files changed since last commit:"
git diff --name-only HEAD 2>/dev/null | head -15 || echo "(none)"

# ── OpenSpec changes ──────────────────────────────────────────────────────────

echo ""
echo "=== OPENSPEC CHANGES ==="

if command -v openspec >/dev/null 2>&1; then
    echo "Source: openspec CLI"
    echo ""
    openspec list 2>/dev/null || echo "(openspec list failed)"
    echo ""

    # For each active change directory, extract remaining tasks
    CHANGES_DIR="openspec/changes"
    if [ -d "$CHANGES_DIR" ]; then
        for change_dir in "$CHANGES_DIR"/*/; do
            name=$(basename "$change_dir")
            [ "$name" = "archive" ] && continue
            [ -d "$change_dir" ] || continue

            tasks_file="$change_dir/tasks.md"
            [ -f "$tasks_file" ] || continue

            echo "--- Change: $name ---"
            # Proposal title
            grep "^# " "$change_dir/proposal.md" 2>/dev/null | head -1 || echo "# $name"

            # Remaining tasks (first 5)
            echo "Remaining tasks:"
            grep '^\- \[ \]' "$tasks_file" 2>/dev/null | head -5 \
                || echo "  (none — all complete)"
            remaining=$(grep -c '^\- \[ \]' "$tasks_file" 2>/dev/null || echo 0)
            done_count=$(grep -c '^\- \[x\]' "$tasks_file" 2>/dev/null || echo 0)
            echo "Progress: $done_count done / $remaining remaining"
            echo ""
        done
    fi

elif [ -d "openspec/changes" ]; then
    echo "Source: directory scan (openspec CLI not found)"
    echo ""
    for change_dir in openspec/changes/*/; do
        name=$(basename "$change_dir")
        [ "$name" = "archive" ] && continue
        [ -d "$change_dir" ] || continue

        tasks_file="$change_dir/tasks.md"
        echo "--- Change: $name ---"
        grep "^# " "$change_dir/proposal.md" 2>/dev/null | head -1 || echo "# $name"

        if [ -f "$tasks_file" ]; then
            remaining=$(grep -c '^\- \[ \]' "$tasks_file" 2>/dev/null || echo 0)
            done_count=$(grep -c '^\- \[x\]' "$tasks_file" 2>/dev/null || echo 0)
            echo "Progress: $done_count done / $remaining remaining"
            echo "Remaining tasks:"
            grep '^\- \[ \]' "$tasks_file" 2>/dev/null | head -5 || echo "  (none)"
        else
            echo "(no tasks.md)"
        fi
        echo ""
    done

    # Archived changes — just count
    if [ -d "openspec/changes/archive" ]; then
        archived=$(find openspec/changes/archive -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l)
        echo "Archived changes: $archived"
    fi
else
    echo "No OpenSpec directory found"
fi

# ── Todo files ────────────────────────────────────────────────────────────────

echo ""
echo "=== TODO FILES ==="

if [ -d "todo" ]; then
    for f in todo/*.md; do
        [ -f "$f" ] || continue
        [ "$(basename "$f")" = "CLAUDE.md" ] && continue

        status=$(grep "^status:" "$f" 2>/dev/null | head -1 | sed 's/status:[[:space:]]*//' | tr -d ' \r')
        ticket=$(grep "^ticket:" "$f" 2>/dev/null | head -1 | sed 's/ticket:[[:space:]]*//' | sed 's/[[:space:]]*#.*//' | tr -d ' \r')
        created=$(grep "^created:" "$f" 2>/dev/null | head -1 | sed 's/created:[[:space:]]*//' | sed 's/[[:space:]]*#.*//' | tr -d ' \r')
        title=$(grep "^# " "$f" 2>/dev/null | head -1 | sed 's/^# //')

        printf "file=%-40s status=%-12s ticket=%-10s created=%-12s title=%s\n" \
            "$(basename "$f")" \
            "${status:-unknown}" \
            "${ticket:--}" \
            "${created:--}" \
            "${title:-$(basename "$f" .md)}"
    done
else
    echo "No todo/ directory found"
fi

# ── Memory files (optional context) ───────────────────────────────────────────

echo ""
echo "=== PROJECT MEMORY ==="
MEMORY_DIR="${HOME}/.claude/projects/$(pwd | sed 's|/|-|g')/memory"
if [ -d "$MEMORY_DIR" ]; then
    echo "Memory files: $(ls "$MEMORY_DIR"/*.md 2>/dev/null | wc -l)"
    # Most recently modified memory file as a context hint
    latest=$(ls -t "$MEMORY_DIR"/*.md 2>/dev/null | head -1)
    if [ -n "$latest" ]; then
        echo "Most recent: $(basename "$latest")"
        head -8 "$latest"
    fi
else
    echo "No project memory directory found"
fi

echo ""
echo "=== SCAN COMPLETE ==="
