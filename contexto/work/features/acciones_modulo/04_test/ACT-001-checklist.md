# ACT-001 - Checklist de validacion DB/Domain (Fase 03)

## Objetivo
Validar de forma reproducible los AC fundacionales de `ACT-001` en dominio y persistencia, sin tocar runtime/hub ni endpoints.

## Precondiciones
- Ejecutar desde raiz de repo.
- Tener `dotnet` instalado.
- Tener `rg` (ripgrep) disponible.

## Ejecucion
1. Compilacion base del modulo API
   - Comando: `dotnet build telemetric-api/src/Telemetric.Api/Telemetric.Api.csproj`
   - Esperado: `Build succeeded` con `0 Error(s)`.

2. AC1 - Versionado inmutable de templates
   - Comando: `rg --line-number "RuleTemplateId|VersionNumber|DefinitionJson|private set" telemetric-api/src/Telemetric.Api/Domain/Entities/RuleTemplateVersion.cs`
   - Esperado:
     - `RuleTemplateId`, `VersionNumber`, `DefinitionJson` con `private set`.
     - Constructor valida `definitionJson` requerido.
   - Evidencia esperada: `telemetric-api/src/Telemetric.Api/Domain/Entities/RuleTemplateVersion.cs:35`, `telemetric-api/src/Telemetric.Api/Domain/Entities/RuleTemplateVersion.cs:37`, `telemetric-api/src/Telemetric.Api/Domain/Entities/RuleTemplateVersion.cs:39`.

3. AC2 - Rechazo de duplicado `(DeviceId, RuleTemplateVersionId)`
   - Comando (EF): `rg --line-number "UQ_RuleInstance_Device_TemplateVersion" telemetric-api/src/Telemetric.Api/Infrastructure/Persistence/Contexts/TelemetricDbContext.cs`
   - Comando (SQL): `rg --line-number "UQ_RuleInstance_Device_TemplateVersion" telemetric-api/scripts/012_create_actions_schema.sql`
   - Esperado:
     - Indice unico en EF y SQL con el mismo nombre.
   - Evidencia esperada: `telemetric-api/src/Telemetric.Api/Infrastructure/Persistence/Contexts/TelemetricDbContext.cs:578`, `telemetric-api/scripts/012_create_actions_schema.sql:94`.

4. AC3 - Registro `ActionAttempt` success/fail + error obligatorio en fail
   - Comando (Domain): `rg --line-number "StatusSuccess|StatusFail|CreateSuccess|CreateFail|Error is required when status is Fail" telemetric-api/src/Telemetric.Api/Domain/Entities/ActionAttempt.cs`
   - Comando (SQL): `rg --line-number "CK_ActionAttempt_Status|CK_ActionAttempt_ErrorOnFail" telemetric-api/scripts/012_create_actions_schema.sql`
   - Esperado:
     - Dominio limitado a `Success|Fail`.
     - `CreateFail` exige `error`.
     - SQL enforcea `Status` y obligatoriedad de `Error` cuando `Status='Fail'`.
   - Evidencia esperada: `telemetric-api/src/Telemetric.Api/Domain/Entities/ActionAttempt.cs:7`, `telemetric-api/src/Telemetric.Api/Domain/Entities/ActionAttempt.cs:54`, `telemetric-api/scripts/012_create_actions_schema.sql:113`, `telemetric-api/scripts/012_create_actions_schema.sql:114`.

5. AC4 - Presencia operativa de `RuleCheckpoint` para recuperacion
   - Comando (Domain): `rg --line-number "StateJson|CheckpointedAt|RuleInstanceId" telemetric-api/src/Telemetric.Api/Domain/Entities/RuleCheckpoint.cs`
   - Comando (EF/SQL): `rg --line-number "RuleCheckpoint|IX_RuleCheckpoint_RuleInstanceId|FK_RuleCheckpoint_RuleInstance" telemetric-api/src/Telemetric.Api/Infrastructure/Persistence/Contexts/TelemetricDbContext.cs telemetric-api/scripts/012_create_actions_schema.sql`
   - Esperado:
     - Entidad con `StateJson` requerido y `CheckpointedAt`.
     - Tabla, FK e indice para consulta por `RuleInstanceId`.
   - Evidencia esperada: `telemetric-api/src/Telemetric.Api/Domain/Entities/RuleCheckpoint.cs:32`, `telemetric-api/src/Telemetric.Api/Infrastructure/Persistence/Contexts/TelemetricDbContext.cs:627`, `telemetric-api/scripts/012_create_actions_schema.sql:145`.

6. AC5 - Sin contaminacion runtime/API
   - Comando: `rg --line-number "RuleTemplate|RuleTemplateVersion|RuleInstance|ActionAttempt|RuleCheckpoint|AlertFired" telemetric-api/src/Telemetric.Api/Features telemetric-hub`
   - Esperado:
     - Sin resultados (sin endpoints/hub/runtime de ACT-001 en esta historia fundacional).

## Resultado de referencia en esta corrida
- `dotnet build`: OK (`0 Error(s)`, `0 Warning(s)`).
- AC1..AC4: evidencias localizadas en Domain + EF + SQL.
- AC5: sin resultados en `Features` ni `telemetric-hub`.
