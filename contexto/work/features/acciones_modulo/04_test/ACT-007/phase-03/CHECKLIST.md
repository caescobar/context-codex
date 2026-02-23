# CHECKLIST - ACT-007 phase-03

## Objetivo
Validar implementacion frontend del tab `Rules` en `/actions` para ACT-007 fase 03, incluyendo estado operativo, badge rojo de ultimo fail y toggle pause/resume.

## Precondiciones
1. Repo disponible desde la raiz.
2. Herramientas: `rg`.
3. Opcional: `node`, `npm`, `sqlcmd`, API local.

## Setup
1. Ejecutar `scripts/setup.ps1` o `scripts/setup.sh`.
2. Verificar evidencia en:
- `evidence/commands.log`
- `evidence/outputs.log`

## Verificaciones funcionales
1. Trazabilidad de fase
- Accion: revisar `contexto/work/features/acciones_modulo/03_execution/ACT-007/phase-03.md`.
- PASS: estado `DONE` y descripcion de tab `Rules`, badge rojo y toggle de estado.

2. Tab Rules en `/actions`
- Accion: revisar `telemetric-front/src/features/actions/views/ActionsTemplatesView.vue`.
- PASS: existen tabs `Runs`, `Rules`, `Templates` y `activeTab` soporta `rules`.

3. UX de Rules
- Accion: revisar `ActionsTemplatesView.vue`.
- PASS: filtro de estado operativo (`Enabled`/`Paused`) via `UiDynamicFilter`.
- PASS: tabla server-side con `UiServerTable`.
- PASS: estados `loading/empty/error/success` para Rules.

4. Badge rojo por ultimo fail
- Accion: revisar `ActionsTemplatesView.vue`.
- PASS: usa `hasLastAttemptFail` para mostrar chip `Ultimo fail`.
- PASS: muestra fallback `Fail sin detalle de error.` cuando corresponde.

5. Toggle de estado operativo
- Accion: revisar `ActionsTemplatesView.vue` y `actions.service.ts`.
- PASS: existe `updateRuleState(item, !item.isPaused)` en UI con permiso `Actions.Update`.
- PASS: servicio consume `PATCH /actions/rules/{ruleInstanceId}/state`.

6. Contratos tipados
- Accion: revisar `telemetric-front/src/features/actions/types.ts`.
- PASS: existen `ActionRuleListItem`, `ActionRulesQueryParams`, `RuleOperationalStatus`, `UpdateRuleStateRequest`, `UpdateRuleStateResponse`.

7. Rutas/menu y permisos
- Accion: revisar `telemetric-front/src/features/actions/actions.routes.ts` y `telemetric-front/src/layouts/menuItems.ts`.
- PASS: ruta/menu `/actions` requiere `Actions.View`.

8. Gate `any` no permitido en scope
- Accion: revisar conteo de `any` en `ActionsTemplatesView.vue`, `actions.service.ts`, `types.ts`.
- PASS: suma de ocurrencias `any` en scope es `0`.

9. Typecheck no-regresion no-demo (DRY_RUN=0)
- Accion: `npm --prefix telemetric-front run typecheck`.
- PASS: `observed_no_demo_ts_errors <= BASELINE_TS_ERRORS` (si baseline fue provisto).
- WARN: si no hay baseline, registrar evidencia sin gate numerico.

10. Auto-login/autodiscovery (DRY_RUN=0)
- Accion: revisar `outputs.log`.
- PASS: logs con resultado de auto-login y autodiscovery SQL (si aplica).

## Teardown
1. Ejecutar `scripts/teardown.ps1` o `scripts/teardown.sh`.
2. Confirmar cierre de runtime si se levantaron instancias.
3. Registrar notas finales en `evidence/notes.md`.

## Estado de corrida
- [x] Setup ejecutado
- [x] Run ejecutado (FAIL: `service_rules_patch_route`)
- [x] Teardown ejecutado
- [x] Evidencia completa
- [ ] QA cerrada

## Resultado de ejecucion (2026-02-23)
1. Setup: OK (`DRY_RUN=0`), evidencia en `evidence/commands.log` y `evidence/outputs.log`.
2. Run: FAIL por check requerido `service_rules_patch_route=False`.
3. Teardown: OK (safe no-op).
4. Cierre runtime: `STILL_RUNNING: none` para `Telemetric.Api`.
