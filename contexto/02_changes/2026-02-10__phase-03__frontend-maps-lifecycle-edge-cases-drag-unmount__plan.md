# CHANGE PLAN - phase-03__frontend-maps-lifecycle-edge-cases-drag-unmount - Fase 03

## 0) Metadata
- Fecha: 2026-02-10
- Alcance: Frontend Maps - harden lifecycle edge-cases (drag durante unmount)
- Modo: refactor-safe + change-control
- Skills: telemetric-frontend-style, refactor-safe, change-control

## 0.1 Trazabilidad del pack
- PackDir: contexto/00_prompts/2026-02-04__pack-audit-pack-inicial-global
- PhaseId: PHASE-03
- IndexRef: contexto/00_prompts/2026-02-04__pack-audit-pack-inicial-global/INDEX.md
- PromptSource: contexto/00_prompts/2026-02-04__pack-audit-pack-inicial-global/phases/phase-03__frontend-maps-lifecycle-edge-cases-drag-unmount__PHASE__PROMPT.md

## 1) Objetivo
- Asegurar cleanup de listeners globales de drag al desmontar, evitando leaks si se sale de la vista durante un drag.

## 2) Archivos a tocar (max 5)
- telemetric-front/src/features/maps/composables/plan/useLeafletTransform.ts
- telemetric-front/src/features/maps/composables/useChildNodeDragging.ts

## 3) Evidencia (paths)
- telemetric-front/src/features/maps/composables/plan/useLeafletTransform.ts (window mousemove/mouseup sin onUnmounted)
- telemetric-front/src/features/maps/composables/useChildNodeDragging.ts (window mousemove/mouseup sin onUnmounted)
- contexto/03_hallazgos/pending.md (HALL-20260206-007)

## 4) Plan en 5 bullets
1) Agregar cleanup explicito de listeners en unmount para transform/drag.
2) Consolidar reset de estado para evitar commits parciales al desmontar.
3) Mantener comportamiento actual en mouseup (commit al store y re-enable de dragging segun tool).
4) Actualizar plan/summary y (si aplica) el hallazgo relacionado.
5) Actualizar indice con outputs y marcar PHASE-03.

## 5) Riesgos y mitigaciones
- Riesgo: re-enable de map dragging en escenarios no PAN.
  Mitigacion: mantener la misma regla que en mouseup (solo PAN).
- Riesgo: cancelar drag sin commit al unmount.
  Mitigacion: comportamiento esperado para evitar writes fuera de contexto al desmontar.

## 6) Como verificar (pasos manuales)
1) Iniciar drag de nodo/transform y navegar fuera de la vista antes de soltar el mouse.
2) Confirmar que no quedan listeners en window (no se dispara mas el drag).
3) Volver a la vista y repetir drag; el comportamiento debe ser normal.

## 7) No-go rules (si pasa esto, parar)
- Se requieren cambios fuera de los 2 composables.
- Se necesita cambiar contratos externos o APIs no autorizadas.

## 8) Post-step (actualizar checklist)
- Marcar `[x]` en `IndexRef` para `PHASE-03`.
- Completar/actualizar links a Plan y Summary en el indice.
