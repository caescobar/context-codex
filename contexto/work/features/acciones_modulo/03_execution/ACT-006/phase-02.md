# FASE 02 — ACT-006

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
- telemetric-api/src/Telemetric.Api/Features/Actions/Runs/GetRuns/GetRunsEndpoint.cs
- telemetric-api/src/Telemetric.Api/Features/Actions/Runs/GetRuns/GetRunsQueryHandler.cs
- telemetric-api/src/Telemetric.Api/Features/Actions/Templates/GetTemplateRuns/GetTemplateRunsEndpoint.cs
- telemetric-api/src/Telemetric.Api/Features/Actions/Templates/GetTemplateRuns/GetTemplateRunsQueryHandler.cs
- contexto/work/features/acciones_modulo/03_execution/ACT-006/phase-02.md

## Changes summary
- Se implemento endpoint GET `/api/v1/actions/runs` con policy `Actions.View`, filtro opcional por `status` y respuesta paginada tipada.
- Se implemento endpoint GET `/api/v1/actions/templates/{RuleTemplateId}/runs` con policy `Actions.View`, validacion de template y filtro opcional por `status`.
- Ambas queries leen desde `ActionAttempt` como fuente de verdad, aplican `AsNoTracking`, filtro por tenant (`ClientId`) y orden descendente por intento mas reciente.
- Se incluyo `error` en cada run para casos `Fail` y separacion de contexto (`Global` / `Template`) en el DTO de salida.

## Verification checklist
- `dotnet build telemetric-api/src/Telemetric.Api/Telemetric.Api.csproj -nologo` -> PASS (0 errores).
- Validado en codigo que `/api/v1/actions/runs` proyecta `ActionAttemptId`, `RuleInstanceId`, `RuleTemplateId`, `Status`, `Error`, `AttemptedAt` y contexto `Global`.
- Validado en codigo que `/api/v1/actions/templates/{RuleTemplateId}/runs` filtra por `RuleTemplateId`, respeta tenant scope y devuelve `404` cuando el template no existe/no esta en alcance.
- Validado en codigo que ambos handlers usan `AsNoTracking`, filtro por soft-delete y orden `AttemptedAt desc`.

## Notes / Risks
- El build mantiene warnings preexistentes del repositorio que no forman parte de ACT-006 fase 02.
- La validacion funcional end-to-end (smoke/integration) queda para el QA pack de fases posteriores.
