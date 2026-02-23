# QA PACK - acciones-modulo-act-005-phase-03

## 0) Metadata
- Fecha: 2026-02-20
- Tipo: QA PACK
- Objetivo: Validar Fase 03 de ACT-005 (reemplazo de textarea JSON por builder guiado en `/actions` con validaciones pre-submit).
- Entorno: frontend (`telemetric-front`) + API local opcional para auto-login/evidencia.
- Autor: Codex (asistido)

## 0.1 Trazabilidad del pack
- PackDir: `contexto/work/features/acciones_modulo/04_test/ACT-005/phase-03/`
- StoryId: `ACT-005`
- Requirement: `acciones_modulo`
- PhaseId: `03`
- ChangePlan: `contexto/work/features/acciones_modulo/02_plans/ACT-005.plan.md`
- ChangeSummary: `contexto/work/features/acciones_modulo/03_execution/ACT-005/phase-03.md`

---

## 1) Alcance
### 1.1 Incluye
- Verificacion de builder guiado en `ActionsTemplatesView.vue` para 5 `ruleType`.
- Verificacion de validaciones UI (`durationSeconds <= windowSeconds`, `ttlSeconds` para `HOLD_LAST_VALUE`, recipients email).
- Verificacion de UX base (`UiDynamicFilter`, `UiServerTable`, copy de error/estado).
- Verificacion de rutas/permisos de `/actions` y menu.
- Verificacion de contratos tipados en `types.ts`.
- Gate no-regresion TypeScript no-demo contra baseline.

### 1.2 No incluye
- Cambios de codigo de producto.
- Pruebas de performance.
- Provisioning de entorno.

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
  - `ts_errors: 240`
  - `date: 2026-02-20`

---

## 2.5) Descubrimiento (fuentes y evidencia)

### Objetivo inferido (mandatorio)
- Fuente: `contexto/work/features/acciones_modulo/02_plans/ACT-005.plan.md`
- Seccion: `Fase 3`
- Objetivo inferido: "Reemplazar textarea JSON en `/actions` por builder guiado con validaciones previas al submit."

### Docker compose detectados
- `telemetric-hub/kiss/scripts/docker-compose.yml`
- `telemetric-api/old/docker-compose.yml`
- Decision: usar `telemetric-hub/kiss/scripts/docker-compose.yml` como compose operativo; `telemetric-api/old/docker-compose.yml` es legado.

### API base URL y runtime
- `http://localhost:5220`
- Evidencia: `telemetric-api/src/Telemetric.Api/Properties/launchSettings.json`

### Endpoints/policies relacionados
- `POST /api/v1/actions/templates` + `Policies(PermissionClaims.Actions.Create)`
  - `telemetric-api/src/Telemetric.Api/Features/Actions/Templates/CreateTemplate/CreateTemplateEndpoint.cs`
- `PUT /api/v1/actions/templates/{ruleTemplateId}` + `Policies(PermissionClaims.Actions.Update)`
  - `telemetric-api/src/Telemetric.Api/Features/Actions/Templates/UpdateTemplate/UpdateTemplateEndpoint.cs`
- `POST /api/v1/actions/assignments/template-version` + `Policies(PermissionClaims.Actions.Assign)`
  - `telemetric-api/src/Telemetric.Api/Features/Actions/Assignments/AssignTemplateToDevices/AssignTemplateToDevicesEndpoint.cs`
- Login auto-token:
  - `POST /api/v1/auth/login`
  - `telemetric-api/src/Telemetric.Api/Features/Auth/Login/LoginEndpoint.cs`

### Builder/rutas/contratos verificados
- `telemetric-front/src/features/actions/views/ActionsTemplatesView.vue`
  - `validateAndBuild`
  - `durationSeconds no puede ser mayor que windowSeconds.`
  - `ttlSeconds invalido para HOLD_LAST_VALUE.`
  - `Debe ingresar al menos un destinatario.`
- `telemetric-front/src/features/actions/types.ts`
  - `RuleType`, `RuleDefinitionV1`
- `telemetric-front/src/features/actions/actions.service.ts`
- `telemetric-front/src/features/actions/actions.routes.ts`
  - `path: '/actions'`
  - `requiresPermission: 'Actions.View'`
- `telemetric-front/src/layouts/menuItems.ts`
  - item `Acciones` hacia `/actions` con `Actions.View`

### Scripts/comandos base
- `rg --line-number -F "validateAndBuild" telemetric-front/src/features/actions/views/ActionsTemplatesView.vue`
- `rg --line-number -F "durationSeconds no puede ser mayor que windowSeconds." telemetric-front/src/features/actions/views/ActionsTemplatesView.vue`
- `rg --line-number -F "ttlSeconds invalido para HOLD_LAST_VALUE." telemetric-front/src/features/actions/views/ActionsTemplatesView.vue`
- `rg --line-number -F "Debe ingresar al menos un destinatario." telemetric-front/src/features/actions/views/ActionsTemplatesView.vue`
- `rg --line-number -F "path: '/actions'" telemetric-front/src/features/actions/actions.routes.ts`
- `rg --line-number -F "requiresPermission: 'Actions.View'" telemetric-front/src/features/actions/actions.routes.ts telemetric-front/src/layouts/menuItems.ts`
- `npm --prefix telemetric-front run typecheck`

---

## 3) Setup
1. Ejecutar `scripts/setup.ps1` o `scripts/setup.sh`.
2. Confirmar prerequisitos/discovery.
3. Confirmar logs en `evidence/commands.log` y `evidence/outputs.log`.

## 4) Run
1. Ejecutar `scripts/run.ps1` o `scripts/run.sh`.
2. Validar builder, reglas UI, rutas/permisos, typecheck no-demo y evidencia.
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
- Builder cubre 5 `ruleType` sin editar JSON manual.
- UI bloquea submit invalido (`durationSeconds`, `ttlSeconds`, recipients).
- Ruta `/actions` y menu `Acciones` exigen `Actions.View`.
- `types.ts` mantiene contrato `RuleDefinitionV1`.
- Gate no-regresion no-demo PASS (`observed <= baseline.ts_errors`).
