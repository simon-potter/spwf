#!/usr/bin/env bash
# migrate-to-spwf.sh
#
# Moves the SPWorkflow project from plugin-marketplace-simon → spwf and
# migrates all associated Claude Code session history so sessions remain
# accessible in the new location.
#
# Usage:
#   bash migrate-to-spwf.sh [--dry-run]
#
# What it does:
#   1. Moves /var/www/spottmedia/academyplus/plugin-marketplace-simon
#          → /var/www/spottmedia/academyplus/spwf
#   2. Moves ~/.claude/projects/-var-www-spottmedia-academyplus-plugin-marketplace-simon
#          → ~/.claude/projects/-var-www-spottmedia-academyplus-spwf
#   3. Verifies git remote still points to git@github.com:Academy-Plus/spwf.git
#   4. Reports a summary
#
# Prerequisites:
#   - Run OUTSIDE an active Claude Code session in this project. Exit Claude Code
#     first, then run this script, then reopen from the new path.
#   - You must be the owner of both directories (no sudo required).

set -euo pipefail

# ── Config ────────────────────────────────────────────────────────────────────

SRC="/var/www/spottmedia/academyplus/plugin-marketplace-simon"
DST="/var/www/spottmedia/academyplus/spwf"

# Claude Code slugifies paths by replacing leading / with - and all / with -
CLAUDE_DIR="${HOME}/.claude/projects"
SRC_SLUG="-var-www-spottmedia-academyplus-plugin-marketplace-simon"
DST_SLUG="-var-www-spottmedia-academyplus-spwf"

CLAUDE_SRC="${CLAUDE_DIR}/${SRC_SLUG}"
CLAUDE_DST="${CLAUDE_DIR}/${DST_SLUG}"

DRY_RUN=false
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=true

# ── Helpers ───────────────────────────────────────────────────────────────────

info()  { echo "  [info]  $*"; }
ok()    { echo "  [ok]    $*"; }
warn()  { echo "  [warn]  $*"; }
err()   { echo "  [error] $*" >&2; exit 1; }
run()   {
    if $DRY_RUN; then
        echo "  [dry]   $*"
    else
        "$@"
    fi
}

# ── Pre-flight checks ─────────────────────────────────────────────────────────

echo ""
echo "SPWorkflow project migration"
echo "  ${SRC}"
echo "  → ${DST}"
echo ""

$DRY_RUN && echo "  *** DRY RUN — no changes will be made ***" && echo ""

# Source project must exist
[[ -d "$SRC" ]] || err "Source directory not found: ${SRC}"
ok "Source project exists"

# Destination must not exist
[[ ! -e "$DST" ]] || err "Destination already exists: ${DST}  (remove it first or choose a different path)"
ok "Destination path is free"

# Must not be running inside the source dir (best-effort check)
if [[ "$(pwd)" == "$SRC"* ]]; then
    err "Current working directory is inside the source project. Exit Claude Code or cd elsewhere first."
fi
ok "Working directory is outside source project"

# Claude history source must exist
if [[ -d "$CLAUDE_SRC" ]]; then
    SESSION_COUNT=$(find "$CLAUDE_SRC" -maxdepth 1 -name "*.jsonl" | wc -l | tr -d ' ')
    ok "Claude history exists (${SESSION_COUNT} session files)"
else
    warn "Claude history directory not found at ${CLAUDE_SRC} — skipping history migration"
    CLAUDE_SRC=""
fi

# Claude history destination must not exist
if [[ -n "$CLAUDE_SRC" && -e "$CLAUDE_DST" ]]; then
    err "Claude history destination already exists: ${CLAUDE_DST}  (remove it first)"
fi

# ── Step 1: Move the project directory ───────────────────────────────────────

echo ""
echo "Step 1 — Move project directory"
run mv "$SRC" "$DST"
ok "Project moved: ${DST}"

# ── Step 2: Move Claude history ───────────────────────────────────────────────

echo ""
echo "Step 2 — Move Claude Code session history"

if [[ -n "$CLAUDE_SRC" ]]; then
    run mv "$CLAUDE_SRC" "$CLAUDE_DST"
    if ! $DRY_RUN; then
        MOVED_SESSIONS=$(find "$CLAUDE_DST" -maxdepth 1 -name "*.jsonl" | wc -l | tr -d ' ')
        MOVED_MEMORY=$(find "$CLAUDE_DST/memory" -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
        ok "History moved: ${MOVED_SESSIONS} sessions, ${MOVED_MEMORY} memory files"
        ok "New history path: ${CLAUDE_DST}"
    else
        ok "Would move: ${CLAUDE_SRC} → ${CLAUDE_DST}"
    fi
else
    info "No Claude history to migrate"
fi

# ── Step 3: Verify git remote ─────────────────────────────────────────────────

echo ""
echo "Step 3 — Verify git remote"

if ! $DRY_RUN; then
    REMOTE=$(git -C "$DST" remote get-url origin 2>/dev/null || echo "")
    EXPECTED="git@github.com:Academy-Plus/spwf.git"
    if [[ "$REMOTE" == "$EXPECTED" ]]; then
        ok "Remote origin: ${REMOTE}"
    elif [[ -z "$REMOTE" ]]; then
        warn "No git remote configured — run: git -C ${DST} remote add origin ${EXPECTED}"
    else
        warn "Remote is '${REMOTE}' — expected '${EXPECTED}'"
        info "To fix: git -C ${DST} remote set-url origin ${EXPECTED}"
    fi
else
    info "Would verify remote in: ${DST}"
fi

# ── Step 4: Note about session content ───────────────────────────────────────

echo ""
echo "Step 4 — Session content note"
info "The .jsonl session files contain historical references to the old path"
info "  (plugin-marketplace-simon) inside tool call results. This is expected —"
info "  Claude Code identifies projects by directory name, not by scanning"
info "  session content. The history will load correctly from the new location."
info "  Historical context will reference old paths, which is an accurate record."

# ── Summary ───────────────────────────────────────────────────────────────────

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if $DRY_RUN; then
    echo "  Dry run complete. Re-run without --dry-run to apply."
else
    echo "  Migration complete."
    echo ""
    echo "  Project:  ${DST}"
    echo "  History:  ${CLAUDE_DST}"
    echo ""
    echo "  Next steps:"
    echo "    1. Open a new terminal in ${DST}"
    echo "    2. Run: claude  (sessions will be available from new path)"
    echo "    3. Update any IDE workspace settings pointing to the old path"
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
