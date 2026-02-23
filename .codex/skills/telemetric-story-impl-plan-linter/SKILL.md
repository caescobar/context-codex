# telemetric-story-impl-plan-linter

## Purpose
Lint automático para asegurar que un **plan de implementación** (y/o audit) cumple guardrails y estándares del repo
antes de ejecutar implementación.

Este linter existe para evitar “mejoras manuales” después: si falla un gate, el output queda **BLOQUEADO**.

---

## Mode
**LINT-ONLY (NO CODE)**

### Hard Prohibitions
- DO NOT generar código, SQL, OpenAPI, ADRs.
- DO NOT modificar archivos de repo.
- DO NOT proponer implementaciones detalladas.
- Solo validar y reportar.

---

## Inputs (required)
- `requirement_slug`: ej. `acciones_modulo`
- `story_id`: ej. `ACT-001`
- `plan_path`: ej. `contexto/02_plans/{requirement_slug}/{story_id}.plan.md`
- `audit_path`: ej. `contexto/01_audits/{requirement_slug}/{story_id}.audit.md`
- `storypack_path`: ej. `contexto/work/features/{requirement_slug}/storypacks/ACT_v1.md`
- `spec_path`: ej. `contexto/work/features/{requirement_slug}/spec.md`

---

## Output (required)

### Output file (MANDATORY)
Escribir SIEMPRE el reporte a:
- `contexto/03_lints/{requirement_slug}/{story_id}.plan.lint.md`

También imprimir el mismo contenido en el chat.

### Determinism rules
- Siempre create/overwrite el archivo.
- El reporte debe incluir: status, gates, fixes sugeridos.

---

## Gates (mandatory)
El linter evalúa G1..G6.

### G1 — Endpoint rule gate (consistencia story vs plan)
- Si la historia en storypack indica **Endpoints: No aplica**, el plan NO puede incluir:
  - OpenAPI, endpoints, rutas `/api/v1/...`, ni “actualizar actions.yaml”.
- Si la historia indica que **sí** aplica endpoints, el plan DEBE incluir explícitamente:
  - “Verificar existentes” + “OpenAPI delta incremental” + “pruebas smoke/integration”.

### G2 — Runtime contamination gate (DB-fundacional)
Si story es DB/Domain fundacional sin endpoints (ej. ACT-001):
- Prohibido que el plan proponga tocar:
  - `telemetric-api/src/Telemetric.Api/Features/Telemetry/**`
  - `TelemetryWorker`, `TelemetryHub`
  - `telemetric-hub/**`
  - connectors del hub no relacionados a persistencia base
- Si aparece, el gate falla.

### G3 — Unique + soft-delete gate (decisión explícita)
Si el plan incluye constraint/index unique relacionado con entidades con soft-delete:
- Debe declarar explícitamente semántica:
  - **A) Histórico fuerte** o **B) Filtrado IsDeleted=0**
- Si no está declarado, falla.

### G4 — Migration path gate
- El plan NO puede inventar rutas de migración SQL.
- Debe usar la ruta estándar observada en el audit (por ejemplo `Database/Migrations/*.sql`).
- Si el audit reporta “híbrido” y no hay estándar elegido, el linter exige “DECISIÓN PENDIENTE” o un estándar fijado.

### G5 — Phase constraint gate
- Cada fase: máximo **5 archivos** listados.
- Si excede, falla.

### G6 — Repo standards alignment gate
- El plan debe reflejar estándares observados en el audit:
  - Backend: FastEndpoints + CQRS-lite + Result<T> + Mapster + Policies
  - DB: DbContext mappings, tablas singular, BaseEntity/auditoría/soft-delete
- Si el plan propone algo que contradice lo observado (ej. envelope distinto, rutas no versionadas, naming fuera),
falla o marca “DECISIÓN PENDIENTE”.

---

## Output Format (mandatory)
El reporte debe tener EXACTAMENTE estas secciones:

# HEADER
- Story:
- Requirement:
- Inputs:
- Status: READY | BLOQUEADO
- Fecha:

## LINT REPORT
- Gates checked: G1..G6
- Failures:
  - (lista)
- Fixes sugeridos:
  - (lista concreta)
- Notes:
  - (si aplica)

---

## Status rules
- Si algún gate falla => **BLOQUEADO**
- Si todos pasan => **READY**

---

## Language
- Reporte en español.
- Nombres internos (entities/clases/tablas) en inglés.
