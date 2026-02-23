# DECISIONS - acciones_modulo

Este archivo registra decisiones minimas para desbloquear AUDIT/PLAN por historia (ACT-###).
Formato: cada decision referencia el audit y la pregunta (B1, B2, etc.) para trazabilidad.

---

## ACT-001

### D-ACT-001-B1 - Ruta oficial para cambios SQL (ACT-001)
- **Audit origen:** `contexto/01_audits/acciones_modulo/ACT-001.audit.md`
- **Pregunta:** B1
- **Decision:** Opcion B - `telemetric-api/scripts/*.sql`
- **Motivo (1 linea):** Centralizaremos los scripts de schema nuevos en `telemetric-api/scripts` para este requerimiento.
- **Impacto:** Fase 2 y Fase 3 de ACT-001 quedan desbloqueadas respecto a la ruta de SQL.
- **Fecha:** 2026-02-16

### D-ACT-001-B2 - Persistencia de AlertFired (ACT-001)
- **Audit origen:** `contexto/01_audits/acciones_modulo/ACT-001.audit.md`
- **Pregunta:** Para ACT-001, ?`AlertFired` se materializa ya como tabla SQL en `telemetric-api/scripts/*.sql` o se difiere como evento persistido para historia posterior?
- **Decision:** Opcion B - diferir como evento persistido / historia posterior
- **Motivo (1 linea):** Mantener ACT-001 fundacional (dominio+DB core) y evitar ampliar alcance de trazabilidad de eventos antes del engine.
- **Impacto:** ACT-001 no crea tabla `AlertFired`; se crea entidad/contrato minimo si hace falta. Materializacion SQL se agenda en ACT-002 o historia dedicada.
- **Fecha:** 2026-02-16

---

## ACT-002

### D-ACT-002-B1 - Host del engine de evaluacion de acciones (ACT-002)
- **Audit origen:** `contexto/work/features/acciones_modulo/01_audits/ACT-002.audit.md`
- **Pregunta:** B1
- **Decision:** Opcion A - Worker dedicado en `telemetric-hub/kiss` consumiendo `telemetry.actions`
- **Motivo (1 linea):** Alinea la evaluacion runtime con la arquitectura event-driven del hub y evita sobrecargar el worker de SignalR en API.
- **Impacto:** Se define host unico del engine para ACT-002; desbloquea diseno de fases runtime (Fase 1/2/3) pendiente de cerrar B2.
- **Fecha:** 2026-02-17

### D-ACT-002-B2 - Contrato de `Resolve manual` para latch (ACT-002)
- **Audit origen:** `contexto/work/features/acciones_modulo/01_audits/ACT-002.audit.md`
- **Pregunta:** B2
- **Decision:** Opcion B - excepcion explicita y agregar endpoint HTTP en ACT-002 (actualizando storypack para reflejarlo)
- **Motivo (1 linea):** Se requiere una accion operativa explicita y auditable por usuario para rearmar latch de forma controlada.
- **Impacto:** ACT-002 debe actualizar storypack (y contrato API incremental) para incorporar el canal HTTP de `Resolve manual`; habilita validacion completa de AC6.
- **Fecha:** 2026-02-17

---

## ACT-003

### D-ACT-003-PERMISSIONS - Convencion de permisos para Templates/Versions (ACT-003)
- **Audit origen:** `contexto/work/features/acciones_modulo/01_audits/ACT-003.audit.md`
- **Pregunta:** B1
- **Decision:** Opcion B - usar permisos genericos `PermissionClaims.Actions.View/Create/Update`
- **Motivo (1 linea):** Simplifica la matriz de autorizacion inicial del modulo Actions y evita granularidad prematura en ACT-003.
- **Impacto:** Desbloquea Fase 1 y Fase 2 de ACT-003 respecto al criterio de policies para endpoints de templates/versiones.
- **Fecha:** 2026-02-17

### D-ACT-003-QA-PATH - Normalizacion de QA path canónico (ACT-003)
- **Audit origen:** `contexto/work/features/acciones_modulo/01_audits/ACT-003.audit.md`
- **Pregunta:** B2
- **Decision:** Opcion A - usar solo ruta canonica `contexto/work/features/acciones_modulo/04_test/ACT-003/...`
- **Motivo (1 linea):** Alinea la evidencia QA al estandar operativo actual y evita duplicidad de artefactos en rutas legacy.
- **Impacto:** Desbloquea Fase 4 de ACT-003 y fija `STORY_QA.md` + carpetas por fase como unica ubicacion valida.
- **Fecha:** 2026-02-17

### D-ACT-003-FE-ROUTES - Ruta frontend del modulo Actions (ACT-003)
- **Audit origen:** `contexto/work/features/acciones_modulo/01_audits/ACT-003.audit.md`
- **Pregunta:** B3
- **Decision:** Opcion A - respetar spec literal `/actions` y `/actions/templates/:id`
- **Motivo (1 linea):** Mantiene coherencia directa con el spec v1 y evita desalineacion funcional/documental.
- **Impacto:** Desbloquea Fase 3 de ACT-003 para definir rutas y navegacion frontend del modulo.
- **Fecha:** 2026-02-17

### D-ACT-003-FRONT-NONREGRESSION - Politica de deuda TS no-demo (ACT-003)
- **Audit origen:** `contexto/work/features/acciones_modulo/04_test/ACT-003/phase-03/evidence/outputs.log`
- **Pregunta:** La deuda de typecheck no-demo del frontend bloquea el delivery de ACT-003?
- **Decision:** Opcion B - No bloquea delivery con gate de no-regresion; bloquea solo si empeora o impacta archivos/rutas tocadas por la story activa.
- **Motivo (1 linea):** Permite continuidad del delivery funcional de Acciones sin aceptar degradacion tecnica incremental.
- **Impacto:** QA por fase frontend debe validar baseline no-demo y fallar si el conteo de errores sube; se mantiene track tecnico separado en `contexto/work/backlogs/front-typecheck/FRONT-TYPECHECK_v1.md`.
- **Fecha:** 2026-02-19

---

## ACT-004

### D-ACT-004-FE-DEVICE-ROUTE - Ruta Device Detail para Acciones (ACT-004)
- **Audit origen:** `contexto/work/features/acciones_modulo/01_audits/ACT-004.audit.md`
- **Pregunta:** B1
- **Decision:** Opcion A - reutilizar el detalle customer existente `'/my-devices/:id/edit'` como superficie `Device Detail` para ACT-004/ACT-007 (sin crear ruta nueva en esta historia).
- **Motivo (1 linea):** Ya existe flujo operativo de detalle por device en customer y evita duplicar UX/routing en v1.
- **Impacto:** Desbloquea B1 en ACT-004; las fases FE deben integrar acciones sobre `DeviceCustomerEditView` y mantener trazabilidad con el spec de `Device Detail`.
- **Fecha:** 2026-02-19

### D-ACT-004-PERMISSIONS-ASSIGN - Claim de autorizacion para asignacion (ACT-004)
- **Audit origen:** `contexto/work/features/acciones_modulo/01_audits/ACT-004.audit.md`
- **Pregunta:** B2
- **Decision:** Opcion B - claim dedicado `PermissionClaims.Actions.Assign`.
- **Motivo (1 linea):** La asignacion de templates es una operacion exclusiva de customer y requiere control separado de `Actions.Create/Update`.
- **Impacto:** Endpoints y UI de asignacion en ACT-004 usan `Actions.Assign`; el flujo de superadmin queda fuera del alcance operativo de asignacion.
- **Fecha:** 2026-02-19

---

## ACT-005

### D-ACT-005-DSL-CONTRACT - Contrato canonico de `DefinitionJson` (ACT-005)
- **Audit origen:** `contexto/work/features/acciones_modulo/01_audits/ACT-005.audit.md`
- **Pregunta:** B1
- **Decision:** Opcion A - definir schema DSL canonico v1 (base comun + `oneOf` por `ruleType`) con accion `EMAIL` unica.
- **Motivo (1 linea):** Cierra la ambiguedad actual de `definitionJson` libre y alinea FE/BE/OpenAPI con validacion determinista.
- **Impacto:** Desbloquea fases 1-4 de ACT-005 respecto al contrato de datos; habilita validaciones semanticas en backend y builder guiado en frontend.
- **Fecha:** 2026-02-20

Detalles de la decision:
- `ruleType` (enum cerrado v1): `INSTANT_THRESHOLD`, `CONTINUOUS_DURATION`, `ACCUMULATED_DURATION_WINDOW`, `AGGREGATION_WINDOW`, `COUNT_OCCURRENCES_WINDOW`.
- Base obligatoria en `DefinitionJson`: `version=1`, `ruleType`, `metricCode`, `valueType=NUMBER`, `evaluation`, `lifecycle`, `action`, `condition`.
- `condition` por tipo:
  - `INSTANT_THRESHOLD`: `op`, `value`.
  - `CONTINUOUS_DURATION`: `op`, `value` + `evaluation.durationSeconds`.
  - `ACCUMULATED_DURATION_WINDOW`: `op`, `value` + `evaluation.durationSeconds`.
  - `AGGREGATION_WINDOW`: `aggregation`, `op`, `value`.
  - `COUNT_OCCURRENCES_WINDOW`: `op`, `value`, `minCount`.
- `action.type` v1: solo `EMAIL`.
- Errores de validacion: HTTP 400, path de campo (ej. `evaluation.durationSeconds`, `action.recipients[2]`) y orden estable por path.

### D-ACT-005-TIME-UNITS - Unidad temporal y rangos DSL (ACT-005)
- **Audit origen:** `contexto/work/features/acciones_modulo/01_audits/ACT-005.audit.md`
- **Pregunta:** B2
- **Decision:** Opcion A - unidad unica `seconds` para todos los campos temporales del DSL.
- **Motivo (1 linea):** Evita ambiguedad entre FE/BE y simplifica reglas de validacion temporal (`T <= W`) en v1.
- **Impacto:** Desbloquea validaciones temporales de fases 2-4 de ACT-005 y contrato OpenAPI incremental de la historia.
- **Fecha:** 2026-02-20

Rangos v1:
- `evaluation.windowSeconds`: `1..604800`.
- `evaluation.durationSeconds`: `1..windowSeconds` (solo cuando aplique por `ruleType`).
- `lifecycle.cooldownSeconds`: `0..86400` (`0` = sin cooldown).

Regla global:
- Todo campo temporal derivado debe cumplir `<= evaluation.windowSeconds` cuando aplique.

### D-ACT-005-HOLD-LAST-TTL - Politica de TTL para `HOLD_LAST_VALUE` (ACT-005)
- **Audit origen:** `contexto/work/features/acciones_modulo/01_audits/ACT-005.audit.md`
- **Pregunta:** B3
- **Decision:** Opcion A - `ttlSeconds` obligatorio y `> 0` cuando `missingDataPolicy.mode=HOLD_LAST_VALUE`.
- **Motivo (1 linea):** Reduce ambiguedad operativa en runtime y evita semanticas especiales de TTL infinito en v1.
- **Impacto:** Desbloquea validaciones de missing data policy en fases 2-4 de ACT-005.
- **Fecha:** 2026-02-20

Reglas v1:
- `missingDataPolicy.mode` enum: `INSUFFICIENT_DATA | HOLD_LAST_VALUE`.
- Si `mode=HOLD_LAST_VALUE`: `ttlSeconds` obligatorio, rango `1..604800`.
- Si `mode=INSUFFICIENT_DATA`: `ttlSeconds` debe ir `null` o ausente.
- `ttlSeconds=0` no permitido en v1.

### D-ACT-005-EMAIL-VALIDATION - Validacion de recipients Email (ACT-005)
- **Audit origen:** `contexto/work/features/acciones_modulo/01_audits/ACT-005.audit.md`
- **Pregunta:** B4
- **Decision:** Opcion B - validar formato email basico + normalizacion en v1.
- **Motivo (1 linea):** Mejora calidad de datos de acciones sin introducir validaciones RFC extremas de alto costo.
- **Impacto:** Desbloquea validaciones de accion en fases 2-4 de ACT-005 y criterios QA de la fase 5.
- **Fecha:** 2026-02-20

Reglas v1:
- `action.recipients`: `1..20` elementos.
- Normalizacion: `trim`, `lowercase`, `unique`.
- Longitud maxima por email: `254`.
- Formato: email basico (no RFC extremo).
- Si existe algun invalido: responder 400 con error determinista por indice (`action.recipients[i]`).

---

## Notas
- Si una decision aplica a varias historias (ACT-002, ACT-003...), se replica como referencia en cada historia para mantener trazabilidad.
- Si una decision cambia, se agrega una nueva entrada (no se borra la anterior) indicando "Reemplaza a ...".
