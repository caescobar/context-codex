# CHECKLIST - ACT-006 phase-03

## Objetivo
Validar implementacion frontend de la fase 03 de ACT-006: tab `Runs` en `/actions` con UX canonica y contratos tipados.

## Precondiciones
1. Repo disponible desde la raiz.
2. Herramientas: `rg`.
3. Opcional: `node`, `npm`, `curl`, `jq`, `sqlcmd`.

## Setup
1. Ejecutar `scripts/setup.ps1` o `scripts/setup.sh`.
2. Verificar:
- `evidence/commands.log`
- `evidence/outputs.log`

## Verificaciones funcionales
1. Trazabilidad de fase
- Accion: revisar `contexto/work/features/acciones_modulo/03_execution/ACT-006/phase-03.md`.
- PASS: fase reportada como `DONE` y describe tab `Runs`.

2. Tab Runs en `/actions`
- Accion: revisar `telemetric-front/src/features/actions/views/ActionsTemplatesView.vue`.
- PASS: existe `activeTab` con `runs/templates` y tab `Runs`.

3. Estado de error de runs
- Accion: revisar `ActionsTemplatesView.vue`.
- PASS: existe `runsErrorMessage` y mensaje legible de falla.

4. Error por fila fail
- Accion: revisar render de columna `error` en runs.
- PASS: cuando `status=Fail` se muestra detalle o fallback.

5. Estado empty de runs
- Accion: revisar alerta para lista vacia de runs.
- PASS: existe copy para `runsTotalItems === 0`.

6. UX canonica
- Accion: validar presencia de `UiDynamicFilter` y `UiServerTable`.
- PASS: ambos componentes presentes en la vista.

7. Servicio tipado de runs
- Accion: revisar `telemetric-front/src/features/actions/actions.service.ts`.
- PASS: existe `getRuns` y ruta `/actions/runs`.

8. Contratos tipados
- Accion: revisar `telemetric-front/src/features/actions/types.ts`.
- PASS: existen `ActionRunsQueryParams`, `ActionRunListItem`, `ActionRunStatus`, `ActionRunContext`.

9. Rutas/permisos/menu
- Accion: revisar `actions.routes.ts` y `menuItems.ts`.
- PASS: ruta `/actions` y permiso `Actions.View` presentes.

10. Typecheck no-regresion no-demo (DRY_RUN=0)
- Accion: `npm --prefix telemetric-front run typecheck`.
- PASS: `observed_no_demo_ts_errors <= BASELINE_TS_ERRORS` (si baseline fue provisto).
- WARN: si no existe `BASELINE_TS_ERRORS`, registrar evidencia sin gate numerico.

11. Auto-login/autodiscovery (DRY_RUN=0)
- Accion: revisar `outputs.log`.
- PASS: logs con resultado de auto-login y autodiscovery SQL (si aplica).

## Teardown
1. Ejecutar `scripts/teardown.ps1` o `scripts/teardown.sh`.
2. Confirmar cierre de runtime si se levantaron instancias.
3. Registrar notas finales en `evidence/notes.md`.

## Estado de corrida
- [x] Setup ejecutado
- [x] Run ejecutado
- [x] Teardown ejecutado
- [x] Evidencia completa
- [x] QA cerrada
