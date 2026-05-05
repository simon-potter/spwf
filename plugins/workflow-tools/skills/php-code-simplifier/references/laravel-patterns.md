# Laravel Patterns

Reference for php-code-simplifier and php-code-quality-reviewer. Laravel-specific idioms, common bad patterns, and preferred alternatives.

Laravel version assumed: 10+ / 11. Note PHP version before suggesting features.

---

## Eloquent

### N+1 — eager loading

```php
// Bad — N+1
$posts = Post::all();
foreach ($posts as $post) {
    echo $post->author->name;  // query per post
}

// Good — eager load relationships
$posts = Post::with('author')->get();
$posts = Post::with(['author', 'tags', 'comments.author'])->get();

// Good — lazy eager load (when unsure if needed)
$posts->load('author');

// Good — conditional eager load
$posts = Post::when($needsAuthor, fn($q) => $q->with('author'))->get();
```

Detection:
```bash
grep -rn "->author\|->user\|->category\|->tags" --include="*.php" app/ | grep -v "with(\|load("
```

### Unbounded queries

```php
// Bad
$users = User::all();
$orders = Order::where('company_id', $id)->get();

// Good — paginate
$users = User::paginate(50);

// Good — cursor for processing large sets
Order::where('company_id', $id)->cursor()->each(fn($order) => ...);

// Good — chunk for batch processing
User::chunk(200, function ($users) { ... });
```

### Query scopes over inline conditions

```php
// Verbose — repeated inline conditions
$users = User::where('company_id', $companyId)
             ->where('active', true)
             ->where('role', 'admin')
             ->get();

// Prefer — local scopes
class User extends Model {
    public function scopeActive($query) { return $query->where('active', true); }
    public function scopeForCompany($query, $id) { return $query->where('company_id', $id); }
}
$users = User::active()->forCompany($companyId)->admins()->get();
```

### Raw queries

```php
// Bad — injection risk
$results = DB::select("SELECT * FROM users WHERE company_id = $id");
$results = DB::select("SELECT * FROM users WHERE name LIKE '%$search%'");

// Good — bindings
$results = DB::select("SELECT * FROM users WHERE company_id = ?", [$id]);
$results = DB::select("SELECT * FROM users WHERE name LIKE ?", ["%$search%"]);

// Good — query builder
$results = DB::table('users')->where('company_id', $id)->get();
```

### `DB::raw()` — safe vs unsafe

```php
// Safe — hardcoded SQL expression
User::orderByRaw('FIELD(status, "active", "inactive", "banned")')->get();
User::selectRaw('COUNT(*) as total, DATE(created_at) as date')->groupByRaw('DATE(created_at)')->get();

// Unsafe — variable interpolated
User::whereRaw("status = '$status'")->get();          // injection
User::orderByRaw("$column $direction")->get();         // injection

// Safe with bindings
User::whereRaw("status = ?", [$status])->get();
```

---

## Controllers

### Fat controller anti-pattern

```php
// Bad — business logic in controller
public function store(Request $request) {
    $validated = $request->validate([...]);
    $subtotal = array_sum(array_column($validated['items'], 'price'));
    $tax = $subtotal * config('pricing.tax_rate');
    $order = Order::create([...]);
    Mail::to($request->user())->send(new OrderConfirmation($order));
    event(new OrderPlaced($order));
    return redirect()->route('orders.show', $order);
}

// Good — controller delegates to service
public function store(StoreOrderRequest $request) {
    $order = $this->orderService->placeOrder($request->validated(), $request->user());
    return redirect()->route('orders.show', $order);
}
```

### Form Requests for validation

```php
// Bad — inline validation in controller
public function store(Request $request) {
    $validated = $request->validate([
        'email' => 'required|email|unique:users',
        'name' => 'required|string|max:255',
    ]);
}

// Good — FormRequest class
class StoreUserRequest extends FormRequest {
    public function rules(): array {
        return [
            'email' => 'required|email|unique:users',
            'name' => 'required|string|max:255',
        ];
    }
    public function authorize(): bool {
        return $this->user()->can('create', User::class);
    }
}
```

---

## Authentication and authorisation

### Policies over inline checks

```php
// Bad — inline capability check
if (auth()->user()->role === 'admin' || auth()->user()->id === $post->user_id) {
    // allow
}

// Good — Gate / Policy
$this->authorize('update', $post);

// Policy
class PostPolicy {
    public function update(User $user, Post $post): bool {
        return $user->isAdmin() || $user->id === $post->user_id;
    }
}
```

### IDOR — always scope by authenticated user

```php
// Bad — any authenticated user can access any order
$order = Order::findOrFail($id);

// Good — scope to authenticated user
$order = Order::where('user_id', auth()->id())->findOrFail($id);

// Good — use route model binding with policy
Route::get('/orders/{order}', [OrderController::class, 'show']);
// In controller: $this->authorize('view', $order); — Gate checks ownership
```

---

## Service layer

### Repository pattern

```php
// Interface
interface OrderRepositoryInterface {
    public function findForUser(int $userId, int $orderId): Order;
    public function create(array $data): Order;
}

// Implementation
class EloquentOrderRepository implements OrderRepositoryInterface {
    public function findForUser(int $userId, int $orderId): Order {
        return Order::where('user_id', $userId)->findOrFail($orderId);
    }
}

// Service uses interface — testable, swappable
class OrderService {
    public function __construct(private OrderRepositoryInterface $orders) {}
}
```

---

## Queues and jobs

```php
// Bad — slow operations in request cycle
public function store(Request $request) {
    Mail::to($user)->send(new WelcomeEmail($user));  // blocks response
    $this->generateReport($user);                     // expensive
}

// Good — dispatch to queue
public function store(Request $request) {
    SendWelcomeEmail::dispatch($user);
    GenerateReport::dispatch($user);
}
```

---

## Configuration and environment

```php
// Bad — hardcoded values
$apiKey = 'sk-abc123';
$timeout = 30;

// Good
$apiKey = config('services.stripe.key');
$timeout = config('app.http_timeout', 30);
```

```php
// Bad — env() called outside config files (not cached)
$key = env('STRIPE_KEY');

// Good — env() only in config/ files; use config() everywhere else
// config/services.php: 'stripe' => ['key' => env('STRIPE_KEY')]
// Elsewhere: config('services.stripe.key')
```

---

## Common simplification wins

| Before | After | Notes |
|---|---|---|
| `User::where('id', $id)->first()` | `User::find($id)` | Equivalent; cleaner |
| `if (!is_null($x))` | `if ($x !== null)` | More explicit |
| `collect($array)->pluck('id')->toArray()` | `array_column($array, 'id')` | Avoid collection overhead for simple operations |
| `$query->where('deleted_at', null)` | `$query->whereNull('deleted_at')` | Clearer intent |
| Manual pagination loop | `->chunk(200, fn($batch) => ...)` | Framework handles cursor |
