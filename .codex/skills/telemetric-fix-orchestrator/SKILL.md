---
name: telemetric-fix-orchestrator
description: Orquesta FIXES para una fase. Puede (A) consumir un FixPack existente y emitir prompts, o (B) si no hay FixPack o el fix excede 5 archivos, generar múltiples FixPacks (fix-01, fix-02, ...) a partir del ReviewReport y luego emitir prompts por cada fix.
---

# Telemetric Fix Orchestrator — Skill

## Purpose
Orchestrate fixes after a phase implementation in Telemetric.

This skill supports two workflows:

### Workflow A — From FixPack
If a fix source already exists (`phase-XX.fix.md` from reviewer, or `phase-XX.fix-nn.md`), emit **copy/paste minimal prompts** to:
1) Implement fix with `telemetric-story-impl-executor` (FIX mode)
2) Generate/update QA pack with `telemetric-qa-pack-builder` (if required)
3) Execute QA with `telemetric-qa-executor` (if required)
4) Re-run `telemetric-post-impl-reviewer`

### Workflow B — Auto-split fixes (>5 files)
If the required fixes exceed 5 files, this skill will:
1) Read the `ReviewReport` (`phase-XX.review.md`)
2) Generate **multiple FixPacks** `phase-XX.fix-01.md`, `phase-XX.fix-02.md`, ... each with **<= 5 files**
3) Emit the same minimal prompts for each FixPack, in order.

This skill does NOT implement code. It only writes FixPack markdown files under `contexto/work/.../03_execution/...`.

---

## Mode
DOCS/ORCHESTRATION ONLY (NO PRODUCT CODE)

### Hard Prohibitions
- DO NOT modify product code.
- DO NOT modify audit/plan files.
- DO NOT invent runtime commands: only refer to gates/verification already present in FixPack or ReviewReport.
- ONLY write documentation artifacts under:
  - `contexto/work/features/{requirement_slug}/03_execution/{story_id}/`
- If the review indicates `NEEDS_REAUDIT=1`, STOP and emit only ONE minimal auditor prompt.

---

## Inputs (required)
- `requirement_slug`
- `story_id` (e.g., `ACT-003`)
- `phase_id` (source phase that produced issues, e.g., `03`)

## Inputs (optional)
- `review_report_override` (full path to `phase-XX.review.md`)
- `fix_pack_override` (full path to an existing FixPack)
- `max_files_per_fix` (default 5; must remain 5 in Telemetric, do not change unless user explicitly overrides)
- `strategy` (default `auto`):
  - `auto` = prefer FixPack if exists, else generate from review
  - `from_fix` = only consume existing FixPack (no generation)
  - `from_review` = always generate FixPacks from review

---

## Path Resolution (deterministic)

### Base directory
`base_dir = contexto/work/features/{requirement_slug}/03_execution/{story_id}/`

### Review report
Default:
- `review_report = {base_dir}/phase-{phase_id}.review.md`
Override must be used if provided.

### FixPack discovery patterns
Canonical reviewer base:
- `phase-{phase_id}.fix.md`
Canonical execution packs:
- `phase-{phase_id}.fix-<nn>.md`  (nn = 01..99)

If `fix_pack_override` is provided, use it as the selected FixPack for Workflow A.

---

## Outputs (files this skill may create)
Only for Workflow B (auto-split):
- `{base_dir}/phase-{phase_id}.fix-01.md`
- `{base_dir}/phase-{phase_id}.fix-02.md`
- ...

This skill MUST NOT create files outside `base_dir`.

---

## Decision Logic (mandatory)

### Step 1 — Determine operation mode
If `strategy=from_fix`:
- Run Workflow A using `fix_pack_override` or auto-discovered FixPack.

If `strategy=from_review`:
- Run Workflow B using `review_report`.

If `strategy=auto`:
1) If `fix_pack_override` provided → Workflow A
2) Else if any execution FixPack exists for this phase (`phase-XX.fix-*.md`) → Workflow A (pick latest)
3) Else if reviewer base fix exists (`phase-XX.fix.md`):
   - If `phase-XX.fix.md` references MORE than 5 unique files → Workflow B (generate FixPacks from review)
   - Else → Workflow A
4) Else → Workflow B (generate FixPacks from review)

### Step 2 — NEEDS_REAUDIT hard stop
If the chosen source (FixPack or ReviewReport) indicates `NEEDS_REAUDIT: 1`:
- Output only ONE auditor prompt and STOP.

---

### FixPack selection + Normalization (if not overridden)

Auto-discover in `base_dir`:
- execution candidates: `phase-{phase_id}.fix-*.md`
- reviewer base: `phase-{phase_id}.fix.md`

Selection rules (deterministic):
1) If any execution candidate exists (`fix-<nn>`):
   - Pick the latest by highest `<nn>` and set it as `selected_fix_pack`.
   - Mode remains FROM_FIX (no generation needed).

2) Else if reviewer base exists (`phase-{phase_id}.fix.md`):
   - Treat it as BASE (may exceed 5 files / may lack `## Files (max 5)`).
   - The orchestrator MUST normalize it into an execution FixPack:
     - Create `{base_dir}/phase-{phase_id}.fix-01.md` (overwrite if exists)
     - Ensure it contains the executor contract:
       - `## Files (max 5)`  (derived from BASE "Archivos involucrados" / "Affected Files")
       - `## Actions (ordered)` (copied as-is)
       - `## Gates` + `## Verification` (copied as-is)
       - `## QA Pack Impact` must target `phase_id_suggested` (NOT the source `phase-{phase_id}`)
   - After generation, set `selected_fix_pack = phase-{phase_id}.fix-01.md`
   - Mode becomes FROM_REVIEW_SPLIT (even if it's only one fix), because generation occurred.

3) Else:
   - No fix source found -> fallback to Workflow B (generate from review report).

Ambiguity rule:
- If there are multiple execution candidates with the same `<nn>` (should not happen),
  STOP with `Status=BLOQUEADO` and ask **NECESITO 1 RESPUESTA**:
  - "Hay más de un FixPack candidato. Indícame el path exacto o el `fix_id` (ej: 03.02)."


---

## Workflow B — Auto-split from ReviewReport (>5 files)

### Required ReviewReport structure
The orchestrator MUST parse **Hallazgos** from the ReviewReport:
- Find items like:
  - `H-001 (Severidad: P0|P1|P2)`
  - Must include `Evidencia:` with file paths
  - Must include `Recomendación:` text (no code)

If ReviewReport lacks file paths, STOP with `Status=BLOQUEADO` and ask **NECESITO 1 RESPUESTA**:
- "El review no tiene rutas de archivos por hallazgo. Â¿Quieres que use una lista de archivos manual o me pasas un review con evidencias por path?"

### Fix splitting rules (deterministic)
1) Group fixes by severity: P0 first, then P1, then P2.
2) Within same severity, order by Hallazgo ID (H-001, H-002,...).
3) Extract file paths from each hallazgo evidence.
4) Build FixPack chunks with at most 5 unique files each:
   - Fill chunk 01 with earliest hallazgos until reaching 5 unique files
   - Then chunk 02, etc.
5) A hallazgo must not be split across two FixPacks if avoidable.
   - If a single hallazgo references >5 files:
    - Try to split it across multiple FixPacks ONLY if the hallazgo's recommendation/actions are separable by sub-area or file groups.
    - If the hallazgo is atomic/non-separable (one logical change requiring >5 files in the same step), then set `NEEDS_REAUDIT: 1` and STOP.


### FixPack content generation
For each chunk `k`:
- Write `phase-{phase_id}.fix-{k:02}.md` with the FIX PACK format (see below).
- `phase_id_suggested` MUST be computed as:
  - next numeric phase after the latest existing `phase-<NN>.md` in `base_dir`
  - and then increment per fix pack: first fix uses next phase, second uses next+1, etc.
- `phase_label` MUST be `fix-{k:02}`

### Gates propagation
For each FixPack:
- If any file starts with `telemetric-front/`, set:
  - `typecheck_no_demo: required`
- Else:
  - `typecheck_no_demo: na`
Other gates:
- `smoke_tests`: required only if review explicitly mentions endpoint changes in the hallazgos included
- `sql_migration_check`: required only if review explicitly mentions SQL schema/migration changes in the hallazgos included

If gates cannot be inferred, default to `na` and note it in FixPack "Verification".

---

## Output Format (mandatory)
Return exactly:

1) `BaseDir: <path>`
2) `Mode: FROM_FIX | FROM_REVIEW_SPLIT`
3) If Mode FROM_FIX:
   - `FixPack: <path>`
   - `NEEDS_REAUDIT: 0|1`
   - If NEEDS_REAUDIT=1: emit auditor prompt and STOP
   - Else emit prompts A..D (see templates)
4) If Mode FROM_REVIEW_SPLIT:
   - `ReviewReport: <path>`
   - `FixPacksCreated:` list created fix packs (ordered)
   - For EACH FixPack created, emit prompts A..D (grouped per fix)

No extra commentary outside this format.

---

## FIX PACK Format (mandatory when generating)

# FIX — {story_id} — phase-{phase_id}

## Trigger
- Estado original: BLOQUEADO | READY_CON_HALLAZGOS
- Razón: resumen 1-2 lÃ­neas

## Fix Scope
- Must be implementable in <= 5 files.
- Must not expand story scope.
- If requires plan changes: set `NEEDS_REAUDIT=1`.

## NEEDS_REAUDIT
- NEEDS_REAUDIT: 0|1
- If 1: reason + suggested auditor prompt.

## Target Phase (suggested)
- phase_id_suggested: <next numeric phase id>  (e.g., 04)
- phase_label: fix-<nn> (e.g., fix-01)

## Files (max 5)
- <path1>
- <path2>
- <path3>
- <path4>
- <path5>

## Actions (ordered)
1) <action step, no code>
2) <action step, no code>
3) ...

## Verification (must be concrete)
- <check> + expected outcome
- <check> + expected outcome

## Gates
- typecheck_no_demo: required|na
- smoke_tests: required|na
- sql_migration_check: required|na

## QA Pack Impact
- qa_pack_required: yes|no
- qa_exec_required: yes|no
- If yes: which evidence files must be updated

---

## Prompt Templates (to emit)

### A) Executor prompt (mandatory)
Must include:
- skill: telemetric-story-impl-executor
- requirement_slug, story_id
- is_fix=1
- fix_id = "{phase_id}.{nn}" when using `fix-<nn>` OR `fix_pack_path` exact
- if using reviewer base `phase-XX.fix.md`, prefer `fix_pack_path` exact (do not invent nn)
- phase_id is OPTIONAL in FIX prompts.
- If included, use `phase_id_suggested` from the FixPack for QA path lock only.
- executor output report in FIX mode is derived from FixPack filename, not from `phase_id`:
  - `phase-<src>.fix-<nn>.md` -> `phase-<src>.fix-<nn>.fixed.md`
  - legacy `phase-<src>.fix.md` -> `phase-<src>.fix-01.fixed.md`
- "Implementar SOLO lo del FixPack"
- "Max 5 archivos: los listados en FixPack"
- Mention expected gates briefly

### B) QA Pack Builder prompt (only if qa_pack_required=yes)
- skill: telemetric-qa-pack-builder
- same story + target phase (phase_id_suggested)
- reference FixPack path

### C) QA Executor prompt (only if qa_exec_required=yes)
- skill: telemetric-qa-executor
- same story + target phase
- reference FixPack path
- must require filling Observed in evidence logs

### D) Post-impl reviewer prompt (mandatory)
- skill: telemetric-post-impl-reviewer
- story + target phase
- require QA evidence presence if qa_pack_required=yes

---

