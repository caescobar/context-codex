PackDir: contexto/00_prompts/2026-02-04__pack-audit-pack-inicial-global
ItemId: AUDIT-02
IndexRef: contexto/00_prompts/2026-02-04__pack-audit-pack-inicial-global/INDEX.md
PromptPath: contexto/00_prompts/2026-02-04__pack-audit-pack-inicial-global/audit-02__unificacion-di-config-connectors-api-kiss-workers__AUDIT__PROMPT.md

Modo: docs-only
Skills: telemetric-backend-style, telemetric-connectors-standard

Objetivo
Auditar la unificacion de DI/configuracion de connectors entre API y KISS/Workers para detectar duplicidades, divergencias y riesgos de drift.

Alcance
- Buscar y confirmar paths reales de configuraciones DI, settings y factories de connectors.
- Comparar setups entre API y KISS/Workers (Redis, Rabbit, ClickHouse u otros conectores).
- Identificar puntos de configuracion duplicada o no estandarizada.

Entregables
- Reporte en contexto/01_audits/YYYY-MM-DD__audit-02__unificacion-di-config-connectors-api-kiss-workers.md usando el template de auditoria real (buscar en contexto/01_overview/templates/ y confirmar path exacto; si existe TEMPLATE_AUDIT_REPORT usarlo, si no usar el template de auditoria disponible).
- Actualizar contexto/03_hallazgos/pending.md solo si hay hallazgos nuevos.

Guardrails
- Prohibido modificar codigo.
- No inventar paths: buscar y confirmar paths reales, citarlos en el reporte.
- Si algo no se encuentra: anotar "No encontrado".
- No pedir confirmacion.

No-go rules
- No ejecutar cambios de codigo ni refactors.

Post-step
- Marcar [x] AUDIT-02 en IndexRef.
- Completar o actualizar el link de Output en IndexRef.
