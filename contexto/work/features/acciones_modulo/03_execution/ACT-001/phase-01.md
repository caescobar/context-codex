# FASE 01 - ACT-001

## Estado
DONE

## Standards Lock Check
- Backend: ADOPTED (ref: audit A0)
- SQLServer: ADOPTED (ref: audit A0)

## Files touched (max 5)
- telemetric-api/src/Telemetric.Api/Domain/Entities/RuleTemplate.cs
- telemetric-api/src/Telemetric.Api/Domain/Entities/RuleTemplateVersion.cs
- telemetric-api/src/Telemetric.Api/Domain/Entities/RuleInstance.cs
- telemetric-api/src/Telemetric.Api/Domain/Entities/ActionAttempt.cs
- telemetric-api/src/Telemetric.Api/Domain/Entities/RuleCheckpoint.cs

## Changes summary
- Se agrego `RuleTemplate` como entidad base reusable y scope por `ClientId`.
- Se agrego `RuleTemplateVersion` con contrato inmutable para `RuleTemplateId`, `VersionNumber` y `DefinitionJson` mediante setters privados y constructor con guardas.
- Se agrego `RuleInstance` con referencia obligatoria a `RuleTemplateVersionId` y campos base de ciclo (`IsPaused`, `IsLatchMode`, `CooldownSeconds`, `OverridesJson`).
- Se agrego `ActionAttempt` con contrato de estado estricto (`Success|Fail`) y factories que obligan `error` cuando el estado es `Fail`.
- Se agrego `RuleCheckpoint` para snapshot persistente de runtime (`StateJson`, `CheckpointedAt`) orientado a rehidratacion.

## Verification checklist
- Compilar API: `dotnet build telemetric-api/src/Telemetric.Api/Telemetric.Api.csproj` (resultado: 0 errores).
- Verificar inmutabilidad de `RuleTemplateVersion`: propiedades clave con `private set` y validacion de constructor.
- Verificar relacion obligatoria en `RuleInstance`: incluye `RuleTemplateVersionId` no nullable.
- Verificar contrato de `ActionAttempt`: solo `Success|Fail`, y `CreateFail` exige `error` no vacio.
- Verificar alcance: no se crearon endpoints ni cambios de runtime/hub en esta fase.

## Notes / Risks
- La compilacion reporta warnings de nulabilidad preexistentes en el proyecto; no se introdujeron errores.
- El mapeo EF y constraints SQL quedan para la fase 02 (incluyendo bloqueo de duplicado en persistencia).

---
