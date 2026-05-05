# SQL Injection Pattern Library

Reference for the security-scan skill. Load this file when reviewing database interaction code in Phase 3.

Adapted from the `github/awesome-copilot/sql-code-review` skill (MIT).

---

## Severity classification

| Pattern | Severity | Reasoning |
|---|---|---|
| String concatenation with user input | Critical | Direct injection, no mitigation |
| f-string / format string with user input | Critical | Equivalent to concatenation |
| `%` string substitution into query | Critical | NOT parameterisation — common Python mistake |
| ORM escape hatch with user-controlled variable | Critical | Bypasses ORM safety |
| ORM escape hatch with internal variable | High | Internal values can be attacker-influenced through indirect paths |
| Dynamic table/column name without allowlist | High | Cannot be parameterised; requires explicit allowlist |
| Stored procedure with dynamic SQL | High | `EXEC`/`EXECUTE IMMEDIATE` inside sproc can be injected |
| Second-order injection | Medium | Stored value later interpolated without re-parameterisation |
| Missing allowlist on dynamic identifier | High | Allowlist is the only safe mitigation for identifiers |

---

## First-order injection patterns

### PHP

```php
// Critical — string concatenation
$result = $db->query("SELECT * FROM users WHERE id = " . $_GET['id']);
$result = mysqli_query($conn, "SELECT * FROM orders WHERE email = '" . $email . "'");

// Critical — variable interpolation in string
$result = $pdo->query("SELECT * FROM users WHERE name = '$name'");

// Safe — PDO prepared statements
$stmt = $pdo->prepare("SELECT * FROM users WHERE id = ?");
$stmt->execute([$_GET['id']]);

// Safe — named parameters
$stmt = $pdo->prepare("SELECT * FROM users WHERE email = :email");
$stmt->execute([':email' => $email]);
```

### Python

```python
# Critical — string concatenation
cursor.execute("SELECT * FROM users WHERE id = " + user_id)
cursor.execute("SELECT * FROM users WHERE email = '" + email + "'")

# Critical — f-string interpolation
cursor.execute(f"SELECT * FROM users WHERE name = '{name}'")

# Critical — % format substitution (common mistake — looks like parameterisation)
cursor.execute("SELECT * FROM users WHERE email = '%s'" % email)
cursor.execute("SELECT * FROM users WHERE id = %d" % user_id)

# Safe — tuple parameterisation (psycopg2, mysql-connector, sqlite3)
cursor.execute("SELECT * FROM users WHERE email = %s", (email,))
cursor.execute("SELECT * FROM users WHERE id = %s", (user_id,))

# Safe — SQLAlchemy with bindparams
from sqlalchemy import text
result = db.execute(text("SELECT * FROM users WHERE email = :email"), {"email": email})
```

### JavaScript / TypeScript

```javascript
// Critical — string concatenation
db.query("SELECT * FROM users WHERE id = " + userId);
db.query(`SELECT * FROM orders WHERE status = '${status}'`);

// Safe — pg (node-postgres)
db.query("SELECT * FROM users WHERE id = $1", [userId]);

// Safe — mysql2
db.query("SELECT * FROM users WHERE email = ?", [email]);

// Safe — Knex
knex("users").where("id", userId);
knex.raw("SELECT * FROM users WHERE id = ?", [userId]);
```

### Go

```go
// Critical — string concatenation with Sprintf
query := fmt.Sprintf("SELECT * FROM users WHERE id = %d", userID)
db.Query(query)

// Safe — parameterised
db.QueryRow("SELECT * FROM users WHERE id = $1", userID)
db.Exec("UPDATE users SET name = $1 WHERE id = $2", name, id)
```

---

## ORM escape hatch matrix

| ORM | Escape hatch | Safe usage | Vulnerable usage |
|---|---|---|---|
| Laravel Eloquent | `DB::raw()` | `DB::raw("NOW()")` — hardcoded | `DB::raw($userInput)` — Critical |
| Laravel Eloquent | `whereRaw()` | `whereRaw("status = ?", [$status])` | `whereRaw("status = '$status'")` |
| Laravel Eloquent | `selectRaw()` | `selectRaw("COUNT(*) as total")` | `selectRaw("$column as val")` |
| Laravel Eloquent | `orderByRaw()` | Only with allowlisted column | `orderByRaw($userColumn)` |
| Django ORM | `RawSQL()` | `RawSQL("age > %s", [18])` | `RawSQL(f"age > {age}")` |
| Django ORM | `.raw()` | `.raw("SELECT * FROM t WHERE id = %s", [id])` | `.raw(f"... WHERE id = {id}")` |
| Django ORM | `extra(where=)` | `extra(where=["age > %s"], params=[18])` | `extra(where=[f"age > {age}"])` |
| SQLAlchemy | `text()` | `text("... WHERE id = :id").bindparams(id=id)` | `text(f"... WHERE id = {id}")` |
| Sequelize | `Sequelize.literal()` | Only hardcoded SQL | `literal(userInput)` — Critical |
| Sequelize | `sequelize.query()` | `query("... WHERE id = ?", { replacements: [id] })` | `query("... WHERE id = " + id)` |
| Knex | `.raw()` | `raw("? AS alias", [value])` | `raw(`\`${column}\`` )` |

**Detection:**
```bash
# Laravel escape hatches
grep -rn "DB::raw\|whereRaw\|selectRaw\|orderByRaw\|havingRaw\|fromRaw\|joinRaw" --include="*.php" .

# Django escape hatches
grep -rn "RawSQL\|\.raw(\|extra(where\|extra(select" --include="*.py" .

# SQLAlchemy text()
grep -rn "from sqlalchemy.*import.*text\|db\.execute.*text\|session\.execute.*text" --include="*.py" .

# Sequelize escape hatches
grep -rn "Sequelize\.literal\|sequelize\.query\|\.query(" --include="*.js" --include="*.ts" . | grep -v "test\|spec"

# Knex raw
grep -rn "\.raw(" --include="*.js" --include="*.ts" . | grep -v "test\|spec"
```

---

## Dynamic identifiers (table names, column names)

Table and column names **cannot be parameterised**. The only safe mitigation is an explicit allowlist.

```python
# Vulnerable — user controls column name
sort_column = request.args.get("sort")
cursor.execute(f"SELECT * FROM products ORDER BY {sort_column}")

# Safe — explicit allowlist
ALLOWED_SORT_COLUMNS = {"id", "name", "price", "created_at"}
sort_column = request.args.get("sort", "id")
if sort_column not in ALLOWED_SORT_COLUMNS:
    sort_column = "id"
cursor.execute(f"SELECT * FROM products ORDER BY {sort_column}")  # Now safe
```

```php
// Safe — Laravel dynamic column with allowlist
$allowed = ['name', 'email', 'created_at'];
$column = in_array(request('sort'), $allowed) ? request('sort') : 'name';
$users = User::orderBy($column)->get();
```

The same pattern applies to table names, schema names, and database names.

---

## Second-order injection

A user-supplied value stored correctly (parameterised insert) but later used in a new query by string interpolation.

**Example:**
```python
# Step 1 — safe insert (user provides username)
cursor.execute("INSERT INTO users (username) VALUES (%s)", (username,))

# Step 2 — later, username is read back and interpolated — VULNERABLE
user = get_user(user_id)
cursor.execute(f"SELECT * FROM audit_log WHERE actor = '{user['username']}'")
# If username was stored as: admin' OR '1'='1  → injection succeeds at Step 2
```

**Detection:**
Second-order injection is not detectable by grep alone. Look for:
1. Places where user-supplied values are stored (INSERT/UPDATE)
2. Places where stored values are later retrieved and used in subsequent queries
3. Trace whether the retrieved value is parameterised in the second query

Focus on fields that users control directly: username, display name, email, address, bio, comments.

---

## Stored procedures

`EXEC` and `EXECUTE IMMEDIATE` inside stored procedures can be injection vectors if they accept user-supplied parameters:

```sql
-- Vulnerable stored procedure
CREATE PROCEDURE SearchUsers(@SearchTerm NVARCHAR(255))
AS BEGIN
    DECLARE @sql NVARCHAR(1000)
    SET @sql = 'SELECT * FROM users WHERE name LIKE ''%' + @SearchTerm + '%'''
    EXEC(@sql)  -- Injection via @SearchTerm
END

-- Safe — parameterised sp_executesql
CREATE PROCEDURE SearchUsers(@SearchTerm NVARCHAR(255))
AS BEGIN
    DECLARE @sql NVARCHAR(1000)
    SET @sql = N'SELECT * FROM users WHERE name LIKE @pattern'
    EXEC sp_executesql @sql, N'@pattern NVARCHAR(255)', @pattern = '%' + @SearchTerm + '%'
END
```

**Detection:**
```sql
-- Find stored procedures using dynamic SQL
SELECT OBJECT_NAME(object_id), definition
FROM sys.sql_modules
WHERE definition LIKE '%EXEC(%' OR definition LIKE '%EXECUTE IMMEDIATE%'
```

---

## Access control in SQL

Beyond injection, review SQL for access control failures:

```sql
-- Missing tenant isolation — all companies can see all records
SELECT * FROM orders WHERE id = ?

-- Correct — always scope by company/user
SELECT * FROM orders WHERE id = ? AND company_id = ?
```

Check every query that returns user data for proper ownership/tenant scoping. In multi-tenant systems this is as critical as injection.

---

## Output format for SQL findings

Use the standard finding template from SKILL.md with these additions:

- **Attack vector**: include a concrete example payload (e.g. `' OR '1'='1` or `1; DROP TABLE users--`)
- **Estimated exploitability**: Can an unauthenticated user reach this? Authenticated? Admin only?
- **Data at risk**: What data could be extracted or corrupted?
