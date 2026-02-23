# CHECKLIST - ACT-006 phase-02

## Objetivo
Validar implementacion backend de runs (global y por template) para ACT-006 fase 02.

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
- Accion: revisar `contexto/work/features/acciones_modulo/03_execution/ACT-006/phase-02.md`.
- PASS: documenta implementacion backend de runs para fase 02.

2. Endpoint global de runs
- Accion: revisar `GetRunsEndpoint.cs`.
- PASS: existe `Get("/api/v1/actions/runs")` y `Policies(PermissionClaims.Actions.View)`.

3. Endpoint de runs por template
- Accion: revisar `GetTemplateRunsEndpoint.cs`.
- PASS: existe `Get("/api/v1/actions/templates/{RuleTemplateId}/runs")` y `Policies(PermissionClaims.Actions.View)`.

4. Query handler global
- Accion: revisar `GetRunsQueryHandler.cs`.
- PASS: consulta usa `_context.ActionAttempts`, `AsNoTracking`, tenant scope y orden por intento mas reciente.

5. Query handler por template
- Accion: revisar `GetTemplateRunsQueryHandler.cs`.
- PASS: filtra por `RuleTemplateId`, usa `ActionAttempt` + `AsNoTracking`, tenant scope y orden por intento mas reciente.

6. Contrato OpenAPI runs
- Accion: validar `contexto/openapi/actions.yaml`.
- PASS: existen `/api/v1/actions/runs` y `/api/v1/actions/templates/{ruleTemplateId}/runs` con `x-required-policy: Actions.View`.

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
- [x] QA cerrada
