## LINT REPORT
- Gates checked: G1..G6
- Fixes applied:
  - Storypack tecnico inicial para track separado de salud frontend.
- Remaining notes (if any):
  - Ajustar fases segun evidencia incremental de typecheck.

# STORY PACK v1 - Frontend Health

## A) STORY INDEX
- **ID:** FT-001
- **Titulo:** Contrato HTTP tipado en servicios frontend
- **Tipo:** FE
- **Depends on:** `contexto/work/features/frontend_health/spec.md`
- **Blocks:** FT-002, FT-003, FT-004

- **ID:** FT-002
- **Titulo:** Normalizacion de respuestas de tablas y listados
- **Tipo:** FE
- **Depends on:** FT-001
- **Blocks:** FT-004

- **ID:** FT-003
- **Titulo:** Maps store/runtime typing hardening
- **Tipo:** FE
- **Depends on:** FT-001
- **Blocks:** FT-005, FT-006

- **ID:** FT-004
- **Titulo:** Customer views tipadas sin unknown/any implicito
- **Tipo:** FE
- **Depends on:** FT-001, FT-002
- **Blocks:** Ninguna

- **ID:** FT-005
- **Titulo:** Core UI typing and import compatibility
- **Tipo:** FE
- **Depends on:** FT-003
- **Blocks:** Ninguna

- **ID:** FT-006
- **Titulo:** Legacy maps strategy (repair or exclude)
- **Tipo:** FE
- **Depends on:** FT-003
- **Blocks:** Ninguna

## B) STORIES

### FT-001 - Contrato HTTP tipado en servicios frontend
- **Objetivo:** eliminar errores por genericos invalidos y respuestas `unknown`.
- **Backlog refs:** BL-001, BL-003.
- **Criterio de aceptacion:**
  1) No-regresion no-demo (`observed <= baseline`).
  2) Reduccion comprobable de `TS2558` y `TS18046`.

### FT-002 - Normalizacion de respuestas de tablas y listados
- **Objetivo:** alinear `ListResponse`/`PagedList` entre servicios y vistas.
- **Backlog refs:** BL-002.
- **Criterio de aceptacion:**
  1) No-regresion no-demo.
  2) Reduccion de `TS2345`, `TS2322`, `TS2339` en vistas objetivo.

### FT-003 - Maps store/runtime typing hardening
- **Objetivo:** cortar cascada de errores del modulo maps en store/runtime.
- **Backlog refs:** BL-004.
- **Criterio de aceptacion:**
  1) No-regresion no-demo.
  2) Reduccion significativa de errores en `maps.store.ts`.

### FT-004 - Customer views tipadas sin unknown/any implicito
- **Objetivo:** eliminar `unknown`/`any` implicitos en vistas customer.
- **Backlog refs:** BL-007.
- **Criterio de aceptacion:**
  1) No-regresion no-demo.
  2) Reduccion de `TS18046` y `TS7006` en vistas foco.

### FT-005 - Core UI typing and import compatibility
- **Objetivo:** corregir imports y nullability en core/ui.
- **Backlog refs:** BL-008, BL-009.
- **Criterio de aceptacion:**
  1) No-regresion no-demo.
  2) Reduccion de `TS1192`, `TS2532`, `TS2538`.

### FT-006 - Legacy maps strategy (repair or exclude)
- **Objetivo:** definir y ejecutar estrategia de codigo legacy maps.
- **Backlog refs:** BL-010.
- **Criterio de aceptacion:**
  1) No-regresion no-demo.
  2) Sin `TS2307` en alcance definido para la fase.

## C) GUARDRAILS
- Maximo 5 archivos de codigo por fase.
- No mezclar cambios de negocio con historias FT.
- Mantener evidencia Before/After del conteo no-demo.
- `_demo` fuera de alcance salvo decision explicita.
