#!/usr/bin/env bash
# php-quality-baseline.sh — run available PHP static analysis tools and report results
# Usage: ./scripts/php-quality-baseline.sh [path]
set -euo pipefail

TARGET="${1:-.}"
PASS=0
FAIL=0

echo "=== PHP Quality Baseline ==="
echo "Target: $TARGET"
echo ""

run_if_available() {
    local label="$1"
    local binary="$2"
    shift 2
    if command -v "$binary" >/dev/null 2>&1 || [ -f "vendor/bin/$(basename "$binary")" ]; then
        BIN="vendor/bin/$(basename "$binary")"
        [ -f "$BIN" ] || BIN="$binary"
        echo "--- $label ---"
        "$BIN" "$@" && PASS=$((PASS+1)) || FAIL=$((FAIL+1))
        echo ""
    else
        echo "--- $label --- SKIPPED (not installed)"
        echo ""
    fi
}

run_if_available "PHPStan" phpstan analyse \
    --no-progress --memory-limit=512M "$TARGET" 2>/dev/null || true

run_if_available "Psalm" psalm \
    --no-progress --output-format=compact "$TARGET" 2>/dev/null || true

run_if_available "PHP CodeSniffer" phpcs \
    --standard=PSR12 --report=summary "$TARGET" 2>/dev/null || true

run_if_available "PHP CS Fixer" php-cs-fixer fix \
    --dry-run --diff --quiet "$TARGET" 2>/dev/null || true

run_if_available "Pest" pest \
    --no-coverage 2>/dev/null || true

run_if_available "PHPUnit" phpunit \
    --no-coverage 2>/dev/null || true

echo "=== Summary ==="
echo "Passed: $PASS | Failed/Issues: $FAIL"
