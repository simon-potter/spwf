---
name: php-code-simplifier
description: Simplify and refactor PHP code for clarity, type safety, and maintainability while preserving exact behaviour. Use after implementing a feature or fixing a bug in PHP codebases (Laravel, Symfony, WordPress, or plain PHP). Focuses on recently modified files unless a path is provided. Never changes what code does — only how it does it. Complement to the core simplify skill, which is language-agnostic; this skill knows PHP idioms, framework conventions, and version-specific capabilities.
disable-model-invocation: true
allowed-tools: [Read, Edit, Bash, Glob, Grep]
---

# PHP Code Simplifier

Refactor PHP code for clarity and maintainability while preserving exact behaviour. Read the code, apply safe improvements, flag judgment calls without touching them.

## Core rules

1. **Never change what code does.** All original features, outputs, edge cases, and error paths must remain identical.
2. **Detect PHP version and framework first** — every suggestion must be available in the project's PHP version. Load `references/php-version-capabilities.md` if unsure.
3. **Explicit over compact.** Readable `if`/`match` beats a clever one-liner. A named method beats an inline lambda.
4. **Respect framework conventions.** Laravel, Symfony, and WordPress each have idioms — do not fight them. Load the relevant `references/*.md` before touching framework code.
5. **Focus on recently modified code** unless a path argument was provided.
6. **Never touch test files.** Tests validate behaviour — simplifying them risks changing what they assert.
7. **Flag, don't apply, when confidence is medium or low.** Apply only when the change is unambiguously safe and meaning-preserving.

---

## Phase 1 — Detect PHP version and framework

```bash
# PHP version
cat composer.json 2>/dev/null | grep '"php"'
php --version 2>/dev/null | head -1

# Framework
grep -l "laravel/framework\|illuminate/" composer.json composer.lock 2>/dev/null && echo "Laravel"
grep -l "symfony/framework-bundle\|symfony/http-kernel" composer.json composer.lock 2>/dev/null && echo "Symfony"
grep -rn "add_action\|add_filter\|wp_enqueue" --include="*.php" . -l 2>/dev/null | head -1 && echo "WordPress"
```

Record the PHP version. Load the corresponding reference file:
- Laravel → `references/laravel-patterns.md`
- Symfony → `references/symfony-patterns.md`
- WordPress → `references/wordpress-patterns.md`

---

## Phase 2 — Find files to review

If a path argument was given, use it. Otherwise:

```bash
git diff --name-only main...HEAD -- '*.php'
```

Exclude:
- `tests/`, `test/`, `spec/`, `*Test.php`, `*Spec.php`, `*_test.php`
- `vendor/`, `node_modules/`
- Generated migration files (read-only — migrations must not change after creation)

If no files remain: report "No non-test PHP files changed on this branch."

---

## Phase 3 — Apply simplification patterns

Read each file. Work through the patterns below. For each: apply if confidence is high and behaviour is provably preserved; flag otherwise.

### Pattern 1 — Guard clauses over deep nesting (apply if clear)

```php
// Flag — nested conditions
if ($user) {
    if ($user->isActive()) {
        if ($user->canPurchase()) {
            $this->process($user);
        }
    }
}

// Prefer — guard clauses
if (!$user || !$user->isActive() || !$user->canPurchase()) {
    return;
}
$this->process($user);
```

Apply when: all branches are simple guards with early returns. Flag when there is meaningful logic in the nested branches that changes behaviour if flattened.

### Pattern 2 — Nullsafe operator (apply if PHP ≥ 8.0)

```php
// Before
$name = null;
if ($user && $user->profile) {
    $name = $user->profile->name;
}

// After
$name = $user?->profile?->name;
```

Apply only when null propagation is the intended behaviour. If the original code has distinct handling for each null case, flag instead.

### Pattern 3 — `match` over `switch` for value mapping (apply if PHP ≥ 8.0)

```php
// Before
switch ($role) {
    case 'admin':
        return true;
    case 'editor':
        return true;
    default:
        return false;
}

// After
return match ($role) {
    'admin', 'editor' => true,
    default => false,
};
```

Apply when: every `case` is a simple return or assignment with no side effects. `match` is strict (===) — flag if the original `switch` relied on loose comparison.

### Pattern 4 — Remove debug statements (apply)

Remove: `var_dump(`, `dd(`, `dump(`, `ray(`, `print_r(`, `var_export(` — any that are not behind a conditional or test context.

Flag (do not remove): debug calls inside `if (config('app.debug'))` or similar — these may be intentional.

### Pattern 5 — Typed signatures (flag only)

```php
// Flag — untyped
function calculate($items, $tax) { ... }

// Suggest
function calculateTotal(array $items, Money $tax): Money { ... }
```

Always flag, never apply — adding types changes the signature and can break call sites or fail at runtime if the actual types differ.

### Pattern 6 — Enums over magic strings (flag only, PHP ≥ 8.1)

```php
// Flag
if ($status === 'pending') { ... }
if ($status === 'p') { ... }

// Suggest
if ($status === OrderStatus::Pending) { ... }
```

Flag only — creating an enum is a larger change that affects persistence, serialisation, and all call sites.

### Pattern 7 — `match` / enums over boolean parameters (flag only)

```php
// Flag — boolean parameter hides intent
sendEmail($user, true, false);

// Suggest — named method or options object
sendWelcomeEmail($user);
sendEmailWithOptions($user, EmailOptions::withoutAttachment());
```

### Pattern 8 — Readonly properties and constructor promotion (flag only, PHP ≥ 8.0/8.1)

```php
// Flag — verbose DTO
class CreateUserDTO {
    public string $name;
    public string $email;
    public function __construct(string $name, string $email) {
        $this->name = $name;
        $this->email = $email;
    }
}

// Suggest
final readonly class CreateUserDTO {
    public function __construct(
        public string $name,
        public string $email,
    ) {}
}
```

Flag only — readonly changes mutability semantics; verify no code assigns these properties after construction.

### Pattern 9 — Null coalescing over isset chains (apply if safe)

```php
// Before
$value = isset($data['key']) ? $data['key'] : 'default';

// After
$value = $data['key'] ?? 'default';
```

Apply when: the original uses `isset` purely to provide a default. Do not apply if `null` is a meaningful value that should be distinguished from "missing".

### Pattern 10 — Remove commented-out code (apply)

Remove blocks of commented-out code. Leave in place:
- Doc comments (`/** */`)
- Comments explaining a non-obvious decision or workaround
- TODO/FIXME with meaningful context

---

## Phase 4 — Output

```
## PHP Simplify Report

**PHP version**: {version}
**Framework**: {Laravel | Symfony | WordPress | Plain PHP}
**Files reviewed**: {N}

### Applied

- `{file}:{line range}` — {what was changed and why}

### Flagged (judgment needed)

- `{file}:{line}` — {pattern} — {suggested fix} [confidence: medium|low]

### Clean

- `{file}` — no changes needed

### Skipped

- `{file}` — {reason: generated migration | test file | vendor}
```

---

## Gotchas

- **`match` is strict, `switch` is loose.** Replacing `switch` with `match` changes `==` to `===`. A `switch ('1')` with `case 1:` matches; a `match ('1')` with `1 =>` does not. Always check whether the original relied on type coercion.
- **Nullsafe operator short-circuits the whole chain.** `$a?->b()?->c()` returns `null` if `$a` is null — it does not call `b()` or `c()`. If the original code had side effects in those calls, nullsafe changes behaviour.
- **Readonly properties cannot be assigned after construction.** Before suggesting `readonly`, verify nothing outside the constructor writes to the property.
- **Migration files must not be modified.** Laravel and Doctrine migrations are append-only — changing them breaks the migration history.
- **WordPress output functions are not equivalent.** `esc_html`, `esc_attr`, `esc_url`, `esc_js` each encode differently. Do not swap them. Load `references/wordpress-patterns.md` before touching any WordPress output code.
- **Constructor promotion changes the public API of the class.** The promoted property names become part of the constructor signature. If the class is instantiated with named arguments elsewhere, renaming a promoted property is a breaking change.

## References

Load on demand:
- `references/php-version-capabilities.md` — feature availability by PHP version (8.0–8.3+)
- `references/laravel-patterns.md` — Eloquent, service containers, middleware, form requests
- `references/wordpress-patterns.md` — escaping, nonces, capabilities, `$wpdb`, hooks
- `references/symfony-patterns.md` — DI, voters, events, commands
- `references/php-smell-catalog.md` — full smell list with detection patterns
