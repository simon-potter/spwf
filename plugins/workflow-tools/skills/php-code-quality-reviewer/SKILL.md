---
name: php-code-quality-reviewer
description: Analyse PHP code and flag bad practices with suggested fixes, grouped by risk category. Use before merging PHP changes, when reviewing a PR touching backend logic, or when auditing a legacy PHP codebase. Covers correctness, security, performance, maintainability, and modern PHP opportunities. Framework-aware (Laravel, Symfony, WordPress). Read-only — flags issues and suggests fixes, never applies them. Complement to security-scan (which covers OWASP/injection in depth) and php-code-simplifier (which applies safe refactors).
disable-model-invocation: true
allowed-tools: [Read, Bash, Glob, Grep]
---

# PHP Code Quality Reviewer

Analyse PHP code for bad practices across five risk categories. Produce a structured report with specific findings, suggested fixes, and confidence ratings. Read-only — never edits files.

## Relationship to other skills

| Skill | What it does | When to use |
|---|---|---|
| `php-code-quality-reviewer` (this) | Flags bad practices, design issues, correctness | Pre-merge review of PHP changes |
| `php-code-simplifier` | Applies safe refactors | After implementation, before PR |
| `security-scan` | Deep OWASP + SQL injection review | High-risk surfaces: auth, billing, input handling |
| `workflow-core:simplify` | Language-agnostic dead code removal | Quick pass on any changed file |

---

## Phase 1 — Detect context

```bash
# PHP version
cat composer.json 2>/dev/null | grep '"php"'

# Framework detection
grep -q "laravel/framework" composer.json 2>/dev/null && echo "Laravel"
grep -q "symfony/framework-bundle" composer.json 2>/dev/null && echo "Symfony"
grep -rn "add_action\|add_filter" --include="*.php" . -l 2>/dev/null | head -1 && echo "WordPress"

# Static analysis tools available
ls vendor/bin/phpstan vendor/bin/psalm vendor/bin/phpcs vendor/bin/php-cs-fixer 2>/dev/null

# Changed files (if reviewing a branch)
git diff --name-only main...HEAD -- '*.php' 2>/dev/null
```

Load the relevant framework reference file before reviewing framework-specific code:
- Laravel → `references/laravel-patterns.md`
- WordPress → `references/wordpress-patterns.md`
- Symfony → `references/symfony-patterns.md`

---

## Phase 2 — Review by risk category

Work through each category. Skip categories with no relevant code — note the skip so the reader knows it was considered.

---

### Category 1 — Correctness

Issues that cause wrong behaviour, silent data corruption, or unexpected failures.

**Loose comparison where strict is required**
```php
// Flag — 0 == 'foo' is true in PHP
if ($status == 0) { ... }
if ($role == false) { ... }

// Suggest
if ($status === 0) { ... }
```
Detection: `grep -n " == \| != " --include="*.php" -r .` — review each result for type-safety risk.

**`empty()` hiding valid falsy values**
```php
// Flag — empty('0') is true; valid value silently ignored
if (empty($postCode)) { return; }
if (!empty($quantity)) { process($quantity); }

// Suggest — be explicit about what you're checking
if ($postCode === null || $postCode === '') { return; }
if ($quantity !== null && $quantity !== 0) { process($quantity); }
```

**`isset()` vs `array_key_exists()` when null is meaningful**
```php
// Flag — isset() returns false if key exists but value is null
if (isset($config['timeout'])) { ... }

// Suggest — when null is a valid configured value
if (array_key_exists('timeout', $config)) { ... }
```

**Catching `Throwable` or `Exception` too broadly**
```php
// Flag — swallows unexpected errors silently
try {
    $this->process();
} catch (\Throwable $e) {
    // silent
}

// Suggest — catch specific exceptions; log or rethrow others
try {
    $this->process();
} catch (PaymentException $e) {
    $this->handlePaymentFailure($e);
} catch (\Throwable $e) {
    Log::error('Unexpected error in process', ['exception' => $e]);
    throw $e;
}
```

**Error suppression with `@`**
```php
// Flag — hides real errors; makes debugging impossible
$result = @file_get_contents($url);

// Suggest — handle the failure explicitly
$result = file_get_contents($url);
if ($result === false) {
    throw new \RuntimeException("Failed to fetch: $url");
}
```

---

### Category 2 — Security

Flag injection, XSS, and access control issues. For deeper SQL injection analysis, direct the user to `/workflow-tools:security-scan`.

**SQL injection**
```php
// Flag — string interpolation in query
$sql = "SELECT * FROM users WHERE id = $id";
$results = $wpdb->get_results($sql);

// Suggest
$results = $wpdb->get_results($wpdb->prepare("SELECT * FROM users WHERE id = %d", $id));
// Or Laravel: User::where('id', $id)->get();
```
Detection: `grep -n "\"SELECT\|'SELECT\|\"INSERT\|\"UPDATE\|\"DELETE" --include="*.php" -r .`

**Unescaped output (XSS)**
```php
// Flag
echo $_GET['name'];
echo $user->bio;  // user-controlled content

// Suggest — plain PHP
echo htmlspecialchars($name, ENT_QUOTES, 'UTF-8');

// Suggest — WordPress
echo esc_html($name);
echo esc_attr($attribute);
echo esc_url($url);
```

**WordPress-specific: missing nonce verification**
```php
// Flag — form handler without nonce check
if (isset($_POST['submit'])) {
    update_option('my_setting', $_POST['value']);
}

// Suggest
if (!isset($_POST['_wpnonce']) || !wp_verify_nonce($_POST['_wpnonce'], 'my_action')) {
    wp_die('Security check failed');
}
update_option('my_setting', sanitize_text_field($_POST['value']));
```

**WordPress-specific: missing capability check**
```php
// Flag — no capability check before sensitive action
function my_admin_action() {
    delete_user(intval($_POST['user_id']));
}

// Suggest
function my_admin_action() {
    if (!current_user_can('delete_users')) {
        wp_die('Insufficient permissions');
    }
    delete_user(intval($_POST['user_id']));
}
```

---

### Category 3 — Performance

**N+1 queries**
```php
// Flag — query inside loop
foreach ($posts as $post) {
    $author = User::find($post->author_id);  // N queries
    echo $author->name;
}

// Suggest — Laravel eager loading
$posts = Post::with('author')->get();
foreach ($posts as $post) {
    echo $post->author->name;  // 1 query total
}

// WordPress equivalent
$posts = get_posts(['numberposts' => -1]);
$author_ids = array_column($posts, 'post_author');
$authors = get_users(['include' => $author_ids]);
```
Detection: `grep -n "find\|get_user\|get_post\|query" --include="*.php" -r .` — look for these inside `foreach` or `for` loops.

**Unbounded queries — missing pagination**
```php
// Flag — returns all records regardless of count
$users = User::all();
$orders = Order::where('status', 'pending')->get();

// Suggest
$users = User::paginate(50);
$orders = Order::where('status', 'pending')->cursor(); // for processing
```

**Repeated expensive calls in loops**
```php
// Flag
foreach ($items as $item) {
    $config = Config::get('pricing');  // re-fetches each iteration
    $tax = TaxService::getRate($item->country);  // potential DB call
}

// Suggest — hoist invariants out of the loop
$config = Config::get('pricing');
foreach ($items as $item) {
    $tax = $taxByCountry[$item->country] ??= TaxService::getRate($item->country);
}
```

**`SELECT *` on large tables**
```php
// Flag
$users = DB::table('users')->get();

// Suggest — select only needed columns
$users = DB::table('users')->select('id', 'name', 'email')->get();
```

---

### Category 4 — Maintainability

**God methods — doing too much**
```php
// Flag — method with multiple responsibilities
public function processOrder($orderId) {
    // validate order
    // check inventory
    // charge payment
    // send email
    // update analytics
    // 200+ lines
}
```
Flag any method over ~50 lines with multiple distinct phases. Suggest extracting named private methods or dedicated service classes per responsibility.

**Boolean parameters hiding intent**
```php
// Flag — what do true and false mean?
$this->render($template, true, false);
sendEmail($user, true);

// Suggest — named methods or typed options
$this->renderWithLayout($template);
sendWelcomeEmail($user);
```

**Mixed array shaped as implicit object**
```php
// Flag — opaque array with string keys
$user['email']
$order['total_price']
$config['retry_count']

// Suggest — typed DTO or value object (especially for complex shapes)
$user->email
$order->totalPrice()
```
Flag when: the array is passed across method boundaries or stored in properties. Inline arrays within a single method scope are acceptable.

**Business logic in controllers or templates**
```php
// Flag — pricing logic in controller
public function checkout(Request $request) {
    $subtotal = 0;
    foreach ($request->items as $item) {
        $subtotal += $item['price'] * $item['qty'];
    }
    $tax = $subtotal * 0.2;
    $total = $subtotal + $tax;
    // ...
}

// Suggest — extract to service
public function checkout(Request $request) {
    $total = $this->pricingService->calculateTotal($request->items);
    // ...
}
```

**Static/global coupling outside integration layers**
```php
// Flag — global state in domain logic
function calculateTax($amount) {
    global $wpdb;
    $rate = $wpdb->get_var("SELECT rate FROM tax_rates WHERE ...");
    return $amount * $rate;
}

// Suggest — inject repository
class TaxCalculator {
    public function __construct(private TaxRateRepository $rates) {}
    public function calculate(Money $amount): Money { ... }
}
```
Exception: thin WordPress integration adapters that legitimately need `$wpdb` or `$wp_query` are acceptable at the boundary.

---

### Category 5 — Modern PHP opportunities

Check PHP version first. Only flag improvements available in the project's PHP version.

| Feature | PHP version | Flag when |
|---|---|---|
| Constructor property promotion | 8.0+ | DTO/value object with manual `$this->x = $x` assignment |
| Nullsafe operator `?->` | 8.0+ | Nested null-guard chains |
| Named arguments | 8.0+ | Function call with 3+ positional args where intent is unclear |
| `match` expression | 8.0+ | `switch` with simple value mapping, no side effects |
| Enums | 8.1+ | Magic strings used as status/type values across multiple files |
| Readonly properties | 8.1+ | DTOs or value objects whose properties should be immutable |
| `readonly class` | 8.2+ | Entire class with only readonly properties |
| `declare(strict_types=1)` | All | Missing from any file that handles type-sensitive logic |

Load `references/php-version-capabilities.md` for the full feature list with caveats.

---

## Phase 3 — Static analysis tools

Report which tools are available and their output. Run only if tools are installed:

```bash
./scripts/php-quality-baseline.sh
```

Or manually:
```bash
# PHPStan
vendor/bin/phpstan analyse --level=max --no-progress 2>/dev/null | tail -20

# Psalm
vendor/bin/psalm --no-progress --output-format=compact 2>/dev/null | tail -20

# PHP CodeSniffer
vendor/bin/phpcs --standard=PSR12 --report=summary 2>/dev/null | tail -10
```

Include tool output as a summary section in the report — do not replicate findings already captured by the tools.

---

## Phase 4 — Output

```
## PHP Code Quality Review

**PHP version**: {version}
**Framework**: {Laravel | Symfony | WordPress | Plain PHP}
**Files reviewed**: {N}
**Static analysis**: {PHPStan level X | Psalm | not installed}

---

### Correctness

| # | File:Line | Issue | Suggestion | Confidence |
|---|---|---|---|---|
| 1 | `app/Services/Order.php:42` | Loose comparison `==` on status | Use `===` | High |

### Security

| # | File:Line | Issue | Suggestion | Confidence |
|---|---|---|---|---|

### Performance

| # | File:Line | Issue | Suggestion | Confidence |
|---|---|---|---|---|

### Maintainability

| # | File:Line | Issue | Suggestion | Confidence |
|---|---|---|---|---|

### Modern PHP opportunities

| # | File:Line | Current pattern | Suggested pattern | PHP version required |
|---|---|---|---|---|

---

### Summary

| Category | Critical | High | Medium | Low |
|---|---|---|---|---|
| Correctness | | | | |
| Security | | | | |
| Performance | | | | |
| Maintainability | | | | |
| Modern PHP | — | — | | |

### Top 3 to fix first

1. {Highest impact finding — file:line}
2.
3.

### Next steps

- Run `/workflow-tools:php-code-simplifier` to apply safe refactors
- For SQL injection deep review: `/workflow-tools:security-scan`
- For automated static analysis: `vendor/bin/phpstan analyse --level=9`
```

---

## Gotchas

- **`empty()` and `isset()` look similar but catch different things.** `empty()` catches `null`, `''`, `0`, `'0'`, `[]`, `false`. `isset()` only catches `null` and undefined. Neither is always correct — always read the intent.
- **`==` behaviour in PHP is notoriously surprising.** `0 == 'foo'` is `true` (pre-PHP 8), `'' == false` is `true`, `'1' == true` is `true`. Flag loose comparisons on any non-boolean values.
- **PHPStan and Psalm disagree.** If both are installed, their findings will overlap but not be identical. Don't double-report the same issue from both tools — use tool output as a supplement, not the primary source.
- **WordPress functions have specific escaping contexts.** `esc_html`, `esc_attr`, `esc_url`, `esc_js`, `esc_textarea` are not interchangeable. Swapping them is a correctness issue, not a style issue.
- **N+1 detection requires reading the loop context.** A `find()` inside a `foreach` is an N+1 only if the `foreach` iterates a collection from the database. If it iterates a small in-memory array (e.g. `$statuses`), it is fine.
- **Scope this review to the changed files when reviewing a PR.** Running it on the whole codebase of a legacy project will produce hundreds of findings — triage is impossible. Use the git diff to scope.

## References

Load on demand:
- `references/php-smell-catalog.md` — full smell catalogue with detection queries
- `references/laravel-patterns.md` — Eloquent N+1, service containers, form requests, policies
- `references/wordpress-patterns.md` — escaping contexts, nonces, capabilities, `$wpdb`, hooks
- `references/symfony-patterns.md` — DI, voters, event subscribers, console commands
- `references/php-version-capabilities.md` — feature availability by PHP version with caveats
