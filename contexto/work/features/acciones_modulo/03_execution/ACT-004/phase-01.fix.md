# FIX - ACT-004 - phase-01

## Trigger
- Estado original: READY_CON_HALLAZGOS
- Razon: el endpoint nuevo no tiene evidencia de smoke/integration ejecutada en QA de la fase.

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
- phase_id_suggested: 02
- phase_label: fix-base (este label NO se usa para ejecucion; el orchestrator asigna fix-01, fix-02, ...)

## Fix Items (can exceed 5 files in BASE)
1. F-001 (Severidad: P1) - Ejecutar y evidenciar smoke/integration del endpoint de asignacion masiva.
- Evidencia: `contexto/work/features/acciones_modulo/03_execution/ACT-004/phase-01.md:41`; `contexto/work/features/acciones_modulo/04_test/ACT-004/phase-01/evidence/outputs.log:554`; `contexto/work/features/acciones_modulo/04_test/ACT-004/phase-01/evidence/notes.md:8`
- Accion recomendada (sin codigo): correr script de fase con `DRY_RUN=0` y variables completas (`API_AUTH_TOKEN`, `TEST_RULE_TEMPLATE_VERSION_ID`, `TEST_DEVICE_IDS`), verificar respuesta del endpoint y registrar resultado reproducible.
- Archivos involucrados:
  - contexto/work/features/acciones_modulo/04_test/ACT-004/phase-01/scripts/run.ps1
  - contexto/work/features/acciones_modulo/04_test/ACT-004/phase-01/scripts/run.sh
  - contexto/work/features/acciones_modulo/04_test/ACT-004/phase-01/evidence/commands.log
  - contexto/work/features/acciones_modulo/04_test/ACT-004/phase-01/evidence/outputs.log
  - contexto/work/features/acciones_modulo/04_test/ACT-004/phase-01/evidence/notes.md
- Gates: typecheck_no_demo na, smoke_tests required, sql_migration_check na

## Actions (ordered)
1) Preparar credenciales y datos de prueba validos para el tenant objetivo.
2) Ejecutar corrida integrada de `phase-01` con `DRY_RUN=0` y variables requeridas.
3) Capturar request/response del endpoint y criterio de aceptacion (Created/RejectedDuplicate/RejectedNotFoundOrOutOfScope).
4) Actualizar evidencia y cierre de fase en QA pack.

## Verification (must be concrete)
- `pwsh contexto/work/features/acciones_modulo/04_test/ACT-004/phase-01/scripts/run.ps1 -DryRun 0` + expected outcome: endpoint smoke ejecutado y resultado PASS en `outputs.log`.
- `rg -n "prueba API integrada" contexto/work/features/acciones_modulo/04_test/ACT-004/phase-01/evidence/outputs.log` + expected outcome: no aparece "omitida"; aparece evidencia de ejecucion.
- `rg -n "Created|RejectedDuplicate|RejectedNotFoundOrOutOfScope" contexto/work/features/acciones_modulo/04_test/ACT-004/phase-01/evidence/outputs.log` + expected outcome: estados de negocio trazables en evidencia.

## Gates
- typecheck_no_demo: na
- smoke_tests: required
- sql_migration_check: na

## QA Pack Impact
- qa_pack_required: yes
- qa_exec_required: yes
- If yes: which evidence files must be updated
  - contexto/work/features/acciones_modulo/04_test/ACT-004/phase-01/evidence/commands.log
  - contexto/work/features/acciones_modulo/04_test/ACT-004/phase-01/evidence/outputs.log
  - contexto/work/features/acciones_modulo/04_test/ACT-004/phase-01/evidence/notes.md
  - contexto/work/features/acciones_modulo/04_test/ACT-004/phase-01/INDEX.md
