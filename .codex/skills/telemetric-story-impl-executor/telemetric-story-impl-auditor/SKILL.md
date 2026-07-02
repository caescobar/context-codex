# telemetric-story-impl-auditor

## Purpose
Orchestrate **audit-only** for a single Telemetric story (**ACT-###**) to prepare implementation:
- Inspect repo to infer **real standards** (backend + DB)
- Apply Telemetric **normative standards** (backend + SQLServer) as baseline
- Validate story feasibility against repo + spec + storypack
- Ask only **minimum blocking questions**
- Produce a **phase plan** (max 5 files per phase) with verification checklists
- **Never write code** in this run

---

## Mode
**AUDIT-ONLY (NO CODE)**

### Hard Prohibitions
- DO NOT create/modify any product/source files (code/DB/scripts/OpenAPI/ADRs/etc.).
- DO NOT generate code, migrations, SQL scripts, OpenAPI YAML, ADRs, or commits.
- DO NOT propose exact method implementations or full code blocks.
- DO NOT continue to implementation in the same run.

If the user asks for code in this run, respond:
**“Este run es SOLO AUDIT. Puedo preparar el plan y las preguntas; luego pasamos a implementación.”**

---

## Inputs (required)
- `requirement_slug`: e.g., `acciones_modulo` (used only for output folder grouping)
- `story_id`: e.g., `ACT-001`
- `storypack_path`: e.g., `contexto/work/features/<slug>/storypacks/ACT_v1.md`
- `spec_path`: e.g., `contexto/work/features/<slug>/spec.md`

Optional:
- Any repo paths/modules the user provides for faster discovery

---

## Standards Inputs (MANDATORY)
The auditor MUST load and apply these standards as the normative baseline:
- `.codex/skills/telemetric-backend-standards/SKILL.md`
- `.codex/skills/telemetric-sqlserver-standards/SKILL.md`

If any standards file is missing, STOP and set **Status=BLOQUEADO** with one blocking question.

---

## Outputs (required)

### Output files (MANDATORY)
The auditor MUST:
1) Write the full audit report to:
   `contexto/work/features/<requirement_slug>/01_audits/{story_id}.audit.md`
2) Write the phase plan to:
   `contexto/work/features/<requirement_slug>/02_plans/{story_id}.plan.md`
3) Also print the SAME audit content in chat output (for visibility).

### Determinism rules
- Always create/overwrite the two files above.
- The files MUST contain the exact sections described in **Output Format** (HEADER + A/B/C/D) in the same order.
- Include a top header with `Status: READY | BLOQUEADO`.

---

## What to Inspect (mandatory)

### 0) Standards Lock (MANDATORY)
The auditor MUST produce a **Standards Lock** for this story by comparing:
- Repo-discovered practices (observed)
VS
- Telemetric normative standards from:
  - `telemetric-backend-standards`
  - `telemetric-sqlserver-standards`

For each category below, output one status:
- **ADOPTED**: repo matches standards OR standards can be applied without contradictions.
- **CONFLICT**: repo contradicts standards (blocking).
- **NEW/NO-EVIDENCE**: repo lacks evidence (may be blocking if it impacts this story).

**Categories to lock (minimum):**
Backend:
- Routing/versioning pattern, Tags/Policies, DTO conventions,
- CQRS-lite naming (`*Command/*Query/*Handler`), Result<T> envelope,
- Send.OkAsync/Send.ErrorsAsync style, Mapster mapping approach,
- Folder structure conventions, error/status codes.
SQLServer:
- Migrations source of truth, naming (tables/PK/FK/index/constraints),
- soft-delete/audit columns, multi-tenant scoping, unique constraints semantics (incl. soft-delete).

**Blocking rule for lock:**
- If any required category for this story is **CONFLICT** → Status=BLOQUEADO.
- If any required category for this story is **NEW/NO-EVIDENCE** → Status=BLOQUEADO with minimal questions (max 7 total).
- If everything required is **ADOPTED** → can be READY.

---

### 1) Backend standards discovery (repo-driven)
Extract from existing code (observed-only):
- FastEndpoints routing/versioning pattern
- Tags/Policies conventions
- Request/Response DTO conventions
- CQRS-lite conventions: `ICommand<>`, `ICommandHandler<>`, naming
- `Result<T>` / `Send.OkAsync` / `Send.ErrorsAsync` style
- Mapping patterns (Mapster)
- Permissions pattern: `PermissionClaims.*`
- Folder structure: `Features/<Area>/<Action>/...`
- Error handling/status codes conventions

---

### 2) DB standards discovery (repo-driven)
Extract (observed-only):
- How SQL schema is managed (EF model mapping vs manual scripts) and what is *actually* used
- Naming conventions (tables/PK/FK/columns/indexes/constraints)
- Audit/soft-delete conventions (if any)
- Multi-client scoping patterns (e.g., `ClientId`)
- Constraints patterns (unique keys, FKs)

---

### 3) Story alignment check (repo + spec + storypack)
For the requested `story_id`:
- Identify required artifacts (entities, tables, constraints, endpoints, UI surfaces) but DO NOT generate them.
- Verify whether equivalents already exist; recommend reuse-first.
- Validate guardrails (no invention, v1 scope).

---

## Output Format (mandatory)

### HEADER
- **Story:** <ACT-###>
- **Requirement:** <requirement_slug>
- **Inputs:** <storypack_path>, <spec_path>
- **Status:** READY | BLOQUEADO
- **Fecha:** YYYY-MM-DD

### A) AUDIT
#### A0. Standards Lock (MANDATORY)
For each category:
- **Category:** <Backend|SQLServer|...>
- **Status:** ADOPTED | CONFLICT | NEW/NO-EVIDENCE
- **Evidence (repo):** file paths or "no evidence found"
- **Standard (source):** `telemetric-backend-standards` or `telemetric-sqlserver-standards`
- **Impact:** phases affected (01/02/03...)

#### A1. Repo Standards (Backend)
Bullets of observed conventions (repo evidence).

#### A2. Repo Standards (DB)
Bullets of observed conventions (repo evidence).

#### A3. Story Fit Check
Needs vs existing (reuse candidates, gaps).

#### A4. Guardrails Confirmation
Key “no hacer” constraints for this story.

### B) PREGUNTAS o “SIN PREGUNTAS”
- Max 7 questions, binary/specific.
- If questions exist, still provide plan with affected phases marked **BLOQUEADO**.

### C) PLAN POR FASES (máx 5 archivos por fase)
For each phase:
- Objetivo
- Archivos candidatos (máx 5) (paths only)
- Cambios esperados (alto nivel) (no code)
- Checklist de verificación (concreto)
- Bloqueos (si aplica)

### D) RIESGOS / DECISIONES PENDIENTES (si aplica)
- Include “Decisiones sugeridas” with IDs when blocked:
  - `D-{story_id}-{topic}` (example: `D-ACT-001-SQL-MIGRATIONS`)

---

## Stop-on-Ambiguity Rule
If a required standard cannot be inferred or locked (envelope/errors/versioning/auth/migrations),
1) Ask a blocking question,
2) Mark phases as BLOQUEADO,
3) Do NOT invent a standard.

---

## Reuse-First Rule
Prefer reuse; if “close but not equal”, ask instead of assuming.

---

## Constraints
- Each phase: max 5 files
- Output in Spanish; internal names in English; UI labels in Spanish.

---

## Hard Guardrails adicionales (repo-driven)

### R1 — No runtime contamination en historias DB-fundacionales
Si la historia:
- es principalmente **DB/Domain** (ej. ACT-001) y
- **no requiere endpoints** (storypack dice “No aplica”),

ENTONCES el auditor **NO DEBE** proponer tocar archivos runtime/engine, wiring de conectores, ni componentes de telemetría.
Prohibido proponer archivos candidatos como:
- `telemetric-api/src/Telemetric.Api/Features/Telemetry/**`
- `TelemetryWorker`, `TelemetryHub`
- cualquier ruta `telemetric-hub/**`
- “connectors” del hub fuera del API

Permitido:
- `Domain/Entities/**`
- `Infrastructure/Persistence/**`
- `Common/Interfaces/**`
- `Database/Migrations/**` (si aplica)
- checklists en `contexto/**` o `contexto/work/**`

### R2 — Unique index + soft-delete: decisión explícita obligatoria
Si el plan incluye unicidad sobre entidades con soft-delete:
- **A) Histórico fuerte:** unique NO considera `IsDeleted`.
- **B) Re-creación permitida:** unique SÍ permite recrear (p.ej. índice filtrado `IsDeleted = 0`).

Si no se puede inferir del repo o standards:
- marcar **BLOQUEADO**,
- preguntar A/B,
- fases afectadas **BLOQUEADO**.

### R3 — Ruta estándar de migraciones SQL (no inventar rutas nuevas)
Si el repo usa una ruta dominante (p.ej. `.../Database/Migrations/*.sql`),
NO proponer una ruta nueva.
Si hay dos rutas activas, levantar **DECISIÓN PENDIENTE** y pedir escoger una.

### R4 — Output determinístico obligatorio (orden)
Este skill siempre escribe:
- `contexto/work/features/<requirement_slug>/01_audits/{story_id}.audit.md`
- `contexto/work/features/<requirement_slug>/02_plans/{story_id}.plan.md`
Y el contenido en chat debe ser el mismo.
