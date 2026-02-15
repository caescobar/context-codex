# CHANGE PLAN - frontend-maps-cleanup-listeners-duplicados-interaccion - Fase 01

## 0) Metadata
- Fecha: 2026-02-09
- Alcance: PHASE-01 Frontend Maps: limpiar listeners y evitar duplicados de interaccion
- Modo: refactor-safe + change-control
- Skills: telemetric-frontend-style

## 0.1 Trazabilidad del pack
- PackDir: contexto/00_prompts/2026-02-04__pack-audit-pack-inicial-global/
- PhaseId: PHASE-01
- IndexRef: contexto/00_prompts/2026-02-04__pack-audit-pack-inicial-global/INDEX.md
- PromptSource: contexto/00_prompts/2026-02-04__pack-audit-pack-inicial-global/phases/phase-03__frontend-maps-cleanup-listeners-duplicados-interaccion__PHASE__PROMPT.md

## 1) Objetivo
- Limpiar listeners globales y evitar duplicados de interaccion en el editor/renderer sin ampliar alcance.

## 2) Archivos a tocar (max 5)
- telemetric-front/src/features/maps/views/MapsEditorView.vue
- telemetric-front/src/features/maps/components/canvas/renderers/MapRenderer.vue
- telemetric-front/src/features/maps/composables/useNodeInteractions.ts
- telemetric-front/src/features/maps/services/selection/selection.service.ts

## 3) Evidencia (paths)
- telemetric-front/src/features/maps/views/MapsEditorView.vue
- telemetric-front/src/features/maps/components/canvas/renderers/MapRenderer.vue
- telemetric-front/src/features/maps/composables/useNodeInteractions.ts
- telemetric-front/src/features/maps/services/selection/selection.service.ts

## 4) Plan en 5 bullets
1) Consolidar keydown global en el editor y remover duplicados de inicializacion.
2) Evitar doble setup de interacciones en el renderer al crear nodos.
3) Hacer idempotente el binding de listeners en capas y elementos DOM de nodos.
4) Evitar duplicacion de listeners en handles de seleccion.
5) Validar manualmente navegacion Editor/Viewer y seleccion/drag.

## 5) Riesgos y mitigaciones
- Riesgo: rebind de interacciones pueda desactivar handlers esperados.
- Mitigacion: re-registrar handlers por capa con almacenamiento y rebind controlado.

## 6) Como verificar (pasos manuales)
1) Accion: repetir navegacion Editor/Viewer. Expected: los handlers no se duplican.
2) Accion: revisar seleccion/drag. Expected: los handlers responden una sola vez y sin duplicacion.

## 7) No-go rules (si pasa esto, parar)
- Requiere tocar archivos fuera del Alcance o superar 5 archivos de codigo.
- Implica cambiar contratos externos sin migracion explicita.
- No se puede cumplir la verificacion.

## 8) Post-step (actualizar checklist)
- Marcar `[x]` en `IndexRef` para `PHASE-01`.
- Completar/actualizar links a Plan y Summary en el indice.
