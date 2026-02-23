# FASE 03 — ACT-005

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
- telemetric-front/src/features/actions/views/ActionsTemplatesView.vue
- contexto/work/features/acciones_modulo/04_test/ACT-005/STORY_QA.md
- contexto/work/features/acciones_modulo/04_test/ACT-005/phase-03/evidence/commands.log
- contexto/work/features/acciones_modulo/04_test/ACT-005/phase-03/evidence/outputs.log
- contexto/work/features/acciones_modulo/03_execution/ACT-005/phase-03.md

## Changes summary
- Se reemplazó la captura manual por `textarea` JSON en `/actions` por un builder guiado con campos estructurados del DSL v1 (ruleType, condition, evaluation, missing data policy, lifecycle y recipients email).
- Se agregó validación previa al submit en frontend para bloquear guardado con reglas incompletas o inválidas (`windowSeconds`, `durationSeconds`, `minCount`, `ttlSeconds`, destinatarios email).
- Se mantuvo el flujo de listado y modal create/detail, incluyendo asignación de templates a dispositivos en modo detalle.
- En edición se hidrata el builder desde `currentVersion.definitionJson` cuando el JSON es válido.

## Verification checklist
- UI `/actions` permite configurar los 5 `ruleType` sin editar JSON manual.
- Guardado bloqueado por validaciones de builder cuando hay inconsistencias temporales (`durationSeconds > windowSeconds`) o campos faltantes.
- `missingDataPolicy=HOLD_LAST_VALUE` exige `ttlSeconds > 0` antes de submit.
- `action.recipients` exige al menos un email y formato válido.
- Typecheck ejecutado: `npm --prefix telemetric-front run typecheck`.
- Evidencia no-regresión no-demo en `phase-03/evidence/outputs.log`: `observed_no_demo_ts_errors=118`, baseline `240`, resultado `PASS`.

## Notes / Risks
- Se observó deuda de typecheck global fuera del scope de esta fase (incluye `_demo` y módulos no relacionados); no bloquea el gate no-demo para ACT-005.
- Para respetar el límite estricto de archivos por fase, no se incluyeron artefactos QA adicionales (QA_PACK/CHECKLIST/scripts) en esta corrida.
