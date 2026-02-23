# CHECKLIST - ACT-005 phase-04

## Objetivo
Validar Fase 04 de ACT-005: alinear `/my-devices/:id/edit` al builder/contrato DSL canonico con overrides v1 acotados.

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
- Accion: revisar `contexto/work/features/acciones_modulo/03_execution/ACT-005/phase-04.md`.
- PASS: existe resumen de contrato DSL canonico en customer.

2. Ruta customer activa
- Accion: revisar `telemetric-front/src/router/MainRoutes.ts`.
- PASS: existe `path: '/my-devices/:id/edit'`.

3. Builder DSL activo en customer
- Accion: revisar `DeviceCustomerEditView.vue`.
- PASS: existen `validateAndBuildDefinition` y `buildOverrides`.

4. Validacion temporal
- Accion: validar rechazo para `durationSeconds > windowSeconds`.
- PASS: mensaje presente.

5. Missing data HOLD_LAST_VALUE
- Accion: validar rechazo cuando `ttlSeconds` invalido.
- PASS: mensaje presente.

6. Recipients y email
- Accion: validar rechazo por recipients vacios/invalidos.
- PASS: mensajes presentes.

7. Overrides v1 acotados
- Accion: revisar `buildOverrides`.
- PASS: solo usa `threshold` y `email.recipients`; errores de override invalidos presentes.

8. Gate de permiso
- Accion: revisar `DeviceCustomerEditView.vue`.
- PASS: usa `Actions.Assign` y muestra bloqueo sin permiso.

9. Wiring servicio + contrato
- Accion: revisar `actions.service.ts`, `types.ts`, `contexto/openapi/actions.yaml`.
- PASS: `create-from-device` usa `DefinitionJsonV1` + `RuleInstanceOverridesV1` y serializa JSON para backend actual.

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

## Resultado de ejecucion (2026-02-20)
- `DRY_RUN=1`: setup/run/teardown ejecutados para validacion segura del pack.
- `DRY_RUN=0`: setup/run/teardown ejecutados con evidencia real.
- Gate no-regresion no-demo: PASS (`observed_no_demo_ts_errors=118`, `baseline.ts_errors=118`).
- Auto-login API: PASS (`http://localhost:5220`, usuario `vcsoft`).
- SQL discovery: PASS (`RuleTemplateId=4`, `RuleTemplateVersionId=6`, `DeviceIds=7,6,5`).
- Cierre runtime: PASS (`Telemetric.Api` detenido, `STILL_RUNNING: none`).
