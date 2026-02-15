# PHASE PROMPT - phase-01__frontend-maps-cleanup-listeners-duplicados-interaccion

PackDir: contexto/00_prompts/2026-02-04__pack-audit-pack-inicial-global/
ItemId: PHASE-01
IndexRef: contexto/00_prompts/2026-02-04__pack-audit-pack-inicial-global/INDEX.md
PromptPath: contexto/00_prompts/2026-02-04__pack-audit-pack-inicial-global/phases/phase-03__frontend-maps-cleanup-listeners-duplicados-interaccion__PHASE__PROMPT.md

Modo: refactor-safe + change-control
Skills: telemetric-frontend-style

Objetivo
- limpiar listeners globales y evitar duplicados de interacción.

Alcance (max 5 archivos de codigo)
- telemetric-front/src/features/maps/views/MapsEditorView.vue
- telemetric-front/src/features/maps/components/canvas/renderers/MapRenderer.vue
- telemetric-front/src/features/maps/composables/useNodeInteractions.ts
- telemetric-front/src/features/maps/services/selection/selection.service.ts
- telemetric-front/src/features/maps/composables/useChildNodeDragging.ts

Entregables
- contexto/02_changes/2026-02-09__phase-01__frontend-maps-cleanup-listeners-duplicados-interaccion__plan.md (usar contexto/01_overview/templates/TEMPLATE_CHANGE_PLAN.md)
- contexto/02_changes/2026-02-09__phase-01__frontend-maps-cleanup-listeners-duplicados-interaccion__summary.md (usar contexto/01_overview/templates/TEMPLATE_CHANGE_SUMMARY.md)
- Actualizar contexto/03_hallazgos/pending.md solo si hay hallazgos nuevos o cambio de estado

Guardrails
- Maximo 5 archivos: solo los listados en Alcance
- No ampliar alcance
- Prohibido cambiar contratos externos (Redis key patterns, Rabbit routing keys, SignalR group naming) sin migracion explicita
- Si algun path no existe: buscar y confirmar el path real antes de continuar

No-go rules
- Si requiere tocar archivos fuera del Alcance o superar 5 archivos
- Si implica cambiar contratos externos sin migracion explicita
- Si no se puede cumplir la verificacion

Tarea (ejecutor)
1) Ejecutar cambios minimos para limpiar listeners globales y evitar duplicados de interaccion dentro del Alcance.
2) Completar plan + summary usando templates (con evidencia paths).
3) En summary: resultado observado vs expected para cada paso de verificacion + Done criteria.

Verificacion (pasos manuales)
1) Accion: repetir navegacion Editor/Viewer. Expected: los handlers no se duplican.
2) Accion: revisar seleccion/drag. Expected: los handlers responden una sola vez y sin duplicacion.

Done criteria
- Los listeners globales quedan con cleanup y no se duplican en navegacion.
- La seleccion/drag funciona sin duplicacion de handlers.

Post-step obligatorio
- Marcar [ ] PHASE-01 en IndexRef
- Completar/actualizar links de Output (plan y summary) en el indice
