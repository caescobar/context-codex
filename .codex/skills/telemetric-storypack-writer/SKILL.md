# telemetric-storypack-writer

## Purpose
Generate a Telemetric **Story Pack** from a single spec document, enforcing strict guardrails and full traceability (spec → stories → implementation).

---

## Inputs (required)
- `contexto/specs/<module>/spec.md`

Optional (if provided by the user/repo):
- `contexto/specs/<module>/API_INVENTORY.md`
- `contexto/adrs/` (existing ADR index)
- `contexto/openapi/` (existing OpenAPI files)

---

## Output (required)
Write **one** Markdown document that contains:

1) **Story Index** (ACT-001…ACT-0NN)  
2) **Stories** with Acceptance Criteria + QA checklist + dependencies  
3) **Guardrails (Do Not Do)**  
4) **Doc Deliverables list** (ADRs / OpenAPI delta / migration checklists) — **do not write those docs**, only list them

---

## Hard Guardrails (must follow)
1) **No invention**: Do NOT invent endpoints, routes, technologies, queues, tables, naming conventions, or rule semantics that are not explicitly stated in `spec.md`.
2) **Stop on ambiguity**: If `spec.md` is missing details or ambiguous, you MUST stop and output only a **DECISIÓN PENDIENTE** section (format below). Do not proceed with the Story Pack beyond the blocked point.
3) **Traceability**: Every story MUST reference:
   - Exact `spec.md` section(s) (e.g., “Spec §4 Lifecycle”)
   - UI route(s) involved (e.g., `/actions`, `/actions/templates/:id`, `/devices/:id#rules`)
   - Internal domain entities (English names), e.g. `RuleTemplate`, `RuleTemplateVersion`, `RuleInstance`, `ActionAttempt`, `AlertFired`
4) **Testable AC**: Acceptance Criteria must be numbered and testable. No vague language (“debería”, “idealmente”) without a measurable condition.
5) **Language rule**: UI labels in **Spanish**; internal names (code/DB/entities) in **English**.
6) **V1 focus**: Keep scope strictly in v1 as defined by `spec.md`. Any extras must be explicitly marked as v2/out-of-scope.
7) **No code**: Do not generate implementation code. Produce requirements artifacts only.

---

## Endpoint rule (mandatory)
- Stories must be "vertical slices": if a story requires API endpoints, it must:
  1) Check if an equivalent endpoint already exists in the repo.
  2) If missing, define the endpoint contract (OpenAPI delta) AND implement it in the same story.
  3) Add tests for the endpoint (at least smoke/integration).
- OpenAPI must be updated incrementally per story, not via a single giant pre-step.
- If API standards (envelope/errors/versioning/auth) cannot be inferred from existing code, output "DECISIÓN PENDIENTE" and STOP.

### Endpoint Dedup Gate (mandatory)
When a story may require endpoints, the Story Pack must include a short **“Endpoint check gate”** section (NOT a full endpoint map) with these mandatory steps for the implementation phase:

1) **Discover**: Search the repo for existing endpoints that satisfy the story intent (same resource + action).
2) **Equivalence test**: If a candidate exists, compare request/response shape and behavior to the story AC.
3) **Reuse-first**: Reuse the existing endpoint if it can satisfy the AC with small changes.
4) **Only if missing**: If no equivalent endpoint exists, define OpenAPI delta incrementally in `contexto/openapi/actions.yaml`, then implement the endpoint.
5) **Stop on ambiguity**: If unsure whether an endpoint is equivalent or the API standard is unclear, output **DECISIÓN PENDIENTE** and STOP.

Important:
- The Story Pack MUST NOT include detailed endpoint routes unless the spec explicitly provides them.
- The deep review happens during the story implementation prompt, not in the Story Pack.

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
- **Depends on:** (files or story IDs, e.g. `ADR-00xx-...`, `contexto/openapi/actions.yaml`, `ACT-002`)
- **Blocks:** (story IDs that are blocked by this story)

---

### B) STORIES
For each ACT-### include:

#### ACT-### — <Título>
- **Como** <rol>  
  **Quiero** <objetivo>  
  **Para** <beneficio>
- **Alcance:** (qué incluye / qué excluye dentro de esta historia)
- **Rutas UI:** (ej. `/actions`, `/actions/templates/:id`)
- **Entidades internas:** (English names)

- **Endpoints (si aplica):**
  - Verificar existentes
  - Si faltan: actualizar `contexto/openapi/actions.yaml`
  - Implementar + pruebas mínimas

- **Endpoint check gate (obligatorio si hay endpoints):**
  - Discover → Equivalence test → Reuse-first → Only if missing (OpenAPI delta) → DECISIÓN PENDIENTE si hay dudas

- **Criterios de aceptación (AC):**
  1) …
  2) …
  3) …
  4) …
  5) …
  6) … (mínimo 6)

- **Checklist QA:**
  1) …
  2) …
  3) …
  4) …
  5) …
  6) …
  7) …
  8) … (mínimo 8)

- **Datos / Contratos (si aplica):**
  - **SQL:** tablas a tocar/crear/alterar
  - **Redis:** keys/fields esperados
  - **RabbitMQ:** eventos consumidos/publicados
  - **ClickHouse:** queries/scheduler (si aplica)

- **Depends on:** (archivos/story IDs)
- **Referencias:** (secciones exactas del spec, ej. “Spec §1 Alcance, §4 Lifecycle, §6 UX”)

---

### C) GUARDRAILS (DO NOT DO)
Bullet list of strict “no hacer”, at minimum:
- No nuevos endpoints/colas/tecnologías sin ADR + actualización de contrato
- No “function-per-rule deployment”
- No semánticas de tiempo inventadas
- No exponer “estado interno” en UI si el spec lo excluye

---

### D) DOC DELIVERABLES (do not write them)
List which docs are required/updated **as outputs of the process**, but do not write them in this step:
- ADRs needed (titles + why)
- OpenAPI delta needed (file name + why)
- DB migration checklist (file name + why)
- Any QA/Runbook doc needed

---

## Non-goals
- Do not implement code or migrations in the **Story Pack generation step**.
- Do not write full ADR/OpenAPI documents in the **Story Pack generation step**.
  - Exception: stories MUST declare when OpenAPI is required and specify the file path (`contexto/openapi/actions.yaml`) as part of the story’s implementation.
- Do not override `spec.md`. If spec conflicts, raise a DECISIÓN PENDIENTE.

---

## Example (mini, for calibration)
### ACT-001 — Listado de Templates (FE/BE)
- **Rutas UI:** `/actions` (tab Templates)
- **Entidades internas:** `RuleTemplate`, `RuleTemplateVersion`
- **AC (ejemplo):**
  1) Se lista RuleTemplate con nombre, estado y última edición…
- **QA (ejemplo):**
  1) Con 0 templates, muestra estado vacío…
- **Referencias:** Spec §6 UX, §1 Alcance
