---
name: telemetric-post-impl-reviewer
description: Revisa (sin implementar) una fase ya ejecutada en Telemetric y valida cumplimiento de standards (Backend/SQLServer/Frontend), scope, gates de QA y evidencia. Si hay P0/P1 o BLOQUEADO, genera un FIX PACK (fix.md) machine-friendly para orquestación.
---

# Telemetric Post-Implementation Reviewer — Skill

## Purpose
Perform a **review-only** pass after a phase has been implemented to ensure:
- The phase stayed within the approved plan + scope
- Telemetric standards were followed (Backend + SQLServer, and Frontend if applicable)
- Required QA artifacts and evidence exist (phase QA pack)
- No-regression gates were respected (especially frontend typecheck no-demo)
- Changes are coherent and can be safely promoted

Additionally, when fixes are needed, produce a **machine-friendly FIX PACK** that can be consumed by `telemetric-fix-orchestrator`.

This skill **NEVER writes product code**.

---

## Mode
REVIEW-ONLY (NO CODE)

### Hard Prohibitions
- DO NOT modify any product/source files.
- DO NOT generate patches/diffs or code blocks.
- DO NOT update audit/plan files.
- DO NOT proceed to implementation in the same run.

If the user asks for code:
**“Este run es SOLO REVIEW. Puedo señalar hallazgos y generar un FIX PACK; luego el executor implementa.”**

---

## Inputs (required)
- `requirement_slug`
- `story_id` (e.g., `ACT-003`)
- `phase_id` (e.g., `03`)

## Inputs (optional)
- `audit_path_override`
- `plan_path_override`
- `execution_report_override`
- `qa_phase_dir_override`

---

## Path Resolution (deterministic)
Defaults:
- `audit_path = contexto/work/features/{requirement_slug}/01_audits/{story_id}.audit.md`
- `plan_path  = contexto/work/features/{requirement_slug}/02_plans/{story_id}.plan.md`
- `execution_report = contexto/work/features/{requirement_slug}/03_execution/{story_id}/phase-{phase_id}.md`
- `qa_phase_dir = contexto/work/features/{requirement_slug}/04_test/{story_id}/phase-{phase_id}/`

Outputs:
- `review_report = contexto/work/features/{requirement_slug}/03_execution/{story_id}/phase-{phase_id}.review.md`

Fix outputs (ONLY if needed):
- `fix_base_dir = contexto/work/features/{requirement_slug}/03_execution/{story_id}/`
- `fix_pack = {fix_base_dir}/phase-{phase_id}.fix.md`


Overrides MUST be used if provided.

---

## Standards Inputs (MANDATORY)
Reviewer MUST load and validate against:
- `.codex/skills/telemetric-backend-standards/SKILL.md`
- `.codex/skills/telemetric-sqlserver-standards/SKILL.md`

Conditional (MANDATORY if phase touches FE / includes `telemetric-front/` paths):
- `.codex/skills/telemetric-frontend-standards/SKILL.md`

If any required standards file is missing:
- Output `Estado: BLOQUEADO`
- Provide 1 blocking question.

---

## What to Inspect (mandatory)

### 1) Plan Compliance (scope + 5-file rule)
Compare `Files touched` (from execution report) vs plan phase section:
- Must be <= 5 files touched
- Must match planned target areas
- Must not introduce out-of-scope modules

### 2) Standards Lock Compliance
From `audit_path` section `A0. Standards Lock`:
- Confirm required categories are ADOPTED for this phase
- If phase touched a category that was CONFLICT/NEW/NO-EVIDENCE → `BLOQUEADO`

### 3) QA Pack Presence + Evidence
Validate `qa_phase_dir` exists and contains:
- `INDEX.md`
- `QA_PACK.md` (or project-equivalent referenced by execution report)
- `scripts/` with `run.(ps1|sh)` (at least one)
- `evidence/commands.log`
- `evidence/outputs.log`
- `evidence/notes.md`

Also verify `QA_PACK.md` includes:
- "Descubrimiento (fuentes y evidencia)" section

### 4) Gate Checks (must be explicit)
Verify report/evidence includes:
- FE phases: typecheck no-regression (no-demo scope)
- Endpoint changes: smoke/integration references (if applicable)
- SQL changes: migration/checklist evidence (if applicable)

### 5) Frontend Review (conditional)
If any touched file starts with `telemetric-front/`, check:
- Route meta (`requiresAuth`, `requiresPermission`) if routes touched
- Menu parity if menu touched
- Admin/devices parity if list views touched
- Types: no new `any/unknown` introduced
- Encoding: no mojibake
- UX states (loading/empty/error/success) for affected views

### 6) Backend/SQL Review (conditional)
Validate:
- Backend conventions per standards
- SQL naming/constraints/audit columns per standards
- No implicit uniqueness decision with soft-delete (must be explicit)

---

## Output Artifacts (required)
Always write:
- `review_report` and print same content in chat.

If **Estado=BLOQUEADO** OR there are **P0/P1 findings**, ALSO write:
- `fix_pack` as described below and print a short summary in chat.

---

## Fix Outputs (MANDATORY)

When fixes are needed, the reviewer MUST always create ONLY a single base fix file:

- `fix_base_dir = contexto/work/features/{requirement_slug}/03_execution/{story_id}/`
- `fix_pack_base = {fix_base_dir}/phase-{phase_id}.fix.md`

Rules:
1) The reviewer MUST overwrite `phase-{phase_id}.fix.md` (single source of truth).
2) The reviewer MUST NOT create `phase-{phase_id}.fix-<nn>.md` packs. Splitting is the orchestrator's job.
3) The reviewer MUST NOT set `NEEDS_REAUDIT=1` only because there are >5 files.
   - If fixes exceed 5 files, set `NEEDS_SPLIT=1` in the base fix and keep `NEEDS_REAUDIT=0`.
4) The reviewer MUST set `NEEDS_REAUDIT=1` ONLY if:
   - the fix requires changing audit/plan/standards lock decisions, OR
   - the fix expands story scope beyond plan/spec, OR
   - a SINGLE atomic fix requires >5 files and cannot be split safely.
---

## Review Report Format (mandatory, Spanish)
# REVIEW — FASE {phase_id} — {story_id}

## Estado
READY | READY_CON_HALLAZGOS | BLOQUEADO

## Inputs
- Audit: <path>
- Plan: <path>
- Execution report: <path>
- QA dir: <path>

## Resumen
- bullets

## Compliance Check
### Plan / Scope
- Max 5 files: PASS/FAIL
- Matches planned areas: PASS/FAIL
- Out-of-scope touches: None / List

### Standards Lock
- Backend: PASS/FAIL (evidence)
- SQLServer: PASS/FAIL (evidence)
- Frontend: PASS/FAIL/NA (evidence)

### QA Pack
- Presence: PASS/FAIL
- Discovery section: PASS/FAIL
- Evidence logs: PASS/FAIL
- Scripts: PASS/FAIL

### Gates
- Typecheck no-regression (FE): PASS/FAIL/NA (baseline -> after)
- Endpoints smoke/integration: PASS/FAIL/NA
- SQL migration checklist: PASS/FAIL/NA

## Hallazgos (accionables)
Lista numerada:
- H-001 (Severidad: P0/P1/P2) — descripción corta
  - Evidencia: rutas exactas / sección / archivo
  - Recomendación: qué cambiar (sin código)
  - ¿Requiere FIX?: Sí/No

## Recomendación final
- READY / READY_CON_HALLAZGOS / BLOQUEADO + pasos mínimos

---

## FIX PACK Format (mandatory if created)
The fix pack MUST be machine-friendly and deterministic.

# FIX — {story_id} — phase-{phase_id}

## Trigger
- Estado original: BLOQUEADO | READY_CON_HALLAZGOS
- Razón: resumen 1-2 líneas

## Fix Scope
- This is a BASE FixPack and MAY reference more than 5 files.
- The 5-file limit is enforced by the executor; the orchestrator is responsible for splitting into `fix-01`, `fix-02`, ... (<= 5 files each).
- Must not expand story scope.
- If the fix requires audit/plan/standards-lock changes OR expands scope => set `NEEDS_REAUDIT=1`.
- If the fix touches more than 5 files BUT can be split safely => set `NEEDS_SPLIT=1` and keep `NEEDS_REAUDIT=0`.
- The reviewer MUST NOT set `NEEDS_REAUDIT=1` only because there are more than 5 files.


## NEEDS_REAUDIT
- NEEDS_REAUDIT: 0|1
- If 1: reason + suggested auditor prompt.

## NEEDS_SPLIT
- NEEDS_SPLIT: 0|1
- If 1: the orchestrator MUST split this base FixPack into:
  - `phase-{phase_id}.fix-01.md`, `phase-{phase_id}.fix-02.md`, ...
  each with <= 5 files.

## Target Phase (suggested)
- phase_id_suggested: <next numeric phase id>  (e.g., 04)
- phase_label: fix-base (este label NO se usa para ejecución; el orchestrator asigna fix-01, fix-02, ...)


## Fix Items (can exceed 5 files in BASE)
Lista numerada:
- F-001 (Severidad: P0|P1|P2) — descripción corta
  - Evidencia: paths exactos
  - Acción recomendada (sin código)
  - Archivos involucrados:
    - <path1>
    - <path2>
  - Gates: typecheck_no_demo required|na, smoke_tests required|na, sql_migration_check required|na

## Actions (ordered)
1) <action step, no code>
2) <action step, no code>
3) ...

## Verification (must be concrete)
- <command or check> + expected outcome
- <command or check> + expected outcome

## Gates
- typecheck_no_demo: required|na
- smoke_tests: required|na
- sql_migration_check: required|na

## QA Pack Impact
- qa_pack_required: yes|no
- qa_exec_required: yes|no
- If yes: which evidence files must be updated

---
