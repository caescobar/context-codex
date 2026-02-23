# FASE 02 — ACT-002

## Estado
DONE

## Standards Lock Check
- Backend: ADOPTED (ref: audit A0)
- SQLServer: ADOPTED (ref: audit A0)

## Files touched (max 5)
- telemetric-api/src/Telemetric.Api/Domain/Entities/ActionAttempt.cs
- telemetric-api/src/Telemetric.Api/Domain/Entities/RuleCheckpoint.cs
- telemetric-api/src/Telemetric.Api/Infrastructure/Persistence/Contexts/TelemetricDbContext.cs
- telemetric-api/scripts/012_create_actions_schema.sql

## Changes summary
- Se reforzó `ActionAttempt` para persistir `Error` solo cuando `Status=Fail`, evitando estados inconsistentes en escritura runtime.
- Se agregó `RuleCheckpoint.UpdateState(...)` para actualizar checkpoint de forma controlada y con `CheckpointedAt` renovado para rehidratación.
- Se alineó EF Core con checks de consistencia de `ActionAttempt` y se definió checkpoint único por `RuleInstance` para lectura determinística tras caída.
- Se actualizó el script SQL oficial (`telemetric-api/scripts/012_create_actions_schema.sql`) con constraints idempotentes y migración segura de índice de checkpoint a único.

## Verification checklist
- Compilación backend OK: `dotnet build telemetric-api/src/Telemetric.sln`.
- Ejecutar script `telemetric-api/scripts/012_create_actions_schema.sql` en entorno de prueba y validar creación/alter de constraints `CK_ActionAttempt_Status` y `CK_ActionAttempt_ErrorConsistency`.
- Validar en SQL que existe índice único `UQ_RuleCheckpoint_RuleInstance` y que se eliminó `IX_RuleCheckpoint_RuleInstanceId` cuando aplica.
- Probar inserción `ActionAttempt` con `Status='Success'` y `Error` no nulo: debe fallar por constraint.
- Probar inserción/actualización de `RuleCheckpoint` por mismo `RuleInstanceId`: debe mantenerse una sola fila lógica por regla.

## Notes / Risks
- Si ya existen duplicados de `RuleCheckpoint` por `RuleInstanceId`, la creación del índice único fallará hasta depurar datos previos.
- El build expone warnings preexistentes del repositorio (sin errores), no introducidos por esta fase.

---
