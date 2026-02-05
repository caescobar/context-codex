PackDir: contexto/00_prompts/2026-02-04__pack-audit-pack-inicial-global
ItemId: AUDIT-05
IndexRef: contexto/00_prompts/2026-02-04__pack-audit-pack-inicial-global/INDEX.md
PromptPath: contexto/00_prompts/2026-02-04__pack-audit-pack-inicial-global/audit-05__frontend-maps-structure-lifecycle-performance-leaks__AUDIT__PROMPT.md

Modo: docs-only
Skills: telemetric-frontend-style

Objetivo
Auditar la implementacion de Maps en frontend (estructura, lifecycle, performance, leaks).

Alcance
- Buscar y confirmar paths reales de componentes, servicios y wrappers de mapas.
- Revisar ciclo de vida, listeners, cleanup y potenciales leaks.
- Evaluar rendimiento (cargas, rerenders, heavy operations) con evidencia de ubicacion en codigo.

Entregables
- Reporte en contexto/01_audits/YYYY-MM-DD__audit-05__frontend-maps-structure-lifecycle-performance-leaks.md usando el template de auditoria real (buscar en contexto/01_overview/templates/ y confirmar path exacto; si existe TEMPLATE_AUDIT_REPORT usarlo, si no usar el template de auditoria disponible).
- Actualizar contexto/03_hallazgos/pending.md solo si hay hallazgos nuevos.

Guardrails
- Prohibido modificar codigo.
- No inventar paths: buscar y confirmar paths reales, citarlos en el reporte.
- Si algo no se encuentra: anotar "No encontrado".
- No pedir confirmacion.

No-go rules
- No ejecutar cambios de codigo ni refactors.

Post-step
- Marcar [x] AUDIT-05 en IndexRef.
- Completar o actualizar el link de Output en IndexRef.
