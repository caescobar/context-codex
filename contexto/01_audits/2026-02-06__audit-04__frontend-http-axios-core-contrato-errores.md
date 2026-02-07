# AUDIT REPORT - audit-04__frontend-http-axios-core-contrato-errores

## 0) Metadata
- Fecha: 2026-02-06
- Modo: docs-only (audit-exec, sin cambios de codigo)
- Skills aplicadas: telemetric-frontend-style
- Objetivo: Auditar el estandar HTTP (AXIOS CORE unico) y el contrato de errores en frontend.
- Repos/servicios: telemetric-front
- Autor: Codex (asistido)

## 0.1 Trazabilidad del pack
- PackDir: contexto/00_prompts/2026-02-04__pack-audit-pack-inicial-global
- AuditId: AUDIT-04
- IndexRef: contexto/00_prompts/2026-02-04__pack-audit-pack-inicial-global/INDEX.md
- PromptSource: contexto/00_prompts/2026-02-04__pack-audit-pack-inicial-global/audit-04__frontend-http-axios-core-contrato-errores__AUDIT__PROMPT.md

## 1) Executive Summary (max 5 bullets)
- Se detectaron multiples caminos HTTP (axios en `src/utils/axios.ts`, axios alterno en `src/core/utils/axios.ts`, `fetchWrapper` y `fetch` directo), con contratos de error divergentes.
- La instancia con baseURL y auth en `src/core/utils/axios.ts` no tiene usos detectados; el resto importa `@/utils/axios`.
- `fetchWrapper` y `fetch` directo se usan en servicios principales (auth, organization, admin, telemetry), lo que rompe el estandar de AXIOS CORE unico.
- El contrato de errores no es uniforme: axios rechaza con `error.response.data` o string, `fetchWrapper` emite eventos/redirect, y `telemetry.service` retorna `[]` en error.

## 2) Alcance (Scope)
### 2.1 Paths/archivos analizados
- telemetric-front/src/utils/axios.ts
- telemetric-front/src/core/utils/axios.ts
- telemetric-front/src/core/index.ts
- telemetric-front/src/utils/helpers/fetch-wrapper.ts
- telemetric-front/src/features/auth/auth.service.ts
- telemetric-front/src/services/organization.service.ts
- telemetric-front/src/features/telemetry/telemetry.service.ts
- telemetric-front/src/stores/apps/blog.ts

### 2.2 Fuera de alcance
- Otros repos/plantillas (template-project, guia-Programador) y backend.
- Cambios de codigo o refactors.

## 3) Contrato actual observado (Fuente: codigo)
> Tabla obligatoria. No asumir. Si algo no se encontro, escribir "No encontrado".

| Capa | Identidad externa (serial/id) | Key/Routing/Group | Campos/Shape | Evidencia (paths) |
|---|---|---|---|---|
| SQL | No encontrado | No encontrado | No encontrado | No encontrado |
| Redis config | No encontrado | No encontrado | No encontrado | No encontrado |
| Redis last-value | No encontrado | No encontrado | No encontrado | No encontrado |
| Rabbit raw | No encontrado | No encontrado | No encontrado | No encontrado |
| Rabbit normalized | No encontrado | No encontrado | No encontrado | No encontrado |
| SignalR | No encontrado | No encontrado | No encontrado | No encontrado |
| Payload | No encontrado | No encontrado | No encontrado | No encontrado |

## 4) Nombres canonicos encontrados (no inventar)
- Redis: No encontrado
- Rabbit: No encontrado
- SignalR: No encontrado
**Evidencia:** No encontrado (scope frontend HTTP)

## 5) Hallazgos (con evidencia)
> Cada hallazgo debe tener: severidad, impacto, evidencia, repro si aplica, recomendacion.

### Medium
- **HALL-20260206-001 - Multiples clientes HTTP y contratos de error divergentes**
  - Impacto: comportamiento inconsistente en manejo de errores/autorizacion (logout, redirects, mensajes, retries), riesgo de UX desigual y hardening parcial.
  - Evidencia (paths): `telemetric-front/src/utils/axios.ts`, `telemetric-front/src/core/utils/axios.ts`, `telemetric-front/src/utils/helpers/fetch-wrapper.ts`, `telemetric-front/src/features/telemetry/telemetry.service.ts`
  - Repro (si aplica): provocar 401/403/500 en endpoints usados por `auth.service`, `organization.service` y `telemetry.service` y comparar respuesta (redirect/eventos/string/[]).
  - Recomendacion: consolidar en un solo AXIOS CORE, centralizar interceptors y unificar contrato de error.

### Medium
- **HALL-20260206-002 - Uso de fetchWrapper/fetch directo en capas de servicio**
  - Impacto: rompe el estandar (AXIOS CORE unico), dificulta observabilidad y manejo consistente de auth/error.
  - Evidencia (paths): `telemetric-front/src/utils/helpers/fetch-wrapper.ts`, `telemetric-front/src/features/auth/auth.service.ts`, `telemetric-front/src/services/organization.service.ts`, `telemetric-front/src/features/telemetry/telemetry.service.ts`
  - Repro (si aplica): revisar imports y llamadas a `fetchWrapper`/`fetch` en los paths anteriores.
  - Recomendacion: migrar servicios a axios core y eliminar el wrapper basado en `fetch`.

### Low
- **HALL-20260206-003 - Duplicidad de instancia axios y export inconsistente**
  - Impacto: existe una instancia con baseURL/auth (`src/core/utils/axios.ts`) sin uso detectado, mientras la usada (`src/utils/axios.ts`) no define baseURL ni auth.
  - Evidencia (paths): `telemetric-front/src/core/utils/axios.ts`, `telemetric-front/src/core/index.ts`, `telemetric-front/src/utils/axios.ts`, `telemetric-front/src/stores/apps/blog.ts`
  - Repro (si aplica): buscar imports de `@/utils/axios` vs `@/core/...` en el frontend.
  - Recomendacion: definir una sola instancia canonica y alinear imports.

## 6) Riesgos de romper contratos
- Riesgo: al unificar cliente HTTP, cambios en shape de errores o en auth headers pueden impactar flows (logout, redirect, notificaciones).
- Mitigacion: mantener adapter temporal con mapeo de errores y pruebas de smoke en login, listados y telemetry history.

## 7) Recomendacion priorizada
1) Definir el AXIOS CORE canonico (path unico) con interceptors y contrato de error unificado.
2) Migrar servicios que usan `fetchWrapper`/`fetch` al AXIOS CORE.
3) Deprecar/eliminar la instancia duplicada y ajustar imports.

## 8) Plan sugerido por fases (sin ejecutar)
> Max 5 archivos por fase. No cambiar contratos sin migracion.

### Fase 1
- Objetivo: Definir cliente canonico y contrato de error.
- Archivos potenciales (max 5): `telemetric-front/src/core/utils/axios.ts`, `telemetric-front/src/utils/axios.ts`, `telemetric-front/src/core/index.ts`, `telemetric-front/src/utils/helpers/fetch-wrapper.ts`, `telemetric-front/src/features/auth/auth.service.ts`
- Verificacion: smoke de login, refresh y permisos.

### Fase 2
- Objetivo: Migrar servicios principales y telemetry history a axios core.
- Archivos potenciales (max 5): `telemetric-front/src/services/organization.service.ts`, `telemetric-front/src/features/telemetry/telemetry.service.ts`, `telemetric-front/src/features/admin/devices/device.service.ts`, `telemetric-front/src/features/admin/security/security.service.ts`, `telemetric-front/src/features/admin/units/unit.service.ts`
- Verificacion: listados principales, errores 401/403 y respuesta 500.

### Fase 3
- Objetivo: Migrar stores demo y limpiar imports residuales.
- Archivos potenciales (max 5): `telemetric-front/src/stores/apps/blog.ts`, `telemetric-front/src/stores/apps/chat.ts`, `telemetric-front/src/stores/apps/email.ts`, `telemetric-front/src/stores/apps/invoice/index.ts`, `telemetric-front/src/stores/apps/notes.ts`
- Verificacion: pantallas demo y notificaciones de error.

## 9) Como verificar (smoke test)
1) Login y refresh de token; verificar que el header Authorization se envia y no hay redirects inesperados.
2) Listar organizations y crear/editar para validar manejo de errores 401/403/500.
3) Ejecutar telemetry history; verificar que fallas retornan error consistente y no silencian excepciones.

## 10) Pendientes registrados
- Anadir/actualizar en `contexto/03_hallazgos/pending.md`: HALL-20260206-001, HALL-20260206-002, HALL-20260206-003
