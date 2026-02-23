# QA PACK - acciones-modulo-act-007-phase-02

## 0) Metadata
- Fecha: 2026-02-23
- Tipo: QA PACK
- Objetivo: Validar Fase 02 de ACT-007 (backend Rules: listado global/device + toggle de estado).
- Entorno: API local (`telemetric-api`) + frontend para gate no-regresion (`telemetric-front`).
- Autor: Codex (asistido)

## 0.1 Trazabilidad del pack
- PackDir: `contexto/work/features/acciones_modulo/04_test/ACT-007/phase-02/`
- StoryId: `ACT-007`
- Requirement: `acciones_modulo`
- PhaseId: `02`
- RegeneratedAt: `2026-02-23`
- ChangePlan: `contexto/work/features/acciones_modulo/02_plans/ACT-007.plan.md`
- ChangeSummary: `contexto/work/features/acciones_modulo/03_execution/ACT-007/phase-02.md`

## 1) Alcance
### 1.1 Incluye
- Verificacion de endpoints backend:
  - `GET /api/v1/actions/rules`
  - `PATCH /api/v1/actions/rules/{ruleInstanceId}/state`
- Verificacion de semantica del listado Rules:
  - alcance por tenant (`ClientId`)
  - filtro opcional por `deviceId`
  - filtro por `status` (`Enabled`/`Paused`)
  - calculo de badge rojo por ultimo intento (`hasLastAttemptFail`, `lastAttemptStatus`, `lastAttemptedAt`)
- Verificacion de persistencia de toggle de estado (`IsPaused`) y audit (`UpdatedAt`, `UpdatedBy`).
- Verificacion de contrato OpenAPI de Rules y policies (`Actions.View`, `Actions.Update`) en `contexto/openapi/actions.yaml`.
- Gate no-regresion de typecheck frontend no-demo.

### 1.2 No incluye
- Cambios de codigo de producto.
- Provisioning de infraestructura.
- Pruebas de performance.

## 2) Pre-requisitos
- Ejecutar desde raiz del repo.
- Herramientas: `rg`.
- Opcional: `node`, `npm`, `sqlcmd`, API local en `http://localhost:5220`.

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
- `BASELINE_TS_ERRORS` (opcional; baseline no-demo para gate de no-regresion)

## 2.5) Descubrimiento (fuentes y evidencia)

### Objetivo inferido (mandatorio)
- Fuente: `contexto/work/features/acciones_modulo/02_plans/ACT-007.plan.md`
- Seccion: `Fase 2`
- Objetivo inferido: "Implementar backend de Rules para ACT-007 (listado global/device + toggle estado)."

### Docker compose detectados
- `telemetric-hub/kiss/scripts/docker-compose.yml`
- `telemetric-api/old/docker-compose.yml`
- Decision: usar `telemetric-hub/kiss/scripts/docker-compose.yml` por ser compose operativo actual; `telemetric-api/old/docker-compose.yml` se considera legacy.

### API base URL y runtime
- `http://localhost:5220`
- Evidencia: `telemetric-api/src/Telemetric.Api/Properties/launchSettings.json`

### Endpoints/policies
- Endpoint listado Rules:
  - `GET /api/v1/actions/rules`
  - Evidencia: `telemetric-api/src/Telemetric.Api/Features/Actions/Rules/GetRules/GetRulesEndpoint.cs`
- Endpoint toggle Rules:
  - `PATCH /api/v1/actions/rules/{ruleInstanceId}/state`
  - Evidencia: `telemetric-api/src/Telemetric.Api/Features/Actions/Rules/UpdateRuleState/UpdateRuleStateEndpoint.cs`
- Policies backend:
  - `Policies(PermissionClaims.Actions.View)`
  - `Policies(PermissionClaims.Actions.Update)`
  - Evidencia: endpoints anteriores + `telemetric-api/src/Telemetric.Api/Domain/Constants/PermissionClaims.cs`
- Semantica backend (query/command):
  - tenant scope por `ClientId`
  - filtro opcional `DeviceId`, filtro `Status`
  - badge rojo por ultimo `ActionAttempt`
  - persistencia de `IsPaused` con `SaveChangesAsync`
  - Evidencia: `telemetric-api/src/Telemetric.Api/Features/Actions/Rules/GetRules/GetRulesQueryHandler.cs`, `telemetric-api/src/Telemetric.Api/Features/Actions/Rules/UpdateRuleState/UpdateRuleStateCommandHandler.cs`
- Contrato OpenAPI Rules:
  - `/api/v1/actions/rules`
  - `/api/v1/actions/devices/{deviceId}/rules`
  - `/api/v1/actions/rules/{ruleInstanceId}/state`
  - Esquemas: `GetRulesResponse`, `RuleListItem`, `UpdateRuleStateRequest`, `UpdateRuleStateResponse`
  - Evidencia: `contexto/openapi/actions.yaml`

### Scripts/comandos base
- `rg --line-number -F -e '/api/v1/actions/rules:' -e '/api/v1/actions/devices/{deviceId}/rules:' -e '/api/v1/actions/rules/{ruleInstanceId}/state:' contexto/openapi/actions.yaml`
- `rg --line-number -F -e 'Get("/api/v1/actions/rules")' telemetric-api/src/Telemetric.Api/Features/Actions/Rules/GetRules/GetRulesEndpoint.cs`
- `rg --line-number -F -e 'Patch("/api/v1/actions/rules/{RuleInstanceId}/state")' telemetric-api/src/Telemetric.Api/Features/Actions/Rules/UpdateRuleState/UpdateRuleStateEndpoint.cs`
- `rg --line-number -F -e 'Policies(PermissionClaims.Actions.View)' -e 'Policies(PermissionClaims.Actions.Update)' telemetric-api/src/Telemetric.Api/Features/Actions/Rules/GetRules/GetRulesEndpoint.cs telemetric-api/src/Telemetric.Api/Features/Actions/Rules/UpdateRuleState/UpdateRuleStateEndpoint.cs`
- `rg --line-number -F -e 'DeviceId' -e 'Status' -e 'ClientId' -e 'ActionAttempts' -e 'StatusFail' telemetric-api/src/Telemetric.Api/Features/Actions/Rules/GetRules/GetRulesQueryHandler.cs`
- `rg --line-number -F -e 'SaveChangesAsync' -e 'UpdatedAt' -e 'UpdatedBy' -e 'ClientId' telemetric-api/src/Telemetric.Api/Features/Actions/Rules/UpdateRuleState/UpdateRuleStateCommandHandler.cs`
- `npm --prefix telemetric-front run typecheck`

## 3) Setup
1. Ejecutar `scripts/setup.ps1` o `scripts/setup.sh`.
2. Confirmar prerequisitos y presencia de artefactos target fase 02.
3. Confirmar logs en `evidence/commands.log` y `evidence/outputs.log`.

## 4) Run
1. Ejecutar `scripts/run.ps1` o `scripts/run.sh`.
2. Validar endpoints/handlers de Rules, tenant scope, filtros y semantica de badge rojo.
3. Si `API_AUTH_TOKEN` no existe, intentar auto-login.
4. Si faltan IDs, intentar autodiscovery por `sqlcmd`.
5. Ejecutar gate no-regresion no-demo (si `DRY_RUN=0` y hay `npm`).

## 5) Teardown
- No-op seguro.
- Regla de cierre: toda instancia levantada en QA debe apagarse y verificarse detenida.

## 6) Evidencia
- `evidence/commands.log`
- `evidence/outputs.log`
- `evidence/notes.md`

## 7) Resultados esperados (PASS)
- Endpoints backend de Rules existen y usan policies esperadas.
- Query de listado aplica tenant scope, filtros `deviceId/status` y calcula senal de ultimo intento fallido.
- Toggle de estado persiste `IsPaused` y audit fields.
- Contrato OpenAPI de Rules y toggle permanece trazable.
- Typecheck no-demo sin incremento frente a baseline (si baseline fue provisto).
