# telemetric-backend-standards

## Purpose
Enforce the **Telemetric Backend coding standard** for new features/endpoints, based on the current project:
- FastEndpoints
- CQRS-ish (ICommand/ICommandHandler for both commands & queries)
- Result<T> pattern
- EF Core through IApplicationDbContext
- /api/v1 routes + Tags + Policies(PermissionClaims.*)
- Mapster for mapping request -> command/query
- Send.OkAsync / Send.ErrorsAsync handling

This skill is meant to be used by implementation prompts (per story) so Codex follows the same style consistently.

---

## Scope
Applies to:
- New endpoints (GET/POST/PUT/DELETE)
- New Request/Response DTOs
- New Command/Query + Handler
- New Domain entities/constants/enums (when required by spec/story)
- Persistence changes via IApplicationDbContext + EF Core

Non-goals:
- Do not refactor existing features unless story explicitly requires it.
- Do not change global error/envelope behavior.
- Do not change auth/policies conventions.

---

## Backend Project Structure (mandatory)
Feature folder layout:
- `Telemetric.Api/Features/<Area>/<Action>/`
  - `<Action>Endpoint.cs` (or `<Verb><Entity>Endpoint.cs`)
  - `<Action>CommandHandler.cs` or `<Action>QueryHandler.cs` (MANDATORY: file contains both the `Command/Query` type and its `Handler`)

Default per-action footprint in this repo:
- 2 files: `Endpoint` + `CommandHandler/QueryHandler`
- `Request/Response` MUST be declared in `Endpoint.cs` (do not split into separate files unless explicitly requested by the story)

Domain:
- `Telemetric.Api/Domain/Entities/*`
- `Telemetric.Api/Domain/Enums/*`
- `Telemetric.Api/Domain/Constants/PermissionClaims.cs` (policies)

Infrastructure:
- persistence, repositories, services, security remain under `Infrastructure/`
- handlers must depend on abstractions (`IApplicationDbContext`, interfaces), not concrete infra.

---

## Endpoint Standard (FastEndpoints) (mandatory)
Every endpoint MUST:
1) Inherit from `Endpoint<TRequest, TResponse>` (or `Endpoint<TRequest>` when appropriate).
2) Declare typed contracts in `Endpoint.cs`:
   - `Request` MUST exist as a class/record (do not bind loose parameters directly in handler logic).
   - `Response` MUST exist as a class/record when returning 2+ fields.
   - If response payload is exactly 1 scalar value, returning that scalar directly is allowed.
3) Configure:
   - Route: `Get("/api/v1/<resource>")` / `Post(...)` / etc
   - `Tags("<AreaName>")`
   - `Policies(PermissionClaims.<Area>.<Action>)` (must match existing PermissionClaims style)
4) Handle:
   - Map request -> Query/Command using Mapster (`req.Adapt<...>()`) if needed
   - Call `ExecuteAsync(ct)`
   - If `result.IsSuccess`:
     - return `Send.OkAsync(response, ct)` (response is a typed DTO)
   - Else:
     - return `Send.ErrorsAsync(400, ct)` (do not invent new error envelope)

### Do NOT do
- Do not return anonymous objects like `new { message = ... }` or loose multi-property payloads.
- Do not use old-style `SendOkAsync` or mismatched FastEndpoints APIs.
- Do not invent new response envelopes.

---

## Endpoint Patterns By Type (mandatory)
Use these concrete shapes to keep consistency with current Telemetric backend style:

1) List (paginated/filterable)
- `Request`: typed record/class (usually extends `PaginatedRequest` when applicable).
- `Response`: typed class/record, usually a `PaginatedList<TDto>` specialization.
- Endpoint type: `Endpoint<TRequest, TResponse>`.
- Return typed response only (no anonymous payload).

2) Create
- `Request`: typed record/class with required fields.
- `Response`: typed record/class with created id + optional message (for example `CreateXResponse(int Id, string? Message = null)`).
- Endpoint type: `Endpoint<TRequest, TResponse>`.
- Success path uses `Send.OkAsync(new TResponse(...), ct)`.

3) Update
- `Request`: typed record/class including identifier and updatable fields.
- `Response`: typed record/class when returning status/message; do not return anonymous objects.
- Endpoint type: `Endpoint<TRequest, TResponse>` when body is returned.
- If returning a single scalar value only, scalar response is allowed.

4) Delete
- `Request`: typed record/class with identifier.
- Preferred success response:
  - typed `Response` with message (recommended), or
  - no body (`Endpoint<TRequest>`) if the story explicitly defines empty success body.
- If message is returned, it MUST be a typed response (no `new { message = ... }`).

5) Validation
- Keep validators in `Endpoint.cs` for simple cases (`<Action>Validator`), aligned with repo style.
- Do not move validator to separate file unless the story explicitly requires it.

---

## CQRS-ish Standard (mandatory)
### Commands
- Must implement: `ICommand<Result<T>>`
- Must have a handler: `ICommandHandler<TCommand, Result<T>>`
- Handler method signature:
  - `Task<Result<T>> ExecuteAsync(TCommand request, CancellationToken cancellationToken)`
- In this repo style, define `Command` in the same file as `CommandHandler` (`<Action>CommandHandler.cs`).

### Queries
- Project uses the same ICommand interface even for queries:
  - Query class implements `ICommand<Result<TDto>>`
  - Handler is `ICommandHandler<TQuery, Result<TDto>>`
- In this repo style, define `Query` in the same file as `QueryHandler` (`<Action>QueryHandler.cs`).

### Result<T>
- On success: `Result<T>.Success(value, optionalMessage)`
- On failure: `Result<T>.Failure(errorMessage)`
- Endpoint decides HTTP response using `IsSuccess` only (do not invent new mapping rules).

---

## EF Core / Persistence Standard (mandatory)
- Handlers access DB only via `IApplicationDbContext`
- Use `.AsNoTracking()` for queries by default
- Use `.Include(...)` only when required for the DTO
- Writes:
  - `FindAsync(...)`, `Add(...)`, `Remove(...)`, `SaveChangesAsync(ct)`

Do NOT:
- Do not use DbContext directly (must go through IApplicationDbContext)
- Do not introduce repository pattern unless existing code uses it in the same feature area

---

## Naming Conventions (mandatory)
- Endpoints: `<Verb><Entity><Purpose>Endpoint` (e.g., `GetMetricsListEndpoint`)
- Request: `<Verb><Entity><Purpose>Request`
- Response: `<Verb><Entity><Purpose>Response`
- Handler: `<Verb><Entity><Purpose>CommandHandler` or `QueryHandler`
- DTOs: `<Entity>Dto`

---

## Security/Policies (mandatory)
- Every endpoint must define `Policies(PermissionClaims.<...>)` unless the existing module explicitly allows anonymous.
- Do not create new PermissionClaims strings without checking existing patterns in `Domain/Constants/PermissionClaims.cs`.

If a new policy is required but pattern is unclear:
- Output a **DECISIÓN PENDIENTE** (see below) and STOP.

---

## DECISIÓN PENDIENTE (mandatory when blocked)
### DECISIÓN PENDIENTE: <Title>
- Contexto: 1–2 líneas
- Opción A: ...
- Opción B: ...
- Preguntas mínimas (max 5):
  1) ...

Then STOP.

---

## Quick Template (reference only)
Endpoint:
- Configure(): route + tags + policies
- HandleAsync(): map -> execute -> ok/errors

Command/Query + Handler:
- Keep both in the same `*CommandHandler.cs` / `*QueryHandler.cs` file
- `ICommand<Result<T>>` + `ICommandHandler<..., Result<T>>`
