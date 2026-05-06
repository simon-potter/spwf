# PHP Smell Catalog

Reference for php-code-simplifier and php-code-quality-reviewer. Full list of PHP-specific code smells with detection patterns and suggested remediation.

---

## Detection commands

Run these before deep review to identify high-density smell areas:

```bash
# Loose comparisons (correctness risk)
grep -rn " == \| != " --include="*.php" . | grep -v "===\|!=="

# Debug output left in code
grep -rn "var_dump\|print_r\|dd(\|dump(\|ray(\|var_export" --include="*.php" .

# Error suppression
grep -rn "@[a-z_]" --include="*.php" . | grep -v "@ " | grep -v "phpstan\|psalm\|@throws\|@param\|@return"

# SQL string interpolation
grep -rn '"SELECT\|"INSERT\|"UPDATE\|"DELETE' --include="*.php" . | grep '\$'

# Global state in domain code
grep -rn "global \$" --include="*.php" . | grep -v "wpdb\|wp_"

# Empty catch blocks
grep -rn "catch.*{" --include="*.php" -A 1 . | grep -B 1 "^--$\|^\s*}$"

# Long methods (rough signal — >50 lines)
awk '/function [a-zA-Z]/{fn=$0; ln=NR} /}/{if(NR-ln>50) print FILENAME":"ln" - possible long method"}' $(find . -name "*.php" -not -path "*/vendor/*")
```

---

## Smell catalogue

### S01 — Loose comparison where strict is required

**Risk**: Correctness — type coercion produces surprising results.

```php
// PHP < 8: 0 == 'foo' is true; '1' == true is true; '' == false is true
if ($status == 0) { ... }
if ($result == false) { ... }
if ($id == null) { ... }  // use $id === null or is_null($id)
```

**Fix**: Replace `==` with `===`, `!=` with `!==`. Exception: intentional type-flexible comparisons (document with a comment).

---

### S02 — `empty()` hiding valid falsy values

**Risk**: Correctness — `empty()` returns true for `0`, `'0'`, `[]`, `''`, `false`, `null`. All may be valid values.

```php
if (empty($quantity)) { ... }    // 0 is a valid quantity
if (empty($postCode)) { ... }    // '' may need separate handling from null
if (!empty($items)) { ... }      // [] vs null distinction lost
```

**Fix**: Be explicit:
```php
if ($quantity === null || $quantity === 0) { ... }
if ($postCode === null || $postCode === '') { ... }
if ($items !== null && count($items) > 0) { ... }
```

---

### S03 — `isset()` vs `array_key_exists()` when null is meaningful

**Risk**: Correctness — `isset($arr['key'])` returns false when the key exists but the value is null.

```php
// False negative — key exists with null value, but treated as "not set"
if (isset($config['timeout'])) {
    setTimeout($config['timeout']);  // never reached if timeout is null
}
```

**Fix**: `array_key_exists('timeout', $config)` when null is a valid value. Use `isset()` only when null and missing are equivalent.

---

### S04 — Error suppression with `@`

**Risk**: Maintainability + Correctness — silences all errors including fatal ones; makes debugging impossible.

```php
$result = @file_get_contents($url);
$conn = @mysqli_connect($host, $user, $pass);
```

**Fix**: Handle the failure explicitly with error checking or exceptions.

---

### S05 — Broad catch (Throwable/Exception without re-throw)

**Risk**: Correctness — unexpected errors disappear silently.

```php
try {
    $this->process();
} catch (\Throwable $e) {
    // silent
}
```

**Fix**: Catch specific exceptions. If catching broadly, always log and rethrow unexpected types.

---

### S06 — Debug output in production code

**Risk**: Security + Maintainability — exposes internal state; breaks output.

Functions: `var_dump(`, `print_r(`, `dd(`, `dump(`, `ray(`, `var_export(`, `debug_backtrace(`

**Fix**: Remove. If intentional debug mode output, gate behind `if (app()->environment('local'))` or equivalent.

---

### S07 — SQL string interpolation

**Risk**: Security — SQL injection.

```php
$sql = "SELECT * FROM users WHERE id = $id";
$sql = "SELECT * FROM posts WHERE title LIKE '%$search%'";
```

**Fix**: Parameterised queries. See `security-scan` for full SQL injection pattern library.

---

### S08 — Unescaped output

**Risk**: Security — XSS.

```php
echo $user->name;
echo $_GET['q'];
```

**Fix**: `htmlspecialchars($value, ENT_QUOTES, 'UTF-8')` for plain PHP. Framework-specific: see laravel-patterns.md, wordpress-patterns.md.

---

### S09 — God method (too many responsibilities)

**Risk**: Maintainability — hard to test, change, or understand.

Signal: method >50 lines with multiple distinct phases (validate → query → transform → respond).

**Fix**: Extract named private methods or move to a dedicated service class per responsibility.

---

### S10 — Boolean parameters hiding intent

**Risk**: Maintainability — call sites are unreadable.

```php
createUser($name, $email, true, false, true);
sendEmail($user, true);
```

**Fix**: Named methods, options objects, or enums.

---

### S11 — Mixed array used as implicit object

**Risk**: Maintainability — no type safety, no IDE support, schema implicit.

```php
$user['first_name']
$order['total_price']
$config['retry_count']
```

**Fix**: Typed DTO or value object when the array crosses method boundaries or is stored in a property.

---

### S12 — Business logic in controllers or views

**Risk**: Maintainability — untestable; duplicated across endpoints.

```php
// Controller doing pricing calculation inline
$tax = $subtotal * 0.2;
$total = $subtotal + $tax;
```

**Fix**: Extract to a service class. Controllers should only: parse input, call a service, return a response.

---

### S13 — Static/global coupling outside integration boundary

**Risk**: Testability + Maintainability — cannot be mocked; hidden dependency.

```php
function calculateTax($amount) {
    global $wpdb;
    $rate = $wpdb->get_var("...");
    return $amount * $rate;
}
```

**Fix**: Inject a repository or service. Reserve `global $wpdb` for WordPress integration adapter layer only.

---

### S14 — N+1 queries

**Risk**: Performance — database queries inside loops.

```php
foreach ($posts as $post) {
    $author = User::find($post->author_id);
}
```

**Fix**: Eager loading. Framework-specific patterns in laravel-patterns.md, wordpress-patterns.md.

---

### S15 — Unbounded queries

**Risk**: Performance — fetches entire table regardless of size.

```php
$users = User::all();
$orders = Order::where('status', 'pending')->get();
```

**Fix**: Add pagination (`->paginate(50)`) or streaming (`->cursor()`).

---

### S16 — Magic strings/numbers used across multiple files

**Risk**: Maintainability — a string change requires finding all occurrences.

```php
if ($status === 'pending') { ... }  // in 8 different files
if ($type === 2) { ... }
```

**Fix**: Enum (PHP 8.1+), class constant, or config value.

---

### S17 — Deeply nested conditionals

**Risk**: Maintainability — cognitive load; hard to follow all paths.

```php
if ($a) {
    if ($b) {
        if ($c) {
            // ...
        }
    }
}
```

**Fix**: Guard clauses with early returns; `match`; extracted named conditions.

---

### S18 — Missing `declare(strict_types=1)`

**Risk**: Correctness — PHP coerces types at function calls without strict_types; a `string` parameter receives an `int` silently.

**Fix**: Add `declare(strict_types=1);` as the second line (after `<?php`) in any file containing typed function signatures.

---

### S19 — Unnecessary `else` after `return`/`throw`

**Risk**: Maintainability — cognitive overhead; `else` branch is implicit after early return.

```php
if ($condition) {
    return $a;
} else {
    return $b;  // else is redundant
}
```

**Fix**:
```php
if ($condition) {
    return $a;
}
return $b;
```

---

### S20 — Repeated remote/expensive calls without caching

**Risk**: Performance — redundant external requests or heavy computations.

```php
foreach ($users as $user) {
    $rate = file_get_contents('https://api.rates.io/current');  // per iteration
}
```

**Fix**: Hoist invariant calls outside the loop; use application cache (`Cache::remember()`).
