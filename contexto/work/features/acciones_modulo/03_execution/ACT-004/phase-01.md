# FASE 01 — ACT-004

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
- telemetric-api/src/Telemetric.Api/Features/Actions/Assignments/AssignTemplateToDevices/AssignTemplateToDevicesEndpoint.cs
- telemetric-api/src/Telemetric.Api/Features/Actions/Assignments/AssignTemplateToDevices/AssignTemplateToDevicesCommandHandler.cs
- telemetric-api/src/Telemetric.Api/Domain/Constants/PermissionClaims.cs
- contexto/openapi/actions.yaml
- contexto/work/features/acciones_modulo/03_execution/ACT-004/phase-01.md

## Changes summary
- Reuse-first ejecutado: se verifico que no existia endpoint equivalente de asignacion masiva en `Features/Actions/*` antes de crear uno nuevo.
- Se agrego endpoint `POST /api/v1/actions/assignments/template-version` con contrato tipado, validator y policy `PermissionClaims.Actions.Assign`.
- Se implemento handler CQRS para asignacion masiva por `RuleTemplateVersionId` con resultado por device:
  - `Created`
  - `RejectedDuplicate`
  - `RejectedNotFoundOrOutOfScope`
- Se enforceo scope por cliente autenticado para template version y devices.
- Se mantuvo bloqueo de duplicados por par `(DeviceId, RuleTemplateVersionId)` sin relajar restricciones existentes.
- Se actualizo OpenAPI de forma incremental en `contexto/openapi/actions.yaml`.

## Verification checklist
- `rg -n "AssignTemplateToDevices|Assignments|/api/v1/actions"` en `telemetric-api/src/Telemetric.Api` para gate Discover/Equivalence (sin endpoint equivalente previo).
- `dotnet build telemetric-api/src/Telemetric.Api/Telemetric.Api.csproj`:
  - observado bloqueo externo por proceso en ejecucion (`Telemetric.Api`, PID 31552), sin errores de compilacion atribuibles a la fase.
- `dotnet build telemetric-api/src/Telemetric.Api/Telemetric.Api.csproj -p:OutDir=../../../../artifacts/act004-phase01-build/ -p:AppendTargetFrameworkToOutputPath=true`:
  - resultado: `0 Error(s)`, compilacion valida de la implementacion.

## Notes / Risks
- No se ejecutaron pruebas smoke/integration de endpoint en esta fase; quedan para QA pack de fases posteriores.
- El claim `Actions.Assign` fue agregado en constantes; la asignacion del permiso a roles/seed operativa depende del flujo de administracion de permisos del entorno.
