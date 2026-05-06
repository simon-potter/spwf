# Symfony Patterns Reference

Framework-specific idioms, bad practices, and good patterns for PHP code review and simplification in Symfony applications.

## Dependency Injection

### Service container — inject, don't fetch
```php
// Bad — service locator anti-pattern
class FooController extends AbstractController
{
    public function action(): Response
    {
        $mailer = $this->container->get('mailer'); // do not do this
    }
}

// Good — constructor injection
class FooController extends AbstractController
{
    public function __construct(private readonly MailerInterface $mailer) {}
}
```

### Avoid `ContainerAwareInterface` / `ContainerAwareTrait`
These expose the full container, defeating the purpose of DI. Use explicit constructor injection for every dependency.

### Autowiring vs manual wiring
- Prefer `#[Autowire]` attribute (Symfony 6.1+) or interface-to-class binding in `services.yaml`
- Flag any `$container->get(...)` call outside a `KernelTestCase` test

### Shared state in services
Symfony services are singletons by default. Mutable instance properties across requests cause subtle bugs:
```php
// Bad — state leaks between requests in FPM
class CartService
{
    private array $items = []; // reset needed per request
}

// Good — stateless service, or use RequestStack / session explicitly
```

---

## Security — Voters and Access Control

### Use voters, not inline checks
```php
// Bad — policy logic in controller
if ($user->getId() !== $post->getAuthor()->getId() && !in_array('ROLE_ADMIN', $user->getRoles())) {
    throw new AccessDeniedException();
}

// Good — voter handles the rule
$this->denyAccessUnlessGranted('POST_EDIT', $post);
```

### Voter structure
```php
class PostVoter extends Voter
{
    protected function supports(string $attribute, mixed $subject): bool
    {
        return in_array($attribute, ['POST_EDIT', 'POST_DELETE'])
            && $subject instanceof Post;
    }

    protected function voteOnAttribute(string $attribute, mixed $subject, TokenInterface $token): bool
    {
        $user = $token->getUser();
        if (!$user instanceof User) {
            return false;
        }
        return match ($attribute) {
            'POST_EDIT'   => $subject->getAuthor() === $user,
            'POST_DELETE' => $subject->getAuthor() === $user || $this->security->isGranted('ROLE_ADMIN'),
            default       => false,
        };
    }
}
```

### `#[IsGranted]` attribute (Symfony 6.0+)
```php
#[IsGranted('POST_EDIT', subject: 'post')]
public function edit(Post $post): Response { ... }
```

### CSRF protection
Forms rendered via Twig `{{ form_start(form) }}` include CSRF tokens automatically. Manual form handlers must call:
```php
$this->isCsrfTokenValid('delete-post', $request->getPayload()->getString('_token'))
```

---

## Event System

### Event subscribers over listeners for multi-event classes
```php
// Good — one class, multiple events, explicit priorities
class OrderSubscriber implements EventSubscriberInterface
{
    public static function getSubscribedEvents(): array
    {
        return [
            OrderCreatedEvent::class => 'onOrderCreated',
            KernelEvents::TERMINATE   => ['onTerminate', -100],
        ];
    }
}
```

### Stopping propagation
Call `$event->stopPropagation()` only intentionally — it silently disables downstream listeners. Flag any unexpected usage.

### Async events via Messenger
For heavy post-event work (emails, webhooks), dispatch a Messenger message instead of blocking in the listener:
```php
// Bad — HTTP response held while email sends
public function onOrderCreated(OrderCreatedEvent $event): void
{
    $this->mailer->send($this->buildEmail($event->getOrder()));
}

// Good — async
public function onOrderCreated(OrderCreatedEvent $event): void
{
    $this->bus->dispatch(new SendOrderConfirmationEmail($event->getOrder()->getId()));
}
```

---

## Console Commands

### Command structure
```php
#[AsCommand(name: 'app:import-products', description: 'Import products from CSV')]
class ImportProductsCommand extends Command
{
    public function __construct(private readonly ProductImporter $importer)
    {
        parent::__construct();
    }

    protected function configure(): void
    {
        $this->addArgument('file', InputArgument::REQUIRED, 'CSV file path')
             ->addOption('dry-run', null, InputOption::VALUE_NONE, 'Simulate without writing');
    }

    protected function execute(InputInterface $input, OutputInterface $output): int
    {
        $io = new SymfonyStyle($input, $output);
        // ... use $io->progressBar(), $io->success(), $io->error()
        return Command::SUCCESS; // or Command::FAILURE
    }
}
```

### Avoid logic in `execute()` — delegate to services
The command is a CLI adapter; business logic belongs in the injected service.

### Returning exit codes
Always return `Command::SUCCESS` or `Command::FAILURE` — never bare `0` or `1`.

---

## Doctrine ORM

### N+1 in loops
```php
// Bad — one query per post for author
foreach ($posts as $post) {
    echo $post->getAuthor()->getName(); // lazy load per iteration
}

// Good — join fetch
$posts = $this->em->createQueryBuilder()
    ->select('p, a')
    ->from(Post::class, 'p')
    ->join('p.author', 'a')
    ->getQuery()
    ->getResult();
```

### Unbounded queries
```php
// Bad
$allUsers = $userRepository->findAll(); // O(n) memory

// Good
$paginator = new Paginator($query);
```

### Repository pattern
Custom finders belong in the entity repository, not in controllers or services:
```php
// Bad — query in controller
$this->em->createQuery('SELECT p FROM Post p WHERE p.published = true')->getResult();

// Good — repository method
$this->postRepository->findPublished();
```

### Flush scope — avoid `flush()` inside loops
```php
// Bad — one flush per iteration = N round trips
foreach ($items as $item) {
    $this->em->persist($item);
    $this->em->flush(); // do not do this
}

// Good — batch flush
foreach ($items as $item) {
    $this->em->persist($item);
}
$this->em->flush();
```

### Raw DQL / native SQL
Only use `createNativeQuery()` when DQL genuinely cannot express the query. Parameterise everything:
```php
// Bad — injection risk
$dql = "SELECT p FROM Post p WHERE p.title = '$title'";

// Good
$query = $this->em->createQuery('SELECT p FROM Post p WHERE p.title = :title')
    ->setParameter('title', $title);
```

---

## Maintainability

### Fat controller anti-pattern
Controllers should: validate input (or delegate to FormType), call a service method, return a response. Business logic inside controller actions is untestable and hard to reuse.

### Form types for input validation
```php
// Bad — inline validation in controller
if (empty($request->get('email'))) { ... }

// Good — FormType with constraints
class RegistrationFormType extends AbstractType
{
    public function buildForm(FormBuilderInterface $builder, array $options): void
    {
        $builder->add('email', EmailType::class, [
            'constraints' => [new NotBlank(), new Email()],
        ]);
    }
}
```

### Environment variables — always via `%env()%`
Never call `$_ENV['FOO']` or `getenv('FOO')` in production code. Use `%env(APP_SECRET)%` in `services.yaml` or inject via constructor parameter.

---

## Performance

### Response caching
```php
// Controller-level HTTP caching
$response->setPublic()->setMaxAge(3600)->setSharedMaxAge(3600);

// Or attribute-based
#[Cache(public: true, maxage: 3600)]
public function index(): Response { ... }
```

### Lazy services for rarely used dependencies
Tag heavy services as lazy in `services.yaml`:
```yaml
App\Service\HeavyPdfGenerator:
    lazy: true
```

### Avoid `findAll()` on large tables
Always scope queries: date range, status filter, or paginate.

---

## Modern Symfony / PHP Opportunities (version-gated)

| Pattern | Min version | Notes |
|---|---|---|
| `#[AsCommand]` attribute | Symfony 6.0 | Replaces `protected static $defaultName` |
| `#[IsGranted]` attribute | Symfony 6.0 | Replaces `@Security` annotation |
| `#[Autowire]` attribute | Symfony 6.1 | Replaces explicit `bind:` in yaml |
| `#[Route]` attribute | Symfony 5.2 | Replaces annotation routing |
| `#[ORM\Entity]` attribute | Doctrine ORM 2.9 | Replaces annotation mapping |
| Enum-backed Doctrine types | PHP 8.1 + DoctrineBundle 2.7 | Replace magic string columns |
| `readonly` service properties | PHP 8.1 | Constructor-promoted + `readonly` |

---

## Detection Queries

```bash
# Service locator anti-pattern
grep -rn "->container->get(" src/ --include="*.php"

# Missing voter — inline role check in controller
grep -rn "getRoles()\|hasRole(" src/Controller --include="*.php"

# N+1 candidate — lazy load in loop
grep -rn "foreach" src/ --include="*.php" -A5 | grep "->get[A-Z]"

# Direct env access
grep -rn "getenv(\|$_ENV\[" src/ --include="*.php"

# findAll() on repository
grep -rn "->findAll()" src/ --include="*.php"

# flush inside loop (heuristic — manual review required)
grep -rn "->flush()" src/ --include="*.php"

# Native SQL with string interpolation
grep -rn "createNativeQuery\|createQuery" src/ --include="*.php" -A2 | grep '\$'

# Missing CSRF token validation in form handler
grep -rn "handleRequest\|isSubmitted" src/Controller --include="*.php" -B2 -A5 | grep -v "isCsrfTokenValid"
```
