---
name: telemetric-frontend-style
description: Estándar frontend Telemetric (Vue 3 + features + AXIOS CORE único + tipos).
---

DECISIÓN DE PROYECTO (NO NEGOCIABLE)
- El cliente HTTP estándar es AXIOS CORE.
- Prohibido usar fetch() directo.
- Prohibido usar fetchWrapper.
- Prohibido importar axios directamente desde features.
- Prohibido crear axios instances fuera del core.

REGLAS DURAS DE IMPLEMENTACIÓN
1) Toda llamada HTTP debe pasar por el core:
   - Importar SIEMPRE desde: core/http/httpClient (o el path real del proyecto).
2) Todo service debe ser tipado:
   - No usar payload:any en features nuevos.
   - Definir Request/Response types en *.types.ts dentro del feature.
   - En vistas con `UiServerTable`, garantizar contrato paginado compatible con `PagedList` (sin shapes ad-hoc).
3) No inventar patrones:
   - Antes de implementar, buscar 2 ejemplos similares y citar paths.
   - En TODAS las listas, mantener paridad canónica: `BaseBreadcrumb` + `UiDynamicFilter` + `UiCard` + `UiServerTable`.
   - En acciones por fila, usar iconos con tooltip (sin botones de texto en celdas de acciones).
4) No reestructurar:
   - Prohibido mover carpetas/renames masivos sin orden explícita.
5) Manejo de errores unificado:
   - Los services no deben “inventar” shapes de error.
   - Usar el error-mapping estándar del core.
6) Contratos list/paged:
   - Si backend retorna payload legado (`items`, `pageNumber`, `totalPages`, `totalCount`), mapear en frontend a `PagedList<T>` antes de bindear a `UiServerTable`.
   - Prohibido reemplazar `UiServerTable` por `v-table` + paginación manual para evitar contratos.
7) Preferencia de interacción:
   - Editar/crear debe usar modal por defecto en flujos de gestión.
   - Si se usa navegación a detalle en lugar de modal, debe estar explícito en el spec/story.
8) Canon visual de modales (obligatorio):
   - Referencia principal: `telemetric-front/src/features/customer/devices/views/DeviceCustomerModal.vue`.
   - Referencia de footer/acciones: `telemetric-front/src/features/admin/devices/views/DeviceForm.vue`.
   - Todo modal de create/edit/detail debe respetar:
     - Header con jerarquía clara y acción de cierre.
     - Cuerpo por secciones (no formulario plano pegado).
     - Espaciado consistente (`pa-*`, bloques visuales, separación entre grupos).
     - Footer estándar: `Cancelar` (text/neutral) + `Guardar` (primary flat + `mdi-content-save`).
   - Prohibido introducir un layout de modal alterno sin decisión explícita.

PROTOCOLO OBLIGATORIO (ANTES DE CODEAR)
1) Encontrar 2 services similares existentes y citar paths.
2) Confirmar el path del axios core (core/http/...) y citarlo.
3) Definir types (Request/Response).
4) Implementar service con axios core.
5) En componentes/composables:
   - cleanup obligatorio (abort/cancel si aplica; remove listeners/subs).
6) Resumen:
   - archivos tocados
   - cómo probar (pasos manuales)
7) Si hay modal en alcance:
   - citar qué archivo canon se usó como referencia visual;
   - validar header/body/footer contra el canon.

ANTI-DESVÍO
- Si aparece deuda técnica no pedida, NO desviarse.
- Registrar en “Hallazgos” y seguir el objetivo.
