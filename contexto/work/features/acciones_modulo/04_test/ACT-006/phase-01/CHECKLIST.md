# CHECKLIST - ACT-006 phase-01

## Objetivo
Validar discovery/equivalence de endpoints Runs y contrato OpenAPI de ACT-006 fase 01.

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
- Accion: revisar `contexto/work/features/acciones_modulo/03_execution/ACT-006/phase-01.md`.
- PASS: documenta discovery/equivalence y no implementacion backend en fase 01.

2. Equivalence gate backend
- Accion: ejecutar busqueda de rutas/handlers runs en `Features/Actions`.
- PASS: no se encuentran endpoints backend de runs (`/api/v1/actions/runs` ni `/api/v1/actions/templates/{ruleTemplateId}/runs`).

3. Contrato OpenAPI rutas runs
- Accion: validar `contexto/openapi/actions.yaml`.
- PASS: existen `/api/v1/actions/runs` y `/api/v1/actions/templates/{ruleTemplateId}/runs`.

4. Contrato OpenAPI payload
- Accion: validar esquemas.
- PASS: existen `ActionRunListItem`, `ActionRunStatus`, `ActionRunContext` y campos `status`, `error`, `attemptedAt`, `ruleInstanceId`, `context`.

5. Seguridad y versionado
- Accion: validar policy y prefijo.
- PASS: `x-required-policy: Actions.View` y rutas `/api/v1`.

6. Policy backend de referencia
- Accion: verificar endpoints existentes de templates.
- PASS: `Policies(PermissionClaims.Actions.View)` presente en endpoints de lectura.

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
