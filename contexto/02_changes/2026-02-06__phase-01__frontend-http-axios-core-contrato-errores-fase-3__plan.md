# CHANGE PLAN - frontend-http-axios-core-contrato-errores-fase-3 - Fase 01

## 0) Metadata
- Fecha: 2026-02-06
- Alcance: PHASE-01
- Modo: refactor-safe + change-control
- Skills: telemetric-frontend-style

## 0.1 Trazabilidad del pack
- PackDir: contexto/00_prompts/2026-02-04__pack-audit-pack-inicial-global/
- PhaseId: PHASE-01
- IndexRef: contexto/00_prompts/2026-02-04__pack-audit-pack-inicial-global/INDEX.md
- PromptSource: contexto/00_prompts/2026-02-04__pack-audit-pack-inicial-global/phases/phase-01__frontend-http-axios-core-contrato-errores-fase-3__PHASE__PROMPT.md

## 1) Objetivo
- Migrar stores demo a AXIOS CORE unico y unificar manejo de errores, limpiando imports residuales.

## 2) Archivos a tocar (max 5)
- telemetric-front/src/stores/apps/blog.ts
- telemetric-front/src/stores/apps/chat.ts
- telemetric-front/src/stores/apps/email.ts
- telemetric-front/src/stores/apps/invoice/index.ts
- telemetric-front/src/stores/apps/notes.ts

## 3) Evidencia (paths)
- AXIOS CORE real del proyecto: telemetric-front/src/core/utils/axios.ts
- Mapeo de errores unificado: telemetric-front/src/core/stores/notification.ts
- Ejemplos similares revisados: telemetric-front/src/stores/apps/contact.ts, telemetric-front/src/stores/apps/eCommerce.ts

## 4) Plan en 5 bullets
1) Cambiar imports en los 5 stores para usar AXIOS CORE del proyecto.
2) Reemplazar alert/console de errores por el handler unificado de notificaciones.
3) Eliminar imports residuales no usados en los stores.
4) Verificar que los stores mantienen el mismo contrato de datos y rutas.
5) Completar plan/summary e index con trazabilidad y resultados de verificacion.

## 5) Riesgos y mitigaciones
- Riesgo: diferencias en comportamiento de errores vs. alert/console.
- Mitigacion: usar catchErrorHandler del core para mantener contrato de errores unificado.

## 6) Como verificar (pasos manuales)
1) Abrir la pantalla demo de Blog y ejecutar la carga/listado principal. Expected: La pantalla carga sin errores y no hay notificaciones de error inesperadas.
2) Abrir la pantalla demo de Chat y realizar la accion principal de lectura/carga. Expected: El flujo responde sin errores y el manejo de error es consistente.
3) Abrir la pantalla demo de Email e Invoice y ejecutar la carga inicial. Expected: La UI carga y los errores, si existen, se reportan con el contrato unificado (sin silencios).
4) Abrir la pantalla demo de Notes y provocar un error controlado (si aplica) usando el mecanismo disponible. Expected: Se muestra una notificacion de error consistente y no se silencian fallos.

## 7) No-go rules (si pasa esto, parar)
- Requiere tocar archivos fuera del Alcance o superar 5 archivos.
- Implica cambiar contratos externos sin migracion explicita.
- No se puede cumplir la verificacion.

## 8) Post-step (actualizar checklist)
- Marcar `[x]` en `IndexRef` para `PHASE-01`.
- Completar/actualizar links a Plan y Summary en el indice.
