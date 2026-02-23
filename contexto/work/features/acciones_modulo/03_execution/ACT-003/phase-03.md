# FASE 03 - ACT-003

## Estado
DONE

## Standards Lock Check
- Backend: ADOPTED (ref: audit A0)
- SQLServer: ADOPTED (ref: audit A0)

## Files touched (max 5)
- telemetric-front/src/features/actions/actions.routes.ts
- telemetric-front/src/features/actions/actions.service.ts
- telemetric-front/src/features/actions/types.ts
- telemetric-front/src/features/actions/views/ActionsTemplatesView.vue
- telemetric-front/src/features/actions/views/ActionTemplateDetailView.vue

## Changes summary
- Se creo la feature frontend `actions` con rutas dedicadas para `/actions` y `/actions/templates/:id` en `actions.routes.ts`, con `requiresAuth` y `requiresPermission: 'Actions.View'`.
- Se implemento `actions.service.ts` usando exclusivamente el cliente core `@/core/utils/axios`, con manejo de errores unificado (`toApiError`) y metodos para list/detail/create/update sobre `/actions/templates`.
- Se definieron contratos tipados en ingles en `types.ts` para listado paginado, detalle de template, versiones y payloads de create/update.
- Se implemento `ActionsTemplatesView.vue` con labels en espanol, busqueda, tabla de templates y navegacion a detalle.
- Se implemento `ActionTemplateDetailView.vue` con tabs de datos (`Definicion`, `Versiones`, `Asignaciones`, `Ejecuciones`), carga de detalle y accion para guardar nueva version via endpoint de update.

## Verification checklist
- Verificacion de rutas de modulo en feature:
  - Revisar `telemetric-front/src/features/actions/actions.routes.ts` para confirmar `path: '/actions'` y `path: '/actions/templates/:id'`.
- Verificacion de cliente HTTP core:
  - Revisar `telemetric-front/src/features/actions/actions.service.ts` y confirmar import `@/core/utils/axios`.
- Verificacion de contratos internos en ingles:
  - Revisar `telemetric-front/src/features/actions/types.ts` (`RuleTemplateListItem`, `RuleTemplateDetail`, `UpdateTemplateRequest`, etc.).
- Verificacion de labels UI en espanol:
  - Revisar `telemetric-front/src/features/actions/views/ActionsTemplatesView.vue` y `telemetric-front/src/features/actions/views/ActionTemplateDetailView.vue`.
- Verificacion tecnica de typecheck global:
  - Comando ejecutado: `npm run typecheck` en `telemetric-front/`.
  - Resultado: FALLA por errores preexistentes en multiples modulos ajenos (`_demo`, `maps`, `admin`, `customer`, etc.); sin bloqueo especifico detectado de la feature `actions` en la salida compartida.

## Notes / Risks
- La fase 03 implementa la feature y sus rutas en `actions.routes.ts`, pero el registro en el router global existente (`src/router/*.ts`) no se incluyo en esta corrida para mantener el alcance estricto de 5 archivos de implementacion definidos por plan.
- Para navegacion efectiva desde el router principal, se requiere una fase posterior que incorpore `actionRoutes` en el arbol de rutas activo.
- Se detecto deuda TS no-demo global del frontend; ver backlog canonico `contexto/work/backlogs/front-typecheck/FRONT-TYPECHECK_v1.md` (no bloquea esta story salvo impacto en archivos tocados).

---
