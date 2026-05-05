---
name: dep-audit
description: Multi-ecosystem dependency vulnerability audit. Detects package managers on the host and in Docker Compose services, runs the appropriate audit tool per ecosystem, and optionally scans container images with Trivy/Grype/Docker Scout. Surfaces Critical and High findings with copy-paste fix commands. Use before creating a PR, after adding or upgrading dependencies, or when a CVE alert arrives. Complements security-scan (OWASP/logic flaws) and pr-create pre-flight (which runs a lighter host-only check).
disable-model-invocation: true
allowed-tools: [Read, Bash, Glob, Grep]
---

# Dependency Vulnerability Audit

Audit every dependency ecosystem in the project — whether tools run on the host or inside Docker Compose containers — and surface Critical and High findings with actionable fix commands.

## When to use

- Before creating a PR (especially after adding or upgrading dependencies)
- When a CVE alert arrives for a package the project uses
- Periodic security hygiene (weekly or sprint cadence)
- After adding a new Docker service that introduces new transitive dependencies

Do **not** run this mid-task. It modifies no files — it only reads and reports.

## Phase 1 — Environment detection

Run the script to detect everything in one pass:

```bash
SKILL_ROOT="$(find ~/.claude -name 'dep-audit.sh' -path '*/dep-audit/scripts/*' 2>/dev/null | head -1 | xargs dirname 2>/dev/null || echo '')"

if [ -n "$SKILL_ROOT" ]; then
    bash "$SKILL_ROOT/dep-audit.sh" 2>&1
else
    echo "dep-audit.sh not found — run detection inline (see Phase 1 manual steps below)"
fi
```

If the script is not found, perform these detection steps inline:

**Host tools check:**
```bash
echo "=== Host tool inventory ==="
command -v npm      && npm --version       || echo "npm: not found"
command -v composer && composer --version  || echo "composer: not found"
command -v pip-audit                       || echo "pip-audit: not found"
command -v cargo    && cargo audit --version 2>/dev/null || echo "cargo-audit: not found"
command -v govulncheck                     || echo "govulncheck: not found"
command -v bundle                          || echo "bundle: not found"
```

**Docker Compose detection:**
```bash
# Find compose file (checked in priority order)
for f in compose.yml compose.yaml docker-compose.yml docker-compose.yaml \
          docker-compose.local.yml docker-compose.override.yml; do
    [ -f "$f" ] && echo "Compose file: $f" && break
done

# Detect compose command (v2 preferred)
docker compose version 2>/dev/null && COMPOSE="docker compose" \
    || (command -v docker-compose && COMPOSE="docker-compose") \
    || echo "Docker Compose not available"

# List running services
$COMPOSE ps --services --filter status=running 2>/dev/null || echo "No running services"

# List all configured services
$COMPOSE config --services 2>/dev/null
```

**Service → ecosystem mapping:**

Map services to ecosystems using two signals — image name and service name. Both are heuristics; the script confirms by checking whether the tool binary exists inside the container.

| Image pattern | Service name pattern | Likely ecosystem |
|---|---|---|
| `node:*`, `*-node` | `node`, `frontend`, `vite`, `next`, `nuxt`, `web` | npm |
| `php:*`, `wordpress:*`, `*-php` | `php`, `app`, `api`, `laravel`, `wordpress` | Composer |
| `python:*`, `*-python` | `python`, `django`, `flask`, `fastapi`, `api` | pip-audit |
| `rust:*`, `*-rust` | `rust` | cargo audit |
| `golang:*`, `go:*` | `go`, `golang` | govulncheck |
| `ruby:*`, `*-ruby` | `ruby`, `rails` | bundle audit |

The script probes each running service with `docker compose exec -T <svc> which <tool>` rather than relying on name matching alone.

## Phase 2 — Package-level audits

For each ecosystem detected, the execution order is:
1. **Host tool** — if the manifest exists and the binary is installed locally
2. **Running container** — `docker compose exec -T <service> <tool>` if a service has the binary
3. **Skip** — report clearly which ecosystem was skipped and why

**Per-ecosystem commands and what to look for:**

### npm / yarn / pnpm
```bash
# Host
npm audit --json 2>/dev/null          # npm 7+: .vulnerabilities{}
yarn audit --json 2>/dev/null         # per-package JSON lines
pnpm audit --json 2>/dev/null

# Container
docker compose exec -T <svc> npm audit --json 2>/dev/null
```
`npm audit` exits 1 when vulnerabilities exist — this is expected. Focus on `.metadata.vulnerabilities.critical` and `.metadata.vulnerabilities.high`.

Fix commands: `npm audit fix` (non-breaking upgrades only), `npm audit fix --force` (may include breaking changes — review first).

### Composer (PHP)
```bash
# Host
composer audit --format=json 2>/dev/null

# Container
docker compose exec -T <svc> composer audit --format=json 2>/dev/null
```
Requires Composer 2.4+. Check version with `composer --version`. If older, suggest upgrading: `composer self-update`.

Fix commands: `composer update <vendor/package> --with-dependencies`

### pip-audit (Python)
```bash
# Host
pip-audit --format=json 2>/dev/null
pip-audit --format=json -r requirements.txt 2>/dev/null

# Container
docker compose exec -T <svc> pip-audit --format=json 2>/dev/null
```
`pip-audit` is not bundled with Python — it must be installed separately. If absent in the container: `docker compose exec <svc> pip install pip-audit`.

Fix commands: `pip install --upgrade <package>==<safe_version>`

### cargo audit (Rust)
```bash
# Host
cargo audit --json 2>/dev/null

# Container
docker compose exec -T <svc> cargo audit 2>/dev/null
```
Requires `cargo install cargo-audit`. The JSON output key path is `.vulnerabilities.list[].advisory.severity`.

Fix commands: `cargo update <crate>` (if a compatible safe version exists)

### govulncheck (Go)
```bash
# Host
govulncheck ./... 2>/dev/null

# Container
docker compose exec -T <svc> govulncheck ./... 2>/dev/null
```
Install: `go install golang.org/x/vuln/cmd/govulncheck@latest`. Reports only vulnerabilities that are actually called in the code — fewer false positives than other tools.

Fix commands: `go get <module>@<safe_version>`

### bundle audit (Ruby)
```bash
# Host
bundle exec bundle-audit check --update 2>/dev/null

# Container
docker compose exec -T <svc> bundle exec bundle-audit check --update 2>/dev/null
```
The `--update` flag refreshes the advisory database first. Install: `gem install bundler-audit`.

Fix commands: `bundle update <gem>`

## Phase 3 — Image-level scanning

If a Docker Compose file is present, extract image references and scan for OS-level CVEs. This is in addition to, not instead of, package-level audits.

```bash
# Extract images from compose file
grep -h "^\s*image:" compose.yml docker-compose.yml 2>/dev/null \
    | sed 's/.*image:\s*//' | tr -d '"'"'" | sort -u
```

Try scanners in priority order:

```bash
# Trivy (preferred — broadest coverage)
trivy image --severity HIGH,CRITICAL --no-progress <image> 2>/dev/null

# Grype (alternative)
grype <image> --only-fixed 2>/dev/null

# Docker Scout (built into Docker Desktop)
docker scout cves <image> 2>/dev/null
```

If no scanner is available, report the gap:
```
⚠ No image scanner found. Install trivy (brew install trivy) or grype (brew install grype)
  to scan OS-level vulnerabilities in:
  - <image1>
  - <image2>
```

**Do not scan images that are not referenced in a compose file** — avoid pulling arbitrary images.

## Phase 4 — Report

Produce a structured report:

```
## Dependency Audit Report

**Environment**: host | docker compose (<compose_file>)
**Ecosystems scanned**: N
**Running services**: <list>

### Findings summary

| Ecosystem | Tool | Critical | High | Medium | Low | Status |
|---|---|---|---|---|---|---|
| npm        | npm audit    | 0 | 2 | 5 | 3 | ✗ HALT |
| Composer   | composer audit | 0 | 0 | 1 | 0 | ⚠ WARN |
| Python     | pip-audit    | — | — | — | — | SKIP (not installed in container) |
| Images     | trivy        | 1 | 3 | — | — | ✗ HALT |

### Critical and High findings

| # | Ecosystem | Package | Installed | CVE / Advisory | Fix |
|---|---|---|---|---|---|
| 1 | npm | lodash | 4.17.20 | CVE-2021-23337 | npm audit fix |
| 2 | npm | axios | 0.21.1 | CVE-2021-3749 | npm install axios@1.7.4 |
| 3 | image:app | openssl | 3.0.2 | CVE-2023-0286 | Update base image |

### Skipped ecosystems

| Ecosystem | Reason | Action |
|---|---|---|
| Python | pip-audit not on host or in containers | docker compose exec app pip install pip-audit |
| Rust | No Cargo.toml found | — |

### Image scan gaps

| Image | Scanner | Gap |
|---|---|---|
| postgres:15 | none | Install trivy to scan OS packages |

### Fix commands

**Host:**
  npm audit fix
  composer update symfony/http-kernel --with-dependencies

**Container (docker compose exec):**
  docker compose exec app npm audit fix
  docker compose exec php composer update symfony/http-kernel

### Next steps

- Critical/High findings above must be resolved before shipping
- For deep code-level security review: /workflow-tools:security-scan
- For structured PR creation with pre-flight gate: /workflow-core:pr-create
```

**Halt criteria:** Any Critical or High finding is a halt. Surface these to the user before any PR creation.

## Gotchas

- **`docker compose exec` requires running containers.** Check with `docker compose ps` first. If containers are stopped, either start them (`docker compose up -d`) or run `docker compose run --rm <svc> <tool>` (slower — creates a throwaway container).
- **npm audit exits 1 on any finding.** This is expected behaviour — it's not a script failure. Use `|| true` when running in CI pipelines.
- **Composer audit requires 2.4+.** Older projects pinned to Composer 2.2 (LTS) don't have the `audit` subcommand. Check `composer --version` before reporting a failure.
- **pip-audit is not bundled with Python.** It must be installed separately in each Python environment or container. `pip-audit` inside a virtualenv only audits that env's packages.
- **Trivy image scans pull images if not cached.** On a slow connection, this can be significant. Flag this to the user before initiating a scan of large or many images.
- **govulncheck only flags reachable vulnerabilities.** It performs call-graph analysis, so it reports fewer findings than other tools — this is a feature, not a miss. Do not override with a broader tool just to get more findings.
- **Service name guessing is heuristic.** If the script can't find the right service, explicitly pass the service name. The script tries `docker compose exec -T <svc> which <tool>` across all running services — if a service doesn't have the tool binary on PATH, it's skipped.
- **Multi-stage Dockerfiles may not have audit tools in the final image.** A production image strips dev dependencies. If `npm` is unavailable in the final container, check if there's a separate `dev` service in the compose file that uses the full image.
- **`compose.yml` takes precedence over `docker-compose.yml`** per the Docker Compose v2 spec. The script checks in this order: `compose.yml`, `compose.yaml`, `docker-compose.yml`, `docker-compose.yaml`.
- **Override files are merged automatically.** `docker-compose.override.yml` is always merged if present. The `docker compose config` output reflects the merged result — use that, not the raw yaml files, for authoritative service configuration.
