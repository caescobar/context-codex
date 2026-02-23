# CHECKLIST - ACT-004 phase-02

## Objetivo
Validar la Fase 02 de ACT-004: backend create-from-device (local/reusable) con whitelist de overrides v1.

## Precondiciones
1. API disponible en `telemetric-api`.
2. Entorno con `dotnet`, `rg`, `node`, `npm`.
3. Frontend disponible en `telemetric-front/` para gate de no-regresion no-demo.
4. (Opcional) Token con `Actions.Assign` para pruebas integradas del endpoint.

## Setup
1. Ejecutar `scripts/setup.ps1` o `scripts/setup.sh`.
2. Verificar que se actualizan:
- `evidence/commands.log`
- `evidence/outputs.log`

## Verificaciones funcionales
1. Reuse-first documentado
- Accion: revisar `contexto/work/features/acciones_modulo/03_execution/ACT-004/phase-02.md`.
- PASS: existe evidencia textual de discover/equivalence/reuse-first.

2. Endpoint de create-from-device
- Accion: inspeccionar endpoint y OpenAPI.
- PASS: existe `POST /api/v1/actions/assignments/create-from-device`.

3. Policy dedicada de asignacion
- Accion: inspeccionar endpoint + constants.
- PASS: se usa `PermissionClaims.Actions.Assign`.

4. Override permitido persiste
- Accion: con `DRY_RUN=0`, enviar payload valido (`threshold`, `email.recipients`) en flujo local o reusable.
- PASS: respuesta 200 y `RuleInstance` creada.

5. Override no permitido falla con error verificable
- Accion: con `DRY_RUN=0`, enviar payload con clave no permitida (ej. `foo`).
- PASS: respuesta de error (400) con mensaje verificable de whitelist.

6. Regla local no aparece como reusable global
- Accion: ejecutar `createReusableTemplate=false`.
- PASS: respuesta con `createdReusableTemplate=false` y `ruleTemplateId=null`.

7. Regla reusable queda disponible para asignaciones posteriores
- Accion: ejecutar `createReusableTemplate=true`.
- PASS: respuesta con `createdReusableTemplate=true` y `ruleTemplateVersionId>0`.

8. Typecheck no-regresion no-demo (obligatorio en DRY_RUN=0)
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
