# CHECKLIST - ACT-007 phase-01

## Objetivo
Validar discovery/equivalence de endpoints Rules (list global/device + toggle state) y contrato OpenAPI de ACT-007 fase 01.

## Precondiciones
1. Repo disponible desde la raiz.
2. Herramienta minima: `rg`.
3. Opcional para corrida real: `node`, `npm`, `sqlcmd`, API local.

## Setup
1. Ejecutar `scripts/setup.ps1` o `scripts/setup.sh`.
2. Verificar creacion/actualizacion de:
- `evidence/commands.log`
- `evidence/outputs.log`

## Verificaciones funcionales
1. Trazabilidad de fase
- Accion: revisar `contexto/work/features/acciones_modulo/03_execution/ACT-007/phase-01.md`.
- PASS: documenta discovery/equivalence y delta OpenAPI para Rules.

2. Equivalence gate backend
- Accion: buscar endpoints Rules faltantes en `telemetric-api/src/Telemetric.Api/Features/Actions/*Endpoint.cs`.
- PASS: no existe `Get("/api/v1/actions/rules")`, no existe `Get("/api/v1/actions/devices/{deviceId}/rules")`, no existe `Patch("/api/v1/actions/rules/{ruleInstanceId}/state")`.

3. Contrato OpenAPI rutas Rules
- Accion: validar `contexto/openapi/actions.yaml`.
- PASS: existen `/api/v1/actions/rules`, `/api/v1/actions/devices/{deviceId}/rules`, `/api/v1/actions/rules/{ruleInstanceId}/state`.

4. Contrato OpenAPI payload Rules
- Accion: validar esquemas.
- PASS: existen `GetRulesResponse`, `RuleListItem`, `RuleOperationalStatus`, `UpdateRuleStateRequest`, `UpdateRuleStateResponse`.
- PASS: `RuleListItem` incluye `ruleInstanceId`, `isPaused`, `operationalStatus`, `hasLastAttemptFail`, `lastAttemptStatus`, `lastAttemptedAt`.

5. Seguridad y versionado
- Accion: validar policies y prefijo.
- PASS: `x-required-policy: Actions.View` en endpoints de lectura y `x-required-policy: Actions.Update` en toggle.
- PASS: rutas bajo `/api/v1`.

6. Policy backend de referencia
- Accion: validar claims disponibles.
- PASS: `Actions.View` y `Actions.Update` existen en `telemetric-api/src/Telemetric.Api/Domain/Constants/PermissionClaims.cs`.

7. Typecheck no-regresion no-demo (DRY_RUN=0)
- Accion: `npm --prefix telemetric-front run typecheck`.
- PASS: `observed_no_demo_ts_errors <= BASELINE_TS_ERRORS` (si baseline fue provisto).
- WARN: si no existe `BASELINE_TS_ERRORS`, registrar evidencia sin gate numerico.

8. Auto-login y autodiscovery (DRY_RUN=0)
- Accion: revisar `outputs.log`.
- PASS: si `API_AUTH_TOKEN` falta, se intenta auto-login.
- PASS: si faltan `TEST_RULE_TEMPLATE_VERSION_ID` y `TEST_DEVICE_IDS`, se intenta autodiscovery via `sqlcmd`.

## Teardown
1. Ejecutar `scripts/teardown.ps1` o `scripts/teardown.sh`.
2. Confirmar regla de cierre de runtime: cualquier instancia levantada durante QA debe apagarse y verificarse detenida.
3. Registrar notas finales en `evidence/notes.md`.

## Estado de corrida
- [x] Setup ejecutado
- [x] Run ejecutado
- [x] Teardown ejecutado
- [x] Evidencia completa
- [x] QA cerrada

## Resultado ultima corrida (2026-02-23)
- Resultado: PASS (QA cerrada).
- Runtime: API levantada con estrategia alternativa (`Start-Job`), validando login integrado y cierre limpio.
- Setup: OK (`DRY_RUN=0`).
- Run: OK en validaciones de contrato/discovery; typecheck ejecutado con errores existentes (`typecheck_exit_code=2`, `no_demo_ts_errors=118`, sin baseline numerico); auto-login OK.
- Teardown: OK (safe no-op).
- STILL_RUNNING (Telemetric.Api): none.
