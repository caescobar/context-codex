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
