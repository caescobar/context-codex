# QA PACK - acciones-modulo-act-006-phase-01

## 0) Metadata
- Fecha: 2026-02-20
- Tipo: QA PACK
- Objetivo: Validar Fase 01 de ACT-006 (discovery/equivalence de endpoints Runs + contrato OpenAPI).
- Entorno: docs + API local opcional para auto-login/evidencia.
- Autor: Codex (asistido)

## 0.1 Trazabilidad del pack
- PackDir: `contexto/work/features/acciones_modulo/04_test/ACT-006/phase-01/`
- StoryId: `ACT-006`
- Requirement: `acciones_modulo`
- PhaseId: `01`
- ChangePlan: `contexto/work/features/acciones_modulo/02_plans/ACT-006.plan.md`
- ChangeSummary: `contexto/work/features/acciones_modulo/03_execution/ACT-006/phase-01.md`

## 1) Alcance
### 1.1 Incluye
- Verificacion de ausencia de endpoint equivalente de runs en `telemetric-api/src/Telemetric.Api/Features/Actions/*`.
- Verificacion de contrato OpenAPI para runs global y por template en `contexto/openapi/actions.yaml`.
- Verificacion de payload esperado: `status`, `error`, `attemptedAt`, `ruleInstanceId`, `context`.
- Verificacion de versionado `/api/v1` y policy `Actions.View`.
- Gate no-regresion de typecheck frontend no-demo.

### 1.2 No incluye
- Cambios de codigo de producto.
- Provisioning de infraestructura.
- Ejecucion de pruebas de performance.

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
- Fuente: `contexto/work/features/acciones_modulo/02_plans/ACT-006.plan.md`
- Seccion: `Fase 1`
- Objetivo inferido: "Cerrar discovery/equivalence de endpoints para Runs y definir delta OpenAPI de ACT-006."

### Docker compose detectados
- `telemetric-hub/kiss/scripts/docker-compose.yml`
- `telemetric-api/old/docker-compose.yml`
- Decision: usar `telemetric-hub/kiss/scripts/docker-compose.yml` por ser compose operativo actual; `telemetric-api/old/docker-compose.yml` queda como legado.

### API base URL y runtime
- `http://localhost:5220`
- Evidencia: `telemetric-api/src/Telemetric.Api/Properties/launchSettings.json`

### Endpoints/policies
- Endpoints Actions existentes:
  - `GET /api/v1/actions/templates`
  - `GET /api/v1/actions/templates/{RuleTemplateId}`
  - Evidencia: `telemetric-api/src/Telemetric.Api/Features/Actions/Templates/GetTemplates/GetTemplatesEndpoint.cs`, `telemetric-api/src/Telemetric.Api/Features/Actions/Templates/GetTemplateById/GetTemplateByIdEndpoint.cs`
- Policy backend existente:
  - `Policies(PermissionClaims.Actions.View)` en endpoints de lectura de templates.
- Contrato OpenAPI ACT-006:
  - `GET /api/v1/actions/runs`
  - `GET /api/v1/actions/templates/{ruleTemplateId}/runs`
  - `x-required-policy: Actions.View`
  - Evidencia: `contexto/openapi/actions.yaml`
- Gate equivalence:
  - No hay endpoint backend implementado para runs global/template en `Features/Actions/*` al momento de esta fase.

### Scripts/comandos base
- `rg --line-number -F -e "/api/v1/actions/runs:" contexto/openapi/actions.yaml`
- `rg --line-number -F -e "/api/v1/actions/templates/{ruleTemplateId}/runs:" contexto/openapi/actions.yaml`
- `rg --line-number -F -e "x-required-policy: Actions.View" contexto/openapi/actions.yaml`
- `rg --line-number -F -e "ActionRunListItem" -e "ActionRunStatus" -e "ActionRunContext" contexto/openapi/actions.yaml`
- `rg --line-number -F -e "Policies(PermissionClaims.Actions.View)" telemetric-api/src/Telemetric.Api/Features/Actions`
- `rg --line-number -g "*.cs" -e "/api/v1/actions/runs" -e "/api/v1/actions/templates/{ruleTemplateId}/runs" telemetric-api/src/Telemetric.Api/Features/Actions`
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
- Discovery confirma ausencia de endpoint backend equivalente para runs.
- OpenAPI define rutas de runs global/template con payload alineado a `ActionAttempt`.
- Contrato incluye `status`, `error`, `attemptedAt`, `ruleInstanceId`, `context`.
- Versionado `/api/v1` y policy `Actions.View` documentados.
- Typecheck no-demo sin incremento frente a baseline (si baseline fue provisto).
