# QA PACK - acciones-modulo-act-006-phase-03

## 0) Metadata
- Fecha: 2026-02-23
- Tipo: QA PACK
- Objetivo: Validar Fase 03 de ACT-006 (tab `Runs` en `/actions` con UX canonica y contrato tipado).
- Entorno: frontend (`telemetric-front`) + API local opcional para auto-login/evidencia.
- Autor: Codex (asistido)

## 0.1 Trazabilidad del pack
- PackDir: `contexto/work/features/acciones_modulo/04_test/ACT-006/phase-03/`
- StoryId: `ACT-006`
- Requirement: `acciones_modulo`
- PhaseId: `03`
- GeneratedAt: `2026-02-23`
- ChangePlan: `contexto/work/features/acciones_modulo/02_plans/ACT-006.plan.md`
- ChangeSummary: `contexto/work/features/acciones_modulo/03_execution/ACT-006/phase-03.md`

## 1) Alcance
### 1.1 Incluye
- Verificacion de tab `Runs` en `telemetric-front/src/features/actions/views/ActionsTemplatesView.vue`.
- Verificacion de estados UX (`loading/empty/error`) para listado de runs.
- Verificacion de tabla y filtros (`UiDynamicFilter` + `UiServerTable`) para runs.
- Verificacion de contrato tipado de runs en:
  - `telemetric-front/src/features/actions/actions.service.ts`
  - `telemetric-front/src/features/actions/types.ts`
- Verificacion de enrutamiento/menu para `/actions`:
  - `telemetric-front/src/features/actions/actions.routes.ts`
  - `telemetric-front/src/layouts/menuItems.ts`
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
- Seccion: `Fase 3`
- Objetivo inferido: "Implementar tab Runs en `/actions` con UX canonica (breadcrumb/filter/server table) y contrato tipado."

### Docker compose detectados
- `telemetric-hub/kiss/scripts/docker-compose.yml`
- `telemetric-api/old/docker-compose.yml`
- Decision: usar `telemetric-hub/kiss/scripts/docker-compose.yml` como compose operativo; `telemetric-api/old/docker-compose.yml` se mantiene como legado.

### API base URL y runtime
- `http://localhost:5220`
- Evidencia: `telemetric-api/src/Telemetric.Api/Properties/launchSettings.json`

### Endpoints/policies relacionados
- `GET /api/v1/actions/runs`
  - `telemetric-api/src/Telemetric.Api/Features/Actions/Runs/GetRuns/GetRunsEndpoint.cs`
- `GET /api/v1/actions/templates/{RuleTemplateId}/runs`
  - `telemetric-api/src/Telemetric.Api/Features/Actions/Templates/GetTemplateRuns/GetTemplateRunsEndpoint.cs`
- Policy de lectura esperada:
  - `Policies(PermissionClaims.Actions.View)` en endpoints de runs.

### Fuentes frontend verificadas
- Vista principal:
  - `telemetric-front/src/features/actions/views/ActionsTemplatesView.vue`
- Servicio tipado:
  - `telemetric-front/src/features/actions/actions.service.ts`
- Contratos:
  - `telemetric-front/src/features/actions/types.ts`
- Rutas:
  - `telemetric-front/src/features/actions/actions.routes.ts`
- Menu:
  - `telemetric-front/src/layouts/menuItems.ts`

### Scripts/comandos base
- `rg --line-number -F -e "activeTab = ref<'runs' | 'templates'>('runs')" -e "<v-tab value=\"runs\">Runs</v-tab>" telemetric-front/src/features/actions/views/ActionsTemplatesView.vue`
- `rg --line-number -F -e "UiDynamicFilter" -e "UiServerTable" -e "runsErrorMessage" -e "No se pudieron cargar las ejecuciones." telemetric-front/src/features/actions/views/ActionsTemplatesView.vue`
- `rg --line-number -F -e "item.status === 'Fail'" -e "Fallo sin detalle de error." telemetric-front/src/features/actions/views/ActionsTemplatesView.vue`
- `rg --line-number -F -e "getRuns:" -e "/actions/runs" telemetric-front/src/features/actions/actions.service.ts`
- `rg --line-number -F -e "ActionRunsQueryParams" -e "ActionRunListItem" -e "ActionRunStatus" -e "ActionRunContext" telemetric-front/src/features/actions/types.ts`
- `rg --line-number -F -e "path: '/actions'" -e "requiresPermission: 'Actions.View'" telemetric-front/src/features/actions/actions.routes.ts telemetric-front/src/layouts/menuItems.ts`
- `npm --prefix telemetric-front run typecheck`

## 3) Setup
1. Ejecutar `scripts/setup.ps1` o `scripts/setup.sh`.
2. Confirmar prerequisitos/discovery de fase.
3. Confirmar que se escribio evidencia en:
- `evidence/commands.log`
- `evidence/outputs.log`

## 4) Run
1. Ejecutar `scripts/run.ps1` o `scripts/run.sh`.
2. Validar checks funcionales de fase 03 (tab runs + UX + contratos).
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
- `/actions` presenta tab `Runs` activo y visible.
- Runs muestra estados de UX (error/empty/success) sin romper carga.
- Filtrado y tabla usan `UiDynamicFilter` + `UiServerTable`.
- Servicio y tipos de runs permanecen tipados y alineados al contrato.
- Typecheck no-demo no empeora baseline cuando se define `BASELINE_TS_ERRORS`.
