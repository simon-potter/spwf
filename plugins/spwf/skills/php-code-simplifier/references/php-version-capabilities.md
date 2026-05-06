# PHP Version Capabilities

Reference for php-code-simplifier and php-code-quality-reviewer. Check the project's PHP version before suggesting any feature below.

---

## Detection

```bash
# From composer.json
cat composer.json | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('require',{}).get('php','unknown'))"

# From running PHP
php -r "echo PHP_VERSION;"
```

---

## Feature availability by version

### PHP 8.0 (released Nov 2020)

| Feature | Notes |
|---|---|
| **Named arguments** | `array_slice(array: $a, offset: 1)` — improves clarity on functions with many params |
| **Union types** | `function foo(int\|string $id): void` |
| **`match` expression** | Strict (`===`) value comparison, returns a value, no fallthrough, exhaustive by default |
| **Nullsafe operator `?->`** | `$user?->profile?->name` — short-circuits to `null` if any step is null |
| **Constructor property promotion** | `public function __construct(private string $name) {}` |
| **`str_contains()`, `str_starts_with()`, `str_ends_with()`** | Replace `strpos() !== false` patterns |
| **`throw` as expression** | `$value = $x ?? throw new \InvalidArgumentException(...)` |
| **`static` return type** | Late static binding return type hint |
| **`mixed` type** | Explicit "any type" declaration |

**Caveats:**
- `match` uses strict comparison — do not replace `switch` that relies on loose comparison
- Constructor promotion: promoted properties become `public`/`protected`/`private` — check visibility intent
- Nullsafe operator short-circuits all method calls in the chain — do not use if any call has a required side effect

---

### PHP 8.1 (released Nov 2021)

| Feature | Notes |
|---|---|
| **Enums** | `enum Status: string { case Pending = 'pending'; }` — backed or pure |
| **Readonly properties** | `public readonly string $name;` — can only be set once, in the constructor |
| **Fibers** | Cooperative multitasking — relevant for async PHP (Swoole, ReactPHP) |
| **Intersection types** | `Countable&Iterator` |
| **`never` return type** | Function that always throws or exits |
| **`array_is_list()`** | Check whether array has sequential integer keys |
| **First-class callable syntax** | `$fn = strlen(...)` — replaces `Closure::fromCallable('strlen')` |

**Caveats:**
- Readonly properties cannot be cloned with a different value — `clone with` syntax is PHP 8.4+
- Backed enums (`Status: string`) are serialisable; pure enums are not
- Readonly + constructor promotion: `public function __construct(public readonly string $name) {}`

---

### PHP 8.2 (released Dec 2022)

| Feature | Notes |
|---|---|
| **`readonly` classes** | All properties are implicitly readonly — useful for value objects and DTOs |
| **Disjunctive Normal Form (DNF) types** | `(A&B)\|null` |
| **`true`, `false`, `null` as standalone types** | `function alwaysFails(): false` |
| **`SensitiveParameter` attribute** | Redacts values in stack traces (useful for passwords, tokens) |
| **Constants in traits** | Traits can now define constants |
| **Deprecation of dynamic properties** | `$obj->undeclaredProp = 1` triggers deprecation unless class uses `#[AllowDynamicProperties]` |

**Caveats:**
- `readonly class` cannot have non-readonly properties — any mutable state requires a non-readonly class
- Dynamic property deprecation: affects legacy code heavily; flag but do not auto-fix

---

### PHP 8.3 (released Nov 2023)

| Feature | Notes |
|---|---|
| **Typed class constants** | `const string VERSION = '1.0';` |
| **`json_validate()`** | Validate JSON without decoding |
| **`#[Override]` attribute** | Declare that a method overrides a parent method — static analysis aid |
| **`mb_str_pad()`** | Multibyte-safe `str_pad()` |
| **Dynamic class constant fetch** | `ClassName::{$const}` |
| **`readonly` property reinitialisation in `clone`** | Partial: `clone` can now reinitialise readonly properties |

---

## Quick reference: "should I suggest this?"

| Suggestion | Requires |
|---|---|
| `match` instead of `switch` | PHP 8.0+ |
| Nullsafe `?->` | PHP 8.0+ |
| Constructor promotion | PHP 8.0+ |
| `str_contains()` | PHP 8.0+ |
| Named arguments | PHP 8.0+ |
| Enum instead of const/magic string | PHP 8.1+ |
| `readonly` property | PHP 8.1+ |
| `readonly class` | PHP 8.2+ |
| Typed class constant | PHP 8.3+ |
| `declare(strict_types=1)` | All versions |
| Guard clauses | All versions |
| Null coalescing `??` | PHP 7.0+ |
| Null coalescing assignment `??=` | PHP 7.4+ |
