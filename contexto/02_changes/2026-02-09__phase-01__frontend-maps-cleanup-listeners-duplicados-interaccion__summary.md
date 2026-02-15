# CHANGE SUMMARY - frontend-maps-cleanup-listeners-duplicados-interaccion - Fase 01

## 0) Metadata
- Fecha: 2026-02-09
- PR/Commit (si aplica):

## 0.1 Trazabilidad del pack
- PackDir: contexto/00_prompts/2026-02-04__pack-audit-pack-inicial-global/
- PhaseId: PHASE-01
- IndexRef: contexto/00_prompts/2026-02-04__pack-audit-pack-inicial-global/INDEX.md
- PromptSource: contexto/00_prompts/2026-02-04__pack-audit-pack-inicial-global/phases/phase-03__frontend-maps-cleanup-listeners-duplicados-interaccion__PHASE__PROMPT.md

## 1) Que cambio
- Consolidado el keydown global del editor y eliminado duplicados de inicializacion.
- Eliminado el doble setup de interacciones al crear capas.
- Hecho idempotente el binding de handlers en capas y en elementos hijos.
- Evitada la duplicacion de listeners en handles de seleccion.

## 2) Archivos tocados
- telemetric-front/src/features/maps/views/MapsEditorView.vue
- telemetric-front/src/features/maps/components/canvas/renderers/MapRenderer.vue
- telemetric-front/src/features/maps/composables/useNodeInteractions.ts
- telemetric-front/src/features/maps/services/selection/selection.service.ts

## 3) Como probar
1) Accion: repetir navegacion Editor/Viewer. Expected: los handlers no se duplican.
2) Accion: revisar seleccion/drag. Expected: los handlers responden una sola vez y sin duplicacion.

## 4) Resultado esperado / observado
- Paso 1: Expected: no duplicacion de handlers al navegar. Observado: no ejecutado (pendiente verificacion manual).
- Paso 2: Expected: seleccion/drag responde una sola vez. Observado: no ejecutado (pendiente verificacion manual).
- Done criteria: pendiente hasta completar verificacion manual.

## 5) Hallazgos nuevos o pendientes
- Ninguno.

## 6) Riesgo de romper contratos
- No: cambios internos de listeners en frontend sin modificar contratos externos.

## 7) Post-step (actualizar checklist)
- Marcar `[x]` en `IndexRef` para `PHASE-01`.
- Completar/actualizar links a Summary en el indice.
