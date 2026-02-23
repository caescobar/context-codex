# CHECKLIST - ACT-004 phase-03

## Objetivo
Validar la Fase 03 de ACT-004: frontend de asignacion masiva y feedback de duplicados en vistas de Actions.

## Precondiciones
1. Frontend disponible en `telemetric-front/`.
2. Entorno con `node`, `npm` y `rg`.
3. (Opcional) API disponible en `http://localhost:5220` para validaciones manuales integradas.

## Setup
1. Ejecutar `scripts/setup.ps1` o `scripts/setup.sh`.
2. Verificar actualizacion de:
- `evidence/commands.log`
- `evidence/outputs.log`

## Verificaciones funcionales
1. Reuse-first documentado
- Accion: revisar `contexto/work/features/acciones_modulo/03_execution/ACT-004/phase-03.md`.
- PASS: existe evidencia textual de `Reuse-first`.

2. Contratos de asignacion masiva
- Accion: inspeccionar `telemetric-front/src/features/actions/types.ts`.
- PASS: existen `AssignTemplateToDevicesRequest`, `AssignTemplateToDevicesResponse` y estados `Created/RejectedDuplicate/RejectedNotFoundOrOutOfScope`.

3. Servicio con endpoints esperados
- Accion: inspeccionar `telemetric-front/src/features/actions/actions.service.ts`.
- PASS: existen `assignTemplateToDevices` (`/actions/assignments/template-version`) y `getAssignableDevices` (`/devices`).

4. UI de seleccion y accion de asignacion
- Accion: inspeccionar vistas de Actions.
- PASS: hay control de seleccion multiple y boton `Asignar seleccionados`.

5. Feedback de duplicados y fuera de alcance
- Accion: inspeccionar mapping de estados en vistas.
- PASS: se muestran labels `Asignado`, `Duplicado`, `Fuera de alcance`.

6. Conteos de resultado backend reflejados
- Accion: inspeccionar seccion de resultado de asignacion en vistas.
- PASS: se muestran `createdCount` y `rejectedCount`.

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

## Resultado de ejecucion integrada (2026-02-20)
- Setup: OK (`DRY_RUN=0`)
- Run: OK (`DRY_RUN=0`)
- Teardown: OK (`DRY_RUN=0`)
- Gate no-regresion no-demo: PASS (`observed_no_demo_ts_errors=120`, `baseline=240`)
- Typecheck tecnico global: continua con errores preexistentes fuera de `src/features/actions`.

## Re-ejecucion solicitada (2026-02-20 12:34 local)
- Setup: OK (`DRY_RUN=0`)
- Run: OK (`DRY_RUN=0`)
- Teardown: OK (`DRY_RUN=0`)
- STILL_RUNNING (Telemetric.Api): `none`
- Gate no-regresion no-demo: PASS (`observed_no_demo_ts_errors=120`, `baseline=240`)
