# QA PACK - acciones-modulo-act-006-phase-04

## 0) Metadata
- Fecha: 2026-02-23
- Tipo: QA PACK
- Objetivo: Validar Fase 04 de ACT-006 (runs en detalle de template con aislamiento por template y consistencia de contador).
- Entorno: frontend (`telemetric-front`) + API local opcional para auto-login/evidencia.
- Autor: Codex (asistido)

## 0.1 Trazabilidad del pack
- PackDir: `contexto/work/features/acciones_modulo/04_test/ACT-006/phase-04/`
- StoryId: `ACT-006`
- Requirement: `acciones_modulo`
- PhaseId: `04`
- GeneratedAt: `2026-02-23`
- ChangePlan: `contexto/work/features/acciones_modulo/02_plans/ACT-006.plan.md`
- ChangeSummary: `contexto/work/features/acciones_modulo/03_execution/ACT-006/phase-04.md`

## 1) Alcance
### 1.1 Incluye
- Verificacion de tab `Ejecuciones` en `telemetric-front/src/features/actions/views/ActionTemplateDetailView.vue`.
- Verificacion de consumo tipado por template via `actionsService.getTemplateRuns` y `TemplateActionRunsQueryParams`.
- Verificacion de estados UX (`error/empty/success`) en detalle de template.
- Verificacion de render de error legible para filas `Fail`.
- Verificacion de consistencia backend de `failedRunsCount` contra filtros de soft-delete/tenant en:
  - `telemetric-api/src/Telemetric.Api/Features/Actions/Templates/GetTemplateById/GetTemplateByIdQueryHandler.cs`
- Gate no-regresion no-demo de typecheck (cuando `DRY_RUN=0`).

### 1.2 No incluye
- Cambios de codigo de producto.
- Provisioning de infraestructura.
- Pruebas de carga/performance.

## 2) Pre-requisitos
- Ejecutar desde raiz del repo.
- Herramientas: `rg`.
- Opcional: `node`, `npm`, `curl`, `jq`, `sqlcmd`.

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
- `BASELINE_TS_ERRORS` (opcional; baseline no-demo para gate numerico)

## 2.5) Descubrimiento (fuentes y evidencia)

### Objetivo inferido (mandatorio)
- Fuente: `contexto/work/features/acciones_modulo/02_plans/ACT-006.plan.md`
- Seccion: `Fase 4`
- Objetivo inferido: "Completar Runs en detalle de template (`/actions/templates/:id`) con aislamiento por template."

### Docker compose detectados
- `telemetric-hub/kiss/scripts/docker-compose.yml`
- `telemetric-api/old/docker-compose.yml`
- Decision: usar `telemetric-hub/kiss/scripts/docker-compose.yml` como compose operativo; `telemetric-api/old/docker-compose.yml` se mantiene como legado.

### API base URL y runtime
- `http://localhost:5220`
- Evidencia: `telemetric-api/src/Telemetric.Api/Properties/launchSettings.json`

### Endpoints/policies relacionados
- `GET /api/v1/actions/templates/{RuleTemplateId}/runs`
  - `telemetric-api/src/Telemetric.Api/Features/Actions/Templates/GetTemplateRuns/GetTemplateRunsEndpoint.cs`
- `GET /api/v1/actions/templates/{RuleTemplateId}`
  - `telemetric-api/src/Telemetric.Api/Features/Actions/Templates/GetTemplateById/GetTemplateByIdEndpoint.cs`
- Policy esperada:
  - `Policies(PermissionClaims.Actions.View)`

### Fuentes frontend verificadas
- Vista detalle:
  - `telemetric-front/src/features/actions/views/ActionTemplateDetailView.vue`
- Servicio tipado:
  - `telemetric-front/src/features/actions/actions.service.ts`
- Contratos:
  - `telemetric-front/src/features/actions/types.ts`

### Fuente backend de consistencia conteo/detalle
- `telemetric-api/src/Telemetric.Api/Features/Actions/Templates/GetTemplateById/GetTemplateByIdQueryHandler.cs`
  - filtro `StatusFail`
  - filtro de soft-delete en `ActionAttempt/RuleInstance/RuleTemplateVersion/RuleTemplate`
  - filtro tenant por `ClientId`

### Scripts/comandos base
- `rg --line-number -F -e "<v-tab value=\"runs\">Ejecuciones</v-tab>" -e "runsErrorMessage" -e "No se pudieron cargar las ejecuciones del template." telemetric-front/src/features/actions/views/ActionTemplateDetailView.vue`
- `rg --line-number -F -e "hasRunsLoaded" -e "runsTotalItems === 0" -e "No hay ejecuciones para el template seleccionado." telemetric-front/src/features/actions/views/ActionTemplateDetailView.vue`
- `rg --line-number -F -e "item.status === 'Fail'" -e "Fallo sin detalle de error." telemetric-front/src/features/actions/views/ActionTemplateDetailView.vue`
- `rg --line-number -F -e "getTemplateRuns:" -e "TemplateActionRunsQueryParams" telemetric-front/src/features/actions/actions.service.ts telemetric-front/src/features/actions/types.ts`
- `rg --line-number -F -e "failedRunsCount" telemetric-front/src/features/actions/views/ActionTemplateDetailView.vue telemetric-front/src/features/actions/types.ts telemetric-api/src/Telemetric.Api/Features/Actions/Templates/GetTemplateById/GetTemplateByIdQueryHandler.cs`
- `rg --line-number -F -e "attempt.Status == ActionAttempt.StatusFail" -e "attempt.RuleInstance.RuleTemplateVersion.RuleTemplateId == template.RuleTemplateId" -e "attempt.RuleInstance.RuleTemplateVersion.RuleTemplate.ClientId == _currentUserService.ClientId.Value" telemetric-api/src/Telemetric.Api/Features/Actions/Templates/GetTemplateById/GetTemplateByIdQueryHandler.cs`
- `npm --prefix telemetric-front run typecheck`

## 3) Setup
1. Ejecutar `scripts/setup.ps1` o `scripts/setup.sh`.
2. Confirmar prerequisitos/discovery de fase.
3. Confirmar que se escribio evidencia en:
- `evidence/commands.log`
- `evidence/outputs.log`

## 4) Run
1. Ejecutar `scripts/run.ps1` o `scripts/run.sh`.
2. Validar checks funcionales de fase 04 (runs en detalle + contrato tipado + consistencia backend).
3. Si `API_AUTH_TOKEN` no existe, intentar auto-login.
4. Si faltan IDs de prueba, intentar autodiscovery por `sqlcmd`.
5. Ejecutar gate no-regresion no-demo (si `DRY_RUN=0` y hay `npm`).

## 5) Teardown
- No-op seguro.
- Regla de cierre: toda instancia levantada en QA debe apagarse y verificarse detenida.

## 6) Evidencia
- `evidence/commands.log`
- `evidence/outputs.log`
- `evidence/notes.md`

## 7) Resultados esperados (PASS)
- Tab `Ejecuciones` en detalle de template visible y funcional.
- Consulta de runs usa endpoint por template y no mezcla contexto global.
- Estados UX `error/empty/success` presentes para runs del detalle.
- Filas `Fail` muestran error legible con fallback.
- `failedRunsCount` backend filtra `StatusFail`, respeta tenant y soft-delete.
- Typecheck no-demo sin incremento frente a baseline (si baseline fue provisto).
