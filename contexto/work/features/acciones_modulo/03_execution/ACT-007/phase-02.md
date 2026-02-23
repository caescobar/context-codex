# FASE 02 - ACT-007

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
- telemetric-api/src/Telemetric.Api/Features/Actions/Rules/GetRules/GetRulesEndpoint.cs
- telemetric-api/src/Telemetric.Api/Features/Actions/Rules/GetRules/GetRulesQueryHandler.cs
- telemetric-api/src/Telemetric.Api/Features/Actions/Rules/UpdateRuleState/UpdateRuleStateEndpoint.cs
- telemetric-api/src/Telemetric.Api/Features/Actions/Rules/UpdateRuleState/UpdateRuleStateCommandHandler.cs
- contexto/work/features/acciones_modulo/03_execution/ACT-007/phase-02.md

## Changes summary
- Se implemento `GET /api/v1/actions/rules` con contrato paginado para listar reglas globales y filtro opcional por `deviceId` + `status` (`Enabled`/`Paused`).
- El query de listado aplica alcance por tenant (`ClientId`), valida existencia de dispositivo cuando se filtra por `deviceId`, y calcula senal de badge rojo con el ultimo `ActionAttempt` (`hasLastAttemptFail`, `lastAttemptStatus`, `lastAttemptError`, `lastAttemptedAt`).
- Se implemento `PATCH /api/v1/actions/rules/{ruleInstanceId}/state` para persistir toggle de estado operativo (`IsPaused`) con respuesta tipada (`operationalStatus`).
- El comando de update mantiene control de alcance por tenant y actualiza `UpdatedAt/UpdatedBy` cuando cambia el estado.

## Verification checklist
- Build backend ejecutado: `dotnet build .\Telemetric.sln` en `telemetric-api/src` -> OK (0 errores).
- Verificar listado global: `GET /api/v1/actions/rules?pageNumber=1&pageSize=10` devuelve `PaginatedList<RuleListItemDto>` y respeta tenant.
- Verificar listado por dispositivo: `GET /api/v1/actions/rules?deviceId={deviceId}` devuelve solo reglas del dispositivo o 400 si el `deviceId` no existe/fuera de alcance.
- Verificar filtro operativo: `status=Enabled|Paused` aplica sobre `IsPaused`.
- Verificar badge rojo: `hasLastAttemptFail=true` cuando el ultimo `ActionAttempt` de la regla es `Fail`.
- Verificar toggle: `PATCH /api/v1/actions/rules/{ruleInstanceId}/state` con `{ "isPaused": true|false }` persiste y se refleja en lecturas posteriores.

## Notes / Risks
- El contrato OpenAPI contempla endpoint dedicado por dispositivo (`/api/v1/actions/devices/{deviceId}/rules`), pero en esta fase se resolvio el caso con filtro `deviceId` en el endpoint global para mantener el limite de archivos de la fase.
- No se agregaron artefactos QA en `04_test` en esta fase; la evidencia tecnica de compilacion quedo en esta ejecucion.
