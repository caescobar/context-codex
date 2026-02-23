# CHECKLIST - ACT-004 phase-01

## Objetivo
Validar la Fase 01 de ACT-004: backend de asignacion masiva template-version a devices con bloqueo de duplicados y scope por cliente.

## Precondiciones
1. API disponible en `telemetric-api`.
2. Entorno con `dotnet`, `rg`, `node`, `npm`.
3. Frontend disponible en `telemetric-front/` para gate de no-regresion no-demo.
4. (Opcional) Token con `Actions.Assign` para prueba integrada del endpoint.

## Setup
1. Ejecutar `scripts/setup.ps1` o `scripts/setup.sh`.
2. Verificar que se actualizan:
   - `evidence/commands.log`
   - `evidence/outputs.log`

## Verificaciones funcionales
1. Reuse-first documentado
- Accion: revisar `contexto/work/features/acciones_modulo/03_execution/ACT-004/phase-01.md`.
- PASS: existe evidencia textual de discover/equivalence/reuse-first.

2. Endpoint de asignacion masiva
- Accion: inspeccionar endpoint y OpenAPI.
- PASS: existe `POST /api/v1/actions/assignments/template-version`.

3. Policy dedicada de asignacion
- Accion: inspeccionar endpoint + constants.
- PASS: se usa `PermissionClaims.Actions.Assign`.

4. Resultado por device
- Accion: inspeccionar handler.
- PASS: aparecen estados `Created`, `RejectedDuplicate`, `RejectedNotFoundOrOutOfScope`.

5. Bloqueo de duplicados
- Accion: inspeccionar handler + SQL.
- PASS: se detectan duplicados y existe indice unico `UQ_RuleInstance_Device_TemplateVersion`.

6. Scope por cliente autenticado
- Accion: inspeccionar handler.
- PASS: consultas filtran por `_currentUserService.ClientId` cuando aplica.

7. Typecheck no-regresion no-demo (obligatorio en DRY_RUN=0)
- Accion: ejecutar `npm --prefix telemetric-front run typecheck`.
- PASS: `observed_no_demo_ts_errors <= baseline.ts_errors`.
- FAIL: `observed_no_demo_ts_errors > baseline.ts_errors`.

8. Prueba integrada opcional endpoint (DRY_RUN=0)
- Accion: `Invoke-RestMethod`/`curl` con payload real.
- PASS: respuesta 200 con `createdCount/rejectedCount/items` coherentes.

## Teardown
1. Ejecutar `scripts/teardown.ps1` o `scripts/teardown.sh`.
2. Registrar observaciones finales en `evidence/notes.md`.

## Estado de corrida
- [x] Setup ejecutado
- [x] Run ejecutado completo
- [x] Teardown ejecutado
- [x] Evidencia completa en logs (`commands.log`, `outputs.log`)
- [x] QA cerrada
