# SPEC v1 — Módulo “Acciones” (Telemetric)

## 0) Objetivo
Permitir a un cliente crear reglas visuales (Scratch) para disparar **acciones** basadas en telemetría de dispositivos, usando plantillas reutilizables y asignación masiva. El sistema debe evitar spam (auto-reset, latch opcional, cooldown) y proveer trazabilidad mínima mediante historial de ejecuciones (**Runs**) y errores.

- UI en **español**: “Acciones”
- Nombres internos (código/DB/contratos) en **inglés**: `RuleTemplate`, `RuleInstance`, `ActionAttempt`, etc.

---

## 1) Alcance

### Entra (v1)
- UI “Acciones” con tabs (en `/actions`):
  - **Runs**: historial de ejecuciones de acciones (success/fail + error).
  - **Rules**: instancias de reglas por dispositivo (enabled/paused + badge rojo si falló una acción).
  - **Templates**: plantillas de reglas (crear/editar/versionar/asignar).
- Rutas:
  - `/actions` (landing con tabs)
  - `/actions/templates/:id` (detalle template)
  - `Device Detail (/devices/:id)` mantiene tab “Rules/Acciones” (attached rules)
- Builder Scratch soporta 5 tipos de regla:
  1) Instant threshold
  2) Continuous duration
  3) Accumulated duration within window
  4) Aggregations in window (avg/min/max/sum)
  5) Count occurrences in window
- Acciones v1 reales: **Email** (arquitectura plugin para extender luego).
- Anti-spam / lifecycle:
  - Default: **Auto-reset**
  - Opcional: **Latch mode**
  - **Cooldown** configurable
- Duplicados: se **bloquean** al asignar al mismo device (misma plantilla/versión).
- Asignación:
  - Crear **plantilla** y asignarla a múltiples dispositivos.
  - Crear regla desde device: el usuario elige si queda como plantilla reutilizable o instancia local.

### No entra (v1)
- Librería completa de acciones activa (webhook/SMS) — solo contrato preparado.
- Límites por suscripción aplicados — solo hooks/campos (futuro).
- Estado interno detallado de evaluación visible en UI (“faltan 2h/5h…”) — no entra.
- Function-per-rule deployment.

---

## 2) UX / Navegación

### Landing
- `/actions` → módulo “Acciones”
  - Tab **Runs**
  - Tab **Rules**
  - Tab **Templates**

### Template detail
- `/actions/templates/:id`
  - Tabs sugeridos: Definition (Scratch), Versions, Assignments, Runs (fallos)

### Device detail
- `/devices/:id` (tab Rules/Acciones)
  - Ver RuleInstances adjuntas
  - Crear desde Template o crear nueva regla (local o reusable)

---

## 3) Conceptos y modelo mínimo (interno, inglés)

### Entidades
- `RuleTemplate`
- `RuleTemplateVersion` (inmutable)
- `RuleInstance` (por device; referencia a template_version)
- `ActionAttempt` (runs: success/fail + error)
- `AlertFired` (evento de dominio; puede persistirse como tabla o como evento persistente)
- `RuleCheckpoint` (recomendado para rehidratación)

### Reglas clave
- Asignar plantilla a device => crea `RuleInstance` por device.
- Duplicado no permitido: `(device_id, template_version_id)` en `RuleInstance`.
- Versionado: instancias quedan “pegadas” a una `RuleTemplateVersion` específica.

---

## 4) Storage y ejecución

### SQL Server (control-plane / transaccional)
Guarda:
- `RuleTemplate`
- `RuleTemplateVersion.definition_json` (DSL Scratch)
- `RuleInstance` + overrides + modo + cooldown + enabled/paused
- `ActionAttempt` (éxito/fallo + error)
- `RuleCheckpoint` (para rehidratar tras caída de Redis/engine)

### ClickHouse (data-plane histórico)
- Telemetría histórica
- Soporte a reglas “históricas” via scheduler/queries (según fase)

### Redis (runtime state/cache)
- Estado vivo por `(deviceId, ruleInstanceId)`:
  - contadores, timers, `cooldownUntil`, `latchActive`, etc.
- Cache opcional de plan compilado

### RabbitMQ (transporte)
- Telemetría llega por RabbitMQ y el engine evalúa event-driven.

**Decisión v1:** Redis runtime state + SQL checkpoint para rehidratación.

---

## 5) Lifecycle y anti-spam

### Auto-reset (default)
- Evalúa por cada evento consumido (event-driven).
- Dispara solo en transición `OK → VIOLATION`.
- Rearma cuando vuelve a `OK`.
- Cooldown suprime disparos nuevos por N segundos tras un disparo.

### Latch mode (opcional)
- Dispara una vez y queda `ACTIVE`.
- No re-dispara hasta rearme.
- Rearme exige:
  - `Resolve manual`
  - y condición `OK`.

---

## 6) Contrato del builder (DSL)

### Inputs DSL
- Trigger: Telemetry metric (`metricCode`)
- Condition: operador + valor
- Window:
  - instant
  - continuous duration (T)
  - accumulated duration within window (W, T)
  - aggregation within window (W, func)
  - count occurrences within window (W, N)
- Missing data policy (configurable por regla):
  - `INSUFFICIENT_DATA`
  - `HOLD_LAST_VALUE` con TTL
- Lifecycle config: auto/latch + cooldown
- Actions: Email v1 (plugin)

### Validaciones mínimas
- Bloques completos (sin valores faltantes)
- Coherencia temporal (T <= W si aplica)
- Acción válida (recipients)
- Duplicados bloqueados al asignar

---

## 7) Overrides v1 (cerrado)

### RuleInstance.overrides_json
**Permitidos v1:**
- `threshold` (solo valor numérico del umbral, si aplica)
- `email.recipients` (lista de destinatarios)

**No permitidos v1:**
- cambiar tipo de ventana o semántica temporal (instant/duration/window)
- cambiar estructura del DSL (solo parámetros permitidos)

**Regla de versionado con override:**
- Si una instancia tiene overrides, queda **pegada** a su `RuleTemplateVersion` (no auto-update).

---

## 8) Regla de indicador rojo (cerrado)

### Badge rojo (error)
- Badge rojo en **Rules** y/o **Templates** cuando el **último `ActionAttempt`** asociado a esa `RuleInstance` (o a instancias del template en la vista template) tuvo `status=Fail`.
- La UI NO muestra estado interno de evaluación; solo muestra el error registrado del `ActionAttempt`.

---

## 9) Regla de endpoints (por historia, sin gate)

- No existe una historia gate dedicada para OpenAPI/endpoints.
- Cada historia que requiera endpoints debe:
  1) Revisar si el endpoint ya existe en el proyecto.
  2) Si no existe, definir el contrato (OpenAPI delta incremental) y crear el endpoint.
  3) Proveer pruebas mínimas (smoke/integration).
- OpenAPI se actualiza incrementalmente por historia en:
  - `contexto/openapi/actions.yaml`
- Si no se puede inferir el estándar de API del proyecto (envelope/errores/versionado/auth),
  se debe emitir “DECISIÓN PENDIENTE” y detenerse.

---

## 10) QA mínimo (v1)
- Anti-spam (flapping): no spamea.
- Cooldown suprime disparos.
- Latch: no rearma sin Resolve+OK.
- Duplicados bloqueados.
- `ActionAttempt` registra success/fail + error.
- Caída de Redis: rehidrata desde `RuleCheckpoint` en SQL.
- Badge rojo se activa por “último intento falló” (sin estado interno visible).

---

## 11) Entregables docs (v1, por historias)
- ADR: runtime state (Redis + SQL checkpoint)
- ADR: lifecycle auto vs latch + cooldown
- OpenAPI delta: `contexto/openapi/actions.yaml`
- Checklist migraciones: tablas + índices + constraints
- Matriz QA: pruebas de anti-spam, latch, cooldown, duplicados, rehidratación
