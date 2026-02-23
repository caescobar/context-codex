# FIX - ACT-004 - phase-03

## Trigger
- Estado original: READY_CON_HALLAZGOS
- Razon: falta QA pack canonico de phase-03 y no hay evidencia reproducible del gate typecheck no-demo.

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
- NEEDS_SPLIT: 1
- El orchestrator debe dividir este base fix en `phase-03.fix-01.md`, `phase-03.fix-02.md`, ... con <= 5 archivos por pack.

## Target Phase (suggested)
- phase_id_suggested: 04
- phase_label: fix-base (este label NO se usa para ejecucion; el orchestrator asigna fix-01, fix-02, ...)

## Fix Items (can exceed 5 files in BASE)
1. F-001 (Severidad: P1) - Crear QA pack canonico de ACT-004 phase-03.
Evidencia: ausencia de `contexto/work/features/acciones_modulo/04_test/ACT-004/phase-03/`; requisito de plan en `contexto/work/features/acciones_modulo/02_plans/ACT-004.plan.md:227`.
Accion recomendada (sin codigo): crear estructura canonica `INDEX.md`, `QA_PACK.md`, `CHECKLIST.md`, `scripts/`, `evidence/` para phase-03 y registrar la fase en `STORY_QA.md`.
Archivos involucrados:
- contexto/work/features/acciones_modulo/04_test/ACT-004/STORY_QA.md
- contexto/work/features/acciones_modulo/04_test/ACT-004/phase-03/INDEX.md
- contexto/work/features/acciones_modulo/04_test/ACT-004/phase-03/QA_PACK.md
- contexto/work/features/acciones_modulo/04_test/ACT-004/phase-03/CHECKLIST.md
- contexto/work/features/acciones_modulo/04_test/ACT-004/phase-03/scripts/run.ps1
- contexto/work/features/acciones_modulo/04_test/ACT-004/phase-03/scripts/run.sh
- contexto/work/features/acciones_modulo/04_test/ACT-004/phase-03/scripts/setup.ps1
- contexto/work/features/acciones_modulo/04_test/ACT-004/phase-03/scripts/setup.sh
- contexto/work/features/acciones_modulo/04_test/ACT-004/phase-03/scripts/teardown.ps1
- contexto/work/features/acciones_modulo/04_test/ACT-004/phase-03/scripts/teardown.sh
- contexto/work/features/acciones_modulo/04_test/ACT-004/phase-03/evidence/commands.log
- contexto/work/features/acciones_modulo/04_test/ACT-004/phase-03/evidence/outputs.log
- contexto/work/features/acciones_modulo/04_test/ACT-004/phase-03/evidence/notes.md
Gates: typecheck_no_demo required, smoke_tests na, sql_migration_check na

2. F-002 (Severidad: P1) - Registrar evidencia no-regresion typecheck no-demo con baseline->after para phase-03.
Evidencia: `contexto/work/features/acciones_modulo/02_plans/ACT-004.plan.md:231`; evidencia insuficiente en `contexto/work/features/acciones_modulo/03_execution/ACT-004/phase-03.md:35`.
Accion recomendada (sin codigo): ejecutar comandos acordados del gate no-demo, capturar conteo baseline y after, y dejar resultado PASS/FAIL trazable en `INDEX.md` + `evidence/outputs.log`.
Archivos involucrados:
- contexto/work/features/acciones_modulo/04_test/ACT-004/phase-03/INDEX.md
- contexto/work/features/acciones_modulo/04_test/ACT-004/phase-03/QA_PACK.md
- contexto/work/features/acciones_modulo/04_test/ACT-004/phase-03/evidence/commands.log
- contexto/work/features/acciones_modulo/04_test/ACT-004/phase-03/evidence/outputs.log
- contexto/work/features/acciones_modulo/04_test/ACT-004/phase-03/evidence/notes.md
Gates: typecheck_no_demo required, smoke_tests na, sql_migration_check na

## Actions (ordered)
1) Crear el QA pack canonico de `phase-03` bajo la ruta lockeada.
2) Actualizar `STORY_QA.md` para incluir `phase-03`.
3) Ejecutar `setup` y `run` del pack (dry-run y/o run real segun entorno) para poblar evidencia.
4) Ejecutar y registrar gate typecheck no-demo con baseline->after.
5) Actualizar `INDEX.md` con resultado de gates y trazabilidad de comandos/evidencia.

## Verification (must be concrete)
- `Test-Path contexto/work/features/acciones_modulo/04_test/ACT-004/phase-03` + expected outcome: `True`.
- `rg -n "Descubrimiento \(fuentes y evidencia\)" contexto/work/features/acciones_modulo/04_test/ACT-004/phase-03/QA_PACK.md` + expected outcome: seccion presente.
- `rg -n "observed_no_demo_ts_errors|baseline|PASS|FAIL" contexto/work/features/acciones_modulo/04_test/ACT-004/phase-03/INDEX.md contexto/work/features/acciones_modulo/04_test/ACT-004/phase-03/evidence/outputs.log` + expected outcome: baseline->after trazable y resultado del gate.
- `Test-Path contexto/work/features/acciones_modulo/04_test/ACT-004/phase-03/evidence/commands.log` + expected outcome: `True`.
- `Test-Path contexto/work/features/acciones_modulo/04_test/ACT-004/phase-03/evidence/notes.md` + expected outcome: `True`.

## Gates
- typecheck_no_demo: required
- smoke_tests: na
- sql_migration_check: na

## QA Pack Impact
- qa_pack_required: yes
- qa_exec_required: yes
- If yes: which evidence files must be updated
- contexto/work/features/acciones_modulo/04_test/ACT-004/STORY_QA.md
- contexto/work/features/acciones_modulo/04_test/ACT-004/phase-03/INDEX.md
- contexto/work/features/acciones_modulo/04_test/ACT-004/phase-03/QA_PACK.md
- contexto/work/features/acciones_modulo/04_test/ACT-004/phase-03/CHECKLIST.md
- contexto/work/features/acciones_modulo/04_test/ACT-004/phase-03/evidence/commands.log
- contexto/work/features/acciones_modulo/04_test/ACT-004/phase-03/evidence/outputs.log
- contexto/work/features/acciones_modulo/04_test/ACT-004/phase-03/evidence/notes.md
