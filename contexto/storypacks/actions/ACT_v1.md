# STORY PACK v1 - Modulo Acciones

## A) STORY INDEX
- **ID:** ACT-001
- **Titulo:** Modelo base de dominio y persistencia de Acciones
- **Tipo:** BE / DB
- **Depends on:** `contexto/specs/actions/spec.md`
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
- **Alcance:** incluye entidades y reglas base de dominio (`RuleTemplate`, `RuleTemplateVersion`, `RuleInstance`, `ActionAttempt`, `AlertFired`, `RuleCheckpoint`) y la separacion SQL/Redis/RabbitMQ/ClickHouse; excluye capacidades fuera de v1.
- **Rutas UI:** `/actions`, `/actions/templates/:id`, `/devices/:id`
- **Entidades internas:** `RuleTemplate`, `RuleTemplateVersion`, `RuleInstance`, `ActionAttempt`, `AlertFired`, `RuleCheckpoint`
- **Criterios de aceptacion (AC):**
  1) Se define persistencia para `RuleTemplate` y `RuleTemplateVersion` con version inmutable.
  2) Se define persistencia para `RuleInstance` por dispositivo con referencia a `RuleTemplateVersion`.
  3) Se define persistencia para `ActionAttempt` con `status` success/fail y error cuando corresponda.
  4) Se bloquea duplicado por `(device_id, template_version_id)` en `RuleInstance`.
  5) Se define `RuleCheckpoint` para rehidratacion tras caida de Redis/engine.
  6) Se mantiene la separacion SQL Server (control-plane), Redis (runtime), RabbitMQ (transporte), ClickHouse (historico).
- **Checklist QA:**
  1) Crear template y version y verificar que la version no cambia al editar de nuevo.
  2) Crear instancia para un device y verificar referencia a version especifica.
  3) Intentar duplicar `(device_id, template_version_id)` y verificar bloqueo.
  4) Registrar intento success y verificar persistencia en `ActionAttempt`.
  5) Registrar intento fail y verificar persistencia de error en `ActionAttempt`.
  6) Simular perdida de runtime state y verificar rehidratacion desde `RuleCheckpoint`.
  7) Verificar que el runtime state no queda solo en memoria volatile.
  8) Verificar que no se introducen entidades fuera de v1.
- **Datos / Contratos (si aplica):**
  - **SQL:** `RuleTemplate`, `RuleTemplateVersion`, `RuleInstance`, `ActionAttempt`, `RuleCheckpoint`; constraint de unicidad `(device_id, template_version_id)`.
  - **Redis:** estado vivo por `(deviceId, ruleInstanceId)` con contadores, timers, `cooldownUntil`, `latchActive`.
  - **RabbitMQ:** consumo de telemetria para evaluacion event-driven.
  - **ClickHouse:** telemetria historica para reglas con ventana cuando aplique.
- **Depends on:** `contexto/specs/actions/spec.md`
- **Referencias:** Spec §0 Objetivo, §1 Alcance, §3 Conceptos y modelo minimo, §4 Storage y ejecucion

#### ACT-002 - Evaluacion runtime con anti-spam y rehidratacion
- **Como** operador de Acciones  
  **Quiero** que la evaluacion runtime reduzca spam y sea recuperable  
  **Para** mantener comportamiento estable ante flapping y fallas
- **Alcance:** incluye auto-reset, latch opcional, cooldown y rehidratacion; excluye semanticas no definidas en el spec.
- **Rutas UI:** `/actions`, `/devices/:id`
- **Entidades internas:** `RuleInstance`, `ActionAttempt`, `AlertFired`, `RuleCheckpoint`
- **Criterios de aceptacion (AC):**
  1) La evaluacion se ejecuta por cada evento consumido desde RabbitMQ.
  2) En auto-reset solo dispara en transicion `OK -> VIOLATION`.
  3) En auto-reset rearma cuando vuelve a `OK`.
  4) El cooldown suprime nuevos disparos durante N segundos configurados.
  5) En latch mode dispara una vez y queda `ACTIVE`.
  6) El rearme en latch exige `Resolve manual` y condicion `OK`.
- **Checklist QA:**
  1) Probar flapping y verificar que no hay spam de disparos.
  2) Probar cooldown y verificar supresion dentro de ventana.
  3) Probar fin de cooldown y verificar nuevo disparo permitido.
  4) Probar latch y verificar que no redispara sin rearme.
  5) Probar resolve manual sin `OK` y verificar que no rearma.
  6) Probar resolve manual con `OK` y verificar rearme.
  7) Simular caida de Redis y verificar rehidratacion desde SQL checkpoint.
  8) Verificar registro de `ActionAttempt` con resultado y error cuando aplique.
- **Datos / Contratos (si aplica):**
  - **SQL:** lectura/escritura de `ActionAttempt` y `RuleCheckpoint`.
  - **Redis:** transiciones, cooldown y latch por instancia.
  - **RabbitMQ:** entrada de telemetria para evaluacion event-driven.
  - **ClickHouse:** apoyo a reglas historicas en fases que lo requieran.
- **Depends on:** ACT-001
- **Referencias:** Spec §4 Storage y ejecucion, §5 Lifecycle y anti-spam, §10 QA minimo

#### ACT-003 - Gestion de Templates y Versiones en Acciones
- **Como** usuario de Acciones  
  **Quiero** crear y versionar templates reutilizables  
  **Para** mantener reglas consistentes y auditables
- **Alcance:** incluye alta/edicion/versionado y detalle de template; excluye extras v2.
- **Rutas UI:** `/actions`, `/actions/templates/:id`
- **Entidades internas:** `RuleTemplate`, `RuleTemplateVersion`, `RuleInstance`
- **Endpoints (si aplica):**
  - Verificar endpoints existentes para gestion y lectura de templates/versiones.
  - Si faltan equivalentes: actualizar `contexto/openapi/actions.yaml` incrementalmente para esta historia.
  - Implementar endpoints faltantes con pruebas minimas smoke/integration.
- **Endpoint check gate (obligatorio si hay endpoints):**
  - Discover -> Equivalence test -> Reuse-first -> Only if missing (OpenAPI delta) -> DECISION PENDIENTE si hay dudas.
- **Criterios de aceptacion (AC):**
  1) `/actions` muestra tab Templates con listado de `RuleTemplate`.
  2) Se permite crear template con definicion DSL valida.
  3) Editar template genera nueva `RuleTemplateVersion` inmutable.
  4) `/actions/templates/:id` expone Definition, Versions, Assignments y Runs (fallos).
  5) Las instancias quedan asociadas a una version especifica.
  6) UI en espanol y entidades internas en ingles en contratos y modelo.
- **Checklist QA:**
  1) Crear template y verificar aparicion en listado.
  2) Editar template y verificar nueva version.
  3) Verificar que version anterior no se modifica.
  4) Verificar tabs de detalle esperadas.
  5) Verificar consumo por version especifica.
  6) Verificar que no se activa libreria de acciones fuera de Email en v1.
  7) Verificar OpenAPI incremental solo para esta historia.
  8) Verificar pruebas smoke/integration de endpoints afectados.
- **Datos / Contratos (si aplica):**
  - **SQL:** `RuleTemplate`, `RuleTemplateVersion`, referencia desde `RuleInstance`.
  - **Redis:** no aplica directo para CRUD de templates/versiones.
  - **RabbitMQ:** no aplica directo para CRUD de templates/versiones.
  - **ClickHouse:** no aplica directo para CRUD de templates/versiones.
- **Depends on:** ACT-001, `contexto/openapi/actions.yaml`
- **Referencias:** Spec §1 Alcance, §2 UX / Navegacion, §3 Conceptos y modelo minimo, §6 Contrato del builder, §9 Regla de endpoints

#### ACT-004 - Asignacion de templates a dispositivos y bloqueo de duplicados
- **Como** usuario de operaciones  
  **Quiero** asignar templates a uno o multiples dispositivos sin duplicados  
  **Para** escalar configuracion sin inconsistencias
- **Alcance:** incluye asignacion masiva y flujo desde Device Detail (reusable/local); excluye deduplicacion fuera de la regla definida.
- **Rutas UI:** `/actions/templates/:id`, `/devices/:id`, `/actions`
- **Entidades internas:** `RuleTemplateVersion`, `RuleInstance`
- **Endpoints (si aplica):**
  - Verificar endpoints existentes para asignacion y validacion de duplicados.
  - Si faltan equivalentes: actualizar `contexto/openapi/actions.yaml` incrementalmente para esta historia.
  - Implementar endpoints faltantes con pruebas minimas smoke/integration.
- **Endpoint check gate (obligatorio si hay endpoints):**
  - Discover -> Equivalence test -> Reuse-first -> Only if missing (OpenAPI delta) -> DECISION PENDIENTE si hay dudas.
- **Criterios de aceptacion (AC):**
  1) Asignar version de template a multiples devices crea una `RuleInstance` por device.
  2) Desde `/devices/:id` se permite crear regla local o reusable.
  3) Se bloquea duplicado por `(device_id, template_version_id)`.
  4) El bloqueo informa error sin crear instancias extra.
  5) Las instancias quedan pegadas a su `RuleTemplateVersion`.
  6) Overrides v1 permitidos: `threshold`, `email.recipients`; se rechazan otros.
- **Checklist QA:**
  1) Asignar template a multiples devices y validar cantidad de instancias.
  2) Repetir misma asignacion al mismo device y validar bloqueo.
  3) Validar feedback de duplicado en UI.
  4) Crear desde device como reusable y validar reutilizacion.
  5) Crear desde device como local y validar que no se publica como reusable.
  6) Aplicar override permitido y validar persistencia.
  7) Intentar override no permitido y validar rechazo.
  8) Verificar pruebas smoke/integration de endpoints de asignacion.
- **Datos / Contratos (si aplica):**
  - **SQL:** `RuleInstance` con unicidad `(device_id, template_version_id)` y `overrides_json` v1.
  - **Redis:** inicializacion/actualizacion de estado runtime por nuevas instancias.
  - **RabbitMQ:** no aplica directo al flujo de asignacion.
  - **ClickHouse:** no aplica directo al flujo de asignacion.
- **Depends on:** ACT-001, ACT-003, `contexto/openapi/actions.yaml`
- **Referencias:** Spec §1 Alcance, §2 UX / Navegacion, §3 Conceptos y modelo minimo, §7 Overrides v1, §9 Regla de endpoints

#### ACT-005 - Builder Scratch y validaciones del DSL v1
- **Como** usuario que disena reglas  
  **Quiero** configurar trigger, condiciones, ventanas y lifecycle  
  **Para** generar definiciones validas para templates e instancias
- **Alcance:** incluye 5 tipos de regla, missing data policy, lifecycle y accion Email v1; excluye cambios de semantica temporal por overrides.
- **Rutas UI:** `/actions/templates/:id`, `/devices/:id`
- **Entidades internas:** `RuleTemplateVersion`, `RuleInstance`
- **Endpoints (si aplica):**
  - Verificar endpoints existentes para validar/persistir definicion DSL.
  - Si faltan equivalentes: actualizar `contexto/openapi/actions.yaml` incrementalmente para esta historia.
  - Implementar endpoints faltantes con pruebas minimas smoke/integration.
- **Endpoint check gate (obligatorio si hay endpoints):**
  - Discover -> Equivalence test -> Reuse-first -> Only if missing (OpenAPI delta) -> DECISION PENDIENTE si hay dudas.
- **Criterios de aceptacion (AC):**
  1) El builder soporta los 5 tipos de regla definidos en v1.
  2) El builder rechaza bloques incompletos.
  3) El builder valida coherencia temporal (`T <= W`) cuando aplica.
  4) El builder soporta `INSUFFICIENT_DATA` y `HOLD_LAST_VALUE` con TTL.
  5) El builder soporta lifecycle auto/latch con cooldown.
  6) El builder valida accion Email con recipients.
- **Checklist QA:**
  1) Guardar regla valida para cada tipo de regla y validar persistencia.
  2) Intentar guardar con bloque incompleto y validar error.
  3) Intentar configuracion temporal invalida y validar error.
  4) Configurar `INSUFFICIENT_DATA` y validar persistencia.
  5) Configurar `HOLD_LAST_VALUE` con TTL y validar persistencia.
  6) Configurar lifecycle auto con cooldown y validar persistencia.
  7) Configurar lifecycle latch y validar persistencia.
  8) Verificar pruebas smoke/integration de endpoints afectados.
- **Datos / Contratos (si aplica):**
  - **SQL:** `RuleTemplateVersion.definition_json`, lifecycle y missing data policy.
  - **Redis:** uso runtime de configuracion compilada para evaluacion.
  - **RabbitMQ:** no aplica directo a la edicion del DSL.
  - **ClickHouse:** soporte para evaluaciones historicas de ventana cuando aplique.
- **Depends on:** ACT-003, `contexto/openapi/actions.yaml`
- **Referencias:** Spec §1 Alcance, §6 Contrato del builder, §7 Overrides v1, §9 Regla de endpoints

#### ACT-006 - Historial de Runs con errores de accion
- **Como** usuario de soporte  
  **Quiero** consultar ejecuciones success/fail con detalle de error  
  **Para** auditar y diagnosticar fallas
- **Alcance:** incluye tab Runs en `/actions` y Runs en template detail; excluye mostrar estado interno de evaluacion.
- **Rutas UI:** `/actions`, `/actions/templates/:id`
- **Entidades internas:** `ActionAttempt`, `RuleInstance`, `RuleTemplate`
- **Endpoints (si aplica):**
  - Verificar endpoints existentes para consulta de runs y error asociado.
  - Si faltan equivalentes: actualizar `contexto/openapi/actions.yaml` incrementalmente para esta historia.
  - Implementar endpoints faltantes con pruebas minimas smoke/integration.
- **Endpoint check gate (obligatorio si hay endpoints):**
  - Discover -> Equivalence test -> Reuse-first -> Only if missing (OpenAPI delta) -> DECISION PENDIENTE si hay dudas.
- **Criterios de aceptacion (AC):**
  1) `/actions` muestra historial de `ActionAttempt` con estado success/fail.
  2) Cada fail muestra el error registrado.
  3) El detalle de template muestra runs fallidos asociados.
  4) Las consultas de runs soportan filtros alineados a la navegacion.
  5) La vista usa `ActionAttempt` como fuente para estados de ejecucion.
  6) La UI no expone estado interno (por ejemplo progreso temporal interno).
- **Checklist QA:**
  1) Generar intento success y validar visualizacion.
  2) Generar intento fail y validar visualizacion de error.
  3) Probar filtros y validar consistencia.
  4) Abrir template detail y validar seccion Runs.
  5) Validar consistencia entre Rules y Runs para una misma instancia.
  6) Validar que no se expone estado interno no permitido.
  7) Verificar OpenAPI incremental para endpoints de runs.
  8) Verificar pruebas smoke/integration de endpoints de runs.
- **Datos / Contratos (si aplica):**
  - **SQL:** lectura de `ActionAttempt` y relaciones con instancia/template.
  - **Redis:** no aplica directo al historico mostrado.
  - **RabbitMQ:** no aplica directo al render del historico.
  - **ClickHouse:** no aplica directo a `ActionAttempt` en v1.
- **Depends on:** ACT-001, ACT-002, `contexto/openapi/actions.yaml`
- **Referencias:** Spec §0 Objetivo, §1 Alcance, §2 UX / Navegacion, §8 Regla de indicador rojo, §9 Regla de endpoints, §10 QA minimo

#### ACT-007 - Vista de Rules y badge rojo en Acciones y Device Detail
- **Como** usuario de operaciones  
  **Quiero** ver y operar reglas por dispositivo con indicador de fallas  
  **Para** detectar errores rapido y controlar enabled/paused
- **Alcance:** incluye tab Rules en `/actions`, tab Rules/Acciones en `/devices/:id`, enabled/paused y badge rojo por ultimo fail; excluye estado interno detallado.
- **Rutas UI:** `/actions`, `/devices/:id`
- **Entidades internas:** `RuleInstance`, `ActionAttempt`
- **Endpoints (si aplica):**
  - Verificar endpoints existentes para listar rules, cambiar enabled/paused y obtener estado de badge por ultimo intento.
  - Si faltan equivalentes: actualizar `contexto/openapi/actions.yaml` incrementalmente para esta historia.
  - Implementar endpoints faltantes con pruebas minimas smoke/integration.
- **Endpoint check gate (obligatorio si hay endpoints):**
  - Discover -> Equivalence test -> Reuse-first -> Only if missing (OpenAPI delta) -> DECISION PENDIENTE si hay dudas.
- **Criterios de aceptacion (AC):**
  1) `/actions` tab Rules lista `RuleInstance` con estado enabled/paused.
  2) `/devices/:id` tab Rules/Acciones muestra reglas adjuntas al device.
  3) Se puede cambiar estado enabled/paused desde vistas de Rules.
  4) El badge rojo se activa cuando el ultimo `ActionAttempt` asociado es `Fail`.
  5) En contexto de template, el badge rojo se deriva de intentos de sus instancias asociadas.
  6) La UI no expone estado interno de evaluacion.
- **Checklist QA:**
  1) Validar listado de Rules en `/actions`.
  2) Validar listado de Rules/Acciones en `/devices/:id`.
  3) Pausar regla y validar impacto operativo.
  4) Rehabilitar regla y validar retorno operativo.
  5) Forzar ultimo intento fail y validar badge rojo activo.
  6) Generar intento success posterior y validar actualizacion del badge.
  7) Verificar OpenAPI incremental para endpoints de rules.
  8) Verificar pruebas smoke/integration de endpoints de rules.
- **Datos / Contratos (si aplica):**
  - **SQL:** lectura/escritura de `RuleInstance` y lectura del ultimo `ActionAttempt` por instancia.
  - **Redis:** sincronizacion de estado runtime con enabled/paused.
  - **RabbitMQ:** no aplica directo a render de vistas de Rules.
  - **ClickHouse:** no aplica directo a vistas de Rules en v1.
- **Depends on:** ACT-001, ACT-002, ACT-004, `contexto/openapi/actions.yaml`
- **Referencias:** Spec §1 Alcance, §2 UX / Navegacion, §5 Lifecycle y anti-spam, §8 Regla de indicador rojo, §9 Regla de endpoints, §10 QA minimo

## C) GUARDRAILS (DO NOT DO)
- No crear endpoints/rutas/colas/tecnologias que no esten explicitamente en `contexto/specs/actions/spec.md`.
- No introducir historia gate separada para endpoints/OpenAPI (no ACT-000).
- No agregar endpoint nuevo sin revisar equivalencia y sin OpenAPI delta incremental cuando falte.
- No usar function-per-rule deployment.
- No inventar semanticas temporales fuera de instant/duration/window/cooldown/latch definidas en v1.
- No exponer estado interno de evaluacion en UI.
- No permitir overrides v1 fuera de `threshold` y `email.recipients`.
- No activar acciones operativas distintas de Email en v1.

## D) DOC DELIVERABLES (do not write them)
- **ADR requerido:** `ADR-acciones-runtime-state-redis-sql-checkpoint.md` - formalizar runtime state en Redis con checkpoint SQL para rehidratacion.
- **ADR requerido:** `ADR-acciones-lifecycle-auto-latch-cooldown.md` - formalizar reglas de lifecycle, anti-spam y rearme en v1.
- **OpenAPI delta requerido:** `contexto/openapi/actions.yaml` - contratos incrementales por historia que requiera endpoints.
- **DB migration checklist requerido:** `contexto/migrations/actions_v1_checklist.md` - tablas, indices y constraints del modelo v1.
- **QA matrix/runbook requerido:** `contexto/qa/actions_v1_test_matrix.md` - pruebas minimas de anti-spam, cooldown, latch, duplicados, runs, badge rojo y rehidratacion.
