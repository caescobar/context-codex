# STORY PACK v1 — Módulo “Acciones”

## A) STORY INDEX
- **ID:** ACT-001
- **Título:** Modelo base de dominio y persistencia de Acciones
- **Tipo:** BE / DB
- **Depends on:** `contexto/specs/actions/spec.md`
- **Blocks:** ACT-002, ACT-003, ACT-004, ACT-005, ACT-006, ACT-007

- **ID:** ACT-002
- **Título:** Evaluación runtime con anti-spam y rehidratación
- **Tipo:** BE
- **Depends on:** ACT-001
- **Blocks:** ACT-006, ACT-007

- **ID:** ACT-003
- **Título:** Gestión de Templates y Versiones en Acciones
- **Tipo:** FE / BE
- **Depends on:** ACT-001
- **Blocks:** ACT-004, ACT-005

- **ID:** ACT-004
- **Título:** Asignación de templates a dispositivos y bloqueo de duplicados
- **Tipo:** FE / BE
- **Depends on:** ACT-001, ACT-003
- **Blocks:** ACT-007

- **ID:** ACT-005
- **Título:** Builder Scratch y validaciones del DSL v1
- **Tipo:** FE / BE
- **Depends on:** ACT-003
- **Blocks:** ACT-004

- **ID:** ACT-006
- **Título:** Historial de Runs con errores de acción
- **Tipo:** FE / BE
- **Depends on:** ACT-001, ACT-002
- **Blocks:** Ninguna

- **ID:** ACT-007
- **Título:** Vista de Rules y badge rojo en Acciones y Device Detail
- **Tipo:** FE / BE
- **Depends on:** ACT-001, ACT-002, ACT-004
- **Blocks:** Ninguna

## B) STORIES

#### ACT-001 — Modelo base de dominio y persistencia de Acciones
- **Como** equipo de plataforma  
  **Quiero** definir el modelo mínimo y su persistencia transaccional/runtime  
  **Para** soportar trazabilidad, versionado y ejecución consistente en v1
- **Alcance:** incluye entidades y reglas base de dominio (`RuleTemplate`, `RuleTemplateVersion`, `RuleInstance`, `ActionAttempt`, `AlertFired`, `RuleCheckpoint`) y la separación SQL/Redis/RabbitMQ/ClickHouse; excluye capacidades fuera de v1.
- **Rutas UI:** `/actions`, `/actions/templates/:id`, `/devices/:id`
- **Entidades internas:** `RuleTemplate`, `RuleTemplateVersion`, `RuleInstance`, `ActionAttempt`, `AlertFired`, `RuleCheckpoint`
- **Criterios de aceptación (AC):**
  1) Se define persistencia para `RuleTemplate` y `RuleTemplateVersion` con versión inmutable.
  2) Se define persistencia para `RuleInstance` por dispositivo con referencia a `RuleTemplateVersion`.
  3) Se define persistencia para `ActionAttempt` con `status` success/fail y error cuando corresponda.
  4) Se bloquea duplicado por `(device_id, template_version_id)` en `RuleInstance`.
  5) Se define `RuleCheckpoint` para rehidratación tras caída de Redis/engine.
  6) Se mantiene la separación SQL Server (control-plane), Redis (runtime), RabbitMQ (transporte), ClickHouse (histórico).
- **Checklist QA:**
  1) Crear template y versión y verificar que la versión no cambia al editar de nuevo.
  2) Crear instancia para un device y verificar referencia a versión específica.
  3) Intentar duplicar `(device_id, template_version_id)` y verificar bloqueo.
  4) Registrar intento success y verificar persistencia en `ActionAttempt`.
  5) Registrar intento fail y verificar persistencia de error en `ActionAttempt`.
  6) Simular pérdida de runtime state y verificar rehidratación desde `RuleCheckpoint`.
  7) Verificar que el runtime state no queda solo en memoria volátil.
  8) Verificar que no se introducen entidades fuera de v1.
- **Datos / Contratos (si aplica):**
  - **SQL:** `RuleTemplate`, `RuleTemplateVersion`, `RuleInstance`, `ActionAttempt`, `RuleCheckpoint`; constraint de unicidad `(device_id, template_version_id)`.
  - **Redis:** estado vivo por `(deviceId, ruleInstanceId)` con contadores, timers, `cooldownUntil`, `latchActive`.
  - **RabbitMQ:** consumo de telemetría para evaluación event-driven.
  - **ClickHouse:** telemetría histórica para reglas con ventana cuando aplique.
- **Depends on:** `contexto/specs/actions/spec.md`
- **Referencias:** Spec §0 Objetivo, §1 Alcance, §3 Conceptos y modelo mínimo, §4 Storage y ejecución

#### ACT-002 — Evaluación runtime con anti-spam y rehidratación
- **Como** operador de Acciones  
  **Quiero** que la evaluación runtime reduzca spam y sea recuperable  
  **Para** mantener comportamiento estable ante flapping y fallas
- **Alcance:** incluye auto-reset, latch opcional, cooldown y rehidratación; excluye semánticas no definidas en el spec.
- **Rutas UI:** `/actions`, `/devices/:id`
- **Entidades internas:** `RuleInstance`, `ActionAttempt`, `AlertFired`, `RuleCheckpoint`
- **Criterios de aceptación (AC):**
  1) La evaluación se ejecuta por cada evento consumido desde RabbitMQ.
  2) En auto-reset solo dispara en transición `OK → VIOLATION`.
  3) En auto-reset rearma cuando vuelve a `OK`.
  4) El cooldown suprime nuevos disparos durante N segundos configurados.
  5) En latch mode dispara una vez y queda `ACTIVE`.
  6) El rearme en latch exige `Resolve manual` y condición `OK`.
- **Checklist QA:**
  1) Probar flapping y verificar que no hay spam de disparos.
  2) Probar cooldown y verificar supresión dentro de ventana.
  3) Probar fin de cooldown y verificar nuevo disparo permitido.
  4) Probar latch y verificar que no redispara sin rearme.
  5) Probar resolve manual sin `OK` y verificar que no rearma.
  6) Probar resolve manual con `OK` y verificar rearme.
  7) Simular caída de Redis y verificar rehidratación desde SQL checkpoint.
  8) Verificar registro de `ActionAttempt` con resultado y error cuando aplique.
- **Datos / Contratos (si aplica):**
  - **SQL:** lectura/escritura de `ActionAttempt` y `RuleCheckpoint`.
  - **Redis:** transiciones, cooldown y latch por instancia.
  - **RabbitMQ:** entrada de telemetría para evaluación event-driven.
  - **ClickHouse:** apoyo a reglas históricas en fases que lo requieran.
- **Depends on:** ACT-001
- **Referencias:** Spec §4 Storage y ejecución, §5 Lifecycle y anti-spam, §10 QA mínimo

#### ACT-003 — Gestión de Templates y Versiones en Acciones
- **Como** usuario de Acciones  
  **Quiero** crear y versionar templates reutilizables  
  **Para** mantener reglas consistentes y auditables
- **Alcance:** incluye alta/edición/versionado y detalle de template; excluye extras v2.
- **Rutas UI:** `/actions`, `/actions/templates/:id`
- **Entidades internas:** `RuleTemplate`, `RuleTemplateVersion`, `RuleInstance`
- **Endpoints (si aplica):**
  - Verificar existentes.
  - Si faltan: actualizar `contexto/openapi/actions.yaml` incrementalmente para esta historia.
  - Implementar + pruebas mínimas.
- **Endpoint check gate (obligatorio si hay endpoints):**
  - Discover → Equivalence test → Reuse-first → Only if missing (OpenAPI delta) → DECISIÓN PENDIENTE si hay dudas.
- **Criterios de aceptación (AC):**
  1) `/actions` muestra tab Templates con listado de `RuleTemplate`.
  2) Se permite crear template con definición DSL válida.
  3) Editar template genera nueva `RuleTemplateVersion` inmutable.
  4) `/actions/templates/:id` expone Definition, Versions, Assignments y Runs (fallos).
  5) Las instancias quedan asociadas a una versión específica.
  6) UI en español y entidades internas en inglés en contratos y modelo.
- **Checklist QA:**
  1) Crear template y verificar aparición en listado.
  2) Editar template y verificar nueva versión.
  3) Verificar que la versión anterior no se modifica.
  4) Verificar tabs de detalle esperadas.
  5) Verificar consumo por versión específica.
  6) Verificar que no se activa librería de acciones fuera de Email en v1.
  7) Verificar OpenAPI incremental solo para esta historia.
  8) Verificar pruebas smoke/integration de endpoints afectados.
- **Datos / Contratos (si aplica):**
  - **SQL:** `RuleTemplate`, `RuleTemplateVersion`, referencia desde `RuleInstance`.
  - **Redis:** no aplica directo para CRUD de templates/versiones.
  - **RabbitMQ:** no aplica directo para CRUD de templates/versiones.
  - **ClickHouse:** no aplica directo para CRUD de templates/versiones.
- **Depends on:** ACT-001, `contexto/openapi/actions.yaml`
- **Referencias:** Spec §1 Alcance, §2 UX / Navegación, §3 Conceptos y modelo mínimo, §6 Contrato del builder, §9 Regla de endpoints

#### ACT-004 — Asignación de templates a dispositivos y bloqueo de duplicados
- **Como** usuario de operaciones  
  **Quiero** asignar templates a uno o múltiples dispositivos sin duplicados  
  **Para** escalar configuración sin inconsistencias
- **Alcance:** incluye asignación masiva y flujo desde Device Detail (reusable/local); excluye deduplicación fuera de la regla definida.
- **Rutas UI:** `/actions/templates/:id`, `/devices/:id`, `/actions`
- **Entidades internas:** `RuleTemplateVersion`, `RuleInstance`
- **Endpoints (si aplica):**
  - Verificar existentes.
  - Si faltan: actualizar `contexto/openapi/actions.yaml` incrementalmente para esta historia.
  - Implementar + pruebas mínimas.
- **Endpoint check gate (obligatorio si hay endpoints):**
  - Discover → Equivalence test → Reuse-first → Only if missing (OpenAPI delta) → DECISIÓN PENDIENTE si hay dudas.
- **Criterios de aceptación (AC):**
  1) Asignar versión de template a múltiples devices crea una `RuleInstance` por device.
  2) Desde `/devices/:id` se permite crear regla local o reusable.
  3) Se bloquea duplicado por `(device_id, template_version_id)`.
  4) El bloqueo informa error sin crear instancias extra.
  5) Las instancias quedan pegadas a su `RuleTemplateVersion`.
  6) Overrides v1 permitidos: `threshold`, `email.recipients`; se rechazan otros.
- **Checklist QA:**
  1) Asignar template a múltiples devices y validar cantidad de instancias.
  2) Repetir misma asignación al mismo device y validar bloqueo.
  3) Validar feedback de duplicado en UI.
  4) Crear desde device como reusable y validar reutilización.
  5) Crear desde device como local y validar que no se publica como reusable.
  6) Aplicar override permitido y validar persistencia.
  7) Intentar override no permitido y validar rechazo.
  8) Verificar pruebas smoke/integration de endpoints de asignación.
- **Datos / Contratos (si aplica):**
  - **SQL:** `RuleInstance` con unicidad `(device_id, template_version_id)` y `overrides_json` v1.
  - **Redis:** inicialización/actualización de estado runtime por nuevas instancias.
  - **RabbitMQ:** no aplica directo al flujo de asignación.
  - **ClickHouse:** no aplica directo al flujo de asignación.
- **Depends on:** ACT-001, ACT-003, `contexto/openapi/actions.yaml`
- **Referencias:** Spec §1 Alcance, §2 UX / Navegación, §3 Conceptos y modelo mínimo, §7 Overrides v1, §9 Regla de endpoints

#### ACT-005 — Builder Scratch y validaciones del DSL v1
- **Como** usuario que diseña reglas  
  **Quiero** configurar trigger, condiciones, ventanas y lifecycle  
  **Para** generar definiciones válidas para templates e instancias
- **Alcance:** incluye 5 tipos de regla, missing data policy, lifecycle y acción Email v1; excluye cambios de semántica temporal por overrides.
- **Rutas UI:** `/actions/templates/:id`, `/devices/:id`
- **Entidades internas:** `RuleTemplateVersion`, `RuleInstance`
- **Endpoints (si aplica):**
  - Verificar existentes.
  - Si faltan: actualizar `contexto/openapi/actions.yaml` incrementalmente para esta historia.
  - Implementar + pruebas mínimas.
- **Endpoint check gate (obligatorio si hay endpoints):**
  - Discover → Equivalence test → Reuse-first → Only if missing (OpenAPI delta) → DECISIÓN PENDIENTE si hay dudas.
- **Criterios de aceptación (AC):**
  1) El builder soporta los 5 tipos de regla definidos en v1.
  2) El builder rechaza bloques incompletos.
  3) El builder valida coherencia temporal (`T <= W`) cuando aplica.
  4) El builder soporta `INSUFFICIENT_DATA` y `HOLD_LAST_VALUE` con TTL.
  5) El builder soporta lifecycle auto/latch con cooldown.
  6) El builder valida acción Email con recipients.
- **Checklist QA:**
  1) Guardar regla válida para cada tipo de regla y validar persistencia.
  2) Intentar guardar con bloque incompleto y validar error.
  3) Intentar configuración temporal inválida y validar error.
  4) Configurar `INSUFFICIENT_DATA` y validar persistencia.
  5) Configurar `HOLD_LAST_VALUE` con TTL y validar persistencia.
  6) Configurar lifecycle auto con cooldown y validar persistencia.
  7) Configurar lifecycle latch y validar persistencia.
  8) Verificar pruebas smoke/integration de endpoints afectados.
- **Datos / Contratos (si aplica):**
  - **SQL:** `RuleTemplateVersion.definition_json`, lifecycle y missing data policy.
  - **Redis:** uso runtime de configuración compilada para evaluación.
  - **RabbitMQ:** no aplica directo a la edición del DSL.
  - **ClickHouse:** soporte para evaluaciones históricas de ventana cuando aplique.
- **Depends on:** ACT-003, `contexto/openapi/actions.yaml`
- **Referencias:** Spec §1 Alcance, §6 Contrato del builder, §7 Overrides v1, §9 Regla de endpoints

#### ACT-006 — Historial de Runs con errores de acción
- **Como** usuario de soporte  
  **Quiero** consultar ejecuciones success/fail con detalle de error  
  **Para** auditar y diagnosticar fallas
- **Alcance:** incluye tab Runs en `/actions` y Runs en template detail; excluye mostrar estado interno de evaluación.
- **Rutas UI:** `/actions`, `/actions/templates/:id`
- **Entidades internas:** `ActionAttempt`, `RuleInstance`, `RuleTemplate`
- **Endpoints (si aplica):**
  - Verificar existentes.
  - Si faltan: actualizar `contexto/openapi/actions.yaml` incrementalmente para esta historia.
  - Implementar + pruebas mínimas.
- **Endpoint check gate (obligatorio si hay endpoints):**
  - Discover → Equivalence test → Reuse-first → Only if missing (OpenAPI delta) → DECISIÓN PENDIENTE si hay dudas.
- **Criterios de aceptación (AC):**
  1) `/actions` muestra historial de `ActionAttempt` con estado success/fail.
  2) Cada fail muestra el error registrado.
  3) El detalle de template muestra runs fallidos asociados.
  4) Las consultas de runs soportan filtros alineados a la navegación.
  5) La vista usa `ActionAttempt` como fuente para estados de ejecución.
  6) La UI no expone estado interno (por ejemplo progreso temporal interno).
- **Checklist QA:**
  1) Generar intento success y validar visualización.
  2) Generar intento fail y validar visualización de error.
  3) Probar filtros y validar consistencia.
  4) Abrir template detail y validar sección Runs.
  5) Validar consistencia entre Rules y Runs para una misma instancia.
  6) Validar que no se expone estado interno no permitido.
  7) Verificar OpenAPI incremental para endpoints de runs.
  8) Verificar pruebas smoke/integration de endpoints de runs.
- **Datos / Contratos (si aplica):**
  - **SQL:** lectura de `ActionAttempt` y relaciones con instancia/template.
  - **Redis:** no aplica directo al histórico mostrado.
  - **RabbitMQ:** no aplica directo al render del histórico.
  - **ClickHouse:** no aplica directo a `ActionAttempt` en v1.
- **Depends on:** ACT-001, ACT-002, `contexto/openapi/actions.yaml`
- **Referencias:** Spec §0 Objetivo, §1 Alcance, §2 UX / Navegación, §8 Regla de indicador rojo, §9 Regla de endpoints, §10 QA mínimo

#### ACT-007 — Vista de Rules y badge rojo en Acciones y Device Detail
- **Como** usuario de operaciones  
  **Quiero** ver y operar reglas por dispositivo con indicador de fallas  
  **Para** detectar errores rápido y controlar enabled/paused
- **Alcance:** incluye tab Rules en `/actions`, tab Rules/Acciones en `/devices/:id`, enabled/paused y badge rojo por último fail; excluye estado interno detallado.
- **Rutas UI:** `/actions`, `/devices/:id`
- **Entidades internas:** `RuleInstance`, `ActionAttempt`
- **Endpoints (si aplica):**
  - Verificar existentes.
  - Si faltan: actualizar `contexto/openapi/actions.yaml` incrementalmente para esta historia.
  - Implementar + pruebas mínimas.
- **Endpoint check gate (obligatorio si hay endpoints):**
  - Discover → Equivalence test → Reuse-first → Only if missing (OpenAPI delta) → DECISIÓN PENDIENTE si hay dudas.
- **Criterios de aceptación (AC):**
  1) `/actions` tab Rules lista `RuleInstance` con estado enabled/paused.
  2) `/devices/:id` tab Rules/Acciones muestra reglas adjuntas al device.
  3) Se puede cambiar estado enabled/paused desde vistas de Rules.
  4) El badge rojo se activa cuando el último `ActionAttempt` asociado es `Fail`.
  5) En contexto de template, el badge rojo se deriva de intentos de sus instancias asociadas.
  6) La UI no expone estado interno de evaluación.
- **Checklist QA:**
  1) Validar listado de Rules en `/actions`.
  2) Validar listado de Rules/Acciones en `/devices/:id`.
  3) Pausar regla y validar impacto operativo.
  4) Rehabilitar regla y validar retorno operativo.
  5) Forzar último intento fail y validar badge rojo activo.
  6) Generar intento success posterior y validar actualización del badge.
  7) Verificar OpenAPI incremental para endpoints de rules.
  8) Verificar pruebas smoke/integration de endpoints de rules.
- **Datos / Contratos (si aplica):**
  - **SQL:** lectura/escritura de `RuleInstance` y lectura del último `ActionAttempt` por instancia.
  - **Redis:** sincronización de estado runtime con enabled/paused.
  - **RabbitMQ:** no aplica directo a render de vistas de Rules.
  - **ClickHouse:** no aplica directo a vistas de Rules en v1.
- **Depends on:** ACT-001, ACT-002, ACT-004, `contexto/openapi/actions.yaml`
- **Referencias:** Spec §1 Alcance, §2 UX / Navegación, §5 Lifecycle y anti-spam, §8 Regla de indicador rojo, §9 Regla de endpoints, §10 QA mínimo

## C) GUARDRAILS (DO NOT DO)
- No crear endpoints/rutas/colas/tecnologías que no estén explícitamente en `contexto/specs/actions/spec.md`.
- No crear historia gate de endpoints/OpenAPI (no `ACT-000`).
- No agregar endpoint nuevo sin revisar equivalencia y sin OpenAPI delta incremental cuando falte.
- No usar function-per-rule deployment.
- No inventar semánticas temporales fuera de instant/duration/window/cooldown/latch definidas en v1.
- No exponer estado interno de evaluación en UI.
- No permitir overrides v1 fuera de `threshold` y `email.recipients`.
- No activar acciones operativas distintas de Email en v1.

## D) DOC DELIVERABLES (do not write them)
- **ADR requerido:** `ADR-acciones-runtime-state-redis-sql-checkpoint.md` — formalizar runtime state en Redis con checkpoint SQL para rehidratación.
- **ADR requerido:** `ADR-acciones-lifecycle-auto-latch-cooldown.md` — formalizar reglas de lifecycle, anti-spam y rearme en v1.
- **OpenAPI delta requerido:** `contexto/openapi/actions.yaml` — contratos incrementales por historia que requiera endpoints.
- **DB migration checklist requerido:** `contexto/migrations/actions_v1_checklist.md` — tablas, índices y constraints del modelo v1.
- **QA matrix/runbook requerido:** `contexto/qa/actions_v1_test_matrix.md` — pruebas mínimas de anti-spam, cooldown, latch, duplicados, runs, badge rojo y rehidratación.
