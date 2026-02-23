# FASE 04 - ACT-004

## Estado
DONE

## Standards Lock Check
- Backend: ADOPTED (ref: audit A0)
- SQLServer: ADOPTED (ref: audit A0)
- Frontend: ADOPTED (ref: audit A0)

## FIX Mode
- is_fix: 0
- fix_id: NA
- fix_pack_used: NA

## Files touched (max 5)
- telemetric-front/src/features/actions/types.ts
- telemetric-front/src/features/actions/actions.service.ts
- telemetric-front/src/features/customer/devices/views/DeviceCustomerEditView.vue
- contexto/work/features/acciones_modulo/03_execution/ACT-004/phase-04.md

## Changes summary
- Se extendieron contratos tipados en Actions para soportar `create-from-device`:
  - `CreateRuleFromDeviceRequest`
  - `CreateRuleFromDeviceResponse`
- Se agrego operacion tipada en `actions.service` para `POST /actions/assignments/create-from-device`.
- Se integro el flujo ACT-004 en `DeviceCustomerEditView.vue` sobre la ruta customer decidida (`/my-devices/:id/edit`):
  - modo `local` para crear regla con template/version existente;
  - modo `reusable` para crear template reusable y asignarlo al device;
  - campo de `overridesJson` con validacion de JSON;
  - controles `isPaused`, `isLatchMode`, `cooldownSeconds`;
  - feedback de exito/error;
  - gate UI por permiso `Actions.Assign`.
- Se mantuvo el flujo existente de edicion del dispositivo (`save`) sin cambiar la ruta ni romper la vista customer.

## Verification checklist
- `npm run typecheck` (en `telemetric-front/`)
  - Resultado observado: falla global por deuda TypeScript preexistente en modulos no relacionados (`_demo`, `admin`, `maps`, etc.).
- `npm run typecheck 2>&1 | Select-String -Pattern "src/features/customer/devices/views/DeviceCustomerEditView.vue|src/features/actions/"` (en `telemetric-front/`)
  - Resultado observado: sin coincidencias de error para `DeviceCustomerEditView.vue` ni `src/features/actions/*`.
- Validacion de codigo:
  - flujo local/reusable disponible dentro de `DeviceCustomerEditView`;
  - permisos UI alineados con claim `Actions.Assign`;
  - labels UI en espanol y contratos internos en ingles.

## Notes / Risks
- El gate global de typecheck del repositorio sigue inestable por deuda previa fuera del scope ACT-004.
- `device-customer.service` y otros modulos customer ya presentan deuda de tipado (`unknown`) previa en repo.
