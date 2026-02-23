# CHECKLIST - ACT-006 phase-04

## Objetivo
Validar Fase 04 de ACT-006: completar runs en detalle de template (`/actions/templates/:id`) con aislamiento por template y consistencia de contador.

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
- Accion: revisar `contexto/work/features/acciones_modulo/03_execution/ACT-006/phase-04.md`.
- PASS: fase reportada como `DONE` y describe runs en detalle por template.

2. Tab de ejecuciones en detalle
- Accion: revisar `telemetric-front/src/features/actions/views/ActionTemplateDetailView.vue`.
- PASS: existe `<v-tab value="runs">Ejecuciones</v-tab>`.

3. Carga de runs al activar tab
- Accion: revisar watcher de `activeTab`.
- PASS: cuando `tab === 'runs'` se ejecuta `reloadRuns()`.

4. Servicio por template
- Accion: revisar `actions.service.ts`.
- PASS: existe `getTemplateRuns` y ruta `/actions/templates/{id}/runs`.

5. Contratos tipados
- Accion: revisar `types.ts`.
- PASS: existe `TemplateActionRunsQueryParams` y `failedRunsCount` en `RuleTemplateDetail`.

6. Estado error de runs
- Accion: revisar `ActionTemplateDetailView.vue`.
- PASS: existe `runsErrorMessage` y copy `No se pudieron cargar las ejecuciones del template.`.

7. Estado empty de runs
- Accion: revisar `ActionTemplateDetailView.vue`.
- PASS: existe alerta para `hasRunsLoaded && !runsErrorMessage && runsTotalItems === 0`.

8. Error legible en filas fail
- Accion: revisar render de columna `error`.
- PASS: cuando `status=Fail` se muestra detalle o fallback `Fallo sin detalle de error.`.

9. Aislamiento por template
- Accion: revisar llamada `actionsService.getTemplateRuns(ruleTemplateId.value, ...)`.
- PASS: consulta usa `ruleTemplateId` del detalle y no endpoint global.

10. Consistencia backend de `failedRunsCount`
- Accion: revisar `GetTemplateByIdQueryHandler.cs`.
- PASS: query aplica `StatusFail`, filtros de soft-delete y filtro tenant por `ClientId`.

11. Typecheck no-regresion no-demo (DRY_RUN=0)
- Accion: `npm --prefix telemetric-front run typecheck`.
- PASS: `observed_no_demo_ts_errors <= BASELINE_TS_ERRORS` (si baseline fue provisto).
- WARN: si no existe `BASELINE_TS_ERRORS`, registrar evidencia sin gate numerico.

12. Auto-login/autodiscovery (DRY_RUN=0)
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
