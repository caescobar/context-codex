# FASE 02 — ACT-004

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
- telemetric-api/src/Telemetric.Api/Features/Actions/Assignments/CreateRuleFromDevice/CreateRuleFromDeviceEndpoint.cs
- telemetric-api/src/Telemetric.Api/Features/Actions/Assignments/CreateRuleFromDevice/CreateRuleFromDeviceCommandHandler.cs
- contexto/openapi/actions.yaml
- contexto/work/features/acciones_modulo/03_execution/ACT-004/phase-02.md

## Changes summary
- Reuse-first aplicado: se verificó que no existía endpoint equivalente `create-from-device` antes de introducir uno nuevo en `Features/Actions/Assignments`.
- Se implementó endpoint tipado `POST /api/v1/actions/assignments/create-from-device` con policy `PermissionClaims.Actions.Assign` y validaciones de contrato para flujo local/reusable.
- Se implementó handler CQRS con dos rutas de ejecución:
  - `CreateReusableTemplate=true`: crea `RuleTemplate` + `RuleTemplateVersion` (v1) y luego crea `RuleInstance` para el `DeviceId` solicitado.
  - `CreateReusableTemplate=false`: reutiliza `RuleTemplateVersionId` existente y crea `RuleInstance` para el `DeviceId` solicitado.
- Se agregó whitelist estricta de overrides v1 sobre `OverridesJson`:
  - Permitidos: `threshold` (numérico), `email.recipients` (array de strings no vacíos).
  - Rechazo explícito de cualquier otra clave o estructura inválida.
- Se mantiene bloqueo de duplicado por `(DeviceId, RuleTemplateVersionId)` antes de insertar, sin relajar reglas existentes.
- Se actualizó OpenAPI incrementalmente en `contexto/openapi/actions.yaml` para el nuevo path y contratos request/response.

## Verification checklist
- `rg -n "CreateRuleFromDevice|/api/v1/actions/assignments/create-from-device" telemetric-api/src/Telemetric.Api contexto/openapi/actions.yaml`
  - Resultado esperado/observado: endpoint y contrato OpenAPI presentes en las rutas nuevas.
- `dotnet build telemetric-api/src/Telemetric.Api/Telemetric.Api.csproj -p:OutDir=../../../../artifacts/act004-phase02-build/ -p:AppendTargetFrameworkToOutputPath=true`
  - Resultado observado: `0 Error(s)`, compilación satisfactoria (warnings preexistentes del repositorio).

## Notes / Risks
- No se ejecutaron smoke/integration del endpoint nuevo en esta fase; quedan para QA pack de `04_test/ACT-004/phase-02/`.
- La validación de `OverridesJson` asume payload JSON string en v1; si frontend decide enviar objeto tipado, requerirá ajuste de contrato en fase FE.
