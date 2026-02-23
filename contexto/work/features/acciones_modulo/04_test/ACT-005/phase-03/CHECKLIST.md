# CHECKLIST - ACT-005 phase-03

## Objetivo
Validar Fase 03 de ACT-005: builder guiado en `/actions` con validaciones previas al submit.

## Precondiciones
1. Frontend en `telemetric-front/`.
2. Entorno con `rg`, `node`, `npm`.
3. (Opcional) API local y `sqlcmd`.

## Setup
1. Ejecutar `scripts/setup.ps1` o `scripts/setup.sh`.
2. Verificar:
- `evidence/commands.log`
- `evidence/outputs.log`

## Verificaciones funcionales
1. Trazabilidad de fase
- Accion: revisar `contexto/work/features/acciones_modulo/03_execution/ACT-005/phase-03.md`.
- PASS: existe resumen de builder guiado.

2. Builder activo en vista
- Accion: inspeccionar `ActionsTemplatesView.vue`.
- PASS: existe `validateAndBuild`.

3. Cobertura de 5 tipos
- Accion: validar `INSTANT_THRESHOLD`, `CONTINUOUS_DURATION`, `ACCUMULATED_DURATION_WINDOW`, `AGGREGATION_WINDOW`, `COUNT_OCCURRENCES_WINDOW`.
- PASS: presentes en la vista.

4. Regla temporal UI
- Accion: validar mensaje de rechazo para `durationSeconds > windowSeconds`.
- PASS: mensaje presente.

5. Missing data HOLD_LAST_VALUE
- Accion: validar rechazo cuando `ttlSeconds` invalido.
- PASS: mensaje presente.

6. Recipients email
- Accion: validar rechazo por recipients vacios e invalidos.
- PASS: mensajes presentes.

7. UX base
- Accion: validar `UiDynamicFilter`, `UiServerTable` y copy de error.
- PASS: presentes.

8. Rutas/permisos
- Accion: revisar `actions.routes.ts` y `menuItems.ts`.
- PASS: `/actions` y menu `Acciones` usan `Actions.View`.

9. Contratos tipados
- Accion: revisar `types.ts`.
- PASS: `RuleDefinitionV1` definido.

10. Typecheck no-regresion no-demo (DRY_RUN=0)
- Accion: `npm --prefix telemetric-front run typecheck`.
- PASS: `observed_no_demo_ts_errors <= baseline.ts_errors`.
- FAIL: `observed_no_demo_ts_errors > baseline.ts_errors`.

11. Auto-login/autodiscovery (DRY_RUN=0)
- Accion: revisar `outputs.log`.
- PASS: logs con resultado de auto-login y autodiscovery SQL.

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
