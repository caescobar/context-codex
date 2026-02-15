# CHANGE PLAN - frontend-maps-unsubscribe-telemetria - Fase 02

## 0) Metadata
- Fecha: 2026-02-10
- Alcance: PHASE-02
- Modo: refactor-safe + change-control
- Skills: refactor-safe + change-control + telemetric-frontend-style

## 0.1 Trazabilidad del pack
- PackDir: contexto/00_prompts/2026-02-04__pack-audit-pack-inicial-global
- PhaseId: PHASE-02
- IndexRef: contexto/00_prompts/2026-02-04__pack-audit-pack-inicial-global/INDEX.md
- PromptSource: contexto/00_prompts/2026-02-04__pack-audit-pack-inicial-global/phases/phase-03__frontend-maps-unsubscribe-telemetria__PHASE__PROMPT.md

## 1) Objetivo
- Agregar unsubscribe de telemetria al desmontar y antes de re-suscribir por cambio de mapa en Viewer/Editor.

## 2) Archivos a tocar (max 5)
- telemetric-front/src/features/maps/views/MapsViewerView.vue
- telemetric-front/src/features/maps/views/MapsEditorView.vue
- contexto/02_changes/2026-02-09__phase-02__frontend-maps-unsubscribe-telemetria__plan.md
- contexto/02_changes/2026-02-09__phase-02__frontend-maps-unsubscribe-telemetria__summary.md
- contexto/00_prompts/2026-02-04__pack-audit-pack-inicial-global/INDEX.md

## 3) Evidencia (paths)
- Suscripcion en Viewer: telemetric-front/src/features/maps/views/MapsViewerView.vue
- Suscripcion en Editor: telemetric-front/src/features/maps/views/MapsEditorView.vue
- Unsubscribe disponible en TelemetryService: telemetric-front/src/features/telemetry/telemetry.service.ts

## 4) Plan en 5 bullets
1) Extraer/centralizar el calculo de deviceIds por escena en Viewer/Editor.
2) Guardar la lista de deviceIds suscritos para cleanup.
3) Ejecutar unsubscribe en onUnmounted en ambos views.
4) Ejecutar unsubscribe antes de re-suscribir al cambiar de mapa en Editor.
5) Documentar cambios, riesgos y verificacion en plan/summary e index.

## 5) Riesgos y mitigaciones
- Riesgo: quedar suscrito a dispositivos que ya no aplican si el cambio de mapa falla a mitad.
- Mitigacion: hacer unsubscribe antes de cargar el nuevo mapa y limpiar el estado local.
- Riesgo: pequena ventana sin telemetria si re-suscripcion se demora.
- Mitigacion: mantener re-suscripcion inmediata tras loadMap.

## 6) Como verificar (pasos manuales)
1) Abrir Viewer con un mapa que tenga dispositivos y observar logs de suscripcion (console).
2) Navegar a otro mapa / salir del viewer y verificar logs de unsubscribe.
3) En Editor, cambiar de mapa con route params y confirmar que se hace unsubscribe previo y luego subscribe.

## 7) No-go rules (si pasa esto, parar)
- No tocar otros modulos ni archivos fuera del alcance.
- No introducir cambios de API ni contratos externos.

## 8) Post-step (actualizar checklist)
- Marcar `[x]` en `IndexRef` para `PHASE-02`.
- Completar/actualizar links a Plan y Summary en el indice.
