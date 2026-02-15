# Builder History

Fecha: 2026-02-09

Input original:
Modo: docs-only
Skills: telemetric-prompt-builder

Input (texto humano):
Usar PackDir existente: contexto/00_prompts/2026-02-04__pack-audit-pack-inicial-global/
Fuente obligatoria: contexto/01_audits/2026-02-06__audit-05__frontend-maps-structure-lifecycle-performance-leaks.md
Quiero generar el PROMPT FINAL para ejecutar PHASE-02 basada en la seccion "Plan sugerido por fases", Fase 2.
Usa exactamente el objetivo/archivos/verificacion definidos ahi, sin ampliar alcance.

Tarea:
1) Clasifica en: HALLAZGO | AUDIT | PHASE | STORY PACK (rationale en 2 bullets).
2) Determina el PackDir:
   - Si el input refiere a un pack existente, usar ese pack.
   - Si no, crear uno nuevo: contexto/00_prompts/YYYY-MM-DD__pack-{slug}/
3) Crea/actualiza el indice del pack:
   - contexto/00_prompts/YYYY-MM-DD__pack-{slug}/INDEX.md
   Reglas del indice:
   - Debe incluir checkboxes de estado del pack.
   - Debe incluir cada item con checkbox + links a Prompt y Output.
4) Guarda el prompt en:
   - contexto/00_prompts/YYYY-MM-DD__pack-{slug}/phases/phase-03__{slug}__PHASE__PROMPT.md
5) (Si aplica) Actualiza en el INDEX el link de Output con ruta real esperada:
   - PHASE -> contexto/02_changes/YYYY-MM-DD__phase-01__{slug}__{plan|summary}.md

Guardrails:
- Solo escribir en contexto/
- No tocar codigo
- No pedir confirmacion: escribir los archivos en contexto/ directamente.
- No incluir report-only como skill si el prompt debe escribir en contexto/.
- PHASE: max 5 archivos de codigo.
- Prohibido cambiar contratos externos (Redis key patterns, Rabbit routing keys, SignalR group naming) sin migracion explicita.

Salida obligatoria:
- CLASIFICACION
- PROMPT FINAL (listo para copiar/pegar)
- ARCHIVO (PackDir + archivo prompt creado)
- INDEX actualizado

Clasificacion: PHASE
Rationale:
- El input pide ejecutar una fase concreta del plan sugerido (Fase 2) con objetivo, archivos y verificacion ya definidos.
- El alcance esta acotado a dos archivos y un cambio concreto, por lo que es un cambio de fase.

PROMPT FINAL:
# PROMPT FINAL � PHASE-02 Frontend Maps: unsubscribe telemetria

PackDir: contexto/00_prompts/2026-02-04__pack-audit-pack-inicial-global
ItemId: PHASE-02
IndexRef: contexto/00_prompts/2026-02-04__pack-audit-pack-inicial-global/INDEX.md
PromptPath: contexto/00_prompts/2026-02-04__pack-audit-pack-inicial-global/phases/phase-03__frontend-maps-unsubscribe-telemetria__PHASE__PROMPT.md

Modo: refactor-safe + change-control
Skills: telemetric-frontend-style

Objetivo:
Agregar unsubscribe de telemetria al desmontar y/o cambiar de mapa en Viewer/Editor.

Alcance (archivos max 5):
- telemetric-front/src/features/maps/views/MapsViewerView.vue
- telemetric-front/src/features/maps/views/MapsEditorView.vue

Entregables:
- contexto/02_changes/2026-02-09__phase-02__frontend-maps-unsubscribe-telemetria__plan.md (usar contexto/01_overview/templates/TEMPLATE_CHANGE_PLAN.md)
- contexto/02_changes/2026-02-09__phase-02__frontend-maps-unsubscribe-telemetria__summary.md (usar contexto/01_overview/templates/TEMPLATE_CHANGE_SUMMARY.md)
- actualizar contexto/03_hallazgos/pending.md si aplica

Tarea:
1) Identificar donde se realiza la suscripcion a telemetria en Viewer/Editor y el punto correcto de cleanup.
2) Implementar unsubscribe en onUnmounted y antes de re-suscribir por cambio de mapa, sin cambiar el comportamiento funcional esperado.
3) Documentar el cambio y riesgos en el plan/summary.

Verificacion:
- Medir suscripciones activas antes/despues de navegar entre mapas.

Guardrails:
- Max 5 archivos de codigo.
- No cambiar contratos externos (Redis key patterns, Rabbit routing keys, SignalR group naming) sin migracion explicita.
- No ampliar alcance fuera del objetivo y archivos definidos.

No-go rules:
- No tocar otros modulos ni archivos fuera del alcance.
- No introducir cambios de API ni contratos externos.

Post-step obligatorio:
- Marcar como [x] el item PHASE-02 en IndexRef.
- Completar/confirmar el link de Output en IndexRef con las rutas reales de plan/summary.

Fecha: 2026-02-10

Input original:
Modo: docs-only
Skills: telemetric-prompt-builder

Input (texto humano):
Usar PackDir existente: contexto/00_prompts/2026-02-04__pack-audit-pack-inicial-global/
Fuente obligatoria: contexto/01_audits/2026-02-06__audit-05__frontend-maps-structure-lifecycle-performance-leaks.md
Quiero generar el PROMPT FINAL para ejecutar PHASE-03 basada en la seccion “Plan sugerido por fases”, Fase 3.
Usa exactamente el objetivo/archivos/verificacion definidos ahi, sin ampliar alcance.

Tarea:
1) Clasifica en: HALLAZGO | AUDIT | PHASE | STORY PACK (rationale en 2 bullets).
2) Determina el PackDir:
   - Si el input refiere a un pack existente, usar ese pack.
   - Si no, crear uno nuevo: contexto/00_prompts/YYYY-MM-DD__pack-{slug}/
3) Crea/actualiza el indice del pack:
   - contexto/00_prompts/YYYY-MM-DD__pack-{slug}/INDEX.md
   Reglas del indice:
   - Debe incluir checkboxes de estado del pack.
   - Debe incluir cada item con checkbox + links a Prompt y Output.
4) Guarda el prompt en:
   - contexto/00_prompts/YYYY-MM-DD__pack-{slug}/phases/phase-03__{slug}__PHASE__PROMPT.md 
5) (Si aplica) Actualiza en el INDEX el link de Output con ruta real esperada:
   - PHASE -> contexto/02_changes/YYYY-MM-DD__phase-01__{slug}__{plan|summary}.md

Guardrails:
- Solo escribir en contexto/
- No tocar codigo
- No pedir confirmacion: escribir los archivos en contexto/ directamente.
- No incluir report-only como skill si el prompt debe escribir en contexto/.
- PHASE: max 5 archivos de codigo.
- Prohibido cambiar contratos externos (Redis key patterns, Rabbit routing keys, SignalR group naming) sin migracion explicita.

Salida obligatoria:
- CLASIFICACION
- PROMPT FINAL (listo para copiar/pegar)
- ARCHIVO (PackDir + archivo prompt creado)
- INDEX actualizado

Clasificacion: PHASE
Rationale:
- El input pide ejecutar una fase concreta del plan sugerido (Fase 3) con objetivo, archivos y verificacion ya definidos.
- El alcance esta acotado a dos archivos y un cambio concreto, por lo que es un cambio de fase.

PROMPT FINAL:
# PROMPT FINAL — PHASE-03 Frontend Maps: harden lifecycle edge-cases (drag durante unmount)

PackDir: contexto/00_prompts/2026-02-04__pack-audit-pack-inicial-global
ItemId: PHASE-03
IndexRef: contexto/00_prompts/2026-02-04__pack-audit-pack-inicial-global/INDEX.md
PromptPath: contexto/00_prompts/2026-02-04__pack-audit-pack-inicial-global/phases/phase-03__frontend-maps-lifecycle-edge-cases-drag-unmount__PHASE__PROMPT.md

Modo: refactor-safe + change-control
Skills: telemetric-frontend-style

Objetivo:
Harden lifecycle edge-cases (drag durante unmount).

Alcance (archivos max 5):
- telemetric-front/src/features/maps/composables/plan/useLeafletTransform.ts
- telemetric-front/src/features/maps/composables/useChildNodeDragging.ts

Entregables:
- contexto/02_changes/2026-02-10__phase-03__frontend-maps-lifecycle-edge-cases-drag-unmount__plan.md (usar contexto/01_overview/templates/TEMPLATE_CHANGE_PLAN.md)
- contexto/02_changes/2026-02-10__phase-03__frontend-maps-lifecycle-edge-cases-drag-unmount__summary.md (usar contexto/01_overview/templates/TEMPLATE_CHANGE_SUMMARY.md)
- actualizar contexto/03_hallazgos/pending.md si aplica

Tarea:
1) Identificar listeners globales de drag y puntos de cleanup durante unmount en ambos composables.
2) Asegurar cleanup de listeners (mousemove/mouseup) en onUnmounted o hooks equivalentes.
3) Documentar el cambio y riesgos en el plan/summary.

Verificacion:
- Iniciar drag y salir de la vista; confirmar que no quedan listeners en window.

Guardrails:
- Max 5 archivos de codigo.
- No cambiar contratos externos (Redis key patterns, Rabbit routing keys, SignalR group naming) sin migracion explicita.
- No ampliar alcance fuera del objetivo y archivos definidos.

No-go rules:
- No tocar otros modulos ni archivos fuera del alcance.
- No introducir cambios de API ni contratos externos.

Post-step obligatorio:
- Marcar como [x] el item PHASE-03 en IndexRef.
- Completar/confirmar el link de Output en IndexRef con las rutas reales de plan/summary.
