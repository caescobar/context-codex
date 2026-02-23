---
name: telemetric-frontend-admin-parity
description: Checklist operativo para asegurar paridad visual/estructural contra `features/admin/devices` al implementar o refactorizar pantallas Vue 3 en `telemetric-front/src/features/**`. Usar como gate de UX (breadcrumb + filtros + tabla + acciones + permisos + menu + encoding) y como complemento del standard principal.
---

# Telemetric Frontend Admin Parity — Gate Checklist

## Canon references (must inspect)
- `telemetric-front/src/features/admin/devices/views/DeviceListView.vue`
- `telemetric-front/src/features/admin/devices/device.routes.ts`
- `telemetric-front/src/layouts/menuItems.ts`
- `telemetric-front/src/layouts/Sidebar.vue`

## Visual parity checklist (MANDATORY)
1) `BaseBreadcrumb` con titulo y breadcrumbs consistentes.
2) Bloque de filtros con `UiDynamicFilter`:
   - schema claro
   - `@search` y `@reset` conectados a fetch
3) Bloque de listado con `UiCard` + `UiServerTable`.
4) Headers coherentes (`title`, `key`, `align`) y slots para celdas especiales.
5) Chips/estados y acciones con iconos/spacing igual al canon.
6) Estados UX visibles:
   - loading / empty / error / success
7) Copy en español (sin labels mezcladas).

## Route + menu parity checklist (MANDATORY)
1) Ruta en `*.routes.ts` con:
   - `meta.requiresAuth: true`
   - `meta.requiresPermission: '<Module>.<Action>'`
2) Menu item en `layouts/menuItems.ts` con el MISMO permission string.
3) Sidebar filtra por permiso; si no aparece:
   - verificar claims/permisos del usuario primero
   - luego revisar meta/menu parity

## Technical parity checklist (MANDATORY)
1) Servicio usa cliente HTTP central del proyecto (no `fetch`).
2) Tipos en `types.ts` (inglés), UI copy en español.
3) No se introducen `any/unknown` nuevos.
4) Contrato de lista/paginación compatible con el canon (`admin/devices`).
5) Encoding:
   - si hay mojibake, corregir y guardar en UTF-8
6) Typecheck gate:
   - no subir el conteo de errores TS (sin `_demo`)

## Exit criteria
- Vista comparable a `admin/devices` en estructura general (header/filters/table/actions).
- Ruta + menu alineados por permiso.
- Sin caracteres corruptos.
- Typecheck no-demo no empeora.
