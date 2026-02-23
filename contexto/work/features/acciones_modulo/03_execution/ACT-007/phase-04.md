# FASE 04 - ACT-007

## Estado
DONE

## Standards Lock Check
- Backend: ADOPTED (ref: audit A0)
- SQLServer: ADOPTED (ref: audit A0)

## FIX Mode
- is_fix: 0
- fix_id: NA
- fix_pack_used: NA

## Files touched (max 5)
- telemetric-front/src/features/customer/devices/views/DeviceCustomerEditView.vue
- contexto/work/features/acciones_modulo/03_execution/ACT-007/phase-04.md

## Changes summary
- Se completo el bloque `Reglas del dispositivo` dentro de `DeviceCustomerEditView` para listar reglas filtradas por `deviceId` usando `actionsService.getRules(...)`.
- Se agrego filtro por estado operativo (`Enabled`/`Paused`) con recarga de listado y estados UX visibles: `loading`, `error`, `empty`, `success`.
- Se agrego badge rojo `Ultimo fail` basado en `hasLastAttemptFail` y detalle de ultimo error/intento sin exponer campos internos de runtime.
- Se implemento accion por fila de pausar/rehabilitar con iconos + tooltip, usando `actionsService.updateRuleState(...)` y recarga inmediata para mantener sincronia con `/actions`.
- Se sincronizo el listado al crear una nueva regla desde Device Detail (`createRuleFromDevice` ahora refresca reglas del dispositivo al finalizar con exito).

## Verification checklist
- Verificacion de tipado frontend ejecutada en `telemetric-front`:
  - Comando: `npm run typecheck`
  - Resultado: falla global por deuda tecnica preexistente del repo.
- Conteo de errores (no-regresion de referencia):
  - `ERROR_TOTAL=139`
  - `ERROR_NON_DEMO=118` (excluye `src/_demo/**`)
  - `ERROR_TOUCHED_FILE=0` para `src/features/customer/devices/views/DeviceCustomerEditView.vue`.
- Verificacion funcional esperada en UI:
  - Device Detail muestra reglas asociadas al `deviceId` actual.
  - Toggle pause/resume en Device Detail persiste estado y recarga lista.
  - Badge `Ultimo fail` visible cuando `hasLastAttemptFail=true`.
  - Cambio de estado queda alineado con el mismo endpoint/contrato usado por `/actions`.

## Notes / Risks
- Se mantiene deuda global de typecheck fuera del alcance de esta fase; no hubo errores nuevos en el archivo tocado.
- La validacion de consistencia visual cruzada con `/actions` queda sujeta a prueba manual con datos reales del tenant y permisos `Actions.View/Actions.Update`.
