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

## Inputs (required)
- `requirement_slug`
- `story_id`
- `phase_id` (e.g., `01`)

## Inputs (optional overrides)
- `audit_path_override`
- `plan_path_override`

## Path Resolution (deterministic)
By default, resolve paths as:
- `audit_path = contexto/work/features/{requirement_slug}/01_audits/{story_id}.audit.md`
- `plan_path  = contexto/work/features/{requirement_slug}/02_plans/{story_id}.plan.md`

If an override is provided, it MUST be used instead of the default.

---

## Standards Inputs (MANDATORY)
The executor MUST load and follow:
- `.codex/skills/telemetric-backend-standards/SKILL.md`
- `.codex/skills/telemetric-sqlserver-standards/SKILL.md`

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

## Execution Rules
- Execute ONLY what the requested phase requires per `plan_path`.
- Use repo conventions AND normative standards; if they differ, the Standards Lock decides.
- Keep scope strict to the story; if plan suggests touching out-of-scope runtime files for DB-fundational stories, STOP and mark BLOQUEADO.
- Max 5 files touched in this run (create/modify).
- If you need more than 5 files, split into another phase (do not proceed).

---

## Output Persistence (mandatory)
The executor MUST:
1) Write a phase report to:
   `contexto/work/features/<requirement_slug>/03_execution/{story_id}/phase-{phase_id}.md`
2) Print the same content in the chat output.

---

## Language (MANDATORY)
- The phase report (`contexto/.../phase-{phase_id}.md`) MUST be written in **Spanish**.
- UI labels in **Spanish** if mentioned.
- Internal code constructs (classes/entities/tables/fields) MUST remain in **English** when referenced (e.g., `RuleTemplateVersion`, `ActionAttempt`).
- Do NOT translate file paths, identifiers, or code symbols.

If the executor output is not in Spanish, the run is considered **FAILED** and must be re-emitted in Spanish without changing the implemented code.


## Phase Report Format (mandatory,Spanish)
# FASE {phase_id} — {story_id}

## Estado
READY | BLOQUEADO | DONE

## Standards Lock Check
- Backend: ADOPTED (ref: audit A0)
- SQLServer: ADOPTED (ref: audit A0)

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
