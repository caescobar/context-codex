# QA PACK - acciones-modulo-act-007-phase-01

## 0) Metadata
- Fecha: 2026-02-23
- Tipo: QA PACK
- Objetivo: Validar Fase 01 de ACT-007 (discovery/equivalence de endpoints Rules + contrato OpenAPI).
- Entorno: docs + API local opcional para auto-login/evidencia.
- Autor: Codex (asistido)

## 0.1 Trazabilidad del pack
- PackDir: `contexto/work/features/acciones_modulo/04_test/ACT-007/phase-01/`
- StoryId: `ACT-007`
- Requirement: `acciones_modulo`
- PhaseId: `01`
- ChangePlan: `contexto/work/features/acciones_modulo/02_plans/ACT-007.plan.md`
- ChangeSummary: `contexto/work/features/acciones_modulo/03_execution/ACT-007/phase-01.md`

## 1) Alcance
### 1.1 Incluye
- Verificacion de equivalence gate para endpoints Rules faltantes en backend:
  - `GET /api/v1/actions/rules`
  - `GET /api/v1/actions/devices/{deviceId}/rules`
  - `PATCH /api/v1/actions/rules/{ruleInstanceId}/state`
- Verificacion del contrato OpenAPI de Rules en `contexto/openapi/actions.yaml`.
- Verificacion de payload esperado para badge rojo por ultimo fail:
  - `ruleInstanceId`, `isPaused`, `operationalStatus`, `hasLastAttemptFail`, `lastAttemptStatus`, `lastAttemptedAt`.
- Verificacion de versionado `/api/v1`, tags y policies (`Actions.View`, `Actions.Update`).
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
- Seccion: `Fase 1`
- Objetivo inferido: "Cerrar discovery/equivalence para endpoints de Rules (listados + toggle) y definir delta OpenAPI de ACT-007."

### Docker compose detectados
- `telemetric-hub/kiss/scripts/docker-compose.yml`
- `telemetric-api/old/docker-compose.yml`
- Decision: usar `telemetric-hub/kiss/scripts/docker-compose.yml` por ser compose operativo actual y no legacy.

### API base URL y runtime
- `http://localhost:5220`
- Evidencia: `telemetric-api/src/Telemetric.Api/Properties/launchSettings.json`

### Endpoints/policies
- Endpoints Actions existentes (muestra):
  - `GET /api/v1/actions/runs`
  - `GET /api/v1/actions/templates/{RuleTemplateId}/runs`
  - `POST /api/v1/actions/rules/{RuleInstanceId}/resolve-manual`
  - Evidencia: `telemetric-api/src/Telemetric.Api/Features/Actions/Runs/GetRuns/GetRunsEndpoint.cs`, `telemetric-api/src/Telemetric.Api/Features/Actions/Templates/GetTemplateRuns/GetTemplateRunsEndpoint.cs`, `telemetric-api/src/Telemetric.Api/Features/Actions/ResolveManual/ResolveManualEndpoint.cs`
- Claims backend:
  - `Actions.View`
  - `Actions.Update`
  - Evidencia: `telemetric-api/src/Telemetric.Api/Domain/Constants/PermissionClaims.cs`
- Contrato OpenAPI ACT-007:
  - `GET /api/v1/actions/rules`
  - `GET /api/v1/actions/devices/{deviceId}/rules`
  - `PATCH /api/v1/actions/rules/{ruleInstanceId}/state`
  - `x-required-policy: Actions.View` y `x-required-policy: Actions.Update`
  - Evidencia: `contexto/openapi/actions.yaml`
- Gate equivalence:
  - Esta fase valida ausencia de endpoints backend equivalentes para los tres contratos Rules anteriores.

### Scripts/comandos base
- `rg --line-number -F -e "/api/v1/actions/rules:" contexto/openapi/actions.yaml`
- `rg --line-number -F -e "/api/v1/actions/devices/{deviceId}/rules:" contexto/openapi/actions.yaml`
- `rg --line-number -F -e "/api/v1/actions/rules/{ruleInstanceId}/state:" contexto/openapi/actions.yaml`
- `rg --line-number -F -e "x-required-policy: Actions.View" -e "x-required-policy: Actions.Update" contexto/openapi/actions.yaml`
- `rg --line-number -F -e "GetRulesResponse" -e "RuleListItem" -e "RuleOperationalStatus" -e "UpdateRuleStateRequest" -e "UpdateRuleStateResponse" contexto/openapi/actions.yaml`
- `rg --line-number -g "*Endpoint.cs" -e "Get\\(\"/api/v1/actions/rules\"\\)" -e "Get\\(\"/api/v1/actions/devices/\\{deviceId\\}/rules\"\\)" -e "Patch\\(\"/api/v1/actions/rules/\\{ruleInstanceId\\}/state\"\\)" telemetric-api/src/Telemetric.Api/Features/Actions`
- `npm --prefix telemetric-front run typecheck`

## 3) Setup
1. Ejecutar `scripts/setup.ps1` o `scripts/setup.sh`.
2. Confirmar prerequisitos y discovery base.
3. Confirmar logs en `evidence/commands.log` y `evidence/outputs.log`.

## 4) Run
1. Ejecutar `scripts/run.ps1` o `scripts/run.sh`.
2. Validar equivalence gate + contrato OpenAPI + policy/versionado.
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
- Discovery confirma ausencia de endpoint backend equivalente para list global/device y toggle state de Rules.
- OpenAPI define las tres rutas de Rules con versionado `/api/v1`.
- Contrato incluye estado operacional y senal de badge rojo por ultimo fail.
- Policies `Actions.View`/`Actions.Update` quedan trazadas.
- Typecheck no-demo sin incremento frente a baseline (si baseline fue provisto).
