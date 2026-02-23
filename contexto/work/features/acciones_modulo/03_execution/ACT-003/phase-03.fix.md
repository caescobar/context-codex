# FIX - ACT-003 - phase-03

## Trigger
- Estado original: READY_CON_HALLAZGOS
- Raz�n: La implementacion FE de detalle permite edicion/guardado en `/actions/templates/:id`, contrario al plan de fase (detalle read-only y create/edit por modal en `/actions`).

## Fix Scope
- This is a BASE FixPack and MAY reference more than 5 files.
- The 5-file limit is enforced by the executor; the orchestrator is responsible for splitting into `fix-01`, `fix-02`, ... (<= 5 files each).
- Must not expand story scope.
- If the fix requires audit/plan/standards-lock changes OR expands scope => set `NEEDS_REAUDIT=1`.
- If the fix touches more than 5 files BUT can be split safely => set `NEEDS_SPLIT=1` and keep `NEEDS_REAUDIT=0`.
- The reviewer MUST NOT set `NEEDS_REAUDIT=1` only because there are more than 5 files.

## NEEDS_REAUDIT
- NEEDS_REAUDIT: 0

## NEEDS_SPLIT
- NEEDS_SPLIT: 0

## Target Phase (suggested)
- phase_id_suggested: 04
- phase_label: fix-base (este label NO se usa para ejecuci�n; el orchestrator asigna fix-01, fix-02, ...)

## Fix Items (can exceed 5 files in BASE)
1. F-001 (Severidad: P1) - Alinear flujo UX con plan: create/edit por modal en listado y detalle de solo consulta.
- Evidencia: `contexto/work/features/acciones_modulo/02_plans/ACT-003.plan.md:173`, `contexto/work/features/acciones_modulo/02_plans/ACT-003.plan.md:187`, `contexto/work/features/acciones_modulo/02_plans/ACT-003.plan.md:190`, `telemetric-front/src/features/actions/views/ActionTemplateDetailView.vue:120`, `telemetric-front/src/features/actions/views/ActionTemplateDetailView.vue:138`
- Acci�n recomendada (sin c�digo): implementar create/edit mediante modal en `ActionsTemplatesView.vue`; remover formulario editable y acci�n de guardado del detalle, manteniendolo informativo.
- Archivos involucrados:
  - `telemetric-front/src/features/actions/views/ActionsTemplatesView.vue`
  - `telemetric-front/src/features/actions/views/ActionTemplateDetailView.vue`
  - `telemetric-front/src/features/actions/actions.service.ts`
- Gates: typecheck_no_demo required, smoke_tests na, sql_migration_check na

## Actions (ordered)
1) Ajustar `ActionsTemplatesView.vue` para incluir flujo modal de create/edit alineado con contratos existentes de `actions.service.ts`.
2) Convertir `ActionTemplateDetailView.vue` a modo consulta (sin inputs editables ni bot�n de guardado/versionado).
3) Verificar que navegaci�n `/actions` -> `/actions/templates/:id` conserve consistencia funcional y permisos sin ampliar alcance.
4) Actualizar QA pack de fase con nueva corrida y evidencia final de criterios corregidos.

## Verification (must be concrete)
- `npm --prefix telemetric-front run typecheck` + esperado: `no_demo_ts_errors` no aumenta vs `baseline.json` (PASS).
- `rg --line-number -n "Guardar nueva versi�n|v-text-field|v-textarea|saveNewVersion|updateTemplate" telemetric-front/src/features/actions/views/ActionTemplateDetailView.vue` + esperado: sin edici�n/guardado en detalle.
- `rg --line-number -n "modal|v-dialog|create|edit" telemetric-front/src/features/actions/views/ActionsTemplatesView.vue` + esperado: flujo create/edit presente en listado.

## Gates
- typecheck_no_demo: required
- smoke_tests: na
- sql_migration_check: na

## QA Pack Impact
- qa_pack_required: yes
- qa_exec_required: yes
- If yes: which evidence files must be updated
  - `contexto/work/features/acciones_modulo/04_test/ACT-003/phase-04/evidence/commands.log`
  - `contexto/work/features/acciones_modulo/04_test/ACT-003/phase-04/evidence/outputs.log`
  - `contexto/work/features/acciones_modulo/04_test/ACT-003/phase-04/evidence/notes.md`
  - `contexto/work/features/acciones_modulo/04_test/ACT-003/phase-04/INDEX.md`


## Files (max 5)
- telemetric-front/src/features/actions/views/ActionsTemplatesView.vue
- telemetric-front/src/features/actions/views/ActionTemplateDetailView.vue
- telemetric-front/src/features/actions/actions.service.ts