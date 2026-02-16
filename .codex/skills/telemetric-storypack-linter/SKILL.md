# telemetric-storypack-linter

## Purpose
Validate and normalize a Telemetric **Story Pack** against:
- the module `spec.md`
- the Story Pack writer format/guardrails
so that the output requires **no manual corrections** before implementation.

This linter is a post-generation step:
1) A Story Pack is generated (e.g., `contexto/storypacks/actions/ACT_v1.md`)
2) This linter runs and either:
   - (A) fixes the document and rewrites it, or
   - (B) stops with **DECISIÓN PENDIENTE** if blocked by ambiguity.

---

## Inputs (required)
- `contexto/specs/<module>/spec.md`
- `contexto/storypacks/<module>/ACT_v1.md` (or the specific Story Pack file provided)

Optional:
- `.codex/skills/telemetric-storypack-writer/SKILL.md` (as reference of format)

---

## Output (required)
Write exactly one of the following:

### Case A — PASS (or auto-fixed)
Rewrite the same Story Pack file with:
- normalized format
- fixed guardrail violations that are objectively correctable
- a short “LINT REPORT” section at the top with what was changed

### Case B — BLOCKED
Output **only** the DECISIÓN PENDIENTE block (format below) and STOP.
Do not rewrite the Story Pack.

---

## Hard Rules (must follow)
1) **No invention**: Do not invent endpoints, routes, technologies, tables, naming conventions, or semantics not explicitly stated in `spec.md`.
2) **Reuse the Story Pack content**: Prefer minimal edits that preserve meaning. Do not rewrite the pack from scratch unless required to fix a gate failure.
3) **Stop on ambiguity**: If a fix would require guessing, output DECISIÓN PENDIENTE and STOP.
4) **No code**: Do not generate implementation code.
5) **Language rule**: UI labels in Spanish; internal entities in English.

---

## Quality Gates (must pass)
If any gate fails, attempt auto-fix if safe. Otherwise DECISIÓN PENDIENTE.

### G1 — Required sections per story
Every story must include (in order):
- Como/Quiero/Para
- Alcance
- Rutas UI (or N/A for engine/runtime stories)
- Entidades internas
- Endpoints (si aplica) (use “No aplica” if none)
- Endpoint check gate (use “No aplica” if none)
- AC (>= 6 numbered)
- QA (>= 8 numbered)
- Datos/Contratos (if applies; otherwise “No aplica”)
- Depends on
- Referencias (exact spec sections)

Auto-fix:
- Add missing sections with “No aplica” when applicable.
- Reorder sections to match the canonical order.

### G2 — Runtime stories must NOT claim UI routes
If a story is BE/runtime/engine (keywords: “engine”, “runtime”, “worker”, “evaluación runtime”, “RabbitMQ consume”, “rehidratación”):
- `Rutas UI:` must be `N/A (engine runtime)`
Auto-fix:
- Replace UI routes with N/A.

### G3 — OpenAPI file must not be a hard dependency unless confirmed present
`contexto/openapi/actions.yaml` (or module equivalent) must NOT appear in “Depends on”
unless it is explicitly stated as already existing in the repo inputs.

Auto-fix:
- Remove it from “Depends on”
- Keep it only inside “Endpoints (si aplica)” as an incremental artifact:
  “Si faltan: actualizar/crear incrementalmente `contexto/openapi/actions.yaml`…”

### G4 — Testability of AC/QA
Ban ambiguous phrases in AC/QA unless paired with a measurable condition:
Examples banned: “alineado”, “mínimo” (without threshold), “consistente” (without check),
“según corresponda” (without rule), “cuando aplique” (without condition).

Auto-fix:
- Rewrite the single AC/QA line into a measurable condition WITHOUT adding new scope.
- If measurability requires guessing (e.g., unknown filters), trigger DECISIÓN PENDIENTE.

### G5 — No contradictions with spec
Story Pack must not contradict spec:
- v1 scope (Email only as active action)
- no function-per-rule deployment
- no internal state exposed in UI
- duplicates rule `(device_id, template_version_id)` for RuleInstance
- lifecycle rules (auto-reset/latch/cooldown, resolve+OK)

Auto-fix:
- Remove contradictory phrases and align to spec text.
- If contradiction cannot be resolved without guessing intent, DECISIÓN PENDIENTE.

### G6 — Traceability references
Each story must reference at least 2 exact spec sections (e.g. “Spec §1… , §6…”).
Auto-fix:
- Add references if they are obvious from story content.
- If unclear, DECISIÓN PENDIENTE.

---

## Endpoint Check Gate (canonical text)
When endpoints apply, the story must include exactly this gate text:

- **Endpoint check gate (obligatorio si hay endpoints):**
  - Discover → Equivalence test → Reuse-first → Only if missing (OpenAPI delta) → DECISIÓN PENDIENTE si hay dudas

If endpoints do not apply:
- **Endpoint check gate:** No aplica

---

## Decision Pending Protocol (mandatory format)
When blocked, output **only**:

### DECISIÓN PENDIENTE: <Título>
- **Contexto:** (1–2 líneas)
- **Opción A:** <...>
  - **Pros:**
  - **Cons:**
- **Opción B:** <...>
  - **Pros:**
  - **Cons:**
- **Preguntas mínimas para desbloquear:** (máx 5)

Then STOP.

---

## LINT REPORT format (Case A only)
At the top of the rewritten Story Pack file, add:

## LINT REPORT
- Gates checked: G1..G6
- Fixes applied:
  - <bullet list>
- Remaining notes (if any):
  - <bullet list>

Do not include any other meta commentary.

---

## Non-goals
- Do not implement code.
- Do not redesign the product scope.
- Do not invent endpoints/routes/contracts that are not in spec.
