# FASE 03 - ACT-007

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
- telemetric-front/src/features/actions/views/ActionsTemplatesView.vue
- telemetric-front/src/features/actions/actions.service.ts
- telemetric-front/src/features/actions/types.ts
- contexto/work/features/acciones_modulo/04_test/ACT-007/STORY_QA.md
- contexto/work/features/acciones_modulo/03_execution/ACT-007/phase-03.md

## Changes summary
- Se agrego el tab `Rules` en `/actions` dentro de `ActionsTemplatesView` sin romper tabs existentes (`Runs` y `Templates`).
- Se incorporo listado server-side de reglas via `actionsService.getRules(...)` con filtro por estado operativo (`Enabled`/`Paused`).
- Se implemento render de estado operativo (`Enabled`/`Paused`) y badge rojo `Ultimo fail` en base a `hasLastAttemptFail` y ultimo intento.
- Se agrego accion de pausar/rehabilitar por fila (iconos + tooltip) con permiso `Actions.Update`, consumiendo `PATCH /actions/rules/{ruleInstanceId}/state`.
- Se extendieron contratos tipados en `types.ts` para reglas (`ActionRuleListItem`, `ActionRulesQueryParams`, `UpdateRuleState*`) y se actualizaron los estados UX de loading/empty/error/success para el tab Rules.

## Verification checklist
- Frontend typecheck ejecutado: `npm run typecheck` en `telemetric-front`.
- Resultado typecheck: salida con deuda tecnica preexistente del repo (fallo global), sin errores en archivos tocados de la fase.
- Conteo automatizado de errores:
  - `ERROR_TOTAL=139`
  - `ERROR_NON_DEMO=118` (excluye `src/_demo/**`)
  - `ERROR_TOUCHED_FILES=0` (`src/features/actions/actions.service.ts`, `src/features/actions/types.ts`, `src/features/actions/views/ActionsTemplatesView.vue`)
- Verificacion funcional esperada:
  - `/actions` muestra tab `Rules` junto a `Runs` y `Templates`.
  - Toggle de estado en Rules llama `updateRuleState` y recarga tabla.
  - Badge rojo se muestra cuando `hasLastAttemptFail=true`.

## Notes / Risks
- El gate de no-regresion FE se mantiene a nivel de archivos tocados (`ERROR_TOUCHED_FILES=0`), pero el repositorio conserva deuda global de typecheck fuera del alcance de esta fase.
- La consistencia cruzada con Device Detail queda para fase 04 (scope separado por plan).
