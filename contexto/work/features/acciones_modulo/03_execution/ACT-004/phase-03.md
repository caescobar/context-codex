# FASE 03 — ACT-004

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
- telemetric-front/src/features/actions/types.ts
- telemetric-front/src/features/actions/actions.service.ts
- telemetric-front/src/features/actions/views/ActionsTemplatesView.vue
- telemetric-front/src/features/actions/views/ActionTemplateDetailView.vue
- contexto/work/features/acciones_modulo/03_execution/ACT-004/phase-03.md

## Changes summary
- Se extendieron contratos tipados de Actions para soportar asignacion masiva (`AssignTemplateToDevicesRequest/Response`) y estados de resultado por dispositivo.
- Se agregaron operaciones en `actions.service` para:
  - obtener dispositivos asignables desde `/devices`;
  - ejecutar asignacion masiva hacia `POST /actions/assignments/template-version`.
- En `ActionsTemplatesView.vue` se implemento flujo de asignacion masiva dentro de la pestana de asignaciones del modal de detalle:
  - seleccion multiple de dispositivos;
  - ejecucion de asignacion con estado loading/error/success;
  - feedback detallado por dispositivo con chip de estado (`Asignado`, `Duplicado`, `Fuera de alcance`).
- En `ActionTemplateDetailView.vue` se implemento paridad del mismo flujo para la vista de detalle por ruta.
- Se mantuvo compatibilidad con permisos existentes usando `Actions.Assign` para habilitar acciones de asignacion.

## Verification checklist
- `npm run typecheck` (en `telemetric-front/`)
  - Resultado observado: el repositorio mantiene errores TypeScript preexistentes en multiples modulos no relacionados (admin/maps/demo/core).
- `npm run typecheck 2>&1 | Select-String -Pattern "src/features/actions"` (en `telemetric-front/`)
  - Resultado observado: sin errores reportados en `src/features/actions` durante la corrida.
- Validacion manual de codigo:
  - Estado `RejectedDuplicate` se muestra como `Duplicado` con color `warning`.
  - Conteos `createdCount/rejectedCount` del backend se reflejan en UI despues de asignar.

## Notes / Risks
- La puerta global de typecheck del proyecto sigue inestable por deuda previa fuera de ACT-004; para gate estricto de no-regresion conviene baseline formal por fase (excluyendo `src/_demo/**`).
- La carga de dispositivos asignables usa `/devices` sin filtro adicional; si el volumen crece, puede requerir paginacion/selector remoto en una fase posterior.
