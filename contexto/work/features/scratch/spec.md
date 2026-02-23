# Telemetric — SPEC Final v2
## Actions Templates: Variables + Bindings + Scratch Toolbox + Assignments (Fixes incl.)

**Status:** READY FOR CODEX  
**Scope:** Iteración 2 (complementa Iteración 1)  
**Objetivo:** Definir de forma **determinista** (sin ambigüedad) cómo funcionan:
- Variables (derivaciones/inputs lógicos)
- Bindings (variable → sensor/metric) por Modelo y override por Dispositivo
- Scratch editor (toolbox/categorías/bloques, root, validaciones)
- Assignments (Devices y Models) con idempotencia
- Fixes para: *Scratch en blanco* + *Asignaciones que no persisten/duplican*

---

## 0) DB Schema Gate (MANDATORY)
> **Regla:** Antes de crear migrations o nuevas tablas/columnas, se debe auditar el esquema existente (Iteración 1) y **reusar** lo que ya existe.

### 0.1 Discover
- Identificar tablas/columnas existentes relacionadas a:
  - templates / template_versions
  - rule_instances / rule_assignments
  - modelos de dispositivo (device_models) y devices
  - campos que guardan definición Scratch (definition / config / json / etc.)

### 0.2 Equivalence Test (Reuse-first)
- Si existe algo equivalente a:
  - `VariableDefinition`
  - `VariableBinding`
  - `ModelAssignment`
  entonces **reusar** y mapear campos.  
- Solo si faltan entidades equivalentes, crear las tablas mínimas definidas en este spec.

### 0.3 Only if missing
- Si NO hay equivalentes, crear **solo**:
  - `rule_variable_definitions`
  - `rule_variable_bindings`
  - `rule_model_assignments`

---

## 1) Objetivo (Iteración 2)
Agregar un nivel previo a Scratch:
1) Crear **Variables** dentro de un `RuleTemplateVersion`
2) Conectar variables a sensores reales mediante **Bindings**
3) Permitir asignación por:
   - **Dispositivos** (ya existe, se corrige)
   - **Modelos** (nuevo, con auto-attach opcional)
4) Scratch debe:
   - Renderizar toolbox + canvas siempre (nunca “en blanco”)
   - Cargar `definition_json` existente
   - Guardar definición valida y consistente con Variables
5) Asignaciones deben:
   - Ser idempotentes (sin duplicados)
   - Refrescar contadores desde backend
   - Reportar created/skipped determinísticamente

---

## 2) Definiciones y conceptos (sin ambigüedad)

### 2.1 VariableDefinition
Una **Variable** es un input lógico usado en Scratch. Scratch nunca referencia `metricCode` directo.

**Campos**
- `variableKey` (string) único por templateVersion, regex: `[a-z0-9_]{2,32}`
- `displayName` (string)
- `variableType` (enum):
  - `RAW`
  - `LAST_VALUE`
  - `AGGREGATION_WINDOW`
  - `CONSTANT`
- `config` (json por tipo):
  - RAW: `{}`
  - LAST_VALUE: `{ "ttlSeconds": number }`
  - AGGREGATION_WINDOW: `{ "func":"avg"|"sum"|"min"|"max", "windowSeconds": number }`
  - CONSTANT: `{ "value": number }`

### 2.2 VariableBinding
Conecta `variableKey` a un sensor real.

**DECISIÓN v2 (fija):** El binding usa `metricCode` (string).

**Campos**
- `scopeType`: `MODEL | DEVICE`
- `scopeId`: `modelId` o `deviceId`
- `templateVersionId`
- `variableKey`
- `metricCode` (string)
- `transform` opcional: `{ "scale"?: number, "offset"?: number }`

**Resolución**
1) binding DEVICE si existe
2) binding MODEL si existe
3) si no existe: `MISSING_BINDING`

### 2.3 ModelAssignment
Asigna un templateVersion a un modelo para masivo y herencia.

**Campos**
- `templateVersionId`
- `modelId`
- `autoAttachOnDeviceCreate` (bool, default: `true`)

---

## 3) Persistencia de Scratch: JSON (no JS)
**Regla:** Guardar definición como **JSON** (data/AST), no como código JS.

**Motivos (obligatorio):**
- Validable por schema
- Seguro (no ejecución de código)
- Portable multi-lenguaje (.NET, workers)
- Versionable (schemaVersion)

**Almacenamiento DB recomendado (SQL Server):**
- `definition_json` como `NVARCHAR(MAX)` con JSON
- (opcional) `workspace_json` como `NVARCHAR(MAX)` si se quiere persistir layout exacto del editor

---

## 4) UX / Pantallas: Template Detail (Modal)

### 4.1 Orden de secciones (obligatorio)
1) Metadata (Nombre/Descripción/Activo)
2) Variables (CRUD)
3) Bindings (por Modelo; override por Device se maneja en contexto del RuleInstance/device)
4) Regla (Scratch only)
5) Asignaciones (Devices / Models)
6) Footer (Cancelar / Guardar nueva versión)

### 4.2 Sección Variables
- Tabla:
  - displayName
  - variableKey
  - variableType
  - resumen config (ej: `avg(600s)`)
  - estado: `OK` / `Falta binding` (si hay modelo seleccionado) / `No usada` (opcional)
- Botones:
  - `Crear variable`
  - `Editar`
  - `Eliminar`

### 4.3 Sección Bindings (MODEL)
- Dropdown: seleccionar Modelo
- Tabla:
  - variableKey/displayName → input `metricCode` (dropdown si existe catálogo; si no, textbox)
- Botón: `Guardar bindings`
- Estado:
  - si faltan bindings requeridos → warning

### 4.4 Sección Regla (Scratch only)
- Badge:
  - ✅ Regla configurada con Scratch  ⇔ `definition_json` existe y es válido
  - ⚠️ Regla no configurada ⇔ `definition_json` null/vacío/invalid
- Botón: `Abrir Scratch`

### 4.5 Sección Asignaciones
- Selector tipo: `Dispositivos | Modelos`
- Multi-select (chips)
- Botón: `Asignar seleccionados`
- Contadores (backend-driven):
  - `Asignaciones registradas: X`
  - `Ejecuciones fallidas: Y`

---

## 5) Scratch — Toolbox, Bloques y Reglas (DETERMINISTA)

### 5.1 Categorías (orden fijo)
1) Variables  
2) Comparación  
3) Lógica  
4) Tiempo / Ventanas  
5) Acciones  
6) Utilidades (opcional)

### 5.2 Root obligatorio
**Debe existir exactamente 1:**
- `rule_when` (statement root)
  - `condition:boolean`
  - `actions:[]` (lista de statements)
**Validación:**
- root existe 1 vez
- actions >= 1

### 5.3 Categoría Variables
**Bloques**
1) `variable_ref`
- UI: “Variable [dropdown variableKey]”
- Output: number
- Validación: variableKey existe en VariableDefinitions

2) `constant_number`
- UI: “Número [input]”
- Output: number
- Validación: número válido

### 5.4 Categoría Comparación
1) `compare`
- Inputs: left:number, op:(>,>=,<,<=,==,!=), right:number
- Output: boolean

2) `between`
- Inputs: value:number, min:number, max:number
- Output: boolean

### 5.5 Categoría Lógica
1) `and` → boolean
2) `or` → boolean
3) `not` → boolean

### 5.6 Categoría Tiempo / Ventanas
1) `hold_for_duration`
- UI: “Condición [bool] se cumple por [durationSeconds] seg”
- Output: boolean
- Validación: durationSeconds > 0

2) `count_occurrences_window`
- UI: “Contar ocurrencias de [bool] en [windowSeconds] seg >= [count]”
- Output: boolean
- Validación: windowSeconds > 0; count >= 1

> Nota: Implementación interna puede usar estado/ventana deslizante; no depende de ClickHouse para v2.

### 5.7 Categoría Acciones (side-effects)
**Regla:** Acciones son **statements**, no devuelven boolean.

1) `action_email` (v2 implementable)
- recipients[] requerido (chips)
- subject opcional (backend default)
- body opcional (backend default)
- Validación: recipients >= 1; email format básico

2) `action_in_app_alert` (v2 recomendado; si no se implementa, dejar stub no visible)
- severity: INFO|WARN|CRITICAL (req)
- title req
- message req

> Acciones múltiples permitidas; orden = orden del stack.

### 5.8 Utilidades (opcional)
- placeholders permitidos en subject/body:
  - `${device.name}`, `${device.id}`, `${model.name}`, `${rule.templateName}`, `${timestamp.iso}`, `${variables.<variableKey>}`

---

## 6) Scratch — Formato de guardado (AST JSON)
**Se guarda en** `definition_json` (NVARCHAR MAX JSON)

### 6.1 Contrato JSON mínimo (schemaVersion fijo)
```json
{
  "schemaVersion": 1,
  "root": {
    "type": "rule_when",
    "condition": { "type": "compare", "op": ">", "left": { "type": "variable_ref", "variableKey": "temp_avg" }, "right": { "type": "constant_number", "value": 18 } },
    "actions": [
      { "type": "action_email", "recipients": ["a@b.com"], "subject": "Alerta", "body": "Temp alta: ${variables.temp_avg}" }
    ]
  }
}
```

### 6.2 Validación backend (determinista)
- schemaVersion soportado
- root presente 1 vez
- actions.length >= 1
- variable_ref.variableKey existe
- action_email.recipients >= 1
- Si error: devolver lista de errores con `path` estable y ordenada por `path asc`.

---

## 7) Fix obligatorio: Scratch “en blanco”
**Problema típico:** inicializar workspace cuando el contenedor aún mide 0 (modal no visible).

### 7.1 Reglas FE obligatorias
Al abrir modal Scratch:
1) Esperar a que el modal sea visible (ej: `await nextTick()` / `onOpened`)
2) Inicializar workspace en contenedor con tamaño real
3) Ejecutar `resizeWorkspace()` después de mount/paint
4) Si `definition_json` válido → load blocks
5) Si inválido → abrir vacío + toast error

**Criterio de aceptación**
- Toolbox visible siempre
- Canvas visible siempre
- Si “Regla configurada” → se ven blocks

---

## 8) Assignments (Devices/Models) — comportamiento exacto

### 8.1 Assign to Devices (fix + idempotente)
Endpoint crea RuleInstance por cada deviceId con `templateVersionId`.

**Idempotencia**
- Unique lógico: `(deviceId, templateVersionId)`
- Si ya existe: no crear; reportar `skipped`

**Respuesta API**
- `{ created: number, skipped: number, duplicates: [deviceId], errors: [] }`

**UI**
- Tras asignar:
  - refrescar resumen/contadores desde backend
  - mostrar toast “Asignadas X | Duplicadas Y”
  - NO confiar en estado local para el contador

### 8.2 Assign to Models (nuevo)
Crea `ModelAssignment` por modelId con `autoAttachOnDeviceCreate` default true.

**Regla**
- Unique `(modelId, templateVersionId)`; idempotente.

**AutoAttach**
- Al crear un Device nuevo, si su modelId tiene assignments con autoAttach=true:
  - crear RuleInstance(s) automáticamente.

---

## 9) Policy de bindings (fija v2)
### 9.1 Asignar a Modelos
**Fail fast:** bloquear asignación si faltan bindings MODEL para variables usadas en Scratch.

Error backend:
- `MISSING_MODEL_BINDINGS`
- incluye lista `missingVariableKeys[]`

### 9.2 Asignar a Devices
Se permite asignar aunque falten bindings, pero:
- RuleInstance queda en estado `NOT_EVALUABLE_MISSING_BINDING`
- UI debe mostrar warning “Completar bindings”

---

## 10) DB (solo si falta tras el Gate)

### 10.1 rule_variable_definitions
- id (PK)
- template_version_id (FK)
- variable_key (unique per template_version_id)
- display_name
- variable_type
- config_json (NVARCHAR MAX)
- audit columns

### 10.2 rule_variable_bindings
- id (PK)
- template_version_id (FK)
- scope_type (MODEL|DEVICE)
- scope_id
- variable_key
- metric_code
- transform_json (nullable)
- unique: (template_version_id, scope_type, scope_id, variable_key)

### 10.3 rule_model_assignments
- id (PK)
- template_version_id (FK)
- model_id (FK)
- auto_attach (bit, default true)
- unique: (template_version_id, model_id)

---

## 11) API Endpoints (incremental)
### 11.1 Variables
- GET  `/api/v1/actions/templates/{templateId}/versions/{versionId}/variables`
- POST `/api/v1/actions/templates/{templateId}/versions/{versionId}/variables`
- PUT  `/api/v1/actions/templates/{templateId}/versions/{versionId}/variables/{variableKey}`
- DELETE `/api/v1/actions/templates/{templateId}/versions/{versionId}/variables/{variableKey}`

### 11.2 Bindings MODEL
- GET `/api/v1/actions/templates/{templateId}/versions/{versionId}/bindings/models/{modelId}`
- PUT `/api/v1/actions/templates/{templateId}/versions/{versionId}/bindings/models/{modelId}`
  - body: `{ "bindings": [{ "variableKey": "...", "metricCode": "..." }] }`

### 11.3 Definition Scratch
- GET `/api/v1/actions/templates/{templateId}/versions/{versionId}/definition`
- PUT `/api/v1/actions/templates/{templateId}/versions/{versionId}/definition`
  - body: `{ "definitionJson": { ... } }`

### 11.4 Assignments
- POST `/api/v1/actions/templates/{templateId}/versions/{versionId}/assign-devices`
  - body: `{ "deviceIds": [] }`
- POST `/api/v1/actions/templates/{templateId}/versions/{versionId}/assign-models`
  - body: `{ "modelIds": [], "autoAttachOnDeviceCreate": true }`

---

## 12) QA / Acceptance Tests (mínimo)
1) Scratch render:
- Abrir Scratch siempre muestra toolbox+canvas (nunca blanco)

2) Scratch load:
- Si `definition_json` válido → blocks visibles

3) Scratch empty:
- Si no hay `definition_json` → canvas vacío pero usable

4) Variables reference:
- Guardar falla si Scratch usa variable inexistente

5) Assign devices idempotente:
- Re-asignar mismos devices → created=0 skipped=N, sin duplicados

6) Assign model requiere bindings:
- Sin bindings MODEL → 400 MISSING_MODEL_BINDINGS

7) AutoAttach:
- Nuevo device con model assignment autoAttach=true → crea RuleInstance automáticamente

---

## 13) Implementation Notes (para Codex: “no inventar”)
- **No crear migrations** sin completar DB Schema Gate.
- “Regla configurada” depende de `definition_json` parseable + schemaVersion soportado + root+actions válidos.
- Scratch se inicializa **solo** cuando el modal ya tiene tamaño real; luego `resizeWorkspace`.
- Assignments refrescan contadores desde backend; no confiar en estado local.

---

## 14) Prompt de ejecución recomendado (pegar en Codex)
> Implementar “SPEC Final v2 — Variables + Bindings + Scratch Toolbox + Assignments Fix”.  
> Primero ejecutar DB Schema Gate: auditar esquema existente y reusar equivalentes.  
> Corregir Scratch modal para que nunca abra en blanco: init cuando visible + resize + load definition_json.  
> Implementar Variables (CRUD), Bindings por Modelo (PUT/GET), Definition (PUT/GET), Assign-devices idempotente y Assign-models con autoAttach.  
> Validaciones deterministas con error paths estables y ordenados por path asc.

