# QA PACK - acciones-modulo-act-006-phase-02

## 0) Metadata
- Fecha: 2026-02-23
- Tipo: QA PACK
- Objetivo: Validar Fase 02 de ACT-006 (implementacion backend de runs global/template con filtros tenant/contexto).
- Entorno: API local (`telemetric-api`) + frontend para gate no-regresion (`telemetric-front`).
- Autor: Codex (asistido)

## 0.1 Trazabilidad del pack
- PackDir: `contexto/work/features/acciones_modulo/04_test/ACT-006/phase-02/`
- StoryId: `ACT-006`
- Requirement: `acciones_modulo`
- PhaseId: `02`
- RegeneratedAt: `2026-02-23`
- ChangePlan: `contexto/work/features/acciones_modulo/02_plans/ACT-006.plan.md`
- ChangeSummary: `contexto/work/features/acciones_modulo/03_execution/ACT-006/phase-02.md`

## 1) Alcance
### 1.1 Incluye
- Verificacion de endpoints backend:
  - `GET /api/v1/actions/runs`
  - `GET /api/v1/actions/templates/{RuleTemplateId}/runs`
- Verificacion de handlers read-only de runs:
  - tenant scope por `ClientId`
  - separacion de contexto global/template
  - fuente de verdad `ActionAttempt`
  - orden por intento mas reciente
- Verificacion de policy `Actions.View` y prefijo `/api/v1`.
- Verificacion de contrato OpenAPI de runs global/template en `contexto/openapi/actions.yaml`.
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
- Seccion: `Fase 2`
- Objetivo inferido: "Implementar backend de consulta de runs (global y por template) con filtros por tenant/contexto."

### Docker compose detectados
- `telemetric-hub/kiss/scripts/docker-compose.yml`
- `telemetric-api/old/docker-compose.yml`
- Decision: usar `telemetric-hub/kiss/scripts/docker-compose.yml` por ser compose operativo actual; `telemetric-api/old/docker-compose.yml` queda como legado.

### API base URL y runtime
- `http://localhost:5220`
- Evidencia: `telemetric-api/src/Telemetric.Api/Properties/launchSettings.json`

### Endpoints/policies
- Endpoints target fase 02 (implementacion esperada):
  - `GET /api/v1/actions/runs`
    - evidencia de ruta/policy en: `telemetric-api/src/Telemetric.Api/Features/Actions/Runs/GetRuns/GetRunsEndpoint.cs`
  - `GET /api/v1/actions/templates/{RuleTemplateId}/runs`
    - evidencia de ruta/policy en: `telemetric-api/src/Telemetric.Api/Features/Actions/Templates/GetTemplateRuns/GetTemplateRunsEndpoint.cs`
- Handlers target fase 02 (implementacion esperada):
  - `telemetric-api/src/Telemetric.Api/Features/Actions/Runs/GetRuns/GetRunsQueryHandler.cs`
  - `telemetric-api/src/Telemetric.Api/Features/Actions/Templates/GetTemplateRuns/GetTemplateRunsQueryHandler.cs`
- Policy de lectura:
  - `Policies(PermissionClaims.Actions.View)` en ambos endpoints target.
- Contrato OpenAPI:
  - rutas en `contexto/openapi/actions.yaml` para runs global y por template.

### Scripts/comandos base
- `rg --line-number -F -e "/api/v1/actions/runs:" -e "/api/v1/actions/templates/{ruleTemplateId}/runs:" contexto/openapi/actions.yaml`
- `rg --line-number -F -e "Get(\"/api/v1/actions/runs\")" telemetric-api/src/Telemetric.Api/Features/Actions/Runs/GetRuns/GetRunsEndpoint.cs`
- `rg --line-number -F -e "Get(\"/api/v1/actions/templates/{RuleTemplateId}/runs\")" telemetric-api/src/Telemetric.Api/Features/Actions/Templates/GetTemplateRuns/GetTemplateRunsEndpoint.cs`
- `rg --line-number -F -e "Policies(PermissionClaims.Actions.View)" telemetric-api/src/Telemetric.Api/Features/Actions/Runs/GetRuns/GetRunsEndpoint.cs telemetric-api/src/Telemetric.Api/Features/Actions/Templates/GetTemplateRuns/GetTemplateRunsEndpoint.cs`
- `rg --line-number -F -e "_context.ActionAttempts" -e ".AsNoTracking()" -e "OrderByDescending" telemetric-api/src/Telemetric.Api/Features/Actions/Runs/GetRuns/GetRunsQueryHandler.cs telemetric-api/src/Telemetric.Api/Features/Actions/Templates/GetTemplateRuns/GetTemplateRunsQueryHandler.cs`
- `rg --line-number -F -e "ClientId" telemetric-api/src/Telemetric.Api/Features/Actions/Runs/GetRuns/GetRunsQueryHandler.cs telemetric-api/src/Telemetric.Api/Features/Actions/Templates/GetTemplateRuns/GetTemplateRunsQueryHandler.cs`
- `npm --prefix telemetric-front run typecheck`

## 3) Setup
1. Ejecutar `scripts/setup.ps1` o `scripts/setup.sh`.
2. Confirmar prerequisitos y presencia de artefactos target fase 02.
3. Confirmar logs en `evidence/commands.log` y `evidence/outputs.log`.

## 4) Run
1. Ejecutar `scripts/run.ps1` o `scripts/run.sh`.
2. Validar endpoints/handlers de runs, filtros tenant/contexto, orden y contrato OpenAPI.
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
- Endpoints backend de runs global/template existen y usan `Actions.View`.
- Queries de runs usan `ActionAttempt` como fuente, `AsNoTracking`, tenant scope y orden descendente por fecha de intento.
- Endpoint por template filtra por `RuleTemplateId` y no mezcla contexto global/template.
- Contrato OpenAPI de runs global/template permanece alineado a payload esperado.
- Typecheck no-demo sin incremento frente a baseline (si baseline fue provisto).
