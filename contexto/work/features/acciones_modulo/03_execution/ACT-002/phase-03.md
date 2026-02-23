# FASE 03 - ACT-002

## Estado
DONE

## Standards Lock Check
- Backend: ADOPTED (ref: audit A0)
- SQLServer: ADOPTED (ref: audit A0)

## Files touched (max 5)
- telemetric-api/src/Telemetric.Api/Features/Actions/ResolveManual/ResolveManualEndpoint.cs
- telemetric-api/src/Telemetric.Api/Features/Actions/ResolveManual/ResolveManualCommandHandler.cs
- telemetric-api/src/Telemetric.Api/Domain/Constants/PermissionClaims.cs
- contexto/openapi/actions.yaml
- contexto/work/features/acciones_modulo/03_execution/ACT-002/phase-03.md

## Changes summary
- Se implemento `POST /api/v1/actions/rules/{RuleInstanceId}/resolve-manual` con `Tags("Actions")` y policy `PermissionClaims.Actions.ResolveManual`.
- Se aplico patron de 2 archivos por feature: `Endpoint` + `CommandHandler` (con `Command` en el mismo archivo del handler).
- Se registro la solicitud de resolve manual en `RuleCheckpoint.StateJson` y se propago `resolveRequested=1` a Redis (`actions:runtime:rule:{RuleInstanceId}`).
- Se actualizo el delta OpenAPI en `contexto/openapi/actions.yaml`.
- Se corrigio este reporte para reflejar la estructura final real y evitar inconsistencias.

## Verification checklist
- Build backend ejecutado: `dotnet build telemetric-api/src/Telemetric.sln` -> OK (0 errores, 0 warnings en esta corrida).
- Verificacion de endpoint:
  - Ruta `Post("/api/v1/actions/rules/{RuleInstanceId}/resolve-manual")` presente.
  - `Tags("Actions")` presente.
  - `Policies(PermissionClaims.Actions.ResolveManual)` presente.
- Verificacion de contratos tipados:
  - `ResolveManualRequest` y `ResolveManualResponse` definidos en `ResolveManualEndpoint.cs`.
  - `ResolveManualCommand` y `ResolveManualCommandHandler` definidos juntos en `ResolveManualCommandHandler.cs`.
- Verificacion OpenAPI:
  - Path `/api/v1/actions/rules/{ruleInstanceId}/resolve-manual` presente.
  - Schema `ResolveManualResponse` presente.
- Smoke/integration real de API (HTTP + DB + Redis) no ejecutado en esta corrida porque requiere entorno levantado (API + SQL Server + Redis + auth token).

## Notes / Risks
- No se detectaron caracteres mojibake (patrones tipo `Ã`, `â`, `?`) en `phase-03.md` en la revision actual.
- Si Redis no esta disponible, el handler mantiene trazabilidad en SQL checkpoint pero no garantiza propagacion inmediata al runtime.

---