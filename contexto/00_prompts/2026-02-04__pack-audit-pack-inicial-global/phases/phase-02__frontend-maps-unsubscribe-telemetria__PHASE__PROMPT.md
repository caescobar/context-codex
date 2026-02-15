# PROMPT FINAL — PHASE-02 Frontend Maps: unsubscribe telemetria

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
