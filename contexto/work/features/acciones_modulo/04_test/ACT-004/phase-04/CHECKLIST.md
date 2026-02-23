# CHECKLIST - ACT-004 phase-04

## Objetivo
Validar la Fase 04 de ACT-004: integracion del flujo local/reusable en Device Detail customer (`/my-devices/:id/edit`) con gate de permisos y no-regresion.

## Precondiciones
1. Frontend disponible en `telemetric-front/`.
2. Entorno con `node`, `npm` y `rg`.
3. (Opcional) API disponible en `http://localhost:5220`.

## Setup
1. Ejecutar `scripts/setup.ps1` o `scripts/setup.sh`.
2. Verificar actualizacion de:
- `evidence/commands.log`
- `evidence/outputs.log`

## Verificaciones funcionales
1. Ruta customer activa
- Accion: inspeccionar `telemetric-front/src/router/MainRoutes.ts`.
- PASS: existe `path: '/my-devices/:id/edit'` asociado a `DeviceCustomerEditView.vue`.

2. Gate de permiso en UI
- Accion: inspeccionar `DeviceCustomerEditView.vue`.
- PASS: existe `permissions?.includes('Actions.Assign')` y alerta de bloqueo para usuarios sin permiso.

3. Flujo local/reusable disponible
- Accion: inspeccionar `DeviceCustomerEditView.vue`.
- PASS: existen modo `local/reusable`, radios y accion `createRuleFromDevice`.

4. Validacion de overrides JSON
- Accion: inspeccionar manejo de `overridesJson`.
- PASS: se hace `JSON.parse` + `JSON.stringify` y mensaje `Overrides JSON no es valido.` en error.

5. Wiring servicio + contratos
- Accion: inspeccionar `actions.service.ts` y `types.ts`.
- PASS: existe `createRuleFromDevice` con endpoint `/actions/assignments/create-from-device` y tipos `CreateRuleFromDeviceRequest/Response`.

6. No ruptura de flujo de edicion customer
- Accion: inspeccionar `DeviceCustomerEditView.vue`.
- PASS: se mantiene `save` con `deviceCustomerService.update` y boton `Guardar Cambios`.

7. Typecheck no-regresion no-demo (obligatorio en DRY_RUN=0)
- Accion: ejecutar `npm --prefix telemetric-front run typecheck`.
- PASS: `observed_no_demo_ts_errors <= baseline.ts_errors`.
- FAIL: `observed_no_demo_ts_errors > baseline.ts_errors`.

## Teardown
1. Ejecutar `scripts/teardown.ps1` o `scripts/teardown.sh`.
2. Registrar observaciones finales en `evidence/notes.md`.

## Estado de corrida
- [x] Setup ejecutado
- [x] Run ejecutado completo
- [x] Teardown ejecutado
- [x] Evidencia completa en logs (`commands.log`, `outputs.log`)
- [x] QA cerrada
