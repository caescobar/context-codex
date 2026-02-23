# FASE 02 — ACT-005

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
- telemetric-api/src/Telemetric.Api/Features/Actions/Templates/CreateTemplate/CreateTemplateCommandHandler.cs
- telemetric-api/src/Telemetric.Api/Features/Actions/Templates/UpdateTemplate/UpdateTemplateCommandHandler.cs
- telemetric-api/src/Telemetric.Api/Features/Actions/Assignments/CreateRuleFromDevice/CreateRuleFromDeviceCommandHandler.cs
- contexto/work/features/acciones_modulo/03_execution/ACT-005/phase-02.md

## Changes summary
- Se agregó validación semántica DSL server-side para `CreateTemplate` y `UpdateTemplate` antes de persistir `DefinitionJson`.
- Se agregó validación semántica DSL en `CreateRuleFromDevice` cuando `CreateReusableTemplate=true` para validar y normalizar el template reusable antes de crear versión 1.
- Se validan reglas temporales por `ruleType`: `windowSeconds` rango v1, `durationSeconds` obligatorio solo cuando aplica y regla global `durationSeconds <= windowSeconds`.
- Se validan políticas de missing data: `HOLD_LAST_VALUE` exige `ttlSeconds` válido (`1..604800`) y `INSUFFICIENT_DATA` rechaza `ttlSeconds` con valor.
- Se validan recipients con path determinista por índice (`action.recipients[i]`), formato email básico, largo máximo y normalización (`trim`, `lowercase`, `unique`) antes de persistencia.

## Verification checklist
- `dotnet build telemetric-api/src/Telemetric.Api/Telemetric.Api.csproj -nologo -clp:Summary -v:m` ejecutado: OK (0 errores).
- Verificación de rechazo temporal (`T > W`): la validación retorna error en `evaluation.durationSeconds` cuando supera `evaluation.windowSeconds`.
- Verificación de TTL: la validación retorna error cuando `missingDataPolicy.mode=HOLD_LAST_VALUE` y falta `ttlSeconds` o no está en rango válido.
- Verificación de recipients: la validación retorna error indexado por path (`action.recipients[i]`) para formato inválido/no string/vacío.
- Verificación de estilo backend: se mantiene flujo `Result<T>.Failure(...)` en handlers y mapeo de errores HTTP 400 en endpoints existentes (`Send.ErrorsAsync(400)`).

## Notes / Risks
- Para respetar límite estricto de archivos por fase, no se generaron artefactos QA adicionales en `04_test/ACT-005/phase-02`.
- La lógica de validación quedó duplicada en 3 handlers por restricción de alcance/archivos de esta fase; puede factorizarse en una fase posterior si se aprueba explícitamente.
