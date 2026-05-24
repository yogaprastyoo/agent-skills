# Per-Stack Quality Checklists

Stack-specific items that complement the five core categories in `SKILL.md`. Apply the section matching the project's stack. If the project is multi-stack, apply each relevant section.

When to use: read this BEFORE writing code, then again as a self-review BEFORE committing.

---

## Flutter / Dart

### Widget construction
- Widget > 30 lines → extract to `widgets/` (or `lib/widgets/<feature>/`)
- Heavy widget tree → wrap in `const` constructor where possible (`const SizedBox()`, not `SizedBox()`)
- Never define a `Container` / `Column` / `Row` with >5 children inline in `build()` — extract
- `ListView` / `GridView` with dynamic content → use `.builder` constructor (lazy), never `.children: list.map(...).toList()` for non-trivial lists
- Prefer composition: wrap a small widget in another small widget rather than a giant widget with branching `if`s

### State management
- Match the project's existing pattern (BLoC / Provider / Riverpod / GetX / setState) — do NOT introduce a second pattern
- `setState` only when the value actually changes — wrap in `if (newValue != _value)` for non-trivial types
- `emit` (BLoC) / `notifyListeners` (Provider) — same rule, only when state genuinely transitions
- Do not call `setState` inside `build()` — schedule with `WidgetsBinding.instance.addPostFrameCallback`
- Avoid `setState((){})` (empty) — explicit about which field changed

### Null safety
- Never `someValue!` or `someValue as T` without a comment explaining why null is impossible at this point
- Prefer `??` (null-coalesce) over `!`
- For nullable model fields, use pattern matching or `if (x case ... when ...)` rather than nested `if x != null`

### Async / Future
- `await` every `Future` — never have a dangling `Future` that may throw silently
- `async` functions return `Future<void>` only when truly fire-and-forget; otherwise return the typed result
- Cancel `StreamSubscription` / `Timer` in `dispose()` — track them as instance fields

### Build performance
- Compute expensive values OUTSIDE `build()` — store in `initState` or memoize
- `RepaintBoundary` around frequently-rebuilding subtrees if widget tree is large
- `const` constructors wherever possible — they enable widget caching

### Localization
- User-facing strings → ARB / `.arb` files (or whatever localization layer the project uses), NOT inline string literals
- Error messages user reads on-screen → Indonesian
- Error messages logged internally / sent to crashlytics → English

### Testing
- Widget tests for non-trivial UI flows
- BLoC / cubit tests for state transitions
- Run `flutter test` before committing
- Run `flutter analyze` before committing — zero warnings required

---

## ASP.NET Core / C# / .NET

### Async patterns
- `async` methods MUST suffix `Async` (e.g. `GetUserAsync`)
- Always `ConfigureAwait(false)` in library code (not application code)
- Never `.Result` or `.Wait()` — deadlock risk
- `Task` not `Task<void>` for fire-and-forget; otherwise `Task<T>`

### Nullable reference types
- `<Nullable>enable</Nullable>` in `.csproj` — non-negotiable for new projects
- Suppress with `!` only with a justifying comment
- Use `ArgumentNullException.ThrowIfNull(arg)` at method boundaries

### Disposable resources
- Anything implementing `IDisposable` / `IAsyncDisposable` must be wrapped in `using` (or `await using`)
- Constructor-injected disposables → field, dispose in the class's own `Dispose`
- Static/long-lived → no `using`, document the lifetime

### EF Core / database
- Never `ToList()` / `ToArrayAsync()` without justification — streams are usually fine
- Eager-load with `.Include()` for known navigation properties; avoid lazy-loading in production paths
- `AsNoTracking()` for read-only queries — perf win
- Migrations are reviewed like any other code — never `EnsureCreated()` in production

### Validation
- Use FluentValidation or DataAnnotations consistently — do NOT mix
- Validate at the controller boundary; do not re-validate inside services unless service can be called from non-controller paths
- Return validation errors as `{ success: false, message: "...", errors: { field: [...] } }` per `api-response` skill

### Logging
- `ILogger<T>` injected, not `Console.WriteLine`
- Structured logging with named placeholders: `_logger.LogInformation("User {UserId} logged in", userId)` — never string concatenation in the message template
- No PII / secrets in log messages

### Testing
- Run `dotnet build` (treat warnings as errors) before commit
- Run `dotnet test` before commit
- xUnit / NUnit / MSTest — match the project's choice; do NOT introduce a different framework

---

## Node.js / TypeScript

### Type safety
- `strict: true` in `tsconfig.json` — non-negotiable
- Never `any` — use `unknown` if truly polymorphic, then narrow with type guards
- Never `as Type` (type assertion) without a comment — use a real type guard
- Public function signatures have explicit return types — do not rely on inference for the API surface

### Async
- `async`/`await` over `.then()` chains
- Always handle Promise rejection — `try/catch` around `await`, or `.catch()` on raw Promise
- Never `await` inside a loop unless ordering matters — use `Promise.all` for parallel
- `process.on('unhandledRejection', ...)` configured for the process

### Module structure
- Named exports over default exports (better refactoring, autocompletion)
- One responsibility per file — split when files exceed ~300 lines
- Barrel files (`index.ts`) for explicit module boundaries; do not auto-export everything

### Dependencies
- `npm audit` clean before commit
- Prefer standard library — no `lodash` for `Array.from()` etc
- Lock files committed (`package-lock.json` / `pnpm-lock.yaml` / `yarn.lock`)
- Pin major versions in `package.json` — `^4.19.0` is fine, `>=4` is not

### Express / Fastify / Nest
- Match the project's framework — do NOT introduce a second HTTP layer
- Middleware ordering matters — read existing setup before inserting new middleware
- Validate `req.body` / `req.query` / `req.params` at the boundary (Zod / Joi / class-validator)

### Testing
- `vitest` / `jest` / `node:test` — match project
- Run before commit, zero failing tests
- ESLint clean before commit (`npm run lint`)

---

## Python

### Typing
- `from __future__ import annotations` at top of file
- Type hints on all public functions
- `mypy --strict` or `pyright` clean before commit
- Avoid `Any` — use `object` or `TypeVar` or a Protocol

### Standard idioms
- `pathlib.Path` not `os.path`
- `dataclasses` / `pydantic` not bare dicts for structured data
- `Enum` not string constants for fixed sets

### Async
- `async/await` consistently — do not mix with `asyncio.run_until_complete` in the same call stack
- `asyncio.gather` for parallel, `asyncio.create_task` for fire-and-forget (with reference to prevent garbage collection)

### Testing
- `pytest -q` before commit
- `ruff check` and `ruff format` before commit (or whatever linter the project uses)

---

## Go

### Errors
- Always check the error — never `_ = someCall()`
- Wrap with context: `fmt.Errorf("doing X: %w", err)` not bare `return err`
- Sentinel errors via `errors.Is` / `errors.As`, not string matching

### Concurrency
- Always know how a goroutine terminates — no leaks
- `context.Context` first parameter on functions that may be cancelled
- Channel direction (`chan<-`, `<-chan`) in function signatures

### Standard library first
- Prefer standard library over third-party — `net/http` over `gin` unless project commits to it
- `slog` for logging (1.21+)

### Testing
- `go test ./...` before commit
- `go vet ./...` and `staticcheck ./...` clean before commit

---

## Generic — applies to every stack

### Logging discipline
- No `print` / `console.log` / `Debug.WriteLine` in committed code (use the project's logger)
- No `TODO` without a linked issue: `// TODO(#42): handle the edge case`

### Configuration
- Read from env vars or config file, not hardcoded
- Provide defaults; validate at startup
- Never bake secrets into the binary / bundle

### Commits
- Quality gates pass BEFORE the commit, not "in the next commit"
- One logical change per commit (see `github-git` skill for full conventional commit rules)

### Documentation
- Public API (controller route, exported function) deserves a one-line docstring/JSDoc explaining the WHY, not the WHAT
- Update README / API spec when behavior changes
