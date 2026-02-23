# FIX - ACT-004 - phase-01

## Trigger
- Estado original: READY_CON_HALLAZGOS
- Razon: el endpoint nuevo no tiene evidencia de smoke/integration ejecutada en QA de la fase.

## Fix Scope
- Must be implementable in <= 5 files.
- Must not expand story scope.
- If requires plan changes: set `NEEDS_REAUDIT=1`.

## NEEDS_REAUDIT
- NEEDS_REAUDIT: 0

## Target Phase (suggested)
- phase_id_suggested: 02
- phase_label: fix-01

## Files (max 5)
- contexto/work/features/acciones_modulo/04_test/ACT-004/phase-01/scripts/run.ps1
- contexto/work/features/acciones_modulo/04_test/ACT-004/phase-01/scripts/run.sh
- contexto/work/features/acciones_modulo/04_test/ACT-004/phase-01/evidence/commands.log
- contexto/work/features/acciones_modulo/04_test/ACT-004/phase-01/evidence/outputs.log
- contexto/work/features/acciones_modulo/04_test/ACT-004/phase-01/evidence/notes.md

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
  - contexto/work/features/acciones_modulo/04_test/ACT-004/phase-02/evidence/commands.log
  - contexto/work/features/acciones_modulo/04_test/ACT-004/phase-02/evidence/outputs.log
  - contexto/work/features/acciones_modulo/04_test/ACT-004/phase-02/evidence/notes.md
  - contexto/work/features/acciones_modulo/04_test/ACT-004/phase-02/INDEX.md
