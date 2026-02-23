# CHECKLIST - ACT-003 phase-03

## Objetivo
Validar la Fase 03 de ACT-003: feature frontend de Templates en rutas `/actions` y `/actions/templates/:id`.

## Precondiciones
1. Frontend disponible en `telemetric-front/`.
2. Entorno con `node`, `npm` y `rg`.
3. (Opcional) API disponible en `http://localhost:5220` para validacion integrada manual.

## Setup
1. Ejecutar `scripts/setup.ps1` o `scripts/setup.sh`.
2. Verificar que se actualizan:
   - `evidence/commands.log`
   - `evidence/outputs.log`

## Verificaciones funcionales
1. Rutas ACT-003 en frontend
- Accion: buscar `/actions` y `/actions/templates/:id` en router/feature.
- PASS: rutas existen y son navegables en config de router.

2. Estructura de feature Actions
- Accion: verificar archivos esperados:
  - `actions.routes.ts`
  - `actions.service.ts`
  - `types.ts`
  - `views/ActionsTemplatesView.vue`
  - `views/ActionTemplateDetailView.vue`
- PASS: existen bajo `telemetric-front/src/features/actions/`.

3. Cliente API core en servicio
- Accion: inspeccionar `actions.service.ts`.
- PASS: usa `@/core/utils/axios` (o wrapper central equivalente del proyecto).

4. Contratos en ingles
- Accion: inspeccionar `types.ts`.
- PASS: interfaces/types con naming tecnico en ingles.

5. Labels UI en espanol
- Accion: inspeccionar vistas de Actions.
- PASS: labels y textos de usuario en espanol.

6. Conectividad con endpoints de fases previas
- Accion: inspeccionar `actions.service.ts`.
- PASS: referencia endpoints `/api/v1/actions/templates` (list/detail/update segun vista).

7. Typecheck tecnico (opcional)
- Accion: `npm --prefix telemetric-front run typecheck`.
- PASS: salida sin errores.

8. Gate no-regresion TS no-demo (obligatorio en DRY_RUN=0)
- Accion: contar errores TypeScript no-demo de la salida de typecheck y comparar contra `baseline.json`.
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

## Resultado de ejecucion integrada (2026-02-19)
- Setup: OK (`DRY_RUN=0`)
- Run: OK (`DRY_RUN=0`)
- Teardown: OK (`DRY_RUN=0`)
- Gate no-regresion no-demo: configurado con baseline `240` en `baseline.json`.
- Typecheck tecnico global: puede fallar por errores preexistentes; no bloquea si no aumenta el conteo no-demo.
- Estado API al cierre: `STILL_RUNNING: none`
