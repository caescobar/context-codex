# AUDIT REPORT – audit-05__frontend-maps-structure-lifecycle-performance-leaks

## 0) Metadata
- Fecha: 2026-02-06
- Modo: docs-only (audit-exec, sin cambios de código)
- Skills aplicadas: telemetric-frontend-style
- Objetivo: Auditar la implementacion de Maps en frontend (estructura, lifecycle, performance, leaks).
- Repos/servicios: telemetric-front
- Autor: Codex (asistido)

## 0.1 Trazabilidad del pack
- PackDir: contexto/00_prompts/2026-02-04__pack-audit-pack-inicial-global
- AuditId: AUDIT-05
- IndexRef: contexto/00_prompts/2026-02-04__pack-audit-pack-inicial-global/INDEX.md
- PromptSource: contexto/00_prompts/2026-02-04__pack-audit-pack-inicial-global/audit-05__frontend-maps-structure-lifecycle-performance-leaks__AUDIT__PROMPT.md

## 1) Executive Summary (máx 5 bullets)
- La feature Maps está organizada en views + store + renderer Leaflet + composables/servicios específicos; el core visual es `MapRenderer.vue` y el host dinámico es `CanvasHost.vue`.
- Se detectan listeners globales y DOM con cleanup incompleto o re-binds múltiples (keydown global, handle events, setupInteractions duplicado), con riesgo de leaks y eventos duplicados.
- En Viewer/Editor se realiza suscripción a telemetría sin evidencia de unsubscribe en unmount o cambio de mapa, potencialmente acumulando streams.
- Hay optimizaciones locales (signature de nodos, dirty nodes en viewer), pero el renderer aún recalcula/reatacha con watchers deep sobre escenas grandes.

## 2) Alcance (Scope)
### 2.1 Paths/archivos analizados
- telemetric-front/src/features/maps/views/MapsListView.vue
- telemetric-front/src/features/maps/views/MapsViewerView.vue
- telemetric-front/src/features/maps/views/MapsEditorView.vue
- telemetric-front/src/features/maps/components/canvas/CanvasHost.vue
- telemetric-front/src/features/maps/components/canvas/renderers/MapRenderer.vue
- telemetric-front/src/features/maps/composables/useNodeInteractions.ts
- telemetric-front/src/features/maps/composables/useChildNodeDragging.ts
- telemetric-front/src/features/maps/composables/plan/useLeafletTransform.ts
- telemetric-front/src/features/maps/services/selection/selection.service.ts
- telemetric-front/src/features/maps/components/widgets/SparklineWidget.vue
- telemetric-front/src/features/maps/store/maps.store.ts

### 2.2 Fuera de alcance
- Backends de telemetría (API/Hub/Workers).
- Implementación interna de `telemetryService`/SignalR fuera de Maps.

## 3) Contrato actual observado (Fuente: código)
> Tabla obligatoria. No asumir. Si algo no se encontró, escribir “No encontrado”.

| Capa | Identidad externa (serial/id) | Key/Routing/Group | Campos/Shape | Evidencia (paths) |
|---|---|---|---|---|
| SQL | No encontrado | No encontrado | No encontrado | No encontrado |
| Redis config | No encontrado | No encontrado | No encontrado | No encontrado |
| Redis last-value | No encontrado | No encontrado | No encontrado | No encontrado |
| Rabbit raw | No encontrado | No encontrado | No encontrado | No encontrado |
| Rabbit normalized | No encontrado | No encontrado | No encontrado | No encontrado |
| SignalR | No encontrado | No encontrado | No encontrado | No encontrado |
| Payload | No encontrado | No encontrado | No encontrado | No encontrado |

## 4) Nombres canónicos encontrados (no inventar)
- No encontrado (no hay contratos Redis/Rabbit/SignalR definidos en la capa Maps frontend).
**Evidencia:** No encontrado.

## 5) Hallazgos (con evidencia)
> Cada hallazgo debe tener: severidad, impacto, evidencia, repro si aplica, recomendación.

### Medium
- **HALL-20260206-004 – Listener global de teclado no se limpia en MapsEditor**
  - Impacto: cada montaje del editor agrega un listener adicional (focus con tecla “F”), causando duplicación de eventos y fuga de memoria al navegar entre rutas.
  - Evidencia (paths): telemetric-front/src/features/maps/views/MapsEditorView.vue
  - Repro (si aplica): entrar/salir del editor varias veces y presionar “F”; el handler se dispara múltiples veces.
  - Recomendación: extraer el handler a una función nombrada y removerlo en `onUnmounted`, o usar `onMounted/onUnmounted` con el mismo callback.

- **HALL-20260206-005 – Re-binds de interacciones sin cleanup (duplicación de listeners)**
  - Impacto: `setupInteractions` se invoca más de una vez por nodo y vuelve a adjuntar listeners Leaflet/DOM sin `off/removeEventListener`, elevando el costo por frame y riesgo de eventos duplicados.
  - Evidencia (paths):
    - telemetric-front/src/features/maps/components/canvas/renderers/MapRenderer.vue (doble llamada a `interactors.setupInteractions` en creación y en updates)
    - telemetric-front/src/features/maps/composables/useNodeInteractions.ts (eventos `layer.on(...)` y `addEventListener` sin cleanup)
    - telemetric-front/src/features/maps/services/selection/selection.service.ts (handles `addEventListener` sin cleanup)
  - Repro (si aplica): editar un nodo que fuerza `setIcon` y observar que eventos de click/drag se disparan más de una vez.
  - Recomendación: centralizar el binding en un solo punto y limpiar handlers previos (`layer.off`, `removeEventListener`), o usar guardas por nodo para evitar re-registrar.

- **HALL-20260206-006 – Suscripciones a telemetría sin unsubscribe en Viewer/Editor**
  - Impacto: al navegar entre mapas o salir de la vista, los streams podrían permanecer activos y duplicar tráfico/CPU.
  - Evidencia (paths):
    - telemetric-front/src/features/maps/views/MapsViewerView.vue (subscribe en `onMounted`, sin unsubscribe en `onUnmounted`)
    - telemetric-front/src/features/maps/views/MapsEditorView.vue (subscribe en `onMounted` y en `watch`, sin unsubscribe en `onUnmounted`)
  - Repro (si aplica): abrir múltiples mapas en secuencia; verificar si `telemetryService` mantiene múltiples suscripciones concurrentes.
  - Recomendación: agregar `telemetryService.unsubscribe(...)` o un `reset` en `onUnmounted` y antes de re-suscribir por cambio de mapa.

### Low
- **HALL-20260206-007 – Listeners globales de drag sin cleanup en unmount (edge case)**
  - Impacto: si el componente se desmonta durante un drag activo, los listeners de `mousemove/mouseup` podrían quedar vivos.
  - Evidencia (paths):
    - telemetric-front/src/features/maps/composables/plan/useLeafletTransform.ts
    - telemetric-front/src/features/maps/composables/useChildNodeDragging.ts
  - Repro (si aplica): iniciar drag y navegar fuera de la vista antes de soltar el mouse.
  - Recomendación: agregar `onUnmounted` local para forzar `removeEventListener` y resetear flags.

## 6) Riesgos de romper contratos
- Riesgo: cambiar el ciclo de suscripción o el binding de interacciones puede alterar el comportamiento esperado de selección/drag.
- Mitigación: agregar pruebas manuales de interacción (selección, drag, resize, focus, selección múltiple) y validar tráfico de telemetría después de cada cambio.

## 7) Recomendación priorizada
1) Limpiar listeners globales (keydown y drag) en unmount y garantizar cleanup al cambiar de mapa.
2) Consolidar el binding de interacciones (una sola ruta de `setupInteractions` + `off/removeEventListener`).
3) Implementar unsubscribe explícito en Viewer/Editor al salir o cambiar de mapa.

## 8) Plan sugerido por fases (sin ejecutar)
> Máx 5 archivos por fase. No cambiar contratos sin migración.

### Fase 1
- Objetivo: limpiar listeners globales y evitar duplicados de interacción.
- Archivos potenciales (máx 5):
  - telemetric-front/src/features/maps/views/MapsEditorView.vue
  - telemetric-front/src/features/maps/components/canvas/renderers/MapRenderer.vue
  - telemetric-front/src/features/maps/composables/useNodeInteractions.ts
  - telemetric-front/src/features/maps/services/selection/selection.service.ts
  - telemetric-front/src/features/maps/composables/useChildNodeDragging.ts
- Verificación: repetir navegación Editor/Viewer y validar que los handlers no se duplican; revisar selección/drag.

### Fase 2
- Objetivo: agregar unsubscribe de telemetría al desmontar/cambiar mapa.
- Archivos potenciales (máx 5):
  - telemetric-front/src/features/maps/views/MapsViewerView.vue
  - telemetric-front/src/features/maps/views/MapsEditorView.vue
- Verificación: medir suscripciones activas antes/después de navegar entre mapas.

### Fase 3
- Objetivo: harden lifecycle edge-cases (drag durante unmount).
- Archivos potenciales (máx 5):
  - telemetric-front/src/features/maps/composables/plan/useLeafletTransform.ts
  - telemetric-front/src/features/maps/composables/useChildNodeDragging.ts
- Verificación: iniciar drag y salir de la vista; confirmar que no quedan listeners en window.

## 9) Cómo verificar (smoke test)
1) Abrir `MapsListView` y entrar a un mapa; volver atrás y repetir 3 veces; verificar que los atajos no se duplican.
2) En Editor, crear/seleccionar nodos y hacer drag/resize/rotación; confirmar que los handlers responden una sola vez.
3) En Viewer, abrir mapa con telemetría activa, salir y volver; comprobar que no se duplican actualizaciones/streams.

## 10) Pendientes registrados
- Añadir/actualizar en `contexto/03_hallazgos/pending.md`: HALL-20260206-004, HALL-20260206-005, HALL-20260206-006, HALL-20260206-007
