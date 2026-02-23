# FASE 02 - ACT-001

## Estado
DONE

## Standards Lock Check
- Backend: ADOPTED (ref: audit A0)
- SQLServer: ADOPTED (ref: audit A0)

## Files touched (max 5)
- telemetric-api/src/Telemetric.Api/Common/Interfaces/IApplicationDbContext.cs
- telemetric-api/src/Telemetric.Api/Infrastructure/Persistence/Contexts/TelemetricDbContext.cs
- telemetric-api/scripts/012_create_actions_schema.sql

## Changes summary
- Se agregaron `DbSet` para `RuleTemplate`, `RuleTemplateVersion`, `RuleInstance`, `ActionAttempt` y `RuleCheckpoint` en `IApplicationDbContext`.
- Se integraron mapeos EF en `TelemetricDbContext` para las 5 entidades de Acciones con tablas, defaults de auditoria, FKs e indices.
- Se aplico constraint unico `UQ_RuleInstance_Device_TemplateVersion` para bloquear duplicados por `(DeviceId, RuleTemplateVersionId)`.
- Se agrego script SQL oficial `telemetric-api/scripts/012_create_actions_schema.sql` con creacion idempotente de tablas/indices/constraints para ACT-001.
- `AlertFired` no se materializa en SQL en esta fase, respetando D-ACT-001-B2.

## Verification checklist
- Compilar API: `dotnet build telemetric-api/src/Telemetric.Api/Telemetric.Api.csproj` (resultado: 0 errores, warnings preexistentes).
- Verificar contrato de duplicados en EF: indice unico `UQ_RuleInstance_Device_TemplateVersion` en `TelemetricDbContext`.
- Verificar contrato de duplicados en SQL: indice unico `UQ_RuleInstance_Device_TemplateVersion` en `012_create_actions_schema.sql`.
- Verificar regla de `ActionAttempt` fail/error en SQL: `CK_ActionAttempt_Status` y `CK_ActionAttempt_ErrorOnFail`.
- Verificar alcance de fase: sin endpoints nuevos, sin cambios en runtime/hub, sin tabla `AlertFired`.

## Notes / Risks
- No se ejecutaron scripts SQL contra una instancia real en esta fase; la validacion de DDL queda para ejecucion en entorno DB.
- Se agrego unicidad de version por template (`UQ_RuleTemplateVersion_Template_Version`) para consistencia del versionado inmutable.

---
