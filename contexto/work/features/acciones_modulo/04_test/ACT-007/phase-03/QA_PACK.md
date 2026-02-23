# QA PACK - acciones-modulo-act-007-phase-03

## 0) Metadata
- Fecha: 2026-02-23
- Tipo: QA PACK
- Objetivo: Validar Fase 03 de ACT-007 (tab `Rules` en `/actions` con UX canonica y badge rojo por ultimo fail).
- Entorno: frontend (`telemetric-front`) + API local opcional para auto-login/evidencia.
- Autor: Codex (asistido)

## 0.1 Trazabilidad del pack
- PackDir: `contexto/work/features/acciones_modulo/04_test/ACT-007/phase-03/`
- StoryId: `ACT-007`
- Requirement: `acciones_modulo`
- PhaseId: `03`
- GeneratedAt: `2026-02-23`
- ChangePlan: `contexto/work/features/acciones_modulo/02_plans/ACT-007.plan.md`
- ChangeSummary: `contexto/work/features/acciones_modulo/03_execution/ACT-007/phase-03.md`

## 1) Alcance
### 1.1 Incluye
- Verificacion de tab `Rules` en `telemetric-front/src/features/actions/views/ActionsTemplatesView.vue`.
- Verificacion de estados UX (`loading/empty/error/success`) para listado de Rules.
- Verificacion de filtro y tabla server-side (`UiDynamicFilter` + `UiServerTable`) para Rules.
- Verificacion de estado operativo (`Enabled`/`Paused`) y badge rojo por ultimo fail (`hasLastAttemptFail`).
- Verificacion de accion de pause/resume por fila con permiso `Actions.Update`.
- Verificacion de contrato tipado de Rules en:
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
- Fuente: `contexto/work/features/acciones_modulo/02_plans/ACT-007.plan.md`
- Seccion: `Fase 3`
- Objetivo inferido: "Implementar tab Rules en `/actions` con UX canonica y badge rojo por ultimo fail."

### Docker compose detectados
- `telemetric-hub/kiss/scripts/docker-compose.yml`
- `telemetric-api/old/docker-compose.yml`
- Decision: usar `telemetric-hub/kiss/scripts/docker-compose.yml` como compose operativo; `telemetric-api/old/docker-compose.yml` se mantiene como legado.

### API base URL y runtime
- `http://localhost:5220`
- Evidencia: `telemetric-api/src/Telemetric.Api/Properties/launchSettings.json`

### Endpoints/policies relacionados
- `GET /api/v1/actions/rules`
  - `telemetric-api/src/Telemetric.Api/Features/Actions/Rules/GetRules/GetRulesEndpoint.cs`
- `PATCH /api/v1/actions/rules/{ruleInstanceId}/state`
  - `telemetric-api/src/Telemetric.Api/Features/Actions/Rules/UpdateRuleState/UpdateRuleStateEndpoint.cs`
- Policies esperadas:
  - `Policies(PermissionClaims.Actions.View)`
  - `Policies(PermissionClaims.Actions.Update)`

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
- `rg --line-number -F -e "activeTab = ref<'runs' | 'rules' | 'templates'>('runs')" -e "<v-tab value=\"rules\">Rules</v-tab>" telemetric-front/src/features/actions/views/ActionsTemplatesView.vue`
- `rg --line-number -F -e "UiDynamicFilter" -e "UiServerTable" -e "rulesErrorMessage" -e "No se pudieron cargar las reglas." telemetric-front/src/features/actions/views/ActionsTemplatesView.vue`
- `rg --line-number -F -e "hasLastAttemptFail" -e "Ultimo fail" -e "Fail sin detalle de error." telemetric-front/src/features/actions/views/ActionsTemplatesView.vue`
- `rg --line-number -F -e "updateRuleState(item, !item.isPaused)" -e "Actions.Update" telemetric-front/src/features/actions/views/ActionsTemplatesView.vue`
- `rg --line-number -F -e "getRules:" -e "updateRuleState:" -e "/actions/rules" telemetric-front/src/features/actions/actions.service.ts`
- `rg --line-number -F -e "ActionRuleListItem" -e "ActionRulesQueryParams" -e "UpdateRuleStateRequest" -e "UpdateRuleStateResponse" -e "RuleOperationalStatus" telemetric-front/src/features/actions/types.ts`
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
2. Validar checks funcionales de fase 03 (tab Rules + UX + badge + toggle + contratos).
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
- `/actions` presenta tab `Rules` visible junto a `Runs` y `Templates`.
- Rules muestra estado operativo y badge rojo por ultimo fail.
- Toggle de estado operativo ejecuta `updateRuleState` y recarga tabla.
- Servicio y tipos de Rules permanecen tipados y alineados al contrato.
- Typecheck no-demo no empeora baseline cuando se define `BASELINE_TS_ERRORS`.
