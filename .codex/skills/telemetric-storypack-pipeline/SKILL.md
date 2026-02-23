# telemetric-storypack-pipeline

## Purpose
Generate a Telemetric **Story Pack** AND immediately run a **lint pass** (G1..G6) to produce a deterministic, ready-to-use `ACT_v1.md` with a `## LINT REPORT` header.

This skill exists to keep prompts minimal and enforce consistency automatically.

---

## Inputs (required)
- `slug`: feature identifier (e.g., `actions`, `acciones_vista`, `refactor_x`)

Optional:
- `spec_path`: defaults to `contexto/work/features/<slug>/spec.md`
- `storypack_path`: defaults to `contexto/work/features/<slug>/storypacks/ACT_v1.md`

---

## Pipeline (MANDATORY ORDER)
### Step 1 — WRITE
1) Run skill: `telemetric-storypack-writer`
2) Input to writer:
   - `contexto/work/features/<slug>/spec.md`
3) Writer must create/overwrite:
   - `contexto/work/features/<slug>/storypacks/ACT_v1.md`

### Step 2 — LINT (auto)
1) Run skill: `telemetric-storypack-linter`
2) Inputs to linter:
   - `slug`
   - `spec_path`: `contexto/work/features/<slug>/spec.md`
   - `storypack_path`: `contexto/work/features/<slug>/storypacks/ACT_v1.md`

---

## Output (required)

### Output file (MANDATORY)
The pipeline MUST end with exactly one storypack file updated:
- `contexto/work/features/<slug>/storypacks/ACT_v1.md`

This file MUST include at the top:
- `## LINT REPORT`
- `- Gates checked: G1..G6`
- `- Fixes applied: ...`
- `- Remaining notes (if any): ...`

Also print the final `ACT_v1.md` in chat output (for visibility).

---

## Determinism rules
- Always create/overwrite `contexto/work/features/<slug>/storypacks/ACT_v1.md`.
- Do not create additional storypack files unless explicitly requested.
- The lint step must be applied every run (no skipping).

---

## Hard Guardrails
- No invention beyond what `spec.md` states.
- If lint finds blocking ambiguity that cannot be fixed without invention, linter must:
  1) add it under `Remaining notes`
  2) keep the storypack content, but mark impacted stories as `BLOQUEADO` (only if your linter supports that)
  3) never invent endpoints/standards.

---

## Success Criteria
- After running this pipeline, `ACT_v1.md` is immediately usable and normalized:
  - contains the expected sections (Index/Stories/Guardrails/Doc Deliverables)
  - includes `## LINT REPORT` header
  - no missing “Endpoints (si aplica)” block (either filled or `No aplica`)
  - no invalid dependencies (e.g., `contexto/openapi/actions.yaml` as a hard dependency unless explicitly required by spec)
