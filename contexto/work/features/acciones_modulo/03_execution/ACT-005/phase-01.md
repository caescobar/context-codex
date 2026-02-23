# FASE 01 — ACT-005

## Estado
READY

## Standards Lock Check
- Backend: ADOPTED (ref: audit A0)
- SQLServer: ADOPTED (ref: audit A0)
- Frontend: ADOPTED (ref: audit A0)

## FIX Mode
- is_fix: 0
- fix_id: NA
- fix_pack_used: NA

## Files touched (max 5)
- contexto/openapi/actions.yaml
- telemetric-front/src/features/actions/types.ts
- telemetric-api/src/Telemetric.Api/Features/Actions/Templates/CreateTemplate/CreateTemplateEndpoint.cs
- telemetric-api/src/Telemetric.Api/Features/Actions/Templates/UpdateTemplate/UpdateTemplateEndpoint.cs
- contexto/work/features/acciones_modulo/03_execution/ACT-005/phase-01.md

## Changes summary
- Se reforzó el contrato OpenAPI de `DefinitionJsonV1` agregando `discriminator` por `ruleType` y aclarando que en create/update se espera DSL estructurado (no string JSON).
- Se ajustaron tipos frontend del DSL para quitar ambigüedad temporal por `ruleType`: reglas con duración exigen `evaluation.durationSeconds`; reglas sin duración usan solo `windowSeconds`.
- Se endureció validación backend en create/update template para aceptar únicamente `DefinitionJson` como objeto JSON.
- Se simplificó normalización backend de `DefinitionJson` a `GetRawText()` (persistencia consistente de objeto DSL serializado).
- Se alineó token de ruta del `PUT` (`{ruleTemplateId}`) con el contrato OpenAPI.

## Verification checklist
- `dotnet build telemetric-api/src/Telemetric.Api/Telemetric.Api.csproj -nologo -clp:Summary -v:m` ejecutado: OK (0 errores, warnings preexistentes).
- Validación de endpoints:
  - `CreateTemplateRequestValidator` exige `JsonValueKind.Object`.
  - `UpdateTemplateRequestValidator` exige `JsonValueKind.Object`.
- OpenAPI revisado:
  - `CreateTemplateRequest.definitionJson` y `UpdateTemplateRequest.definitionJson` refieren a `DefinitionJsonV1` con aclaración de objeto DSL.
  - `DefinitionJsonV1` incorpora `discriminator.propertyName=ruleType` y mapping completo de 5 `ruleType`.
- `npm run typecheck` (frontend) ejecutado: FALLA por deuda de typecheck preexistente en múltiples módulos (incluye `_demo` y no-demo); no atribuible a los 4 archivos cambiados en esta fase.

## Notes / Risks
- `RuleTemplateVersionDetail.definitionJson` en frontend sigue tipado como `string` para compatibilidad con la UI actual basada en textarea; la normalización integral de superficies legacy queda para fases posteriores del plan.
- No se generaron artefactos QA en esta fase para respetar el límite estricto de 5 archivos tocados.
