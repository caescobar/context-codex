# FRONT-TYPECHECK v1 (no-demo)

Fecha base: 2026-02-19
Fuente de evidencia:
- `contexto/work/features/acciones_modulo/04_test/ACT-003/phase-03/evidence/outputs.log`

## Objetivo
Gestionar la deuda de typecheck de frontend fuera de `_demo` como track tecnico separado, sin interferir con el delivery de `acciones_modulo`.

## Politica de no-colision con delivery
- No bloquea delivery mientras:
  - los cambios nuevos no aumenten el conteo de errores no-demo;
  - los archivos tocados por la story activa queden iguales o mejor en tipado.
- Si bloquea delivery cuando:
  - los errores estan en rutas que se estan modificando en la story actual;
  - e impiden compilar, testear o integrar.

## Baseline actual (no-demo)
- Errores TypeScript no-demo detectados: `240`
- Alcance excluido: `src/_demo/**`
- Concentracion por area:
  - `src/features/**`: `208`
  - `src/core/**`: `14`
  - `src/components/**`: `8`
  - `src/stratlabs-ui/**`: `6`
  - `src/services/**`: `2`
  - `src/stores/**`: `2`

## Backlog tecnico

### Fase 1 (P0) - Contrato HTTP y servicios tipados

#### BL-001
- Prioridad: P0
- Estado: TODO
- Objetivo: unificar contrato HTTP tipado para eliminar `unknown` y mal uso de genericos.
- Errores objetivo: `TS2558`, `TS18046`
- Archivos foco:
  - `telemetric-front/src/features/admin/clients/client.service.ts`
  - `telemetric-front/src/features/admin/metrics/metric.service.ts`
  - `telemetric-front/src/features/admin/models/model.service.ts`
  - `telemetric-front/src/features/admin/sensortypes/sensortype.service.ts`
  - `telemetric-front/src/features/customer/tags/tags.service.ts`
  - `telemetric-front/src/features/maps/store/maps.store.ts`
- Criterio de cierre:
  - No quedan `TS2558` en los archivos foco.
  - Se reduce de forma sustantiva `TS18046` en servicios/store.

#### BL-002
- Prioridad: P0
- Estado: TODO
- Objetivo: normalizar contratos `ListResponse`/`PagedList` entre servicios y vistas de listas.
- Errores objetivo: `TS2345`, `TS2322`, `TS2339`
- Archivos foco:
  - `telemetric-front/src/core/hooks/useDataTableFetch.ts`
  - `telemetric-front/src/features/admin/clients/views/ClientListView.vue`
  - `telemetric-front/src/features/admin/devices/views/DeviceListView.vue`
  - `telemetric-front/src/features/admin/metrics/views/MetricListView.vue`
  - `telemetric-front/src/features/admin/models/views/ModelListView.vue`
  - `telemetric-front/src/features/admin/security/views/UserListView.vue`
  - `telemetric-front/src/features/admin/sensortypes/views/SensorTypeListView.vue`
  - `telemetric-front/src/features/admin/units/views/UnitListView.vue`
  - `telemetric-front/src/features/maps/components/inspector/sections/InspectorBinding.vue`
- Criterio de cierre:
  - No quedan errores de incompatibilidad de respuesta en las vistas foco.
  - Acceso a `items` y paginacion consistente con tipos reales.

#### BL-003
- Prioridad: P0
- Estado: TODO
- Objetivo: corregir funciones con retorno incompleto.
- Errores objetivo: `TS2366`
- Archivos foco:
  - `telemetric-front/src/features/admin/devices/device.service.ts`
  - `telemetric-front/src/features/admin/security/security.service.ts`
  - `telemetric-front/src/features/admin/units/unit.service.ts`
  - `telemetric-front/src/features/telemetry/telemetry.service.ts`
  - `telemetric-front/src/services/organization.service.ts`
- Criterio de cierre:
  - No quedan `TS2366` en los servicios foco.

### Fase 2 (P0/P1) - Maps (store + inspector + runtime)

#### BL-004
- Prioridad: P0
- Estado: TODO
- Objetivo: tipar respuestas y DTOs en `maps.store` para cortar cascada de errores.
- Errores objetivo: `TS18046`, `TS2558`, `TS2339`
- Archivos foco:
  - `telemetric-front/src/features/maps/store/maps.store.ts`
  - `telemetric-front/src/features/maps/utils/runtime/TelemetryAdapter.ts`
- Criterio de cierre:
  - Reduccion significativa de errores de `maps.store.ts`.
  - Sin imports de tipos inexistentes en runtime.

#### BL-005
- Prioridad: P1
- Estado: TODO
- Objetivo: alinear schema de estilos del inspector con tipos reales.
- Errores objetivo: `TS2339`, `TS2352`
- Archivos foco:
  - `telemetric-front/src/features/maps/components/inspector/sections/InspectorStyle.vue`
- Criterio de cierre:
  - No quedan propiedades inexistentes (`title*`, `aggregation*`, `imageVariables`) en el tipado efectivo.

#### BL-006
- Prioridad: P1
- Estado: TODO
- Objetivo: corregir contratos de eventos y handlers en canvas maps.
- Errores objetivo: `TS2345`, `TS2769`, `TS7006`
- Archivos foco:
  - `telemetric-front/src/features/maps/components/canvas/elements/pipe/KonvaPipe.vue`
  - `telemetric-front/src/features/maps/components/canvas/elements/shapes/KonvaPoly.vue`
  - `telemetric-front/src/features/maps/views/MapsViewerView.vue`
- Criterio de cierre:
  - Eventos emitidos/escuchados tipados y compatibles.
  - Sin `any` implicitos en callbacks de canvas.

### Fase 3 (P1) - Customer features

#### BL-007
- Prioridad: P1
- Estado: TODO
- Objetivo: eliminar `unknown` y `any` implicitos en vistas customer.
- Errores objetivo: `TS18046`, `TS7006`, `TS2322`, `TS2345`
- Archivos foco:
  - `telemetric-front/src/features/customer/devices/views/DeviceCustomerModal.vue`
  - `telemetric-front/src/features/customer/devices/views/DeviceCustomerEditView.vue`
  - `telemetric-front/src/features/customer/tags/views/TagFormModal.vue`
  - `telemetric-front/src/features/customer/tags/views/TagListView.vue`
- Criterio de cierre:
  - Respuestas tipadas sin cast inseguros.
  - Callbacks sin parametros `any` implicitos.

### Fase 4 (P1/P2) - Core/UI y modulos aislados

#### BL-008
- Prioridad: P1
- Estado: TODO
- Objetivo: corregir tipado core UI e imports incompatibles.
- Errores objetivo: `TS1192`, `TS2532`, `TS2538`
- Archivos foco:
  - `telemetric-front/src/core/components/ui/table/AppDataTable.vue`
  - `telemetric-front/src/core/components/ui/notification/AppNotification.vue`
  - `telemetric-front/src/core/stores/notification.ts`
  - `telemetric-front/src/core/utils/validation.ts`
- Criterio de cierre:
  - Imports validos para dependencias actuales.
  - Sin indices/objetos potencialmente `undefined`.

#### BL-009
- Prioridad: P2
- Estado: TODO
- Objetivo: resolver errores puntuales en componentes fuera de features principales.
- Errores objetivo: `TS2322`, `TS18046`, `TS2305`
- Archivos foco:
  - `telemetric-front/src/components/apps/email/EmailListing.vue`
  - `telemetric-front/src/stratlabs-ui/components/domain/UiTagModal.vue`
  - `telemetric-front/src/stratlabs-ui/components/domain/UiOrganizationSelector.vue`
  - `telemetric-front/src/stores/modelStore.ts`
- Criterio de cierre:
  - No quedan errores de tipo puntuales en los archivos foco.

### Fase 5 (P2) - Codigo legacy de maps

#### BL-010
- Prioridad: P2
- Estado: TODO
- Objetivo: decidir y ejecutar estrategia para codigo `old` (excluir de build o reparar imports/rutas).
- Errores objetivo: `TS2307`, `TS2353`, `TS7006`
- Archivos foco:
  - `telemetric-front/src/features/maps/composables/plan/old/useDrawPolyline.ts`
  - `telemetric-front/src/features/maps/composables/plan/useToolRouter.ts`
  - `telemetric-front/src/features/maps/composables/plan/useDrawClickNodes.ts`
- Criterio de cierre:
  - Sin modulos inexistentes en compilacion.
  - Estrategia documentada (mantener/excluir/reparar).

## Criterio final de cierre
- [ ] `npm --prefix telemetric-front run typecheck` sin errores para alcance no-demo.
- [ ] `_demo` permanece fuera de alcance de este backlog.
- [ ] Evidencia de corrida final actualizada en `contexto/work/features/frontend_health/04_test/`.
