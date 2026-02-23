# QA PACK - ACT-003 - phase-04 (fix 03.01)

## Scope
- Validar la correccion UI del FixPack `phase-03.fix-01.md`.
- Confirmar reemplazo de accion textual por accion iconografica con tooltip accesible en `ActionsTemplatesView.vue`.
- Verificar gate `typecheck_no_demo` sin regresion contra baseline vigente.

## Commands
- `rg --line-number "Ver detalle" telemetric-front/src/features/actions/views/ActionsTemplatesView.vue`
- `rg --line-number "v-tooltip|tooltip|icon|EyeIcon" telemetric-front/src/features/actions/views/ActionsTemplatesView.vue`
- `npm --prefix telemetric-front run typecheck`
- Conteo de errores TS no-demo (`src/_demo/**` excluido) sobre salida de `typecheck`.

## Gates
- typecheck_no_demo: PASS (120 <= baseline 240)
- smoke_tests: NA
- sql_migration_check: NA
