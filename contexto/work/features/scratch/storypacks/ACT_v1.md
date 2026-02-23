# ACT_v1 - Scratch

## LINT REPORT
- Gates checked: G1..G6
- Fixes applied:
  - Se normalizo el orden canonico de secciones por historia (incluyendo `Endpoint check gate`).
  - Se verifico presencia de `Endpoints (si aplica)` y `Endpoint check gate` en todas las historias.
  - Se verifico trazabilidad con referencias explicitas a secciones del spec (>= 2 por historia).
- Remaining notes (if any):
  - Ninguna.

## STORY INDEX
- **ID:** ACT-001
- **Título:** Corregir editor Scratch (render, carga y guardado de definición JSON)
- **Tipo:** FE/BE
- **Depends on:** `contexto/work/features/scratch/spec.md`
- **Blocks:** ACT-002, ACT-003, ACT-004

- **ID:** ACT-002
- **Título:** Implementar Variables (CRUD) en Template Version
- **Tipo:** FE/BE
- **Depends on:** ACT-001
- **Blocks:** ACT-003, ACT-004

- **ID:** ACT-003
- **Título:** Implementar Bindings por Modelo y política de validación
- **Tipo:** FE/BE
- **Depends on:** ACT-001, ACT-002
- **Blocks:** ACT-004

- **ID:** ACT-004
- **Título:** Implementar Assignments idempotentes (Devices/Models) y AutoAttach
- **Tipo:** BE/FE
- **Depends on:** ACT-001, ACT-002, ACT-003
- **Blocks:** ACT-005

- **ID:** ACT-005
- **Título:** Ejecutar DB Schema Gate y cerrar evidencia de QA/Docs de iteración
- **Tipo:** DB/DOC
- **Depends on:** ACT-001, ACT-002, ACT-003, ACT-004
- **Blocks:** Ninguna

## STORIES

### ACT-001 - Corregir editor Scratch (render, carga y guardado de definición JSON)
- **Como** operador de reglas
  **Quiero** abrir Scratch en el modal de Template Detail sin pantalla en blanco y guardar `definition_json`
  **Para** configurar reglas de forma consistente y reutilizable.
- **Alcance:**
  - Incluye: fix de inicialización visible + `resizeWorkspace`, carga de definición válida, guardado por API de Definition.
  - Excluye: nuevos bloques fuera de categorías definidas en spec.
- **Rutas UI:** Template Detail (modal) -> Sección Regla (Scratch only)
- **Entidades internas:** `RuleTemplateVersion`, `RuleDefinition`, `RuleWhenAst`
- **Endpoints (si aplica):**
  - Verificar existentes: `GET /api/v1/actions/templates/{templateId}/versions/{versionId}/definition`, `PUT /api/v1/actions/templates/{templateId}/versions/{versionId}/definition`.
  - Si faltan: actualizar/crear incrementalmente `contexto/openapi/actions.yaml` para estos endpoints en esta historia.
  - Implementar endpoint(s) faltante(s) y pruebas mínimas de integración/smoke en esta historia.
- **Endpoint check gate (obligatorio si hay endpoints):**
  - Discover -> Equivalence test -> Reuse-first -> Only if missing (OpenAPI delta) -> DECISIÓN PENDIENTE si hay dudas
- **Criterios de aceptación (AC):**
  1. Al abrir el modal Scratch, toolbox y canvas se muestran en <= 1 segundo con contenedor visible.
  2. Si `definition_json` es JSON válido con `schemaVersion` soportado, se renderizan bloques existentes.
  3. Si `definition_json` es null/vacío, el canvas abre vacío pero usable y permite guardar.
  4. Si `definition_json` es inválido, el editor abre vacío y muestra toast de error único.
  5. El backend valida: `schemaVersion`, root único `rule_when`, y `actions.length >= 1`.
  6. Los errores de validación devuelven lista con `path` estable ordenada ascendentemente por `path`.
- **Checklist QA:**
  1. Probar apertura de modal en primer render de página (sin recargar).
  2. Probar apertura/cierre repetido del modal (>= 5 ciclos) sin canvas en blanco.
  3. Probar `definition_json` válido y confirmar bloques visibles.
  4. Probar `definition_json` inválido y confirmar toast + editor usable.
  5. Probar guardado con `actions` vacías y confirmar error backend con `path`.
  6. Probar guardado con `variable_ref` inexistente y confirmar error backend con `path`.
  7. Confirmar que badge "Regla configurada con Scratch" cambia según validez real.
  8. Confirmar que OpenAPI refleja cualquier endpoint nuevo si no existía.
- **Datos / Contratos (si aplica):**
  - **SQL:** `definition_json` en `template_versions` (o equivalente existente por DB Schema Gate).
  - **Redis:** No aplica.
  - **RabbitMQ:** No aplica.
  - **ClickHouse:** No aplica.
- **Depends on:** `contexto/work/features/scratch/spec.md`
- **Referencias:** Spec §3, Spec §4.4, Spec §6, Spec §7, Spec §11.3

### ACT-002 - Implementar Variables (CRUD) en Template Version
- **Como** autor de plantilla
  **Quiero** crear, editar y eliminar variables lógicas
  **Para** que Scratch use `variableKey` y no dependa de `metricCode` directo.
- **Alcance:**
  - Incluye: tabla/CRUD de Variables, validación de `variableKey` y `config` por tipo, integración en UI de Variables.
  - Excluye: bindings por device (se cubren por política y resolución, no por pantalla principal en esta historia).
- **Rutas UI:** Template Detail (modal) -> Sección Variables
- **Entidades internas:** `VariableDefinition`, `RuleTemplateVersion`
- **Endpoints (si aplica):**
  - Verificar existentes: GET/POST/PUT/DELETE `/api/v1/actions/templates/{templateId}/versions/{versionId}/variables`.
  - Si faltan: actualizar/crear incrementalmente `contexto/openapi/actions.yaml` para Variables en esta historia.
  - Implementar endpoint(s) faltante(s) y pruebas mínimas de integración/smoke en esta historia.
- **Endpoint check gate (obligatorio si hay endpoints):**
  - Discover -> Equivalence test -> Reuse-first -> Only if missing (OpenAPI delta) -> DECISIÓN PENDIENTE si hay dudas
- **Criterios de aceptación (AC):**
  1. `variableKey` cumple regex `[a-z0-9_]{2,32}` y unicidad por `templateVersionId`.
  2. `variableType` acepta únicamente `RAW|LAST_VALUE|AGGREGATION_WINDOW|CONSTANT`.
  3. `config` se valida por tipo y rechaza shape inválido con error determinista.
  4. La tabla de Variables muestra `displayName`, `variableKey`, `variableType`, resumen de config y estado.
  5. El bloque `variable_ref` del editor sólo lista variables existentes del template version activo.
  6. Eliminar una variable usada en definición activa falla con error de validación explícito.
- **Checklist QA:**
  1. Crear variable RAW válida y verificar persistencia.
  2. Crear variable con key inválida y verificar error.
  3. Crear variable duplicada en mismo versionId y verificar rechazo.
  4. Editar variable de LAST_VALUE con `ttlSeconds` > 0 y verificar persistencia.
  5. Editar variable AGGREGATION_WINDOW con `func` fuera de catálogo y verificar rechazo.
  6. Eliminar variable no usada y verificar éxito.
  7. Intentar eliminar variable usada y verificar bloqueo con mensaje claro.
  8. Verificar que OpenAPI queda actualizado sólo para deltas realmente faltantes.
- **Datos / Contratos (si aplica):**
  - **SQL:** reusar equivalente o crear `rule_variable_definitions` sólo si falta (DB Schema Gate).
  - **Redis:** No aplica.
  - **RabbitMQ:** No aplica.
  - **ClickHouse:** No aplica.
- **Depends on:** ACT-001
- **Referencias:** Spec §0, Spec §2.1, Spec §4.2, Spec §5.3, Spec §11.1

### ACT-003 - Implementar Bindings por Modelo y política de validación
- **Como** operador de configuración
  **Quiero** registrar bindings de variables por modelo y validar faltantes
  **Para** asegurar evaluabilidad antes de asignaciones masivas a modelos.
- **Alcance:**
  - Incluye: GET/PUT de bindings por modelo, `metricCode` como decisión fija v2, resolución DEVICE > MODEL > missing.
  - Excluye: exposición de estado interno runtime en UI fuera del warning requerido.
- **Rutas UI:** Template Detail (modal) -> Sección Bindings (MODEL)
- **Entidades internas:** `VariableBinding`, `VariableDefinition`, `DeviceModel`
- **Endpoints (si aplica):**
  - Verificar existentes: `GET /api/v1/actions/templates/{templateId}/versions/{versionId}/bindings/models/{modelId}`, `PUT /api/v1/actions/templates/{templateId}/versions/{versionId}/bindings/models/{modelId}`.
  - Si faltan: actualizar/crear incrementalmente `contexto/openapi/actions.yaml` para Bindings MODEL en esta historia.
  - Implementar endpoint(s) faltante(s) y pruebas mínimas de integración/smoke en esta historia.
- **Endpoint check gate (obligatorio si hay endpoints):**
  - Discover -> Equivalence test -> Reuse-first -> Only if missing (OpenAPI delta) -> DECISIÓN PENDIENTE si hay dudas
- **Criterios de aceptación (AC):**
  1. El binding persiste `metricCode` (string) y no usa identificador alternativo en v2.
  2. `scopeType` acepta sólo `MODEL|DEVICE` y valida `scopeId` coherente.
  3. La resolución de binding aplica orden DEVICE, luego MODEL, y si no existe retorna `MISSING_BINDING`.
  4. En asignación a modelos, si faltan bindings de variables usadas se devuelve `MISSING_MODEL_BINDINGS` con `missingVariableKeys[]`.
  5. En UI de bindings, faltantes requeridos muestran warning persistente hasta guardar bindings completos.
  6. El guardado de bindings es idempotente por unique `(template_version_id, scope_type, scope_id, variable_key)`.
- **Checklist QA:**
  1. Guardar bindings completos por modelo y verificar lectura GET consistente.
  2. Guardar binding con `metricCode` vacío y verificar rechazo.
  3. Verificar que un binding DEVICE sobrescribe uno MODEL al resolver variable.
  4. Intentar asignar modelo con faltantes y verificar 400 `MISSING_MODEL_BINDINGS`.
  5. Completar bindings faltantes y repetir asignación con éxito.
  6. En UI, comprobar warning cuando falta al menos un binding usado por Scratch.
  7. Repetir PUT con mismo payload y verificar estado final sin duplicados.
  8. Verificar OpenAPI incremental sólo en endpoints faltantes.
- **Datos / Contratos (si aplica):**
  - **SQL:** reusar equivalente o crear `rule_variable_bindings` sólo si falta (DB Schema Gate).
  - **Redis:** No aplica.
  - **RabbitMQ:** No aplica.
  - **ClickHouse:** No aplica.
- **Depends on:** ACT-001, ACT-002
- **Referencias:** Spec §2.2, Spec §4.3, Spec §8, Spec §9, Spec §11.2

### ACT-004 - Implementar Assignments idempotentes (Devices/Models) y AutoAttach
- **Como** operador de despliegue
  **Quiero** asignar reglas a dispositivos y modelos sin duplicados
  **Para** obtener activación masiva consistente y trazable.
- **Alcance:**
  - Incluye: `assign-devices`, `assign-models`, respuesta `created/skipped/duplicates/errors`, refresh de contadores backend-driven, `autoAttachOnDeviceCreate`.
  - Excluye: lógica de función por regla (fuera de alcance del spec).
- **Rutas UI:** Template Detail (modal) -> Sección Asignaciones
- **Entidades internas:** `RuleInstance`, `ModelAssignment`, `Device`, `DeviceModel`
- **Endpoints (si aplica):**
  - Verificar existentes: `POST /api/v1/actions/templates/{templateId}/versions/{versionId}/assign-devices`, `POST /api/v1/actions/templates/{templateId}/versions/{versionId}/assign-models`.
  - Si faltan: actualizar/crear incrementalmente `contexto/openapi/actions.yaml` para Assignments en esta historia.
  - Implementar endpoint(s) faltante(s) y pruebas mínimas de integración/smoke en esta historia.
- **Endpoint check gate (obligatorio si hay endpoints):**
  - Discover -> Equivalence test -> Reuse-first -> Only if missing (OpenAPI delta) -> DECISIÓN PENDIENTE si hay dudas
- **Criterios de aceptación (AC):**
  1. `assign-devices` es idempotente con unicidad lógica `(deviceId, templateVersionId)`.
  2. Reasignar mismos devices devuelve `created=0`, `skipped=N`, `duplicates` con IDs afectados.
  3. Tras asignar, UI refresca contadores desde backend y no desde estado local previo.
  4. `assign-models` crea `ModelAssignment` único por `(modelId, templateVersionId)`.
  5. `autoAttachOnDeviceCreate=true` crea `RuleInstance` al alta de device del modelo asignado.
  6. Asignación a device con bindings faltantes queda `NOT_EVALUABLE_MISSING_BINDING` y UI muestra warning.
- **Checklist QA:**
  1. Asignar lote de devices nuevo y verificar `created` coincide con tamaño del lote.
  2. Repetir la misma asignación y verificar sólo `skipped`.
  3. Verificar toast con formato "Asignadas X | Duplicadas Y".
  4. Confirmar recarga de contadores mediante nueva lectura backend.
  5. Asignar modelos con autoAttach true y crear nuevo device; verificar RuleInstance automático.
  6. Asignar modelo duplicado y verificar idempotencia.
  7. Forzar faltante de bindings en device assignment y verificar estado `NOT_EVALUABLE_MISSING_BINDING`.
  8. Validar payload/response de OpenAPI contra implementación de endpoints.
- **Datos / Contratos (si aplica):**
  - **SQL:** `rule_instances` (existente/equivalente), `rule_model_assignments` (sólo si falta), unique constraints de idempotencia.
  - **Redis:** No aplica.
  - **RabbitMQ:** No aplica.
  - **ClickHouse:** No aplica.
- **Depends on:** ACT-001, ACT-002, ACT-003
- **Referencias:** Spec §2.3, Spec §4.5, Spec §8, Spec §9, Spec §11.4

### ACT-005 - Ejecutar DB Schema Gate y cerrar evidencia de QA/Docs de iteración
- **Como** responsable técnico
  **Quiero** cerrar la iteración con evidencia de reuso de esquema y entregables documentales
  **Para** evitar drift de contratos y reducir regresiones.
- **Alcance:**
  - Incluye: Discover + Equivalence Test + decisión de crear sólo tablas faltantes, checklist final QA y entregables documentales.
  - Excluye: implementación de features nuevas fuera de Iteración 2.
- **Rutas UI:** N/A (backend/database/documentación)
- **Entidades internas:** `VariableDefinition`, `VariableBinding`, `ModelAssignment`, `RuleTemplateVersion`
- **Endpoints (si aplica):** No aplica
- **Endpoint check gate:** No aplica
- **Criterios de aceptación (AC):**
  1. Existe evidencia de auditoría del esquema actual antes de cualquier migration nueva.
  2. Si hay equivalentes de entidades, se documenta reuso y mapeo campo-a-campo.
  3. Si no hay equivalentes, sólo se crean `rule_variable_definitions`, `rule_variable_bindings`, `rule_model_assignments`.
  4. No se crea ninguna tabla/columna fuera del alcance explícito de este spec.
  5. Se documentan deltas OpenAPI por historia en vez de un mega-cambio único.
  6. Se consolida evidencia de QA de pruebas mínimas de la sección 12.
- **Checklist QA:**
  1. Verificar evidencia de Discover sobre tablas/columnas existentes.
  2. Verificar evidencia de Equivalence Test (reuso-first).
  3. Confirmar que cualquier migration creada corresponde sólo a entidades permitidas.
  4. Revisar que cada historia tiene trazabilidad a secciones del spec.
  5. Revisar que no se expone estado interno no permitido en UI.
  6. Revisar consistencia de mensajes de error deterministas (`MISSING_MODEL_BINDINGS`, etc.).
  7. Confirmar que criterios mínimos de QA de Spec §12 están cubiertos.
  8. Validar que los entregables documentales están listados sin escribirlos en esta fase.
- **Datos / Contratos (si aplica):**
  - **SQL:** DB Schema Gate y tablas objetivo de §10 sólo si faltan.
  - **Redis:** No aplica.
  - **RabbitMQ:** No aplica.
  - **ClickHouse:** No aplica.
- **Depends on:** ACT-001, ACT-002, ACT-003, ACT-004
- **Referencias:** Spec §0, Spec §10, Spec §11, Spec §12, Spec §13

## GUARDRAILS (DO NOT DO)
- No inventar endpoints, tablas, colas, contratos o rutas UI no descritas en el spec.
- No crear migrations sin ejecutar y documentar DB Schema Gate (Discover + Equivalence Test).
- No guardar definición como JS ejecutable; sólo JSON en `definition_json`.
- No omitir idempotencia en assignments (`deviceId/templateVersionId` y `modelId/templateVersionId`).
- No confiar en estado local para contadores de asignación; siempre refrescar backend.
- No marcar una regla como configurada si `definition_json` no es parseable/valida.

## DOC DELIVERABLES (do not write them)
- ADR: "Persistencia de definición de regla en JSON AST (schemaVersion=1)" - justificar seguridad, validación y portabilidad.
- OpenAPI delta incremental por historia (Variables, Bindings, Definition, Assignments) - asegurar contratos verificables por endpoint.
- Migration checklist DB Schema Gate - evidencia de reuso-first y justificación de nuevas tablas sólo si faltan equivalentes.
- QA runbook Iteración 2 - pasos reproducibles para pruebas de Scratch render/load, bindings policy y assignments idempotentes.



