#!/usr/bin/env bash
# dep-audit.sh — multi-ecosystem dependency vulnerability audit
# Detects package managers on host and in Docker Compose services.
# Usage: ./scripts/dep-audit.sh [--service=<name>]
#
# Outputs labeled sections per ecosystem. Audit tools exit non-zero when
# findings exist — that is expected; the LLM interprets severity.

set -uo pipefail

EXPLICIT_SERVICE="${1:-}"
COMPOSE_CMD=""
COMPOSE_FILE=""
RUNNING_SERVICES=""

# ── Utilities ────────────────────────────────────────────────────────────────

section() { echo ""; echo "=== $* ==="; }
skip()    { echo "SKIP — $*"; }
warn()    { echo "⚠  $*"; }

# ── Docker Compose detection ─────────────────────────────────────────────────

detect_compose() {
    if docker compose version &>/dev/null 2>&1; then
        COMPOSE_CMD="docker compose"
    elif command -v docker-compose &>/dev/null 2>&1; then
        COMPOSE_CMD="docker-compose"
    fi

    for f in compose.yml compose.yaml docker-compose.yml docker-compose.yaml \
              docker-compose.local.yml docker-compose.override.yml; do
        if [ -f "$f" ]; then
            COMPOSE_FILE="$f"
            break
        fi
    done

    if [ -n "$COMPOSE_CMD" ] && [ -n "$COMPOSE_FILE" ]; then
        RUNNING_SERVICES=$($COMPOSE_CMD ps --services --filter status=running 2>/dev/null || true)
    fi
}

# Print compose environment summary
show_compose_env() {
    section "Docker Compose environment"
    if [ -z "$COMPOSE_FILE" ]; then
        echo "No compose file found"
        return
    fi
    echo "Compose file : $COMPOSE_FILE"
    echo "Compose cmd  : ${COMPOSE_CMD:-not available}"
    if [ -n "$COMPOSE_CMD" ]; then
        echo "All services :"
        $COMPOSE_CMD config --services 2>/dev/null | sed 's/^/  /' || true
        echo "Running      :"
        if [ -n "$RUNNING_SERVICES" ]; then
            echo "$RUNNING_SERVICES" | sed 's/^/  /'
        else
            echo "  (none)"
        fi
    fi
}

# Return the name of the first running service that has $1 on PATH
find_service_with() {
    local cmd="$1"

    # Explicit override wins
    if [ -n "$EXPLICIT_SERVICE" ]; then
        if $COMPOSE_CMD exec -T "$EXPLICIT_SERVICE" which "$cmd" &>/dev/null 2>&1; then
            echo "$EXPLICIT_SERVICE"
            return 0
        fi
        return 1
    fi

    # Probe all running services
    for svc in $RUNNING_SERVICES; do
        if $COMPOSE_CMD exec -T "$svc" which "$cmd" &>/dev/null 2>&1; then
            echo "$svc"
            return 0
        fi
    done
    return 1
}

# ── npm / yarn / pnpm ────────────────────────────────────────────────────────

audit_node() {
    section "Node.js dependency audit"

    [ -f package.json ] || { skip "no package.json found"; return; }

    # Detect lockfile → preferred tool
    local tool="npm"
    [ -f yarn.lock ]       && tool="yarn"
    [ -f pnpm-lock.yaml ]  && tool="pnpm"

    # Host
    if command -v "$tool" &>/dev/null 2>&1; then
        echo "Source: host ($tool)"
        $tool audit --json 2>/dev/null || $tool audit 2>/dev/null || warn "$tool audit failed"
        return
    fi

    # Container
    if [ -n "$COMPOSE_CMD" ]; then
        local svc
        svc=$(find_service_with npm 2>/dev/null \
              || find_service_with yarn 2>/dev/null \
              || echo "") || true
        if [ -n "$svc" ]; then
            echo "Source: docker compose exec $svc (npm)"
            $COMPOSE_CMD exec -T "$svc" npm audit --json 2>/dev/null \
                || $COMPOSE_CMD exec -T "$svc" npm audit 2>/dev/null \
                || warn "npm audit failed in $svc"
            return
        fi
    fi

    skip "package.json found but $tool not on host and no running Node container detected"
    echo "  To fix: docker compose exec <node-service> npm audit"
}

# ── Composer (PHP) ────────────────────────────────────────────────────────────

audit_composer() {
    section "Composer audit (PHP)"

    [ -f composer.json ] || { skip "no composer.json found"; return; }

    # Host
    if command -v composer &>/dev/null 2>&1; then
        echo "Source: host (composer)"
        composer audit --format=json 2>/dev/null || composer audit 2>/dev/null \
            || warn "composer audit failed — requires Composer 2.4+ ($(composer --version 2>/dev/null | head -1))"
        return
    fi

    # Container
    if [ -n "$COMPOSE_CMD" ]; then
        local svc
        svc=$(find_service_with composer 2>/dev/null || echo "") || true
        if [ -n "$svc" ]; then
            echo "Source: docker compose exec $svc (composer)"
            $COMPOSE_CMD exec -T "$svc" composer audit --format=json 2>/dev/null \
                || $COMPOSE_CMD exec -T "$svc" composer audit 2>/dev/null \
                || warn "composer audit failed in $svc — requires Composer 2.4+"
            return
        fi
    fi

    skip "composer.json found but composer not on host and no running PHP container detected"
    echo "  To fix: docker compose exec <php-service> composer audit"
}

# ── pip-audit (Python) ────────────────────────────────────────────────────────

audit_python() {
    local has_manifest=false
    { [ -f requirements.txt ] || [ -f pyproject.toml ] || [ -f Pipfile ]; } \
        && has_manifest=true

    section "pip-audit (Python)"

    $has_manifest || { skip "no Python manifest found (requirements.txt / pyproject.toml / Pipfile)"; return; }

    # Host
    if command -v pip-audit &>/dev/null 2>&1; then
        echo "Source: host (pip-audit)"
        pip-audit --format=json 2>/dev/null || pip-audit 2>/dev/null \
            || warn "pip-audit failed"
        return
    fi

    # Container
    if [ -n "$COMPOSE_CMD" ]; then
        local svc
        svc=$(find_service_with pip-audit 2>/dev/null \
              || find_service_with python 2>/dev/null \
              || echo "") || true
        if [ -n "$svc" ]; then
            echo "Source: docker compose exec $svc (pip-audit)"
            $COMPOSE_CMD exec -T "$svc" pip-audit --format=json 2>/dev/null \
                || $COMPOSE_CMD exec -T "$svc" pip-audit 2>/dev/null \
                || warn "pip-audit not installed in $svc — run: docker compose exec $svc pip install pip-audit"
            return
        fi
    fi

    skip "Python manifest found but pip-audit not on host and no running Python container detected"
    echo "  To fix: pip install pip-audit  OR  docker compose exec <python-service> pip install pip-audit"
}

# ── cargo audit (Rust) ───────────────────────────────────────────────────────

audit_rust() {
    section "cargo audit (Rust)"

    [ -f Cargo.toml ] || { skip "no Cargo.toml found"; return; }

    # Host
    if command -v cargo &>/dev/null 2>&1 && cargo audit --version &>/dev/null 2>&1; then
        echo "Source: host (cargo audit)"
        cargo audit --json 2>/dev/null || cargo audit 2>/dev/null \
            || warn "cargo audit failed"
        return
    fi

    # Container
    if [ -n "$COMPOSE_CMD" ]; then
        local svc
        svc=$(find_service_with cargo 2>/dev/null || echo "") || true
        if [ -n "$svc" ]; then
            echo "Source: docker compose exec $svc (cargo audit)"
            $COMPOSE_CMD exec -T "$svc" cargo audit 2>/dev/null \
                || warn "cargo audit not available in $svc — run: cargo install cargo-audit"
            return
        fi
    fi

    skip "Cargo.toml found but cargo-audit not installed"
    echo "  To fix: cargo install cargo-audit"
}

# ── govulncheck (Go) ─────────────────────────────────────────────────────────

audit_go() {
    section "govulncheck (Go)"

    [ -f go.mod ] || { skip "no go.mod found"; return; }

    # Host
    if command -v govulncheck &>/dev/null 2>&1; then
        echo "Source: host (govulncheck)"
        govulncheck ./... 2>/dev/null || warn "govulncheck failed"
        return
    fi

    # Container
    if [ -n "$COMPOSE_CMD" ]; then
        local svc
        svc=$(find_service_with govulncheck 2>/dev/null \
              || find_service_with go 2>/dev/null \
              || echo "") || true
        if [ -n "$svc" ]; then
            echo "Source: docker compose exec $svc (govulncheck)"
            $COMPOSE_CMD exec -T "$svc" govulncheck ./... 2>/dev/null \
                || warn "govulncheck not in $svc — run: go install golang.org/x/vuln/cmd/govulncheck@latest"
            return
        fi
    fi

    skip "go.mod found but govulncheck not installed"
    echo "  To fix: go install golang.org/x/vuln/cmd/govulncheck@latest"
}

# ── bundle audit (Ruby) ──────────────────────────────────────────────────────

audit_ruby() {
    section "bundle audit (Ruby)"

    [ -f Gemfile.lock ] || { skip "no Gemfile.lock found"; return; }

    # Host
    if command -v bundle-audit &>/dev/null 2>&1 \
        || (command -v bundle &>/dev/null 2>&1 && bundle exec bundle-audit --version &>/dev/null 2>&1); then
        echo "Source: host (bundle-audit)"
        bundle-audit check --update 2>/dev/null \
            || bundle exec bundle-audit check --update 2>/dev/null \
            || warn "bundle-audit failed"
        return
    fi

    # Container
    if [ -n "$COMPOSE_CMD" ]; then
        local svc
        svc=$(find_service_with bundle 2>/dev/null || echo "") || true
        if [ -n "$svc" ]; then
            echo "Source: docker compose exec $svc (bundle-audit)"
            $COMPOSE_CMD exec -T "$svc" bundle exec bundle-audit check --update 2>/dev/null \
                || warn "bundle-audit not in $svc — run: gem install bundler-audit"
            return
        fi
    fi

    skip "Gemfile.lock found but bundler-audit not installed"
    echo "  To fix: gem install bundler-audit"
}

# ── Image scanning ────────────────────────────────────────────────────────────

scan_images() {
    section "Container image scan"

    [ -n "$COMPOSE_FILE" ] || { skip "no compose file detected"; return; }

    local images
    images=$(grep -h "^\s*image:" "$COMPOSE_FILE" 2>/dev/null \
             | sed 's/.*image:\s*//' \
             | tr -d '"'"'" \
             | grep -v '^\s*$' \
             | sort -u) || true

    if [ -z "$images" ]; then
        skip "no explicit image: references in $COMPOSE_FILE (services may use build: only)"
        return
    fi

    echo "Images found:"
    echo "$images" | sed 's/^/  /'
    echo ""

    if command -v trivy &>/dev/null 2>&1; then
        echo "Scanner: trivy"
        while IFS= read -r img; do
            echo ""
            echo "--- $img ---"
            trivy image --severity HIGH,CRITICAL --no-progress "$img" 2>/dev/null \
                || warn "trivy scan failed for $img"
        done <<< "$images"

    elif command -v grype &>/dev/null 2>&1; then
        echo "Scanner: grype"
        while IFS= read -r img; do
            echo ""
            echo "--- $img ---"
            grype "$img" --only-fixed 2>/dev/null \
                || warn "grype scan failed for $img"
        done <<< "$images"

    elif docker scout version &>/dev/null 2>&1; then
        echo "Scanner: docker scout"
        while IFS= read -r img; do
            echo ""
            echo "--- $img ---"
            docker scout cves "$img" 2>/dev/null \
                || warn "docker scout scan failed for $img"
        done <<< "$images"

    else
        warn "No image scanner available. Install one to scan OS-level vulnerabilities:"
        echo "  brew install trivy     # recommended"
        echo "  brew install grype"
        echo "  docker desktop (includes docker scout)"
        echo ""
        echo "Images that would be scanned:"
        echo "$images" | sed 's/^/  /'
    fi
}

# ── Fix command summary ───────────────────────────────────────────────────────

fix_summary() {
    section "Fix command reference"

    echo "Host:"
    [ -f package-lock.json ] && echo "  npm audit fix"
    [ -f yarn.lock ]         && echo "  yarn upgrade"
    [ -f pnpm-lock.yaml ]    && echo "  pnpm audit --fix"
    [ -f composer.json ]     && echo "  composer update <vendor/package> --with-dependencies"
    [ -f requirements.txt ]  && echo "  pip install --upgrade <package>==<safe_version>"
    [ -f Cargo.toml ]        && echo "  cargo update <crate>"
    [ -f go.mod ]            && echo "  go get <module>@<safe_version>"
    [ -f Gemfile.lock ]      && echo "  bundle update <gem>"

    if [ -n "$COMPOSE_CMD" ] && [ -n "$RUNNING_SERVICES" ]; then
        echo ""
        echo "Container (replace <svc> with the service name):"
        echo "  $COMPOSE_CMD exec <svc> npm audit fix"
        echo "  $COMPOSE_CMD exec <svc> composer update <vendor/package> --with-dependencies"
        echo "  $COMPOSE_CMD exec <svc> pip install --upgrade <package>"
        echo "  $COMPOSE_CMD exec <svc> bundle update <gem>"
    fi
}

# ── Main ─────────────────────────────────────────────────────────────────────

echo "=== dep-audit: $(date -u '+%Y-%m-%dT%H:%M:%SZ') ==="
echo "Working directory: $(pwd)"

detect_compose
show_compose_env
audit_node
audit_composer
audit_python
audit_rust
audit_go
audit_ruby
scan_images
fix_summary

echo ""
echo "=== dep-audit complete ==="
