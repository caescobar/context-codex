# QA PACK - acciones-modulo-act-005-phase-04

## 0) Metadata
- Fecha: 2026-02-20
- Tipo: QA PACK
- Objetivo: Validar Fase 04 de ACT-005 (alinear `/my-devices/:id/edit` al mismo builder/contrato DSL canonico y overrides v1 acotados).
- Entorno: frontend (`telemetric-front`) + API local opcional para auto-login/evidencia.
- Autor: Codex (asistido)

## 0.1 Trazabilidad del pack
- PackDir: `contexto/work/features/acciones_modulo/04_test/ACT-005/phase-04/`
- StoryId: `ACT-005`
- Requirement: `acciones_modulo`
- PhaseId: `04`
- ChangePlan: `contexto/work/features/acciones_modulo/02_plans/ACT-005.plan.md`
- ChangeSummary: `contexto/work/features/acciones_modulo/03_execution/ACT-005/phase-04.md`

---

## 1) Alcance
### 1.1 Incluye
- Verificacion de ruta customer objetivo: `'/my-devices/:id/edit'`.
- Verificacion del builder DSL en `DeviceCustomerEditView.vue` (ruleType, condicion/evaluacion, missing data, lifecycle, action email).
- Verificacion de validaciones previas al submit: `T <= W`, `HOLD_LAST_VALUE` con `ttlSeconds > 0`, recipients email validos.
- Verificacion de overrides v1 acotados a `threshold` y `email.recipients`.
- Verificacion de `create-from-device` con contrato tipado y serializacion compatible backend.
- Verificacion de no-regresion TypeScript no-demo contra baseline.

### 1.2 No incluye
- Cambios de codigo de producto.
- E2E visual automatizado.
- Pruebas de performance.

---

## 2) Pre-requisitos
- Ejecutar desde raiz del repo.
- Herramientas: `rg`, `node`, `npm`.
- Opcional: API en `http://localhost:5220`, `sqlcmd`.

Variables esperadas:
- `DRY_RUN` (`1` default)
- `FRONTEND_DIR` (`telemetric-front` default)
- `API_BASE_URL` (`http://localhost:5220` default)
- `API_AUTH_TOKEN` (opcional; si falta, `run` intenta auto-login)
- `API_USER` (`vcsoft` default, override permitido)
- `API_PASSWORD` (`123456` default, override permitido)
- `SQLCMD_ARGS` (`-S . -d TelemetricDb -U sa -P sa -C` default)
- `TEST_RULE_TEMPLATE_VERSION_ID` (opcional; autodiscovery)
- `TEST_DEVICE_IDS` (opcional; autodiscovery)

Baseline no-regresion:
- `baseline.json`
  - `scope: no-demo`
  - `ts_errors: 118`
  - `date: 2026-02-20`

---

## 2.5) Descubrimiento (fuentes y evidencia)

### Objetivo inferido (mandatorio)
- Fuente: `contexto/work/features/acciones_modulo/02_plans/ACT-005.plan.md`
- Seccion: `Fase 4`
- Objetivo inferido: "Alinear flujo Device Detail customer (`/my-devices/:id/edit`) con el mismo builder/contrato DSL de ACT-005."

### Docker compose detectados
- `telemetric-hub/kiss/scripts/docker-compose.yml`
- `telemetric-api/old/docker-compose.yml`
- Decision: usar `telemetric-hub/kiss/scripts/docker-compose.yml` como compose operativo; `telemetric-api/old/docker-compose.yml` se considera legado.

### API base URL y runtime
- `http://localhost:5220`
- Evidencia: `telemetric-api/src/Telemetric.Api/Properties/launchSettings.json`

### Endpoints/policies relacionados
- `POST /api/v1/actions/assignments/create-from-device` + `Policies(PermissionClaims.Actions.Assign)`
  - `telemetric-api/src/Telemetric.Api/Features/Actions/Assignments/CreateRuleFromDevice/CreateRuleFromDeviceEndpoint.cs`
- Login auto-token:
  - `POST /api/v1/auth/login`
  - `telemetric-api/src/Telemetric.Api/Features/Auth/Login/LoginEndpoint.cs`

### Builder/rutas/contratos verificados
- `telemetric-front/src/router/MainRoutes.ts`
  - `path: '/my-devices/:id/edit'`
- `telemetric-front/src/features/customer/devices/views/DeviceCustomerEditView.vue`
  - `validateAndBuildDefinition`
  - `buildOverrides`
  - `durationSeconds no puede ser mayor que windowSeconds.`
  - `ttlSeconds invalido para HOLD_LAST_VALUE.`
  - `Debe ingresar al menos un destinatario.`
  - `Email invalido:`
  - `threshold override invalido.`
  - `Email override invalido:`
  - `permissions?.includes('Actions.Assign')`
- `telemetric-front/src/features/actions/types.ts`
  - `RuleDefinitionV1`
  - `RuleInstanceOverridesV1`
  - `CreateRuleFromDeviceRequest`
- `telemetric-front/src/features/actions/actions.service.ts`
  - `createRuleFromDevice`
  - `/actions/assignments/create-from-device`
  - serializacion `JSON.stringify(payload.definitionJson)` y `JSON.stringify(payload.overridesJson)`
- `contexto/openapi/actions.yaml`
  - `/api/v1/actions/assignments/create-from-device`
  - `DefinitionJsonV1`
  - `RuleInstanceOverridesV1`

### Scripts/comandos base
- `rg --line-number -F "path: '/my-devices/:id/edit'" telemetric-front/src/router/MainRoutes.ts`
- `rg --line-number -F "validateAndBuildDefinition" telemetric-front/src/features/customer/devices/views/DeviceCustomerEditView.vue`
- `rg --line-number -F "buildOverrides" telemetric-front/src/features/customer/devices/views/DeviceCustomerEditView.vue`
- `rg --line-number -F "durationSeconds no puede ser mayor que windowSeconds." telemetric-front/src/features/customer/devices/views/DeviceCustomerEditView.vue`
- `rg --line-number -F "ttlSeconds invalido para HOLD_LAST_VALUE." telemetric-front/src/features/customer/devices/views/DeviceCustomerEditView.vue`
- `rg --line-number -F "Debe ingresar al menos un destinatario." telemetric-front/src/features/customer/devices/views/DeviceCustomerEditView.vue`
- `rg --line-number -F "createRuleFromDevice" telemetric-front/src/features/customer/devices/views/DeviceCustomerEditView.vue telemetric-front/src/features/actions/actions.service.ts`
- `rg --line-number -F "DefinitionJsonV1" contexto/openapi/actions.yaml`
- `npm --prefix telemetric-front run typecheck`

---

## 3) Setup
1. Ejecutar `scripts/setup.ps1` o `scripts/setup.sh`.
2. Confirmar prerequisitos/discovery.
3. Confirmar logs en `evidence/commands.log` y `evidence/outputs.log`.

## 4) Run
1. Ejecutar `scripts/run.ps1` o `scripts/run.sh`.
2. Validar builder/validaciones/overrides/ruta y contratos de fase 04.
3. Si `API_AUTH_TOKEN` no existe, intentar auto-login.
4. Si faltan IDs, intentar autodiscovery por `sqlcmd`.

## 5) Teardown
- No-op seguro.
- Regla de cierre: toda instancia levantada en QA debe apagarse y verificarse detenida.

## 6) Evidencia
- `evidence/commands.log`
- `evidence/outputs.log`
- `evidence/notes.md`

## 7) Resultados esperados (PASS)
- `/my-devices/:id/edit` mantiene flujo customer con builder DSL canonico ACT-005.
- `create-from-device` reutiliza contrato tipado y serializacion compatible backend.
- Overrides v1 quedan acotados a `threshold` y `email.recipients`.
- Validaciones UI bloquean submit invalido (`durationSeconds`, `ttlSeconds`, recipients, overrides email/threshold).
- Gate no-regresion no-demo PASS (`observed <= baseline.ts_errors`).
