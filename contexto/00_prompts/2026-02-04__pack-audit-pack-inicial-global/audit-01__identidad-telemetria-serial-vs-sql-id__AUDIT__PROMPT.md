PackDir: contexto/00_prompts/2026-02-04__pack-audit-pack-inicial-global
ItemId: AUDIT-01
IndexRef: contexto/00_prompts/2026-02-04__pack-audit-pack-inicial-global/INDEX.md
PromptPath: contexto/00_prompts/2026-02-04__pack-audit-pack-inicial-global/audit-01__identidad-telemetria-serial-vs-sql-id__AUDIT__PROMPT.md

Modo: docs-only
Skills: telemetric-backend-style

Objetivo
Auditar el contrato de identidad y telemetria (serial vs SQL id) y documentar desviaciones o riesgos entre backend y fuentes de verdad.

Alcance
- Buscar y confirmar paths reales de entidades, modelos, migraciones y configuraciones relacionadas con identidad y telemetria.
- Revisar uso de identificadores serial vs SQL id en dominio, persistencia y eventos.
- Identificar puntos de inconsistencia, mapeos duplicados o conversiones peligrosas.

Entregables
- Reporte en contexto/01_audits/YYYY-MM-DD__audit-01__identidad-telemetria-serial-vs-sql-id.md usando el template de auditoria real (buscar en contexto/01_overview/templates/ y confirmar path exacto; si existe TEMPLATE_AUDIT_REPORT usarlo, si no usar el template de auditoria disponible).
- Actualizar contexto/03_hallazgos/pending.md solo si hay hallazgos nuevos.

Guardrails
- Prohibido modificar codigo.
- No inventar paths: buscar y confirmar paths reales, citarlos en el reporte.
- Si algo no se encuentra: anotar "No encontrado".
- No pedir confirmacion.

No-go rules
- No ejecutar cambios de codigo ni refactors.

Post-step
- Marcar [x] AUDIT-01 en IndexRef.
- Completar o actualizar el link de Output en IndexRef.
