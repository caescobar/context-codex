---
name: telemetric-prompt-builder
description: Convierte texto libre en un PROMPT FINAL estandarizado (HALLAZGO | AUDIT | PHASE | STORY PACK) y genera un pack con INDEX checklist + prompts ejecutables dentro de contexto/00_prompts/.
---

# Telemetric Prompt Builder — Skill

## Propósito
Convertir un input humano en un **PROMPT FINAL ejecutable** y **registrar historial** en `contexto/00_prompts/` usando un **pack folder** con índice y checklist.

Este skill **NO ejecuta** auditorías ni cambios de código: solo construye prompts y escribe artefactos en `contexto/`.

---

## Definiciones de modo (contrato)
- **docs-only**: permitido crear/editar **solo** archivos dentro de `contexto/`.
- **refactor-safe + change-control**: permitido tocar código con límites (máx 5 archivos) — este skill solo lo **emite** como prompt; no ejecuta.

> Nota crítica: En este repo, “report-only” se interpreta como “no escribir archivos”.  
> Por eso **PROHIBIDO** usar `report-only` como skill en prompts que deban guardar `.md` en `contexto/`.

---

## REGLAS DURAS (no negociables)
1) **NO ejecutar** auditorías ni cambios de código. Solo generar prompts y escribir archivos en `contexto/`.
2) Clasificar siempre en uno: **HALLAZGO | AUDIT | PHASE | STORY PACK**.
3) Todo PROMPT FINAL debe incluir siempre:
   - Modo
   - Skills
   - Objetivo
   - Alcance
   - Entregables (archivos exactos)
   - Guardrails
   - No-go rules
4) **No inventar paths**. Si se requieren, instruir a buscarlos durante la ejecución (“buscar y confirmar paths reales”).
5) Si es **PHASE**: máximo **5 archivos de código**. Si no puedes limitarlo, **degradar a AUDIT**.
6) **PROHIBIDO pedir confirmación** si el modo ya es docs-only y los entregables están definidos. Debe escribir en `contexto/` sin preguntar.
7) **PROHIBIDO incluir `report-only` como skill** en prompts que deban escribir archivos.
   - Expresar “no tocar código” solo en Guardrails.
8) **PACK POR DEFECTO**: cada run debe crear un directorio pack:
   - `pack_dir = contexto/00_prompts/YYYY-MM-DD__pack-<slug>/`
   - Todo lo generado en ese run vive dentro de `pack_dir`.
9) **ÍNDICE CON CHECKBOXES**: el builder debe crear/actualizar:
   - `{pack_dir}/INDEX.md`
   con checklist `[ ]` por cada item (auditoría/fase/story/hallazgo) generado en el pack.
10) **AUTO-UPDATE HOOK**: todo PROMPT FINAL executor (AUDIT/PHASE/STORY/HALLAZGO) debe incluir un Post-step obligatorio:
   - marcar como `[x]` su ítem en `{pack_dir}/INDEX.md`
   - y completar link del output si faltaba.
11) **SLUG ASCII**: slugs y filenames deben ser ASCII (a-z0-9-). Prohibido tildes/ñ.
    - Ej: `auditoria` (no `auditoría`), `senal` (no `señal`).

---

## SALIDA OBLIGATORIA (siempre)
El builder siempre produce:

1) **CLASIFICACIÓN**: HALLAZGO | AUDIT | PHASE | STORY PACK (y rationale en 2 bullets)
2) **PROMPT FINAL** (bloque `txt` copiables) para ejecutar el siguiente paso
3) **ARCHIVOS DEL BUILDER** (debe escribirlos):
   - `{pack_dir}/_history.md` (fecha + input original + clasificación + rationale)
   - `{pack_dir}/INDEX.md` (checklist + links)
   - `{pack_dir}/builder_prompt.md` (el PROMPT FINAL exactamente igual al devuelto)
   - Opcional: `{pack_dir}/notes.md` si ayuda a resumir

---

## Contenido mínimo de `{pack_dir}/_history.md`
- Fecha (YYYY-MM-DD)
- Input original (texto libre)
- Clasificación + rationale (2 bullets)
- PROMPT FINAL (exactamente igual)

---

## INTENT ROUTER (clasificación)
### A) HALLAZGO
Bug concreto y el usuario quiere registrarlo para después.
Palabras guía: “no persiste”, “no funciona”, “al reabrir”, “sale vacío”, “error”.
- Si solo registrar → HALLAZGO
- Si investigar con evidencia → AUDIT (targeted)

### B) AUDIT
Pide analizar/refactorizar, confirmar contratos, inventariar duplicaciones o riesgos, health check.

**Subtipo: AUDIT DISCOVERY (general)**
Si el input es “revisa el repo”, “qué mejorar”, “migré a Codex”, “health check”.
→ debe proponer auditorías recomendadas (3–10) y generar prompts para cada una.

### C) PHASE
Cambio acotado ya decidido (≤5 archivos). Si no hay evidencia o scope grande → degradar a AUDIT.

### D) STORY PACK
Feature nuevo / flujo / requerimiento para implementar.

---

# RECIPES (plantillas de PROMPT FINAL)

## RECIPE: HALLAZGO (registrar bug)
**PROMPT FINAL debe:**
- Modo: docs-only
- Skills: telemetric-frontend-style o telemetric-backend-style (según módulo)
- Entregables:
  - `contexto/03_hallazgos/pending.md` (usar contexto/01_overview/templates/TEMPLATE_PENDING.md)
- Guardrails: no tocar código; solo editar pending.md
- Post-step: marcar `[x]` el ítem en `{pack_dir}/INDEX.md`

---

## RECIPE: AUDIT (targeted executor)
**PROMPT FINAL debe:**
- Modo: docs-only
- Skills: (telemetric-backend-style / telemetric-frontend-style / dead-code-cleanup / axios-core-contract según aplique)
- Encabezado obligatorio:
  - `PackDir: {pack_dir}`
  - `ItemId: AUDIT-XX`
  - `IndexRef: {pack_dir}/INDEX.md`
  - `PromptPath: {pack_dir}/audit-XX__{slug}__AUDIT__PROMPT.md`
- Entregables:
  - `contexto/01_audits/YYYY-MM-DD__audit-XX__{slug}.md` (usar contexto/01_overview/templates/TEMPLATE_AUDIT.md)
  - update `contexto/03_hallazgos/pending.md` solo si hay hallazgos nuevos
- Guardrails:
  - Prohibido modificar código
  - Evidencia con paths exactos
  - Si no se encuentra: “No encontrado”
- Post-step obligatorio:
  - Actualizar `IndexRef` marcando `[x]` para `AUDIT-XX`
  - Añadir/actualizar link de Output en el índice

---

## RECIPE: AUDIT DISCOVERY (general, cantidad libre)
**PROMPT FINAL debe:**
- Modo: docs-only
- Skills: telemetric-backend-style, telemetric-frontend-style, dead-code-cleanup, axios-core-contract (solo si detecta capa HTTP)
- Debe definir explícitamente:
  - `pack_dir = contexto/00_prompts/YYYY-MM-DD__pack-<slug>/`

- Tarea:
  1) Repo-scan superficial (estructura, proyectos, integraciones)
  2) Proponer auditorías recomendadas (3–10), con prioridad P0/P1/P2 + rationale
  3) Crear/actualizar `{pack_dir}/INDEX.md` con checklist `[ ]` por auditoría
  4) Por cada auditoría: generar un prompt executor (tipo AUDIT) y guardarlo en:
     - `{pack_dir}/audit-XX__{slug}__AUDIT__PROMPT.md`
     Cada uno debe incluir: PackDir, ItemId, IndexRef, PromptPath, Post-step (marcar [x]).
  5) Guardar también un índice de prompts dentro del pack (ya es INDEX.md)

- Guardrails:
  - No ejecutar auditorías
  - No tocar código
  - Solo escribir en `contexto/`
  - No pedir confirmación
  - No inventar paths: los prompts deben ordenar “buscar y confirmar paths reales”.

**Entregables obligatorios del builder:**
- `{pack_dir}/INDEX.md`
- `{pack_dir}/audit-XX__{slug}__AUDIT__PROMPT.md` (uno por auditoría)
- `{pack_dir}/_history.md`
- `{pack_dir}/builder_prompt.md`

---

## RECIPE: PHASE (cambios acotados)
**PROMPT FINAL debe:**
- Modo: refactor-safe + change-control
- Skills: telemetric-backend-style o telemetric-frontend-style + (telemetric-connectors-standard / axios-core-contract según aplique)
- Max 5 archivos de código (lista explícita)
- Encabezado:
  - `PackDir: {pack_dir}`
  - `ItemId: PHASE-XX`
  - `IndexRef: {pack_dir}/INDEX.md`
- Entregables:
  - `contexto/02_changes/YYYY-MM-DD__phase-XX__{slug}__plan.md` (usar contexto/01_overview/templates/TEMPLATE_CHANGE_PLAN.md)
  - `contexto/02_changes/YYYY-MM-DD__phase-XX__{slug}__summary.md` (usar contexto/01_overview/templates/TEMPLATE_CHANGE_SUMMARY.md)
  - update `contexto/03_hallazgos/pending.md`
- Guardrails:
  - Máx 5 archivos de código
  - No cambiar contratos (Redis/Rabbit/SignalR) sin migración explícita
- Post-step: marcar `[x]` PHASE-XX en el índice

---

## RECIPE: STORY PACK
**PROMPT FINAL debe:**
- Modo: docs-only
- Skills: telemetric-frontend-style o telemetric-backend-style (según módulo)
- Encabezado:
  - `PackDir: {pack_dir}`
  - `ItemId: STORY-XX`
  - `IndexRef: {pack_dir}/INDEX.md`
- Entregable:
  - `contexto/04_storypacks/YYYY-MM-DD__{slug}.md` (usar contexto/01_overview/templates/TEMPLATE_STORY.md)
- Guardrails:
  - No tocar código
  - Máximo 5 preguntas abiertas
- Post-step: marcar `[x] STORY-XX en el índice

---

## Cómo escribir `{pack_dir}/INDEX.md` (formato mínimo)
- Debe basarse en `contexto/01_overview/templates/TEMPLATE_INDEX_PACK.md`.

- Debe incluir:
  - Título del pack
  - Lista por prioridad (si aplica)
  - Checklist `[ ]` por item con links relativos al prompt y al output esperado
