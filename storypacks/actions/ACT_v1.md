# STORY PACK v1 - Módulo "Acciones"

## A) STORY INDEX
- **ID:** ACT-001
- **Título:** Base de dominio y persistencia transaccional
- **Tipo:** BE / DB
- **Depends on:** `contexto/specs/actions/spec.md`
- **Blocks:** ACT-002, ACT-003, ACT-004, ACT-006, ACT-007

- **ID:** ACT-002
- **Título:** Engine runtime con anti-spam y rehidratación
- **Tipo:** BE
- **Depends on:** ACT-001
- **Blocks:** ACT-006, ACT-007

- **ID:** ACT-003
- **Título:** Gestión de templates y versionado inmutable
- **Tipo:** FE / BE
- **Depends on:** ACT-001
- **Blocks:** ACT-004, ACT-005

- **ID:** ACT-004
- **Título:** Asignación masiva a dispositivos y bloqueo de duplicados
- **Tipo:** FE / BE
- **Depends on:** ACT-001, ACT-003
- **Blocks:** ACT-007

- **ID:** ACT-005
- **Título:** Builder Scratch v1 y validaciones del DSL
- **Tipo:** FE / BE
- **Depends on:** ACT-003
- **Blocks:** ACT-004

- **ID:** ACT-006
- **Título:** Historial de Runs con errores de acción
- **Tipo:** FE / BE
- **Depends on:** ACT-001, ACT-002
- **Blocks:** ACT-007

- **ID:** ACT-007
- **Título:** Vistas Rules en Acciones y Device Detail con badge rojo
- **Tipo:** FE / BE
- **Depends on:** ACT-001, ACT-002, ACT-004, ACT-006
- **Blocks:** Ninguna

## B) STORIES

### ACT-001 — Base de dominio y persistencia transaccional
- **Como** equipo backend  
  **Quiero** definir el modelo base de `RuleTemplate`, `RuleTemplateVersion`, `RuleInstance`, `ActionAttempt`, `AlertFired`, `RuleCheckpoint`  
  **Para** habilitar ejecución, trazabilidad y recuperación en v1.
- **Alcance:** incluye SQL Server como control-plane y restricciones de integridad; excluye librería activa de acciones distinta de Email.
- **Rutas UI:** `/actions`, `/actions/templates/:id`, `/devices/:id`
- **Entidades internas:** `RuleTemplate`, `RuleTemplateVersion`, `RuleInstance`, `ActionAttempt`, `AlertFired`, `RuleCheckpoint`
- **Endpoints (si aplica):**
  - No aplica en esta historia como contrato funcional de UI; se habilita base de datos y dominio para historias API posteriores.
- **Criterios de aceptación (AC):**
  1) Existe persistencia de `RuleTemplate` y `RuleTemplateVersion` con relación explícita y versión inmutable.
  2) `RuleInstance` referencia una `RuleTemplateVersion` específica.
  3) Se registra `ActionAttempt` con `status` success/fail y error cuando corresponda.
  4) Se establece soporte de `RuleCheckpoint` para rehidratación posterior.
  5) Se define restricción de duplicado para `(device_id, template_version_id)` en `RuleInstance`.
  6) El diseño mantiene separación SQL/Redis/RabbitMQ/ClickHouse según el spec.
- **Checklist QA:**
  1) Crear template + versión y validar inmutabilidad de la versión creada.
  2) Crear instancia por dispositivo y validar referencia a `template_version_id`.
  3) Intentar insertar duplicado `(device_id, template_version_id)` y validar bloqueo.
  4) Registrar run exitoso y validar persistencia.
  5) Registrar run fallido y validar persistencia del error.
  6) Confirmar almacenamiento de checkpoint para rehidratación.
  7) Verificar que no se agregan entidades fuera del alcance v1.
  8) Verificar que la nomenclatura interna permanece en inglés.
- **Datos / Contratos (si aplica):**
  - **SQL:** `RuleTemplate`, `RuleTemplateVersion`, `RuleInstance`, `ActionAttempt`, `RuleCheckpoint`.
  - **Redis:** no aplica directo en esta historia.
  - **RabbitMQ:** no aplica directo en esta historia.
  - **ClickHouse:** no aplica directo en esta historia.
- **Depends on:** `contexto/specs/actions/spec.md`
- **Referencias:** Spec §0 Objetivo, §1 Alcance, §3 Conceptos y modelo mínimo, §4 Storage y ejecución

### ACT-002 — Engine runtime con anti-spam y rehidratación
- **Como** operador de reglas  
  **Quiero** evaluar reglas en tiempo real con auto-reset, latch y cooldown  
  **Para** evitar spam y mantener continuidad operativa tras fallos.
- **Alcance:** incluye evaluación event-driven, lifecycle y checkpoint/rehidratación; excluye semánticas temporales no definidas en el spec.
- **Rutas UI:** `/actions`, `/devices/:id`
- **Entidades internas:** `RuleInstance`, `RuleCheckpoint`, `ActionAttempt`, `AlertFired`
- **Endpoints (si aplica):**
  - No aplica: esta historia cubre engine runtime (consumo RabbitMQ, evaluación, persistencia).
  - Los endpoints de gestión (enabled/paused, resolve manual y consultas de UI) se cubren en ACT-007/ACT-006/ACT-003/ACT-004 según corresponda.

- **Criterios de aceptación (AC):**
  1) La evaluación ocurre por evento consumido desde RabbitMQ (event-driven).
  2) En auto-reset, solo hay disparo en transición `OK -> VIOLATION`.
  3) El rearme en auto-reset solo ocurre cuando condición vuelve a `OK`.
  4) Cooldown bloquea nuevos disparos por N segundos desde el último disparo.
  5) En latch mode se dispara una vez y permanece `ACTIVE`.
  6) En latch mode no re-dispara sin `Resolve manual` y condición `OK`.
- **Checklist QA:**
  1) Caso flapping: validar ausencia de spam de acciones.
  2) Caso cooldown: validar supresión dentro de ventana y nuevo disparo al expirar.
  3) Caso latch: validar no redisparo sin resolve.
  4) Caso latch con resolve sin `OK`: validar que no rearma.
  5) Caso latch con resolve y `OK`: validar rearme correcto.
  6) Simular caída de Redis y validar rehidratación desde `RuleCheckpoint` en SQL.
  7) Validar registro de `ActionAttempt` por cada intento de acción.
  8) Verificar que UI no expone estado interno detallado de evaluación.
- **Datos / Contratos (si aplica):**
  - **SQL:** `ActionAttempt`, `RuleCheckpoint`.
  - **Redis:** estado runtime por `(deviceId, ruleInstanceId)` (`cooldownUntil`, `latchActive`, contadores/timers).
  - **RabbitMQ:** consumo de telemetría.
  - **ClickHouse:** soporte a reglas históricas según fase.
- **Depends on:** ACT-001
- **Referencias:** Spec §4 Storage y ejecución, §5 Lifecycle y anti-spam, §9 Regla de endpoints (por historia, sin gate), §10 QA mínimo

### ACT-003 — Gestión de templates y versionado inmutable
- **Como** usuario de Acciones  
  **Quiero** crear, editar y versionar templates  
  **Para** reutilizar reglas sin romper instancias existentes.
- **Alcance:** incluye listado y detalle en `/actions/templates/:id` con Definition/Versions/Assignments/Runs; excluye auto-update de instancias.
- **Rutas UI:** `/actions`, `/actions/templates/:id`
- **Entidades internas:** `RuleTemplate`, `RuleTemplateVersion`, `RuleInstance`
- **Endpoints (si aplica):**
  - Verificar existentes para CRUD de templates, creación de versión y consulta de detalle/versiones/asignaciones/runs.
  - Si faltan: actualizar `contexto/openapi/actions.yaml` de forma incremental en esta historia.
  - Implementar + pruebas mínimas smoke/integration en la misma historia.
- **Criterios de aceptación (AC):**
  1) `/actions` tab Templates lista templates con información básica operativa.
  2) Crear template genera `RuleTemplate` válido.
  3) Editar template genera nueva `RuleTemplateVersion` inmutable.
  4) El detalle `/actions/templates/:id` muestra tabs Definition, Versions, Assignments, Runs.
  5) Las instancias quedan pegadas a la versión asignada.
  6) No se incorporan acciones activas fuera de Email en v1.
- **Checklist QA:**
  1) Crear template desde UI y validar persistencia.
  2) Editar template y validar incremento de versión.
  3) Confirmar que versiones históricas no mutan.
  4) Navegar a `/actions/templates/:id` y validar tabs requeridos.
  5) Validar que Assignments refleja instancias reales.
  6) Validar que Runs muestra fallos asociados al template.
  7) Validar comportamiento de versión fijada en instancias existentes.
  8) Validar que no aparecen acciones v2 activas (webhook/SMS).
- **Datos / Contratos (si aplica):**
  - **SQL:** `RuleTemplate`, `RuleTemplateVersion`, relación con `RuleInstance`.
  - **Redis:** no aplica directo.
  - **RabbitMQ:** no aplica directo.
  - **ClickHouse:** no aplica directo.
- **Depends on:** ACT-001
- **Referencias:** Spec §1 Alcance, §2 UX / Navegación, §3 Conceptos y modelo mínimo, §6 Contrato del builder, §9 Regla de endpoints (por historia, sin gate)

### ACT-004 — Asignación masiva a dispositivos y bloqueo de duplicados
- **Como** usuario operativo  
  **Quiero** asignar templates a múltiples dispositivos y crear reglas desde device detail  
  **Para** escalar despliegue sin inconsistencias.
- **Alcance:** incluye asignación masiva y creación desde `/devices/:id` (reutilizable o local); excluye estrategias de deduplicación fuera de la clave definida.
- **Rutas UI:** `/actions/templates/:id`, `/devices/:id`
- **Entidades internas:** `RuleTemplateVersion`, `RuleInstance`
- **Endpoints (si aplica):**
  - Verificar existentes para asignación masiva, creación de instancia desde device y bloqueo de duplicados.
  - Si faltan: actualizar `contexto/openapi/actions.yaml` de forma incremental en esta historia.
  - Implementar + pruebas mínimas smoke/integration en la misma historia.
- **Criterios de aceptación (AC):**
  1) Asignar una versión a N dispositivos crea N `RuleInstance`.
  2) Desde `/devices/:id` se puede crear regla como reusable template o local instance.
  3) Se bloquea duplicado por `(device_id, template_version_id)`.
  4) El bloqueo de duplicado informa error operativo al usuario.
  5) La instancia mantiene referencia fija a `RuleTemplateVersion`.
  6) El flujo respeta límites de overrides v1 definidos en el spec.
- **Checklist QA:**
  1) Asignación masiva a varios devices crea instancias esperadas.
  2) Repetir asignación idéntica en mismo device falla por duplicado.
  3) Validar mensaje de duplicado en UI.
  4) Crear desde device como reusable template y validar reutilización.
  5) Crear desde device como local instance y validar alcance local.
  6) Confirmar referencia correcta a versión en cada instancia.
  7) Validar que overrides permitidos sí aplican.
  8) Validar que overrides no permitidos son rechazados.
- **Datos / Contratos (si aplica):**
  - **SQL:** `RuleInstance` con constraint de unicidad `(device_id, template_version_id)`.
  - **Redis:** alta/baja de estado runtime por instancia activa.
  - **RabbitMQ:** no aplica directo.
  - **ClickHouse:** no aplica directo.
- **Depends on:** ACT-001, ACT-003
- **Referencias:** Spec §1 Alcance, §2 UX / Navegación, §3 Conceptos y modelo mínimo, §7 Overrides v1, §9 Regla de endpoints (por historia, sin gate)

### ACT-005 — Builder Scratch v1 y validaciones del DSL
- **Como** usuario creador de reglas  
  **Quiero** construir reglas válidas en Scratch  
  **Para** asegurar ejecución consistente de acciones Email en v1.
- **Alcance:** incluye 5 tipos de regla, políticas de missing data y lifecycle config; excluye cambios de semántica temporal vía overrides.
- **Rutas UI:** `/actions/templates/:id`, `/devices/:id`
- **Entidades internas:** `RuleTemplateVersion`, `RuleInstance`
- **Endpoints (si aplica):**
  - Verificar existentes para guardar/validar definición DSL de templates y reglas locales.
  - Si faltan: actualizar `contexto/openapi/actions.yaml` de forma incremental en esta historia.
  - Implementar + pruebas mínimas smoke/integration en la misma historia.
- **Criterios de aceptación (AC):**
  1) El builder soporta `instant threshold`.
  2) El builder soporta `continuous duration`.
  3) El builder soporta `accumulated duration within window`, `aggregation within window`, `count occurrences within window`.
  4) Se rechazan bloques incompletos.
  5) Se valida coherencia temporal `T <= W` cuando aplica.
  6) Email exige recipients válidos.
  7) Se configura `INSUFFICIENT_DATA` o `HOLD_LAST_VALUE` con TTL.
  8) Se configura lifecycle auto/latch con cooldown.
- **Checklist QA:**
  1) Guardar regla válida de tipo instant.
  2) Guardar regla válida de tipo continuous duration.
  3) Guardar regla válida de cada variante con ventana.
  4) Intentar guardar bloque incompleto y validar rechazo.
  5) Intentar guardar `T > W` y validar rechazo.
  6) Intentar Email sin recipients y validar rechazo.
  7) Guardar con `INSUFFICIENT_DATA` y validar persistencia.
  8) Guardar con `HOLD_LAST_VALUE` + TTL y validar persistencia.
- **Datos / Contratos (si aplica):**
  - **SQL:** `RuleTemplateVersion.definition_json`, configuración lifecycle y missing data.
  - **Redis:** cache/estado compilado para evaluación runtime.
  - **RabbitMQ:** no aplica directo.
  - **ClickHouse:** soporte para reglas con ventana histórica según fase.
- **Depends on:** ACT-003
- **Referencias:** Spec §1 Alcance, §6 Contrato del builder, §7 Overrides v1, §9 Regla de endpoints (por historia, sin gate)

### ACT-006 — Historial de Runs con errores de acción
- **Como** usuario de soporte  
  **Quiero** consultar intentos de acción exitosos/fallidos con error  
  **Para** auditar y diagnosticar comportamiento operativo.
- **Alcance:** incluye tab Runs en `/actions` y Runs en detalle de template; excluye visualización de estado interno de evaluación.
- **Rutas UI:** `/actions`, `/actions/templates/:id`
- **Entidades internas:** `ActionAttempt`, `RuleTemplate`, `RuleInstance`
- **Endpoints (si aplica):**
  - Verificar existentes para listado de runs, filtros y consulta de fallos por template/instancia.
  - Si faltan: actualizar `contexto/openapi/actions.yaml` de forma incremental en esta historia.
  - Implementar + pruebas mínimas smoke/integration en la misma historia.
- **Criterios de aceptación (AC):**
  1) Runs lista `ActionAttempt` con success/fail.
  2) Runs muestra error cuando `status=Fail`.
  3) Runs permite filtros operativos mínimos (device/template/status/rango de fechas).
  4) El detalle de template muestra runs asociados.
  5) Datos de runs provienen del registro real de ejecución.
  6) La UI no expone estado interno de evaluación.
- **Checklist QA:**
  1) Generar run exitoso y validar visibilidad.
  2) Generar run fallido y validar error mostrado.
  3) Probar filtro por device.
  4) Probar filtro por template.
  5) Probar filtro por status.
  6) Probar filtro por rango de fechas.
  7) Validar runs en `/actions/templates/:id`.
  8) Confirmar ausencia de métricas internas de evaluación en UI.
- **Datos / Contratos (si aplica):**
  - **SQL:** lectura de `ActionAttempt`.
  - **Redis:** no aplica directo.
  - **RabbitMQ:** no aplica directo.
  - **ClickHouse:** no aplica directo.
- **Depends on:** ACT-001, ACT-002
- **Referencias:** Spec §0 Objetivo, §1 Alcance, §2 UX / Navegación, §8 Regla de indicador rojo, §9 Regla de endpoints (por historia, sin gate), §10 QA mínimo

### ACT-007 — Vistas Rules en Acciones y Device Detail con badge rojo
- **Como** operador de dispositivos  
  **Quiero** gestionar reglas por dispositivo y ver el indicador rojo por fallo  
  **Para** actuar rápido ante errores de acción.
- **Alcance:** incluye tabs Rules en `/actions` y `/devices/:id`; incluye enabled/paused y badge rojo por último intento fallido; excluye estado interno de evaluación.
- **Rutas UI:** `/actions`, `/devices/:id`
- **Entidades internas:** `RuleInstance`, `ActionAttempt`
- **Endpoints (si aplica):**
  - Verificar existentes para listar reglas por dispositivo, cambiar enabled/paused y consultar estado de badge por último intento.
  - Si faltan: actualizar `contexto/openapi/actions.yaml` de forma incremental en esta historia.
  - Implementar + pruebas mínimas smoke/integration en la misma historia.
    - Incluir operaciones de gestión: toggle `enabled/paused` de `RuleInstance`.
  - Incluir `Resolve manual` (solo aplica para latch mode).

- **Criterios de aceptación (AC):**
  1) `/actions` tab Rules lista reglas por dispositivo.
  2) Se puede pausar/habilitar `RuleInstance`.
  3) El badge rojo se activa cuando el último `ActionAttempt` asociado está en Fail.
  4) `/devices/:id` muestra tab Rules/Acciones con instancias adjuntas.
  5) Desde device detail se mantiene flujo de creación/asignación de regla.
  6) La UI no muestra estado interno detallado de evaluación.
- **Checklist QA:**
  1) Validar listado de reglas en `/actions`.
  2) Pausar regla y confirmar ausencia de disparos.
  3) Rehabilitar regla y confirmar retorno operativo.
  4) Inducir fallo y validar badge rojo.
  5) Inducir último intento exitoso y validar remoción del badge rojo.
  6) Validar vista Rules/Acciones en `/devices/:id`.
  7) Validar coherencia entre `/actions` y `/devices/:id` para misma instancia.
  8) Confirmar que no se muestran estados internos prohibidos.
- **Datos / Contratos (si aplica):**
  - **SQL:** `RuleInstance`, consulta de último `ActionAttempt` por instancia.
  - **Redis:** estado runtime para respetar enabled/paused.
  - **RabbitMQ:** no aplica directo a render UI.
  - **ClickHouse:** no aplica directo a render UI.
- **Depends on:** ACT-001, ACT-002, ACT-004, ACT-006
- **Referencias:** Spec §1 Alcance, §2 UX / Navegación, §5 Lifecycle y anti-spam, §8 Regla de indicador rojo, §9 Regla de endpoints (por historia, sin gate), §10 QA mínimo

## C) GUARDRAILS (DO NOT DO)
- No crear historia gate de endpoints/OpenAPI (no `ACT-000`).
- No inventar endpoints, colas, tablas, tecnologías o semánticas fuera de `spec.md`.
- No introducir `function-per-rule deployment`.
- No inventar semánticas temporales adicionales a las cinco del builder + lifecycle definido.
- No permitir overrides fuera de `threshold` y `email.recipients` en v1.
- No exponer estado interno de evaluación en UI (ej. “faltan 2h/5h”).
- No habilitar acciones operativas distintas de Email en v1.
- No omitir pruebas mínimas smoke/integration cuando una historia agrega endpoint.

## D) DOC DELIVERABLES (solo listar)
- **ADR requerido:** Runtime state v1 (`Redis` + `RuleCheckpoint` en SQL) y criterios de rehidratación.
- **ADR requerido:** Lifecycle v1 (auto-reset vs latch + cooldown + resolve manual).
- **OpenAPI delta requerido:** `contexto/openapi/actions.yaml` para cambios incrementales por historia que agregue/ajuste endpoints.
- **Checklist de migración DB:** tablas, índices y constraints de `RuleTemplate`, `RuleTemplateVersion`, `RuleInstance`, `ActionAttempt`, `RuleCheckpoint`.
- **Matriz QA / runbook:** pruebas de anti-spam, cooldown, latch, duplicados, runs, rehidratación y badge rojo.
