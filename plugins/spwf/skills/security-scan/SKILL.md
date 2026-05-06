---
name: security-scan
description: On-demand deep security code review covering OWASP Top 10 (2021) with priority on SQL injection, command injection, broken access control, and cryptographic failures. Use when a PR touches auth, billing, user input handling, or database queries; when /approve-plan flagged ⚠ Security on a task; when auditing a new feature area; or when investigating a reported vulnerability. Accepts an optional path argument to scope the review. Complements pr-create (automated tool pre-flight) and approve-plan (design-time advisory) — this skill performs the deep manual analysis neither of those does.
disable-model-invocation: true
allowed-tools: [Read, Bash, Glob, Grep]
---

# Security Scan

Deep security code review against OWASP Top 10 (2021) and SQL injection patterns. Read-only — proposes fixes, never applies them.

## Relationship to other security touchpoints

| Touchpoint | When | What it does |
|---|---|---|
| `/spwf:approve-plan` Security lens | Pre-build | Flags which tasks touch security-sensitive surfaces |
| `/spwf:pr-create` pre-flight | Ship time | Runs gitleaks / semgrep / dep-audit automatically |
| `/trailofbits:semgrep` | On demand | Automated SAST with curated Trail of Bits rulesets, SARIF output |
| **This skill** | On demand | Deep manual code review: logic flaws, design issues, IDOR, second-order injection — things SAST misses |

Use this skill for any review where the question is "could a human attacker exploit this?" rather than "does this match a known vulnerability pattern?"

## Input

Optional path argument:
- No argument: scan the working directory
- File or directory path: scope to that target
- The skill reads actual source files — it does not run instrumented tests

---

## Phase 1 — Scope discovery

Identify entry points, database interaction, auth surfaces, file I/O, and external calls. These are the attack surface to review in Phase 2.

```bash
# HTTP entry points
grep -rn "Route::\|@app\.route\|router\.\(get\|post\|put\|patch\|delete\)\|express()\|http\.HandleFunc\|@(Get\|Post\|Put\|Delete\|Patch)" \
  --include="*.php" --include="*.py" --include="*.js" --include="*.ts" --include="*.go" .

# Raw SQL — highest injection risk
grep -rn "DB::select\|DB::statement\|DB::raw\|\->query(\|\->execute(\|mysqli_query\|cursor\.execute\|db\.query\|sql\.Query\|sql\.Exec\|\$pdo->query\|pgx\." \
  --include="*.php" --include="*.py" --include="*.js" --include="*.ts" --include="*.go" .

# Shell execution
grep -rn "exec(\|shell_exec\|passthru\|system(\|subprocess\.\|os\.system\|child_process\|execSync\|spawnSync\|os/exec" \
  --include="*.php" --include="*.py" --include="*.js" --include="*.ts" --include="*.go" .

# File path operations
grep -rn "fopen\|file_get_contents\|readFile\|open(\|os\.Open\|fs\.\|path\.join\|__DIR__" \
  --include="*.php" --include="*.py" --include="*.js" --include="*.ts" --include="*.go" .

# Outbound HTTP (SSRF surface)
grep -rn "curl_exec\|file_get_contents.*http\|requests\.\(get\|post\)\|fetch(\|axios\.\|http\.get\|net/http" \
  --include="*.php" --include="*.py" --include="*.js" --include="*.ts" --include="*.go" .
```

Read the files at the locations found. Record which files contain which surface types — this informs where to focus Phase 2.

---

## Phase 2 — OWASP Top 10 review

Work through each category. Skip categories with no relevant surface from Phase 1 — note the skip explicitly so the reader knows it was considered. Full language-specific patterns are in `references/owasp-checklist.md`.

### A01 — Broken Access Control

The most common OWASP category. Check:

- **IDOR (Insecure Direct Object Reference)**: every endpoint that accepts a resource ID must verify the authenticated user owns that resource. A lookup like `Order::find($id)` with no ownership check is IDOR.
- **Missing authorisation**: routes returning sensitive data with no auth middleware; admin-only actions accessible to regular users.
- **CORS wildcard on authenticated endpoints**: `Access-Control-Allow-Origin: *` combined with `Access-Control-Allow-Credentials: true` is a critical misconfiguration.
- **Privilege escalation**: can a regular user reach a role-elevation endpoint? Can a user modify another user's records?
- **JWT/session token validation**: are tokens verified against a signature, or just decoded? Is the `none` algorithm accepted?

### A02 — Cryptographic Failures

- **Plaintext secrets**: passwords, tokens, PII logged or stored unencrypted
- **Weak algorithms**: MD5 or SHA-1 for passwords (use bcrypt/argon2); ECB mode; 64-bit block ciphers (3DES)
- **Hardcoded secrets**: API keys, private keys, or passwords in source files (grep for `-----BEGIN`, `password =`, `secret =`, `api_key =`)
- **Insufficient entropy**: `rand()`, `Math.random()`, `time()` as seed for security tokens — use `random_bytes()`, `secrets.token_bytes()`, `crypto.randomBytes()`
- **Missing or disabled TLS**: `verify=False` in Python requests, `rejectUnauthorized: false` in Node, `CURLOPT_SSL_VERIFYPEER` set to false

### A03 — Injection

SQL injection is covered in depth in Phase 3. Additional injection vectors:

**Command injection** — any user input reaching a shell:
```php
// Critical — user controls command argument
exec("convert " . $_POST['filename'] . " output.jpg");

// Safe — escape or avoid shell entirely
exec("convert " . escapeshellarg($filename) . " output.jpg");
```

**Path traversal** — user-controlled path components:
```python
# Vulnerable
path = "/uploads/" + request.args.get("file")
return send_file(path)

# Safe — resolve and verify within allowed directory
base = Path("/uploads").resolve()
target = (base / request.args.get("file")).resolve()
if not str(target).startswith(str(base)):
    abort(403)
```

**Template injection** — user input rendered in server-side templates:
```python
# Vulnerable — Jinja2 SSTI
render_template_string(user_input)

# Safe — pass data as context, not as template
render_template("page.html", content=user_input)
```

**LDAP injection** — look for user input in LDAP filter strings without escaping.

### A04 — Insecure Design

Logic-level issues SAST cannot catch:

- No rate limiting on login, password reset, OTP, or registration endpoints
- No account lockout after repeated auth failures
- Sequential or predictable IDs on sensitive resources (order IDs, invoice IDs, reset tokens)
- Business logic bypass: can a user skip a required step (e.g. payment), access draft/unpublished resources, or receive a discount not intended for them?
- Password reset tokens that are long-lived, guessable, or reusable

### A05 — Security Misconfiguration

- `APP_DEBUG=true` or equivalent in production config
- Default framework credentials not changed
- Verbose error messages returning stack traces to the client
- Unnecessary HTTP methods enabled (TRACE, OPTIONS without CORS intent)
- Missing security headers: CSP, HSTS, X-Frame-Options, X-Content-Type-Options
- Overly permissive file upload (no extension allowlist, no MIME validation, uploads stored in webroot)

### A06 — Vulnerable Components

The pr-create pre-flight (npm audit / pip-audit) covers automated dependency scanning. Flag here only if there is a design-level risk:

- A known-vulnerable library version hardcoded in a lockfile with no upgrade path documented
- Direct dependency on an unmaintained package for a security-critical function (crypto, auth)

### A07 — Authentication Failures

- Sessions not invalidated on logout (server-side session must be destroyed, not just cookie cleared)
- Session ID not regenerated on privilege change (login, role elevation)
- "Remember me" tokens with no expiry or revocation mechanism
- Account enumeration via different responses to valid vs. invalid email on login or password reset
- Passwords accepted with no minimum length or complexity requirement

### A08 — Software and Data Integrity Failures

- Deserialisation of untrusted data without a strict schema (PHP `unserialize()`, Python `pickle.loads()`, Java `ObjectInputStream`)
- Auto-update or plugin-load mechanisms that fetch code from user-controlled or unauthenticated sources
- CI/CD steps that `curl | bash` without checksum verification

### A09 — Logging and Monitoring Failures

- Auth failures (wrong password, invalid token) not logged at all, or logged without IP/user context
- Privileged operations (role changes, data exports, bulk deletions) without audit trail
- Logs that capture passwords, tokens, or full request bodies containing PII
- No alerting on repeated auth failures (brute force is silent)

### A10 — SSRF

Any endpoint that accepts a URL and makes a server-side request:

```python
# Vulnerable — attacker can target internal services
url = request.args.get("url")
response = requests.get(url)  # Can reach http://169.254.169.254/metadata

# Safe — strict allowlist
ALLOWED_HOSTS = {"api.example.com", "cdn.example.com"}
parsed = urlparse(url)
if parsed.hostname not in ALLOWED_HOSTS:
    abort(400)
```

Check for: webhook receivers, image proxies, PDF generators fetching URLs, OAuth redirect URIs, import-from-URL features.

---

## Phase 3 — SQL injection deep review

For every raw query or ORM escape hatch found in Phase 1, apply the full pattern checklist. Full pattern library is in `references/sql-injection.md`.

### Critical patterns

**String concatenation into query** (always Critical):
```php
// PHP — Critical
$query = "SELECT * FROM users WHERE id = " . $_GET['id'];
$result = $db->query("SELECT * FROM orders WHERE status = '" . $status . "'");
```
```python
# Python — Critical
cursor.execute("SELECT * FROM users WHERE email = '" + email + "'")
cursor.execute(f"SELECT * FROM users WHERE name = '{name}'")
cursor.execute("SELECT * FROM users WHERE name = '%s'" % name)  # % substitution is NOT safe
```
```javascript
// JavaScript — Critical
db.query("SELECT * FROM orders WHERE user_id = " + userId)
db.query(`SELECT * FROM users WHERE email = '${email}'`)
```

Safe alternatives use parameterised queries:
```python
cursor.execute("SELECT * FROM users WHERE email = %s", (email,))   # tuple form — safe
cursor.execute("SELECT * FROM users WHERE email = ?", [email])       # sqlite — safe
```

### High patterns

**ORM escape hatches** — disable parameterisation silently:

| Framework | Escape hatch | Risk |
|---|---|---|
| Laravel/Eloquent | `DB::raw()`, `whereRaw()`, `selectRaw()`, `orderByRaw()` | High if interpolating variables |
| Django ORM | `RawSQL()`, `.raw()`, `extra(where=)` | High if interpolating variables |
| Sequelize | `Sequelize.literal()`, `sequelize.query()` | High if not using bind parameters |
| Knex | `.raw()` | High if not using `?` placeholders |
| SQLAlchemy | `text()` with `%` formatting | High; use `text()` with `:param` bindparams |

For each escape hatch found: read whether any variable is interpolated. If so: Critical if user-controlled, High if internally-controlled.

**Dynamic identifiers** — table names and column names cannot be parameterised; require an explicit allowlist:
```python
# Vulnerable — user controls column name
column = request.args.get("sort_by")
cursor.execute(f"SELECT * FROM users ORDER BY {column}")

# Safe — explicit allowlist
ALLOWED_SORT = {"id", "name", "created_at"}
if column not in ALLOWED_SORT:
    column = "id"
cursor.execute(f"SELECT * FROM users ORDER BY {column}")  # Now safe
```

### Medium patterns

**Second-order injection**: a value arrives safely and is stored safely but is later read back and interpolated into a new query without re-parameterisation. Search for patterns where a stored user-supplied value (username, email, display name, address) is used in subsequent query construction.

**Stored procedures with dynamic SQL**: `EXEC` or `EXECUTE IMMEDIATE` inside stored procedures can be injection vectors if they accept user-supplied parameters and interpolate them.

---

## Phase 4 — Output

Produce findings in descending severity order: Critical → High → Medium → Low.

For each finding:

```
### [CRITICAL|HIGH|MEDIUM|LOW] {OWASP category}: {Brief title}

**Location**: `{file}:{line}`
**Issue**: {What the vulnerability is and why it is exploitable}
**Attack vector**: {Concrete attack scenario — what an attacker would send and what they could achieve}
**Fix**:

Before (vulnerable):
```{lang}
{vulnerable code}
```

After (secure):
```{lang}
{fixed code}
```
```

End with a summary scorecard:

```
## Security scan summary

**Scope**: {path reviewed}
**Files reviewed**: {N}
**Query date**: {today}

| OWASP Category | Critical | High | Medium | Low |
|---|---|---|---|---|
| A01 Broken Access Control | | | | |
| A02 Cryptographic Failures | | | | |
| A03 Injection | | | | |
| A04 Insecure Design | | | | |
| A05 Misconfiguration | | | | |
| A07 Auth Failures | | | | |
| A09 Logging Failures | | | | |
| A10 SSRF | | | | |
| **Total** | | | | |

### Top priorities
1. {Most critical — file:line — one-line description}
2.
3.

### Next steps
- Fix all Critical and High findings before merging
- For automated SAST on every PR: configure `/trailofbits:semgrep` in CI
- For secret scanning: install gitleaks pre-commit hook (see `/spwf:pr-create` guidance)
```

If no findings in a category: omit the row. If no findings at all: say so explicitly with the scope reviewed, so the reader knows it was not skipped.

---

## Gotchas

- **ORM use is not injection-proof.** Every major ORM has escape hatches (`DB::raw()`, `RawSQL()`, `Sequelize.literal()`) that silently disable parameterisation. Always check ORM escape hatch usage in addition to raw query presence.
- **`%s` in Python is context-dependent.** `cursor.execute("... WHERE x = '%s'" % val)` is injection-vulnerable. Only `cursor.execute("... WHERE x = %s", (val,))` (tuple second argument) is safe.
- **Second-order injection is invisible to grep.** Searching for concatenation finds first-order injection. Second-order requires tracing a stored value forward to where it is later used in query construction.
- **IDOR is the most common A01 finding and easiest to miss.** Every endpoint accepting an ID parameter: verify that the authenticated user owns that resource, not just that the record exists.
- **Session invalidation is server-side.** Deleting a cookie on logout is not sufficient — the server-side session must be destroyed. Look for what happens server-side on logout.
- **Dynamic ORDER BY / table names cannot be parameterised.** They require an explicit allowlist. Absence of parameterisation is not a bug here — absence of an allowlist is.
- **This skill reviews the working tree, not just the diff.** To scope to a PR's changes only, pass the specific files changed in the PR as the path argument.

## References

- `references/owasp-checklist.md` — Full OWASP Top 10 (2021) checklist with language-specific patterns and detection queries. Load for any category needing deeper investigation.
- `references/sql-injection.md` — Complete SQL injection pattern library: parameterisation patterns per language/ORM, escape hatch matrix, second-order injection, stored procedure risks, dynamic identifier handling.
