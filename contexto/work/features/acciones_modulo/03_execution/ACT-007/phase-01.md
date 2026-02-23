# FASE 01 — ACT-007

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
- contexto/openapi/actions.yaml
- contexto/work/features/acciones_modulo/03_execution/ACT-007/phase-01.md

## Changes summary
- Se ejecuto discovery/equivalence de endpoints en `telemetric-api/src/Telemetric.Api/Features/Actions/*` y se confirmo ausencia de endpoints dedicados para listado de Rules (global/device) y toggle de estado.
- Se actualizo `contexto/openapi/actions.yaml` con delta ACT-007 para contratos de Rules:
  - `GET /api/v1/actions/rules` (listado global)
  - `GET /api/v1/actions/devices/{deviceId}/rules` (listado por dispositivo)
  - `PATCH /api/v1/actions/rules/{ruleInstanceId}/state` (toggle enabled/paused)
- Se agregaron esquemas tipados para Rules: `GetRulesResponse`, `RuleListItem`, `RuleOperationalStatus`, `UpdateRuleStateRequest`, `UpdateRuleStateResponse`.
- El payload de Rules explicita `ruleInstanceId`, estado `isPaused/operationalStatus` y señal de badge rojo por ultimo fail (`hasLastAttemptFail`, `lastAttemptStatus`, `lastAttemptedAt`).

## Verification checklist
- Ejecutado `rg --files telemetric-api/src/Telemetric.Api/Features/Actions` para inventario de endpoints existentes.
- Ejecutado `rg -n "Get\(|Post\(|Put\(|Patch\(|Delete\(|/api/v1/actions|Policies\(|Tags\(" telemetric-api/src/Telemetric.Api/Features/Actions -g "*Endpoint.cs"` para verificar rutas existentes y ausencia de rutas `rules` de listado/toggle.
- Verificado en `telemetric-api/src/Telemetric.Api/Domain/Constants/PermissionClaims.cs` que existen `Actions.View` y `Actions.Update` para alinear `x-required-policy` del delta OpenAPI.
- Verificado en `contexto/openapi/actions.yaml` que los nuevos endpoints mantienen versionado `/api/v1`, tag `Actions`, seguridad bearer y respuestas `200/400/404` segun corresponda.

## Notes / Risks
- Riesgo residual: los campos de badge rojo se definieron con semantica de "ultimo ActionAttempt"; la implementacion backend de fase 02 debe asegurar orden consistente (global/device/template).
- Riesgo residual: el endpoint por dispositivo retorna `404` para out-of-scope; confirmar comportamiento exacto en handler para evitar divergencia con UI.
