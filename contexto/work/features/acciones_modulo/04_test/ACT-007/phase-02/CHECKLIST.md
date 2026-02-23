# CHECKLIST - ACT-007 phase-02

## Objetivo
Validar implementacion backend de Rules para ACT-007 fase 02 (listado global/device + toggle estado).

## Precondiciones
1. Repo disponible desde la raiz.
2. Herramientas: `rg`.
3. Opcional: `node`, `npm`, `sqlcmd`, API local.

## Setup
1. Ejecutar `scripts/setup.ps1` o `scripts/setup.sh`.
2. Verificar:
- `evidence/commands.log`
- `evidence/outputs.log`

## Verificaciones funcionales
1. Trazabilidad de fase
- Accion: revisar `contexto/work/features/acciones_modulo/03_execution/ACT-007/phase-02.md`.
- PASS: documenta implementacion de `GET /api/v1/actions/rules` y `PATCH /api/v1/actions/rules/{ruleInstanceId}/state`.

2. Endpoint de listado Rules
- Accion: revisar `GetRulesEndpoint.cs`.
- PASS: existe `Get("/api/v1/actions/rules")` y `Policies(PermissionClaims.Actions.View)`.

3. Endpoint de toggle state
- Accion: revisar `UpdateRuleStateEndpoint.cs`.
- PASS: existe `Patch("/api/v1/actions/rules/{RuleInstanceId}/state")` y `Policies(PermissionClaims.Actions.Update)`.

4. Query handler de listado
- Accion: revisar `GetRulesQueryHandler.cs`.
- PASS: aplica tenant scope por `ClientId`.
- PASS: soporta filtro `DeviceId` y `Status` (`Enabled`/`Paused`).
- PASS: calcula ultimo intento (`ActionAttempts`) y bandera `StatusFail` para badge rojo.

5. Command handler de toggle
- Accion: revisar `UpdateRuleStateCommandHandler.cs`.
- PASS: valida `RuleInstanceId > 0`, alcance tenant por `ClientId`, persiste `IsPaused` con `SaveChangesAsync`, y actualiza `UpdatedAt/UpdatedBy`.

6. Contrato OpenAPI Rules
- Accion: validar `contexto/openapi/actions.yaml`.
- PASS: existen `/api/v1/actions/rules` y `/api/v1/actions/rules/{ruleInstanceId}/state` con policies esperadas.
- INFO: existe `/api/v1/actions/devices/{deviceId}/rules`; en esta fase el backend resolvio caso por `deviceId` en query del endpoint global (ver nota en `phase-02.md`).

7. Typecheck no-regresion no-demo (DRY_RUN=0)
- Accion: `npm --prefix telemetric-front run typecheck`.
- PASS: `observed_no_demo_ts_errors <= BASELINE_TS_ERRORS` (si baseline fue provisto).
- WARN: si no existe `BASELINE_TS_ERRORS`, registrar evidencia sin gate numerico.

8. Auto-login/autodiscovery (DRY_RUN=0)
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
- [ ] QA cerrada

## Resultado de ejecucion (2026-02-23)
- `DRY_RUN=0` ejecutado en `setup`, `run`, `teardown`.
- `RULE_TEMPLATE_ID` seleccionado: `4` (SQL: `dbo.RuleTemplate`, `IsDeleted=0`, orden DESC).
- `run` completo para verificaciones estaticas + typecheck; `auto_login_token=FAIL (Unable to connect to the remote server)`.
- `STILL_RUNNING` final para `Telemetric.Api`: `none`.
- Estado: `PARCIAL/BLOQUEADO` para cierre integrado porque el entorno no permitio levantar API en background (`Start-Process`/`start` bloqueados por policy), por lo que no hubo evidencia HTTP integrada GET/PUT/GET de runtime.
