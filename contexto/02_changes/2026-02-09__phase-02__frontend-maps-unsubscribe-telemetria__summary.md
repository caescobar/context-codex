# CHANGE SUMMARY - frontend-maps-unsubscribe-telemetria - Fase 02

## 0) Metadata
- Fecha: 2026-02-10
- PR/Commit (si aplica):

## 0.1 Trazabilidad del pack
- PackDir: contexto/00_prompts/2026-02-04__pack-audit-pack-inicial-global
- PhaseId: PHASE-02
- IndexRef: contexto/00_prompts/2026-02-04__pack-audit-pack-inicial-global/INDEX.md
- PromptSource: contexto/00_prompts/2026-02-04__pack-audit-pack-inicial-global/phases/phase-03__frontend-maps-unsubscribe-telemetria__PHASE__PROMPT.md

## 1) Que cambio
- Se agrego cleanup de telemetria en Viewer (onUnmounted) usando la lista de deviceIds suscritos.
- En Editor, se agrego unsubscribe en onUnmounted y antes de re-suscribir cuando cambia el mapa.
- Se centralizo el calculo de deviceIds por escena para reutilizarlo en subscribe/unsubscribe.
- Se agregaron logs de seguimiento en Editor para route change y cleanup.

## 2) Archivos tocados
- telemetric-front/src/features/maps/views/MapsViewerView.vue
- telemetric-front/src/features/maps/views/MapsEditorView.vue
- contexto/02_changes/2026-02-09__phase-02__frontend-maps-unsubscribe-telemetria__plan.md
- contexto/02_changes/2026-02-09__phase-02__frontend-maps-unsubscribe-telemetria__summary.md
- contexto/00_prompts/2026-02-04__pack-audit-pack-inicial-global/INDEX.md

## 3) Como probar
1) Abrir Viewer con un mapa que tenga dispositivos y observar logs de suscripcion (console).
2) Navegar a otro mapa / salir del viewer y verificar logs de unsubscribe.
3) En Editor, cambiar de mapa con route params y confirmar que se hace unsubscribe previo y luego subscribe.

## 4) Resultado esperado / observado
- Esperado: las suscripciones activas bajan al salir o cambiar de mapa y se reactivan al cargar el nuevo mapa.
- Observado: pendiente de verificacion manual.

## 5) Hallazgos nuevos o pendientes
- N/A

## 6) Riesgo de romper contratos
- No. No se tocaron contratos externos ni servicios.

## 7) Post-step (actualizar checklist)
- Marcar `[x]` en `IndexRef` para `PHASE-02`.
- Completar/actualizar links a Summary en el indice.
