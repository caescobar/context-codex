## LINT REPORT
- Gates checked: G1..G6
- Fixes applied:
  - Se normalizo el formato canonico de historias y orden de secciones G1.
  - Se agrego `Endpoint check gate` en todas las historias (o `No aplica`) segun G1.
  - Se mantuvo `Rutas UI: N/A (engine runtime)` para historia runtime segun G2.
  - Se removieron dependencias duras a OpenAPI fuera de `Endpoints (si aplica)` segun G3.
  - Se ajustaron AC/QA para condiciones medibles y verificables segun G4.
  - Se alinearon guardrails al spec v1 sin supuestos externos segun G5.
  - Se verifico trazabilidad con referencias exactas del spec en cada historia segun G6.
- Remaining notes (if any):
  - Sin notas bloqueantes.

# STORY PACK v1 - Modulo "Acciones"

## A) STORY INDEX
- **ID:** ACT-001
- **Titulo:** Modelo base de dominio y persistencia de Acciones
- **Tipo:** BE / DB
- **Depends on:** `contexto/work/features/acciones_modulo/spec.md`
- **Blocks:** ACT-002, ACT-003, ACT-004, ACT-005, ACT-006, ACT-007

- **ID:** ACT-002
- **Titulo:** Evaluacion runtime con anti-spam y rehidratacion
- **Tipo:** BE
- **Depends on:** ACT-001
- **Blocks:** ACT-006, ACT-007

- **ID:** ACT-003
- **Titulo:** Gestion de Templates y Versiones en Acciones
- **Tipo:** FE / BE
- **Depends on:** ACT-001
- **Blocks:** ACT-004, ACT-005

- **ID:** ACT-004
- **Titulo:** Asignacion de templates a dispositivos y bloqueo de duplicados
- **Tipo:** FE / BE
- **Depends on:** ACT-001, ACT-003
- **Blocks:** ACT-007

- **ID:** ACT-005
- **Titulo:** Builder Scratch y validaciones del DSL v1
- **Tipo:** FE / BE
- **Depends on:** ACT-003
- **Blocks:** ACT-004

- **ID:** ACT-006
- **Titulo:** Historial de Runs con errores de accion
- **Tipo:** FE / BE
- **Depends on:** ACT-001, ACT-002
- **Blocks:** Ninguna

- **ID:** ACT-007
- **Titulo:** Vista de Rules y badge rojo en Acciones y Device Detail
- **Tipo:** FE / BE
- **Depends on:** ACT-001, ACT-002, ACT-004
- **Blocks:** Ninguna

## B) STORIES

#### ACT-001 - Modelo base de dominio y persistencia de Acciones
- **Como** equipo de plataforma
  **Quiero** definir el modelo minimo y su persistencia transaccional/runtime
  **Para** soportar trazabilidad, versionado y ejecucion consistente en v1
- **Alcance:** Incluye entidades base (`RuleTemplate`, `RuleTemplateVersion`, `RuleInstance`, `ActionAttempt`, `AlertFired`, `RuleCheckpoint`) y separacion SQL/Redis/RabbitMQ/ClickHouse. Excluye capacidades fuera de v1.
- **Rutas UI:** `/actions`, `/actions/templates/:id`, `/devices/:id`
- **Entidades internas:** `RuleTemplate`, `RuleTemplateVersion`, `RuleInstance`, `ActionAttempt`, `AlertFired`, `RuleCheckpoint`
- **Endpoints (si aplica):** No aplica
- **Endpoint check gate:** No aplica
- **Criterios de aceptacion (AC):**
  1) Existe definicion persistente de `RuleTemplate` y `RuleTemplateVersion` con version inmutable.
  2) Existe definicion persistente de `RuleInstance` por device con referencia obligatoria a `RuleTemplateVersion`.
  3) `ActionAttempt` registra `status` (`Success` o `Fail`) y error obligatorio cuando `status=Fail`.
  4) Se bloquea duplicado por `(device_id, template_version_id)` en `RuleInstance`.
  5) `RuleCheckpoint` queda definido para rehidratacion tras caida de Redis/engine.
  6) Se conserva separacion de responsabilidades: SQL Server control-plane, Redis runtime, RabbitMQ transporte, ClickHouse historico.
- **Checklist QA:**
  1) Crear template y version; confirmar que editar luego crea nueva version y no muta la anterior.
  2) Crear instancia para un device; confirmar referencia a `RuleTemplateVersion`.
  3) Intentar duplicar `(device_id, template_version_id)`; confirmar rechazo.
  4) Registrar `ActionAttempt` exitoso; confirmar persistencia con `status=Success`.
  5) Registrar `ActionAttempt` fallido; confirmar persistencia con `status=Fail` y error.
  6) Simular perdida de estado runtime; confirmar rehidratacion desde `RuleCheckpoint`.
  7) Confirmar que estado runtime no se persiste unicamente en memoria volatil.
  8) Confirmar que no aparecen entidades fuera del alcance v1.
- **Datos / Contratos (si aplica):**
  - **SQL:** `RuleTemplate`, `RuleTemplateVersion`, `RuleInstance`, `ActionAttempt`, `RuleCheckpoint`, constraint unico `(device_id, template_version_id)`.
  - **Redis:** estado vivo por `(deviceId, ruleInstanceId)` con `cooldownUntil`, `latchActive`, timers y contadores.
  - **RabbitMQ:** consumo de telemetria para evaluacion event-driven.
  - **ClickHouse:** soporte de telemetria historica para reglas por ventana en fases que lo requieran.
- **Depends on:** `contexto/work/features/acciones_modulo/spec.md`
- **Referencias:** `spec.md` §1, `spec.md` §3, `spec.md` §4

#### ACT-002 - Evaluacion runtime con anti-spam y rehidratacion
- **Como** operador de Acciones
  **Quiero** que la evaluacion runtime reduzca spam y sea recuperable
  **Para** mantener comportamiento estable ante flapping y fallas
- **Alcance:** Incluye auto-reset, latch opcional, cooldown y rehidratacion. Excluye semanticas no definidas por el spec.
- **Rutas UI:** N/A (engine runtime)
- **Entidades internas:** `RuleInstance`, `ActionAttempt`, `AlertFired`, `RuleCheckpoint`
- **Endpoints (si aplica):**
  - Verificar existentes (Discover + Equivalence test)..
  - Si faltan: actualizar incrementalmente contexto/openapi/actions.yaml solo con el delta de esta historia.
  - Implementar Resolve manual y pruebas mínimas smoke/integration en esta historia.
- **Endpoint check gate (obligatorio si hay endpoints):**
  - Discover -> Equivalence test -> Reuse-first -> Only if missing (OpenAPI delta) -> DECISION PENDIENTE si hay dudas
- **Criterios de aceptacion (AC):**
  1) La evaluacion consume eventos desde RabbitMQ por cada telemetria recibida.
  2) En auto-reset, solo dispara en transicion `OK -> VIOLATION`.
  3) En auto-reset, rearma unicamente cuando la condicion retorna a `OK`.
  4) Cooldown suprime cualquier disparo adicional por N segundos configurados.
  5) En latch mode, dispara una vez y queda en estado `ACTIVE`.
  6) En latch mode, el rearme exige `Resolve manual` y condicion `OK` simultaneamente.
- **Checklist QA:**
  1) Simular flapping; confirmar ausencia de spam de disparos.
  2) Configurar cooldown y validar supresion durante ventana activa.
  3) Esperar fin de cooldown y validar habilitacion de nuevo disparo.
  4) Activar latch y validar que no redispara antes de rearme.
  5) Ejecutar `Resolve manual` con condicion en violacion; validar que no rearma.
  6) Ejecutar `Resolve manual` con condicion en `OK`; validar rearme.
  7) Simular caida de Redis; validar rehidratacion desde SQL via `RuleCheckpoint`.
  8) Verificar que cada disparo/falla deja `ActionAttempt` con estado y error cuando corresponde.
- **Datos / Contratos (si aplica):**
  - **SQL:** lectura/escritura de `ActionAttempt` y `RuleCheckpoint`.
  - **Redis:** estado runtime para auto-reset, latch y cooldown por instancia.
  - **RabbitMQ:** entrada de telemetria para evaluacion.
  - **ClickHouse:** no aplica directo en esta historia.
- **Depends on:** ACT-001
- **Referencias:** `spec.md` §4, `spec.md` §5, `spec.md` §10

#### ACT-003 - Gestion de Templates y Versiones en Acciones
- **Como** usuario de Acciones
  **Quiero** crear y versionar templates reutilizables
  **Para** mantener reglas consistentes y auditables
- **Alcance:** Incluye alta, edicion y versionado desde modal en `/actions` (tab Templates), mas detalle de template para consulta en `/actions/templates/:id`. Excluye alcance v2.
- **Rutas UI:** `/actions`, `/actions/templates/:id`
- **Entidades internas:** `RuleTemplate`, `RuleTemplateVersion`, `RuleInstance`
- **Endpoints (si aplica):**
  - Verificar existentes.
  - Si faltan: actualizar/crear incrementalmente `contexto/openapi/actions.yaml` para esta historia.
  - Implementar endpoint y pruebas minimas smoke/integration en esta historia.
- **Endpoint check gate (obligatorio si hay endpoints):**
  - Discover -> Equivalence test -> Reuse-first -> Only if missing (OpenAPI delta) -> DECISION PENDIENTE si hay dudas
- **Criterios de aceptacion (AC):**
  1) `/actions` muestra tab Templates con listado de `RuleTemplate`.
  2) Se permite crear template con DSL valido mediante modal en `/actions` (tab Templates).
  3) Editar template desde modal genera nueva `RuleTemplateVersion` sin modificar versiones previas.
  4) `/actions/templates/:id` muestra Definition, Versions, Assignments y Runs (fallos) en modo consulta (sin formulario de edicion inline).
  5) Las `RuleInstance` quedan asociadas a una version especifica del template.
  6) La UI usa etiquetas en espanol y los nombres internos en contratos/modelo permanecen en ingles.
- **Checklist QA:**
  1) Buscar endpoints equivalentes existentes y documentar evidencia de reuse-first.
  2) Crear template y validar visibilidad en listado.
  3) Editar template desde modal y validar creacion de nueva version.
  4) Confirmar que la version anterior queda inmutable.
  5) Abrir `/actions/templates/:id` y validar tabs requeridas en modo consulta (sin edicion inline).
  6) Verificar que instancias nuevas apuntan a version seleccionada.
  7) Validar actualizacion incremental de OpenAPI solo para endpoints tocados.
  8) Ejecutar pruebas smoke/integration de endpoints incorporados o modificados.
- **Datos / Contratos (si aplica):**
  - **SQL:** `RuleTemplate`, `RuleTemplateVersion`, referencia desde `RuleInstance`.
  - **Redis:** No aplica para CRUD de templates/versiones.
  - **RabbitMQ:** No aplica para CRUD de templates/versiones.
  - **ClickHouse:** No aplica para CRUD de templates/versiones.
- **Depends on:** ACT-001
- **Referencias:** `spec.md` §1, `spec.md` §2, `spec.md` §3, `spec.md` §6, `spec.md` §9

#### ACT-004 - Asignacion de templates a dispositivos y bloqueo de duplicados
- **Como** usuario de operaciones
  **Quiero** asignar templates a uno o multiples dispositivos sin duplicados
  **Para** escalar configuracion sin inconsistencias
- **Alcance:** Incluye asignacion masiva y flujo desde `Device Detail` (local o reusable). Excluye deduplicacion fuera de la regla definida.
- **Rutas UI:** `/actions/templates/:id`, `/devices/:id`, `/actions`
- **Entidades internas:** `RuleTemplateVersion`, `RuleInstance`
- **Endpoints (si aplica):**
  - Verificar existentes.
  - Si faltan: actualizar/crear incrementalmente `contexto/openapi/actions.yaml` para esta historia.
  - Implementar endpoint y pruebas minimas smoke/integration en esta historia.
- **Endpoint check gate (obligatorio si hay endpoints):**
  - Discover -> Equivalence test -> Reuse-first -> Only if missing (OpenAPI delta) -> DECISION PENDIENTE si hay dudas
- **Criterios de aceptacion (AC):**
  1) Asignar una version de template a multiples devices crea una `RuleInstance` por device.
  2) Desde `/devices/:id` se puede crear regla local o reusable.
  3) Se rechaza duplicado por `(device_id, template_version_id)`.
  4) El rechazo por duplicado no crea instancias adicionales.
  5) Las instancias quedan pegadas a su `RuleTemplateVersion`.
  6) Overrides v1 permitidos: `threshold` y `email.recipients`; cualquier otro override se rechaza.
- **Checklist QA:**
  1) Buscar endpoints equivalentes existentes y documentar evidencia de reuse-first.
  2) Asignar template a multiples devices y validar cantidad exacta de instancias creadas.
  3) Repetir asignacion al mismo device/version y validar rechazo por duplicado.
  4) Validar mensaje de error de duplicado en UI.
  5) Crear regla desde device como reusable y validar disponibilidad para reutilizacion.
  6) Crear regla desde device como local y validar que no aparece como reusable global.
  7) Aplicar override permitido y validar persistencia.
  8) Aplicar override no permitido y validar rechazo con error.
- **Datos / Contratos (si aplica):**
  - **SQL:** `RuleInstance`, unicidad `(device_id, template_version_id)`, `overrides_json` acotado a v1.
  - **Redis:** inicializacion del estado runtime para instancias creadas.
  - **RabbitMQ:** No aplica directo al flujo de asignacion.
  - **ClickHouse:** No aplica directo al flujo de asignacion.
- **Depends on:** ACT-001, ACT-003
- **Referencias:** `spec.md` §1, `spec.md` §2, `spec.md` §3, `spec.md` §7, `spec.md` §9

#### ACT-005 - Builder Scratch y validaciones del DSL v1
- **Como** usuario que diseña reglas
  **Quiero** configurar trigger, condiciones, ventanas y lifecycle
  **Para** generar definiciones validas para templates e instancias
- **Alcance:** Incluye los 5 tipos de regla, missing data policy, lifecycle y accion Email v1. Excluye cambios de semantica temporal por override.
- **Rutas UI:** `/actions/templates/:id`, `/devices/:id`
- **Entidades internas:** `RuleTemplateVersion`, `RuleInstance`
- **Endpoints (si aplica):**
  - Verificar existentes.
  - Si faltan: actualizar/crear incrementalmente `contexto/openapi/actions.yaml` para esta historia.
  - Implementar endpoint y pruebas minimas smoke/integration en esta historia.
- **Endpoint check gate (obligatorio si hay endpoints):**
  - Discover -> Equivalence test -> Reuse-first -> Only if missing (OpenAPI delta) -> DECISION PENDIENTE si hay dudas
- **Criterios de aceptacion (AC):**
  1) El builder soporta: instant threshold, continuous duration, accumulated duration in window, aggregation in window y count occurrences in window.
  2) Reglas con bloques incompletos son rechazadas antes de guardar.
  3) Si aplica ventana, el builder valida `T <= W`.
  4) El builder permite `INSUFFICIENT_DATA` y `HOLD_LAST_VALUE` con TTL explicito.
  5) El builder permite lifecycle auto-reset o latch con cooldown configurable.
  6) El builder valida accion Email con recipients no vacios.
- **Checklist QA:**
  1) Buscar endpoints equivalentes existentes y documentar evidencia de reuse-first.
  2) Guardar una regla valida por cada tipo soportado y validar persistencia.
  3) Intentar guardar con bloque faltante y validar error de validacion.
  4) Intentar `T > W` cuando aplica y validar error de coherencia temporal.
  5) Configurar `INSUFFICIENT_DATA` y validar persistencia.
  6) Configurar `HOLD_LAST_VALUE` con TTL y validar persistencia.
  7) Configurar lifecycle auto-reset con cooldown y validar persistencia.
  8) Configurar lifecycle latch y validar persistencia.
- **Datos / Contratos (si aplica):**
  - **SQL:** `RuleTemplateVersion.definition_json`, lifecycle y missing data policy.
  - **Redis:** estado runtime derivado de configuracion compilada por instancia.
  - **RabbitMQ:** No aplica directo a la edicion del DSL.
  - **ClickHouse:** soporte para evaluaciones por ventana cuando la historia de runtime lo requiera.
- **Depends on:** ACT-003
- **Referencias:** `spec.md` §1, `spec.md` §6, `spec.md` §7, `spec.md` §9

#### ACT-006 - Historial de Runs con errores de accion
- **Como** usuario de soporte
  **Quiero** consultar ejecuciones success/fail con detalle de error
  **Para** auditar y diagnosticar fallas
- **Alcance:** Incluye tab Runs en `/actions` y Runs en template detail. Excluye exponer estado interno de evaluacion.
- **Rutas UI:** `/actions`, `/actions/templates/:id`
- **Entidades internas:** `ActionAttempt`, `RuleInstance`, `RuleTemplate`
- **Endpoints (si aplica):**
  - Verificar existentes.
  - Si faltan: actualizar/crear incrementalmente `contexto/openapi/actions.yaml` para esta historia.
  - Implementar endpoint y pruebas minimas smoke/integration en esta historia.
- **Endpoint check gate (obligatorio si hay endpoints):**
  - Discover -> Equivalence test -> Reuse-first -> Only if missing (OpenAPI delta) -> DECISION PENDIENTE si hay dudas
- **Criterios de aceptacion (AC):**
  1) `/actions` muestra historial de `ActionAttempt` con estado success/fail.
  2) Cada item con `status=Fail` muestra error registrado.
  3) `/actions/templates/:id` muestra runs asociados al template seleccionado.
  4) Las consultas separan correctamente resultados por contexto (global vs template).
  5) La fuente para estado de ejecucion es `ActionAttempt`.
  6) Ninguna vista muestra estado interno de evaluacion del engine.
- **Checklist QA:**
  1) Buscar endpoints equivalentes existentes y documentar evidencia de reuse-first.
  2) Generar intento `Success` y validar aparicion en Runs.
  3) Generar intento `Fail` y validar visualizacion del error.
  4) Cambiar entre `/actions` y `/actions/templates/:id` y validar aislamiento de datos.
  5) Validar seccion Runs en detalle de template.
  6) Confirmar consistencia entre ultimo `ActionAttempt` y lectura de estado de ejecucion.
  7) Validar update incremental de OpenAPI para endpoints de runs.
  8) Ejecutar smoke/integration para endpoints de runs.
- **Datos / Contratos (si aplica):**
  - **SQL:** lectura de `ActionAttempt` y relaciones con `RuleInstance`/`RuleTemplate`.
  - **Redis:** No aplica directo a historico.
  - **RabbitMQ:** No aplica directo a render de historico.
  - **ClickHouse:** No aplica directo a `ActionAttempt` en v1.
- **Depends on:** ACT-001, ACT-002
- **Referencias:** `spec.md` §1, `spec.md` §2, `spec.md` §8, `spec.md` §9, `spec.md` §10

#### ACT-007 - Vista de Rules y badge rojo en Acciones y Device Detail
- **Como** usuario de operaciones
  **Quiero** ver y operar reglas por dispositivo con indicador de fallas
  **Para** detectar errores rapido y controlar enabled/paused
- **Alcance:** Incluye tab Rules en `/actions`, tab Rules/Acciones en `/devices/:id`, enabled/paused y badge rojo por ultimo fail. Excluye estado interno detallado.
- **Rutas UI:** `/actions`, `/devices/:id`
- **Entidades internas:** `RuleInstance`, `ActionAttempt`
- **Endpoints (si aplica):**
  - Verificar existentes.
  - Si faltan: actualizar/crear incrementalmente `contexto/openapi/actions.yaml` para esta historia.
  - Implementar endpoint y pruebas minimas smoke/integration en esta historia.
- **Endpoint check gate (obligatorio si hay endpoints):**
  - Discover -> Equivalence test -> Reuse-first -> Only if missing (OpenAPI delta) -> DECISION PENDIENTE si hay dudas
- **Criterios de aceptacion (AC):**
  1) `/actions` tab Rules lista `RuleInstance` con estado enabled/paused.
  2) `/devices/:id` tab Rules/Acciones lista reglas asociadas al device.
  3) Cambiar estado enabled/paused persiste y se refleja en ambas vistas.
  4) El badge rojo se activa cuando el ultimo `ActionAttempt` asociado es `Fail`.
  5) En vista de template, el badge rojo se calcula con intentos de sus instancias asociadas.
  6) No se expone estado interno de evaluacion en la UI.
- **Checklist QA:**
  1) Buscar endpoints equivalentes existentes y documentar evidencia de reuse-first.
  2) Validar listado de Rules en `/actions`.
  3) Validar listado de Rules/Acciones en `/devices/:id`.
  4) Pausar regla y validar impacto en estado persistido.
  5) Rehabilitar regla y validar retorno de estado.
  6) Forzar ultimo intento `Fail` y validar badge rojo activo.
  7) Forzar intento exitoso posterior y validar actualizacion del badge.
  8) Ejecutar smoke/integration para endpoints de rules.
- **Datos / Contratos (si aplica):**
  - **SQL:** lectura/escritura de `RuleInstance` y consulta del ultimo `ActionAttempt` por instancia.
  - **Redis:** sincronizacion del estado runtime con enabled/paused.
  - **RabbitMQ:** No aplica directo al render de vistas.
  - **ClickHouse:** No aplica directo a vistas de Rules en v1.
- **Depends on:** ACT-001, ACT-002, ACT-004
- **Referencias:** `spec.md` §1, `spec.md` §2, `spec.md` §5, `spec.md` §8, `spec.md` §9, `spec.md` §10

## C) GUARDRAILS (DO NOT DO)
- No crear endpoints, rutas, colas, tablas o semanticas no explicitadas en `contexto/work/features/acciones_modulo/spec.md`.
- No agregar una historia gate dedicada para OpenAPI/endpoints.
- No crear endpoint nuevo sin verificar equivalencia y aplicar reuse-first.
- No actualizar OpenAPI fuera de historias que realmente agregan/modifican endpoints.
- No usar function-per-rule deployment.
- No exponer estado interno de evaluacion en UI.
- No permitir overrides v1 fuera de `threshold` y `email.recipients`.
- No activar acciones operativas distintas de Email en v1.

## D) DOC DELIVERABLES (do not write them)
- **ADR requerido:** Runtime state en Redis + SQL checkpoint para rehidratacion (base: `spec.md` §4).
- **ADR requerido:** Lifecycle auto-reset vs latch + cooldown (base: `spec.md` §5).
- **OpenAPI delta requerido:** `contexto/openapi/actions.yaml` incremental por historia con endpoints (base: `spec.md` §9).
- **DB migration checklist requerido:** tablas, indices y constraints del modelo v1 (base: `spec.md` §3 y §4).
- **QA matrix/runbook requerido:** anti-spam, cooldown, latch, duplicados, runs, badge rojo y rehidratacion (base: `spec.md` §10).
