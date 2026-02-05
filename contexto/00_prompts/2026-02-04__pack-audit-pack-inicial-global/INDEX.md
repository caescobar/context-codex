# Pack: audit-pack-inicial-global (2026-02-04)

## Estado
- [x] Pack iniciado
- [ ] P0 completado
- [ ] Plan de fases definido
- [ ] Fases ejecutadas
- [ ] Cierre (resumen + pendientes)

## Items
> Cada item debe tener: checkbox, id, titulo, links (Prompt y Output).

### P0
- [x] AUDIT-01 Backend: Contrato de Identidad y Telemetria (serial vs SQL id)
  - Prompt: ./audit-01__identidad-telemetria-serial-vs-sql-id__AUDIT__PROMPT.md
  - Output: ../../01_audits/2026-02-04__audit-01__identidad-telemetria-serial-vs-sql-id.md
- [x] AUDIT-02 Backend: Unificacion DI/Configuracion de Connectors (API + KISS/Workers)
  - Prompt: ./audit-02__unificacion-di-config-connectors-api-kiss-workers__AUDIT__PROMPT.md
  - Output: ../../01_audits/2026-02-05__audit-02__unificacion-di-config-connectors-api-kiss-workers.md
- [x] AUDIT-03 Backend: Hardening minimo (CORS/JWT/EF auditoria/Authorization duplicada)
  - Prompt: ./audit-03__hardening-minimo-cors-jwt-ef-authorization-duplicada__AUDIT__PROMPT.md
  - Output: ../../01_audits/2026-02-05__audit-03__hardening-minimo-cors-jwt-ef-authorization-duplicada.md
- [ ] AUDIT-04 Frontend: Estandar HTTP (AXIOS CORE unico) + contrato de errores
  - Prompt: ./audit-04__frontend-http-axios-core-contrato-errores__AUDIT__PROMPT.md
  - Output: ../../01_audits/2026-02-04__audit-04__frontend-http-axios-core-contrato-errores.md
- [ ] AUDIT-05 Frontend: Maps (estructura, lifecycle, performance, leaks)
  - Prompt: ./audit-05__frontend-maps-structure-lifecycle-performance-leaks__AUDIT__PROMPT.md
  - Output: ../../01_audits/2026-02-04__audit-05__frontend-maps-structure-lifecycle-performance-leaks.md
- [ ] AUDIT-06 Cleanup global (inventario, sin borrar)
  - Prompt: ./audit-06__cleanup-global-inventario-sin-borrar__AUDIT__PROMPT.md
  - Output: ../../01_audits/2026-02-04__audit-06__cleanup-global-inventario-sin-borrar.md

### Phases
- [x] PHASE-01 Validar invariantes de ID (platform_id obligatorio para persistencia)
  - Prompt: ./phases/phase-01__validar-invariantes-id-platform-id__PHASE__PROMPT.md
  - Output (plan): ../../02_changes/2026-02-04__phase-01__validar-invariantes-id-platform-id__plan.md
  - Output (summary): ../../02_changes/2026-02-04__phase-01__validar-invariantes-id-platform-id__summary.md
- [x] PHASE-01 Unificar configuracion de connectors en API (Redis/Rabbit/ClickHouse)
  - Prompt: ./phases/phase-01__unificar-config-connectors-api__PHASE__PROMPT.md
  - Output (plan): ../../02_changes/2026-02-05__phase-01__unificar-config-connectors-api__plan.md
  - Output (summary): ../../02_changes/2026-02-05__phase-01__unificar-config-connectors-api__summary.md
- [x] PHASE-01 Quitar AllowAnonymous en Organizations
  - Prompt: ./phases/phase-01__quitar-allowanonymous-organizations__PHASE__PROMPT.md
  - Output (plan): ../../02_changes/2026-02-05__phase-01__quitar-allowanonymous-organizations__plan.md
  - Output (summary): ../../02_changes/2026-02-05__phase-01__quitar-allowanonymous-organizations__summary.md
- [x] PHASE-02 Mover KISS/Workers a IConfiguration/appsettings
  - Prompt: ./phases/phase-02__mover-kiss-workers-a-iconfiguration-appsettings__PHASE__PROMPT.md
  - Output (plan): ../../02_changes/2026-02-05__phase-02__mover-kiss-workers-a-iconfiguration-appsettings__plan.md
  - Output (summary): ../../02_changes/2026-02-05__phase-02__mover-kiss-workers-a-iconfiguration-appsettings__summary.md
- [ ] PHASE-02 Quitar AllowAnonymous en OrganizationNodes y Telemetry/History
  - Prompt: ./phases/phase-02__quitar-allowanonymous-organizationnodes-telemetry-history__PHASE__PROMPT.md
  - Output (plan): ../../02_changes/2026-02-05__phase-02__quitar-allowanonymous-organizationnodes-telemetry-history__plan.md
  - Output (summary): ../../02_changes/2026-02-05__phase-02__quitar-allowanonymous-organizationnodes-telemetry-history__summary.md
- [x] PHASE-03 Consolidar esquema unico de Options (conectores)
  - Prompt: ./phases/phase-03__consolidar-esquema-options__PHASE__PROMPT.md
  - Output (plan): ../../02_changes/2026-02-05__phase-03__consolidar-esquema-options__plan.md
  - Output (summary): ../../02_changes/2026-02-05__phase-03__consolidar-esquema-options__summary.md
- [x] PHASE-03 Documentar contrato canonico identidad/telemetria
  - Prompt: ./phases/phase-03__documentar-contrato-canonico-identidad-telemetria__PHASE__PROMPT.md
  - Output: ../../01_overview/README.md

### QA
- [x] AUDIT-07 QA Pack: Validar PHASE-01 (no DeviceId=0, platform_id obligatorio)
  - Prompt: ./audits/audit-07__qa-pack-validar-invariantes-id-platform-id__AUDIT__PROMPT.md
  - Output: ../../05_qa/2026-02-05__audit-07__qa-pack-validar-invariantes-id-platform-id__qa.md

## Pendientes
- pending.md: ../../03_hallazgos/pending.md

