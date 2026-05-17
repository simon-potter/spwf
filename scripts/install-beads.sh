#!/usr/bin/env bash
#
# install-beads.sh — install the Beads (bd) CLI for use with spwf-beadsify.
#
# This is a thin wrapper around the upstream installer at
# https://github.com/gastownhall/beads. It:
#   1. exits early if bd is already on PATH (idempotent),
#   2. downloads the upstream installer to a temp file (no pipe-to-bash),
#   3. prints the script's SHA256 for verification,
#   4. runs it,
#   5. verifies bd works after install.
#
# The upstream installer prefers /usr/local/bin (sudo) and falls back to
# ~/.local/bin (no sudo). On WSL/most dev boxes the fallback is what fires.
#
# Usage:
#   bash scripts/install-beads.sh
#
# After install:
#   bd --version          # confirm CLI works
#   bd init               # initialise the Beads store inside a project
#
# Do NOT run `bd setup claude` — spwf-beadsify provides its own Claude
# Code integration.

set -euo pipefail

UPSTREAM_URL="https://raw.githubusercontent.com/gastownhall/beads/main/scripts/install.sh"
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

INSTALLER="$TMP_DIR/install.sh"

log()  { echo "==> $*" >&2; }
warn() { echo "!!  $*" >&2; }
fail() { echo "ERR $*" >&2; exit 1; }

# 1. Idempotency check
if command -v bd >/dev/null 2>&1; then
  current=$(bd --version 2>&1 || echo "unknown")
  log "bd already installed: $current"
  log "Skipping reinstall. To upgrade, uninstall first or run the upstream"
  log "installer directly:"
  log "  curl -fsSL $UPSTREAM_URL | bash"
  exit 0
fi

# 2. Fetch upstream installer
log "Downloading upstream installer from gastownhall/beads"
if ! curl -fsSL -o "$INSTALLER" "$UPSTREAM_URL"; then
  fail "Failed to download $UPSTREAM_URL"
fi

# 3. Report SHA256 for transparency
if command -v sha256sum >/dev/null 2>&1; then
  hash=$(sha256sum "$INSTALLER" | awk '{print $1}')
elif command -v shasum >/dev/null 2>&1; then
  hash=$(shasum -a 256 "$INSTALLER" | awk '{print $1}')
else
  hash="(no sha256 tool available)"
fi
log "Installer downloaded ($(wc -c <"$INSTALLER") bytes)"
log "SHA256: $hash"
log "Inspect with: less $INSTALLER (will be removed on exit)"

# 4. Run the upstream installer
log "Running upstream installer..."
echo "" >&2
bash "$INSTALLER"
echo "" >&2

# 5. Verify
if ! command -v bd >/dev/null 2>&1; then
  # bd may have landed in ~/.local/bin which is already on PATH for this
  # shell, but new shells need the user's shell rc to pick it up. Surface
  # both possibilities.
  warn "bd is not on PATH yet. Check that ~/.local/bin is on your PATH:"
  warn "  echo \$PATH | tr ':' '\n' | grep -E '/.local/bin|/usr/local/bin'"
  warn "Add to your shell rc if missing:"
  warn "  export PATH=\"\$HOME/.local/bin:\$PATH\""
  fail "Install completed but bd not found on PATH for this shell."
fi

log "Installed: $(bd --version 2>&1)"
log "Location:  $(command -v bd)"
echo "" >&2
log "Next steps:"
log "  - In a project that uses spwf-beadsify, run: bd init"
log "  - Add .bd/ to .gitignore (spwf-beadsify expects this)"
log "  - Do NOT run 'bd setup claude' — SPWF provides its own integration"
