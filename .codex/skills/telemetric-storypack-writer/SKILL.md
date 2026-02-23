# telemetric-storypack-writer

## Purpose
Generate a Telemetric **Story Pack** from a single spec document, enforcing strict guardrails and full traceability (spec → stories → implementation planning).

---

## Inputs (required)
- `contexto/work/features/<slug>/spec.md`

Optional (if provided by the user/repo):
- `contexto/work/features/<slug>/API_INVENTORY.md`
- `contexto/adrs/` (existing ADR index)
- `contexto/openapi/` (existing OpenAPI files)

---

## Output (required)

### Output file (MANDATORY)
Write **one** Markdown file to:
- `contexto/work/features/<slug>/storypacks/ACT_v1.md`

Also print the same content in the chat output (for visibility).

### Determinism rules
- Always create/overwrite `contexto/work/features/<slug>/storypacks/ACT_v1.md`.
- Do not create additional storypack files unless explicitly requested.

---

## Hard Guardrails (must follow)
1) **No invention**: Do NOT invent endpoints, routes, technologies, queues, tables, naming conventions, or rule semantics that are not explicitly stated in `spec.md`.
2) **Stop on ambiguity**: If `spec.md` is missing details or ambiguous, you MUST stop and output only a **DECISIÓN PENDIENTE** section (format below). Do not proceed beyond the blocked point.
3) **Traceability**: Every story MUST reference:
   - Exact `spec.md` section(s)
   - UI route(s) involved (if any)
   - Internal domain entities (English names)
4) **Testable AC**: Acceptance Criteria must be numbered and testable.
5) **Language rule**: UI labels in **Spanish**; internal names (code/DB/entities) in **English**.
6) **V1 focus**: Keep scope strictly in v1 as defined by `spec.md`. Extras must be marked as v2/out-of-scope.
7) **No code**: Do not generate implementation code. Produce requirements artifacts only.

---

## Endpoint rule (mandatory)
Stories must be "vertical slices": if a story requires API endpoints, it must:
1) Check if an equivalent endpoint already exists in the repo.
2) If missing, define the endpoint contract (OpenAPI delta) AND implement it in the same story.
3) Add tests for the endpoint (at least smoke/integration).
OpenAPI must be updated incrementally per story (not via a single giant pre-step).
If API standards (envelope/errors/versioning/auth) cannot be inferred from existing code, output "DECISIÓN PENDIENTE" and STOP.

---

## Decision Pending Protocol (mandatory format)
When blocked, output **only**:

### DECISIÓN PENDIENTE: <Título>
- **Contexto:** (1–2 líneas)
- **Opción A:** <...>
  - **Pros:**
  - **Cons:**
- **Opción B:** <...>
  - **Pros:**
  - **Cons:**
- **Preguntas mínimas para desbloquear:** (máx 5)

Then **STOP**.

---

## Story Pack Format (mandatory)

### A) STORY INDEX
For each story ACT-### include:
- **ID:** ACT-###
- **Título:** (Spanish)
- **Tipo:** FE / BE / DB / DOC
- **Depends on:** (files or story IDs)
- **Blocks:** (story IDs)

---

### B) STORIES
For each ACT-### include:

#### ACT-### — <Título>
- **Como** <rol>
  **Quiero** <objetivo>
  **Para** <beneficio>
- **Alcance:** (incluye / excluye)
- **Rutas UI:** (si aplica)
- **Entidades internas:** (English names)
- **Endpoints (si aplica):**
  - Verificar existentes
  - Si faltan: actualizar `contexto/openapi/actions.yaml` (delta incremental de ESTA historia)
  - Implementar + pruebas mínimas
- **Criterios de aceptación (AC):** (mínimo 6)
- **Checklist QA:** (mínimo 8)
- **Datos / Contratos (si aplica):**
  - **SQL:** tablas a tocar/crear/alterar
  - **Redis:** keys/fields esperados
  - **RabbitMQ:** eventos consumidos/publicados
  - **ClickHouse:** queries/scheduler (si aplica)
- **Depends on:**
- **Referencias:** (secciones exactas del spec)

---

### C) GUARDRAILS (DO NOT DO)
Bullets estrictos.

---

### D) DOC DELIVERABLES (do not write them)
List titles + why (ADRs/OpenAPI delta/migration checklist/QA-runbook). Do not write those docs.

---

## Non-goals
- Do not implement code or migrations in this step.
- Do not write full ADR/OpenAPI documents in this step.
- Do not override `spec.md`. If spec conflicts, raise a DECISIÓN PENDIENTE.
