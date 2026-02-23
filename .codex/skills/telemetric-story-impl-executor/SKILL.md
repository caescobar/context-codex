# telemetric-story-impl-executor

## Purpose
Execute ONE phase at a time for a given story (`ACT-###`) following the approved audit plan.
- Strictly enforce max 5 files per phase
- Respect repo standards discovered in the audit
- Enforce Telemetric normative standards (backend + SQLServer) via lock
- Produce verifiable outcomes

---

## Mode
IMPLEMENTATION (ONE PHASE ONLY)

### Hard Prohibitions
- DO NOT execute more than the requested phase.
- DO NOT touch more than 5 files in a single run.
- DO NOT invent standards; use the audit as source of truth.
- DO NOT proceed if Standards Lock is not ADOPTED for required categories.

---

### QA Path Lock (HARD)
- If the phase creates or updates any QA artifacts (checklists, test scripts, evidence, seeds, smoke scripts),
  the executor MUST only write them under:
  - `contexto/work/features/{requirement_slug}/04_test/{story_id}/phase-{phase_id}/`
  - `contexto/work/features/{requirement_slug}/04_test/{story_id}/STORY_QA.md`
- Creating QA artifacts anywhere else is FORBIDDEN.
- If the executor cannot infer `requirement_slug`, `story_id`, or `phase_id`, STOP with `Status=BLOQUEADO`
  and ask **NECESITO 1 RESPUESTA** for the missing value.
- In FIX mode (`is_fix=1`), `phase_id` SHOULD be inferred from FixPack before blocking.

---

## Inputs (required)
- `requirement_slug`
- `story_id`
- `phase_id` (e.g., `01`, `02`, `03`, `04`)  # required ONLY when `is_fix=0`

## Inputs (optional overrides)
- `audit_path_override`
- `plan_path_override`

## FIX Inputs (optional)
- `is_fix` (0|1) default 0
- `fix_id` (optional; format "<srcPhase>.<fixSeq>", example "03.02")
- `fix_pack_path` (optional; highest priority if provided)

---

## Path Resolution (deterministic)

By default, resolve paths as:
- `audit_path = contexto/work/features/{requirement_slug}/01_audits/{story_id}.audit.md`
- `plan_path  = contexto/work/features/{requirement_slug}/02_plans/{story_id}.plan.md`

If an override is provided, it MUST be used instead of the default.

---

## FIX Pack Resolution (deterministic)

When `is_fix=1`, the executor MUST resolve a FixPack before implementing.

### Base directory (deterministic)
`fix_base_dir = contexto/work/features/{requirement_slug}/03_execution/{story_id}/`

### Accepted FixPack filename pattern (canonical)
- `phase-<srcPhase>.fix-<nn>.md`
  - Example: `phase-03.fix-02.md`

Legacy compatibility (optional)
- `phase-<srcPhase>.fix.md` (treated as `fix-01`)

### Fix selection precedence (when is_fix=1)
1) If `fix_pack_path` is provided:
   - Use it as source of truth.

2) Else if `fix_id` is provided:
   - Parse: `fix_id = "<srcPhase>.<fixSeq>"`
     - Example: `"03.02"` => srcPhase=03, fixSeq=02
   - Resolve canonical filename:
     - `fix_pack_path = phase-<srcPhase>.fix-<fixSeq:02>.md`
   - Full path:
     - `{fix_base_dir}/{fix_pack_path}`
   - If not found: STOP `Status=BLOQUEADO` with 1 question:
     - "No encuentro el FixPack {path}. ¿Cuál es el fix_id correcto o el path exacto?"

3) Else (no fix_pack_path, no fix_id):
   - Auto-discover within `fix_base_dir` candidates matching:
     - `phase-*.fix-*.md`
     - (optional legacy) `phase-*.fix.md`
   - Choose the latest by:
     a) highest `<srcPhase>` number
     b) then highest `<nn>` (legacy `.fix.md` counts as `<nn>=1`)
   - If ambiguity remains (tie): STOP `Status=BLOQUEADO` with 1 question:
     - "Hay más de un FixPack candidato. ¿Qué fix_id debo usar (ej: 03.02) o qué path exacto?"

### Target phase_id resolution (when omitted in FIX mode)
If `phase_id` is NOT provided and `is_fix=1`:
1) If FixPack contains `phase_id_suggested`, use that.
2) Else if FixPack QA paths include `.../phase-<NN>/...`, infer `<NN>` from those paths.
3) Else determine max existing implemented phase report in:
   `contexto/work/features/{requirement_slug}/03_execution/{story_id}/phase-<NN>.md`
   and set `phase_id = (maxNN + 1)` (or `01` if none found).

### FIX execution report filename (deterministic)
When `is_fix=1`, the executor MUST derive the output report filename from the resolved `fix_pack_path`:
- Canonical FixPack: `phase-<srcPhase>.fix-<nn>.md`
  - Output report: `phase-<srcPhase>.fix-<nn>.fixed.md`
- Legacy FixPack: `phase-<srcPhase>.fix.md`
  - Output report: `phase-<srcPhase>.fix-01.fixed.md` (normalized)

Important:
- In FIX mode, `phase_id` may still be used for QA path lock (`04_test/.../phase-{phase_id}/`),
  but it MUST NOT control the execution report filename.

---

## FIX Mode Rules (MANDATORY when is_fix=1)

If `is_fix=1`:
1) The executor MUST resolve `fix_pack_path` using "FIX Pack Resolution".
2) The executor MUST read the FixPack and treat it as the ONLY scope of work.

### FixPack contract (required sections)
The FixPack MUST include these sections:
- `## Files (max 5)`
- `## Actions (ordered)`

Optional but supported:
- `## Gates (expected)` (examples: `typecheck_no_demo`, `lint`, `tests`)
- `NEEDS_REAUDIT: 0|1`

If any required section is missing:
- STOP `Status=BLOQUEADO`
- Ask **NECESITO 1 RESPUESTA** indicating which missing section must be added.

### Hard scope enforcement
3) Files touched MUST be:
- `touched_files ⊆ fixpack.files`
- `len(touched_files) <= 5`

If a 6th file is needed:
- STOP `Status=BLOQUEADO`
- State explicitly: "Se requiere un FixPack adicional (ej: phase-<src>.fix-03.md)."

4) The executor MUST follow `## Actions (ordered)` strictly.
- DO NOT add extra "nice-to-have" changes.

### Gates enforcement (fix)
5) If FixPack defines gates under `## Gates (expected)`:
- The executor MUST reflect them in "Verification checklist".
- The executor MUST NOT mark `Estado=DONE` unless:
  - Evidence exists that the gates were executed and passed, OR
  - The FixPack explicitly allows leaving `Observed (pendiente)` and then executor must set `Estado=READY` (not DONE).

### Reaudit enforcement
6) If FixPack indicates `NEEDS_REAUDIT=1`:
- STOP `Status=BLOQUEADO`
- Instruct to run auditor for the affected story
- Do NOT implement anything in this run

### QA Path Lock interaction (important)
7) If FixPack requires creating/updating QA artifacts, the executor MUST obey "QA Path Lock (HARD)".
If FixPack lists QA file paths outside this lock:
- STOP `Status=BLOQUEADO`
- Ask **NECESITO 1 RESPUESTA**: "¿Actualizo el FixPack para cumplir el QA Path Lock?"

---

## Standards Inputs (MANDATORY)
The executor MUST load and follow:
- `.codex/skills/telemetric-backend-standards/SKILL.md`
- `.codex/skills/telemetric-sqlserver-standards/SKILL.md`
- `.codex/skills/telemetric-frontend-standards/SKILL.md` (MANDATORY if any touched file path starts with `telemetric-front/`)

If any standards file is missing, STOP with `Status=BLOQUEADO`.

---

## Hard Gate — Standards Lock (MANDATORY)
Before touching any file, the executor MUST verify in `audit_path`:
- Section `A0. Standards Lock` exists, AND
- All categories required by the requested `phase_id` are **ADOPTED**.

If any required category is **CONFLICT** or **NEW/NO-EVIDENCE**:
- STOP with `Status: BLOQUEADO`
- Show the failing category + the evidence lines from audit
- Ask max 3 specific questions to unblock
- Do NOT implement anything in this run

If the generated phase report content is not in Spanish:
- Re-emit the report in Spanish in the SAME run output (no new implementation),
- Keep code unchanged,
- Mark `Estado: REFORMATEADO (idioma)`.

---

## Hard Gate — Frontend Standards (conditional)
If the requested phase touches `telemetric-front/`, executor MUST:
- Apply `telemetric-frontend-standards`
- Ensure route+menu permission parity if routes/menu are touched
- Ensure UX states (loading/empty/error/success) for affected views
- Ensure typecheck no-regression evidence exists in the phase QA pack
If any of the above cannot be satisfied without inventing repo commands, STOP with Status=BLOQUEADO and ask max 3 questions.

---

## Execution Rules
- Execute ONLY what the requested phase requires per `plan_path` (NORMAL mode), or per FixPack when `is_fix=1`.
- Use repo conventions AND normative standards; if they differ, the Standards Lock decides.
- Keep scope strict to the story; if plan suggests touching out-of-scope runtime files for DB-fundational stories, STOP and mark BLOQUEADO.
- Max 5 files touched in this run (create/modify).
- If you need more than 5 files, split into another phase (do not proceed).

---

## Output Persistence (mandatory)
The executor MUST:
1) Write an execution report to:
   - Normal mode (`is_fix=0`):
     `contexto/work/features/<requirement_slug>/03_execution/{story_id}/phase-{phase_id}.md`
   - FIX mode (`is_fix=1`):
     `contexto/work/features/<requirement_slug>/03_execution/{story_id}/phase-<srcPhase>.fix-<nn>.fixed.md`
     (or normalized `fix-01` when source is legacy `phase-<srcPhase>.fix.md`)
2) Print the same content in the chat output.

---

## Language (MANDATORY)
- The execution report file (normal or fix naming, per Output Persistence) MUST be written in **Spanish**.
- UI labels in **Spanish** if mentioned.
- Internal code constructs (classes/entities/tables/fields) MUST remain in **English** when referenced (e.g., `RuleTemplateVersion`, `ActionAttempt`).
- Do NOT translate file paths, identifiers, or code symbols.

If the executor output is not in Spanish, the run is considered **FAILED** and must be re-emitted in Spanish without changing the implemented code.

---

## Phase Report Format (mandatory,Spanish)
# FASE {phase_id} — {story_id}

## Estado
READY | BLOQUEADO | DONE

## Standards Lock Check
- Backend: ADOPTED (ref: audit A0)
- SQLServer: ADOPTED (ref: audit A0)

## FIX Mode
- is_fix: 0|1
- fix_id: <value or NA>
- fix_pack_used: <path or NA>

## Files touched (max 5)
- <path1>
- <path2>
...

## Changes summary
- bullets, high level, no fluff

## Verification checklist
- concrete verification steps (tests/endpoints/queries)
- must not modify the repo during verification unless the plan explicitly requires it

## Notes / Risks
- short

---
