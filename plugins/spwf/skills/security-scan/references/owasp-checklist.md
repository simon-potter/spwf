# OWASP Top 10 (2021) Checklist

Reference for the security-scan skill. Load this file when a category needs deeper investigation beyond the abbreviated checks in SKILL.md.

Source: OWASP Top 10 2021 (https://owasp.org/Top10/). Patterns below are language-specific detection guidance.

---

## A01:2021 — Broken Access Control

### Detection queries

```bash
# Laravel — missing middleware on routes
grep -n "Route::" routes/web.php routes/api.php | grep -v "auth\|admin\|middleware"

# Missing ownership check after model fetch
grep -rn "->find\|->findOrFail\|Model::find" --include="*.php" . | grep -v "where\|user_id\|company_id\|owner"

# Django — views missing @login_required or permission_required
grep -rn "def get\|def post\|def put\|def delete" --include="*.py" . -l | \
  xargs grep -L "@login_required\|@permission_required\|IsAuthenticated"
```

### Checklist

- [ ] Every route that returns or modifies a resource verifies the caller owns or is permitted to access that resource
- [ ] Resource IDs in URLs or request bodies are never trusted directly — ownership is verified in the query (e.g. `->where('user_id', auth()->id())->findOrFail($id)`)
- [ ] Admin or privileged routes are protected by a separate middleware or permission check, not just authenticated
- [ ] CORS: `Access-Control-Allow-Origin: *` is not set on any endpoint that also sets `Access-Control-Allow-Credentials: true`
- [ ] JWT `alg` field is validated server-side; `none` algorithm is rejected
- [ ] File download endpoints verify the file belongs to the requesting user (path traversal + IDOR combined risk)

### Common IDOR pattern (Laravel example)

```php
// Vulnerable — looks up by ID without verifying ownership
public function show($id) {
    $order = Order::findOrFail($id);  // Any authenticated user can see any order
    return view('orders.show', compact('order'));
}

// Safe — scope to authenticated user
public function show($id) {
    $order = Order::where('user_id', auth()->id())->findOrFail($id);
    return view('orders.show', compact('order'));
}
```

---

## A02:2021 — Cryptographic Failures

### Detection queries

```bash
# Weak hashing algorithms
grep -rn "md5(\|sha1(\|SHA1\|MD5\|hashlib\.md5\|hashlib\.sha1\|crc32" --include="*.php" --include="*.py" --include="*.js" --include="*.ts" .

# Disabled TLS verification
grep -rn "verify=False\|rejectUnauthorized.*false\|SSL_VERIFYPEER.*false\|InsecureSkipVerify.*true\|verify_ssl.*False" \
  --include="*.py" --include="*.js" --include="*.ts" --include="*.go" --include="*.php" .

# Weak token generation
grep -rn "rand()\|Math\.random()\|random\.random()\|mt_rand\|microtime" --include="*.php" --include="*.py" --include="*.js" .

# Hardcoded secrets
grep -rni "password\s*=\s*['\"][^'\"]\|api_key\s*=\s*['\"][^'\"]\|secret\s*=\s*['\"][^'\"]\|private_key\s*=\s*['\"][^'\"]" \
  --include="*.php" --include="*.py" --include="*.js" --include="*.ts" --include="*.go" \
  --exclude-dir=".git" --exclude-dir="vendor" --exclude-dir="node_modules" .
```

### Checklist

- [ ] Passwords hashed with bcrypt, argon2id, or scrypt — never MD5, SHA-1, SHA-256 (unsalted)
- [ ] Security tokens (session IDs, reset tokens, API keys) generated with cryptographically secure random functions: `random_bytes()` (PHP), `secrets.token_bytes()` (Python), `crypto.randomBytes()` (Node)
- [ ] No plaintext passwords, tokens, or PII in logs, error messages, or HTTP responses
- [ ] TLS verification is enabled on all outbound HTTP clients (no `verify=False`, `rejectUnauthorized: false`)
- [ ] Sensitive data at rest (passwords, PII, payment data) is encrypted or hashed appropriately
- [ ] No hardcoded credentials in source — keys are loaded from environment variables

### Password hashing examples

```php
// PHP — safe
$hash = password_hash($password, PASSWORD_ARGON2ID);
$valid = password_verify($input, $hash);

// PHP — NOT safe
$hash = md5($password);  // Critical
$hash = sha1($password);  // Critical
```

```python
# Python — safe
from passlib.hash import argon2
hash = argon2.hash(password)
valid = argon2.verify(input_password, hash)

# Python — NOT safe
import hashlib
hash = hashlib.md5(password.encode()).hexdigest()  # Critical
```

---

## A03:2021 — Injection

SQL injection is covered in `references/sql-injection.md`. Additional vectors:

### Command injection

```bash
# PHP shell functions
grep -rn "exec(\|shell_exec(\|passthru(\|system(\|popen(\|proc_open(" --include="*.php" .

# Python subprocess
grep -rn "subprocess\.call\|subprocess\.run\|os\.system\|os\.popen\|subprocess\.Popen" --include="*.py" .

# Node child_process
grep -rn "exec(\|execSync(\|spawn(\|spawnSync(" --include="*.js" --include="*.ts" . | grep "child_process"
```

Safe patterns:
- PHP: `escapeshellarg()` / `escapeshellcmd()` on any user input; prefer `proc_open` with argument array
- Python: pass arguments as a list to `subprocess.run([...], shell=False)` — never `shell=True` with user input
- Node: pass argument arrays to `spawn()` — never concatenate into a string for `exec()`

### Path traversal

```bash
grep -rn "file_get_contents\|fopen\|readFile\|send_file\|FileResponse\|storage_path\|base_path" \
  --include="*.php" --include="*.py" --include="*.js" --include="*.ts" . | grep -v "config\|migration\|test"
```

For each file operation that uses a user-supplied path:
1. Is the path resolved to an absolute path before use?
2. Is it verified to be within the allowed base directory?
3. Are `../` sequences stripped or rejected?

### Template injection (SSTI)

```bash
# Jinja2 / Twig / Blade — raw rendering of user input
grep -rn "render_template_string\|Environment\.from_string\|Twig.*createTemplate\|\|->render(\$.*input\|->make(\$.*input" \
  --include="*.py" --include="*.php" .
```

---

## A04:2021 — Insecure Design

Cannot be detected by grep — requires reading business logic.

### Checklist

- [ ] Login endpoint has rate limiting (max N attempts per minute per IP)
- [ ] Password reset has rate limiting and short token lifetime (≤15 minutes)
- [ ] Account lockout or progressive delay after repeated auth failures
- [ ] Resource IDs are not sequential integers on sensitive objects (orders, invoices, reset tokens)
- [ ] Multi-step flows (checkout, onboarding) cannot be completed out of order via direct API calls
- [ ] Discount codes, trial periods, and promotional access cannot be replayed or extended by users
- [ ] Draft/unpublished content is not accessible to unauthenticated users via direct URL

---

## A05:2021 — Security Misconfiguration

```bash
# Debug mode checks
grep -rn "APP_DEBUG\|debug.*true\|DEBUG.*True\|FLASK_DEBUG\|WP_DEBUG" --include="*.env*" --include="*.php" --include="*.py" .
grep -rn "app\.config\[.DEBUG.\]\s*=\s*True\|debug=True" --include="*.py" .

# Error display
grep -rn "display_errors\s*=\s*On\|error_reporting.*E_ALL\|app\.debug\s*=\s*True" --include="*.php" --include="*.py" .

# Default credentials
grep -rni "password.*admin\|password.*password\|password.*1234\|password.*secret" \
  --include="*.php" --include="*.py" --include="*.js" --include="*.ts" \
  --exclude-dir="test" --exclude-dir="tests" --exclude-dir="fixtures" .
```

### Security headers checklist

Check HTTP response headers in middleware configuration:

| Header | Recommended value |
|---|---|
| `Content-Security-Policy` | Restrictive policy; avoid `unsafe-inline` |
| `Strict-Transport-Security` | `max-age=31536000; includeSubDomains` |
| `X-Frame-Options` | `DENY` or `SAMEORIGIN` |
| `X-Content-Type-Options` | `nosniff` |
| `Referrer-Policy` | `strict-origin-when-cross-origin` |
| `Permissions-Policy` | Restrict unused browser APIs |

### File upload checklist

- [ ] File extension validated against an allowlist (not blocklist)
- [ ] MIME type validated server-side (not just from client `Content-Type`)
- [ ] File stored outside webroot or served via a controller (not directly accessible by URL)
- [ ] Maximum file size enforced
- [ ] Filenames sanitised — no user-controlled characters in storage path

---

## A07:2021 — Identification and Authentication Failures

```bash
# Session handling
grep -rn "session_regenerate_id\|Session::regenerate\|request\.session\.cycle_key\|regenerateToken" \
  --include="*.php" --include="*.py" --include="*.js" --include="*.ts" .

# Remember-me tokens
grep -rn "remember_token\|remember_me\|persistent.*cookie\|stay_logged_in" \
  --include="*.php" --include="*.py" --include="*.js" --include="*.ts" .
```

### Checklist

- [ ] Session ID regenerated on login (prevents session fixation)
- [ ] Session destroyed server-side on logout (not just cookie deletion)
- [ ] Minimum password length enforced (≥12 characters recommended)
- [ ] Remember-me tokens are cryptographically random, single-use, and expire
- [ ] Login response is identical for invalid email and invalid password (no enumeration)
- [ ] Password reset tokens expire within 15 minutes
- [ ] Multi-factor authentication available for privileged accounts

---

## A09:2021 — Security Logging and Monitoring Failures

```bash
# Check what is logged on auth events
grep -rn "failed.*login\|login.*failed\|invalid.*password\|authentication.*fail\|Log::warning\|logger\.warning\|logging\.warning" \
  --include="*.php" --include="*.py" --include="*.js" --include="*.ts" .

# Check for sensitive data in logs
grep -rn "Log::info\|logger\.info\|console\.log\|print(" --include="*.php" --include="*.py" --include="*.js" . | \
  grep -i "password\|token\|secret\|key\|credit\|ssn\|dob"
```

### Checklist

- [ ] Failed authentication attempts are logged with IP address and timestamp
- [ ] Account lockout events are logged
- [ ] Privileged operations are logged: role changes, data exports, bulk deletions, admin actions
- [ ] Logs do not contain passwords, tokens, full PII, or payment card data
- [ ] Log entries include enough context to reconstruct an incident (who, what, when, from where)

---

## A10:2021 — Server-Side Request Forgery (SSRF)

```bash
# Outbound HTTP with user-controlled URL
grep -rn "curl_exec\|file_get_contents.*\$\|requests\.\(get\|post\).*request\.\|fetch(.*req\.\|axios\.\(get\|post\).*req\." \
  --include="*.php" --include="*.py" --include="*.js" --include="*.ts" .
```

### Checklist

- [ ] No endpoint accepts a user-supplied URL and makes a server-side request without an allowlist
- [ ] Allowlist uses hostname (not just prefix match): `parsed.hostname in ALLOWED_HOSTS`
- [ ] Redirects from allowed hosts are not followed blindly (a redirect could target `169.254.169.254`)
- [ ] Internal metadata endpoints are blocked at network level: `169.254.169.254`, `::1`, `localhost`, `10.0.0.0/8`, `172.16.0.0/12`, `192.168.0.0/16`
- [ ] Webhook receiver URLs are validated against an allowlist before storage
