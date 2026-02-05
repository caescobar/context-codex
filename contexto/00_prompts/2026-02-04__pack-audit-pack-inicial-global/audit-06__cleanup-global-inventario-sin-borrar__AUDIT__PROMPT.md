PackDir: contexto/00_prompts/2026-02-04__pack-audit-pack-inicial-global
ItemId: AUDIT-06
IndexRef: contexto/00_prompts/2026-02-04__pack-audit-pack-inicial-global/INDEX.md
PromptPath: contexto/00_prompts/2026-02-04__pack-audit-pack-inicial-global/audit-06__cleanup-global-inventario-sin-borrar__AUDIT__PROMPT.md

Modo: docs-only
Skills: dead-code-cleanup

Objetivo
Inventariar codigo y assets candidatos a cleanup global, sin borrar ni refactorizar.

Alcance
- Buscar y confirmar paths reales de modulos, archivos, flags o carpetas aparentemente obsoletas.
- Identificar duplicaciones y componentes no referenciados (sin borrar).
- Documentar riesgo de borrado y evidencia de no uso.

Entregables
- Reporte en contexto/01_audits/YYYY-MM-DD__audit-06__cleanup-global-inventario-sin-borrar.md usando el template de auditoria real (buscar en contexto/01_overview/templates/ y confirmar path exacto; si existe TEMPLATE_AUDIT_REPORT usarlo, si no usar el template de auditoria disponible).
- Actualizar contexto/03_hallazgos/pending.md solo si hay hallazgos nuevos.

Guardrails
- Prohibido modificar codigo.
- No inventar paths: buscar y confirmar paths reales, citarlos en el reporte.
- Si algo no se encuentra: anotar "No encontrado".
- No pedir confirmacion.

No-go rules
- No ejecutar cambios de codigo ni refactors.

Post-step
- Marcar [x] AUDIT-06 en IndexRef.
- Completar o actualizar el link de Output en IndexRef.
