# FASE 04 — ACT-006

## Estado
DONE

## Standards Lock Check
- Backend: ADOPTED (ref: audit A0)
- SQLServer: ADOPTED (ref: audit A0)
- Frontend: ADOPTED (ref: audit A0)

## FIX Mode
- is_fix: 0
- fix_id: NA
- fix_pack_used: NA

## Files touched (max 5)
- telemetric-front/src/features/actions/views/ActionTemplateDetailView.vue
- telemetric-front/src/features/actions/actions.service.ts
- telemetric-front/src/features/actions/types.ts
- telemetric-api/src/Telemetric.Api/Features/Actions/Templates/GetTemplateById/GetTemplateByIdQueryHandler.cs
- contexto/work/features/acciones_modulo/03_execution/ACT-006/phase-04.md

## Changes summary
- Se completo la tab `Runs` en `/actions/templates/:id` con historial paginado por template usando `UiServerTable`, filtro por estado (`Success`/`Fail`) y estados UX de error/empty.
- Se agrego en frontend el consumo tipado de runs por template (`getTemplateRuns`) y el contrato de parametros correspondiente.
- Se mantuvo aislamiento de contexto: la vista de detalle consulta exclusivamente `/actions/templates/{id}/runs`, separado del listado global `/actions/runs`.
- Se alineo `failedRunsCount` en `GetTemplateByIdQueryHandler` con los mismos filtros de soft-delete/tenant usados en runs por template para evitar contradicciones entre conteo y detalle.

## Verification checklist
- `dotnet build telemetric-api/src/Telemetric.Api/Telemetric.Api.csproj -nologo` -> PASS (0 errores, warnings preexistentes fuera de scope).
- `npm --prefix telemetric-front run typecheck -- --pretty false` -> FAIL por deuda tecnica preexistente global del repositorio.
- `npm --prefix telemetric-front run typecheck -- --pretty false 2>&1 | Select-String "features/actions/views/ActionTemplateDetailView|features/actions/actions.service|features/actions/types"` -> `NO_ACTIONS_TYPECHECK_ERRORS`.
- Revision funcional de codigo: tab `Runs` en detalle muestra status, error legible para `Fail`, contexto e intento; incluye filtro y mensaje empty cuando no hay resultados.

## Notes / Risks
- El gate de typecheck global continua pendiente por errores historicos fuera de `features/actions`.
- No se actualizo OpenAPI en esta fase porque los endpoints de runs ya estaban documentados desde fases previas y no hubo cambio de contrato.
