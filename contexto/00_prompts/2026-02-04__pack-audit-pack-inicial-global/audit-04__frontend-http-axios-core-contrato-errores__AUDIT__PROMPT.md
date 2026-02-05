PackDir: contexto/00_prompts/2026-02-04__pack-audit-pack-inicial-global
ItemId: AUDIT-04
IndexRef: contexto/00_prompts/2026-02-04__pack-audit-pack-inicial-global/INDEX.md
PromptPath: contexto/00_prompts/2026-02-04__pack-audit-pack-inicial-global/audit-04__frontend-http-axios-core-contrato-errores__AUDIT__PROMPT.md

Modo: docs-only
Skills: telemetric-frontend-style

Objetivo
Auditar el estandar HTTP (AXIOS CORE unico) y el contrato de errores en frontend.

Alcance
- Buscar y confirmar paths reales de AXIOS CORE, wrappers HTTP y mapeos de errores.
- Identificar usos directos de axios fuera del core o contratos divergentes.
- Documentar inconsistencias y deuda tecnica.

Entregables
- Reporte en contexto/01_audits/YYYY-MM-DD__audit-04__frontend-http-axios-core-contrato-errores.md usando el template de auditoria real (buscar en contexto/01_overview/templates/ y confirmar path exacto; si existe TEMPLATE_AUDIT_REPORT usarlo, si no usar el template de auditoria disponible).
- Actualizar contexto/03_hallazgos/pending.md solo si hay hallazgos nuevos.

Guardrails
- Prohibido modificar codigo.
- No inventar paths: buscar y confirmar paths reales, citarlos en el reporte.
- Si algo no se encuentra: anotar "No encontrado".
- No pedir confirmacion.

No-go rules
- No ejecutar cambios de codigo ni refactors.

Post-step
- Marcar [x] AUDIT-04 en IndexRef.
- Completar o actualizar el link de Output en IndexRef.
