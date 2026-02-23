### Crear StoryPack

MODO: PIPELINE

Usa skill: telemetric-storypack-pipeline

Inputs:
- slug: acciones_modulo


### Auditar una  Historia 

MODO: AUDIT-ONLY (NO CODE)

Usa skill: telemetric-story-impl-auditor

Inputs:
- requirement_slug: acciones_modulo
- story_id: ACT-001


### Registrar decisiones si el audit sale BLOQUEADO (solo si aplica)
MODO: DECISIONS (NO CODE)

Crea/actualiza el archivo:
- contexto/work/features/acciones_modulo/DECISIONS.md

Agrega una entrada:
- ID: D-ACT-001-B1
- Story: ACT-001
- Pregunta: <texto exacto>
- Decisión: <A|B + detalle>
- Fecha: 2026-02-16


### Implementar fases (una por prompt)

MODO: IMPLEMENTATION (ONE PHASE ONLY)

Usa skill: telemetric-story-impl-executor

Inputs:
- requirement_slug: acciones_modulo
- story_id: ACT-007
- phase_id: 04




### Implmentar QA PACK (una por prompt)
MODO: IMPLEMENTATION (QA PACK)

Usa skill: telemetric-qa-pack-builder

Inputs:
- requirement_slug: acciones_modulo
- story_id: ACT-007
- phase_id: 03

## MODO: EXECUTION (QA PACK)

Usa skill: `telemetric-qa-pack-executor`

### Prompt base
MODO: EXECUTION (QA PACK)

Usa skill: telemetric-qa-pack-executor

Inputs:
- requirement_slug: acciones_modulo
- story_id: ACT-007
- phase_id: 03



### Auditoria de codigo

Usa el skill: telemetric-post-impl-reviewer

Inputs:
- requirement_slug: acciones_modulo
- story_id: ACT-003
- phase_id: 03

Objetivo:
Revisar que la fase 03 cumple plan + standards + QA pack y que el gate de typecheck no-demo no regresa.
Si hay hallazgos, devolverlos con severidad y decir si necesito una fase FIX.


### SI existe fixed lo ejecuta

Usa el skill: telemetric-fix-orchestrator

Inputs:
- requirement_slug: acciones_modulo
- story_id: ACT-004
- phase_id: 01

Objetivo:
Leer el FIX PACK `phase-03.fix.md` y devolver prompts mínimos para ejecutar el fix (executor), QA (si aplica) y review final.


Usa el skill: telemetric-story-impl-executor

Inputs:
- requirement_slug: acciones_modulo
- story_id: ACT-003
- is_fix: 1
- fix_id: 03.01
- fix_pack_path: contexto/work/features/acciones_modulo/03_execution/ACT-003/phase-03.fix-01.md
