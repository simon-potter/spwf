# CLAUDE.md Templates

Source: Anthropic `claude-md-management` plugin (Isabella He, isabella@anthropic.com).
Used verbatim under the official Anthropic claude-plugins-official repository (https://github.com/anthropics/claude-plugins-official).

## Key Principles

- **Concise**: Dense, human-readable content; one line per concept when possible
- **Actionable**: Commands should be copy-paste ready
- **Project-specific**: Document patterns unique to this project, not generic advice
- **Current**: All info should reflect actual codebase state

---

## Recommended Sections

Use only the sections relevant to the project. Not all sections are needed.

### Commands

```markdown
## Commands

| Command | Description |
|---------|-------------|
| `<install command>` | Install dependencies |
| `<dev command>` | Start development server |
| `<build command>` | Production build |
| `<test command>` | Run tests |
| `<lint command>` | Lint/format code |
```

### Architecture

```markdown
## Architecture

```
<root>/
  <dir>/    # <purpose>
  <dir>/    # <purpose>
  <dir>/    # <purpose>
```
```

### Key Files

```markdown
## Key Files

- `<path>` - <what it does>
- `<path>` - <entry point / config / main component>
```

### Code Style

```markdown
## Code Style

- <language-specific convention>
- <naming convention>
- <pattern we follow>
```

### Environment

```markdown
## Environment

Required env vars:
- `VAR_NAME` - <what it's for>

Setup: `<command to initialize environment>`
```

### Testing

```markdown
## Testing

- Run: `<test command>`
- Pattern: `<where tests live, naming convention>`
- <any quirks about the test setup>
```

### Gotchas

```markdown
## Gotchas

- <non-obvious issue>: <explanation or workaround>
- <footgun>: <how to avoid>
```

### Workflow

```markdown
## Workflow

- <when to do X>: `<command>`
- <common task>: <steps>
```

---

## Template 1: Project Root (Minimal)

```markdown
# <Project Name>

<One-line description of what this project does.>

## Commands

| Command | Description |
|---------|-------------|
| `<install>` | Install dependencies |
| `<dev>` | Start development |
| `<test>` | Run tests |
| `<build>` | Production build |

## Architecture

```
<root>/
  <dir>/    # <purpose>
  <dir>/    # <purpose>
```

## Gotchas

- <key gotcha>: <explanation>
```

---

## Template 2: Project Root (Comprehensive)

```markdown
# <Project Name>

<One-line description.>

## Commands

| Command | Description |
|---------|-------------|
| `<install>` | Install dependencies |
| `<dev>` | Start development server |
| `<test>` | Run tests |
| `<lint>` | Lint and format |
| `<build>` | Production build |

## Architecture

```
<root>/
  <dir>/    # <purpose>
  <dir>/    # <purpose>
  <dir>/    # <purpose>
```

## Key Files

- `<path>` - <description>
- `<path>` - <description>

## Code Style

- <convention>
- <convention>

## Environment

Required: `VAR_NAME` (<purpose>)
Setup: `<command>`

## Testing

Run: `<command>`
Pattern: `<description>`

## Gotchas

- <gotcha>: <explanation>
- <gotcha>: <explanation>
```

---

## Template 3: Package/Module (for monorepos)

```markdown
# <Package Name>

<One-line description of this package's role.>

## Usage

```bash
<how to use or import this package>
```

## Key Exports

- `<export>` - <what it does>

## Dependencies

- Depends on: `<other packages in monorepo>`
- Used by: `<packages that import this>`

## Notes

- <non-obvious implementation detail>
- <performance consideration>
```

---

## Template 4: Monorepo Root

```markdown
# <Monorepo Name>

<One-line description.>

## Packages

| Package | Description |
|---------|-------------|
| `<name>` | <purpose> |
| `<name>` | <purpose> |

## Commands

| Command | Description |
|---------|-------------|
| `<install>` | Install all dependencies |
| `<build:all>` | Build all packages |
| `<test:all>` | Test all packages |
| `<dev>` | Start development |

## Cross-Package Patterns

- <how packages communicate>
- <shared configuration>
- <release process>
```
