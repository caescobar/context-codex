# Notes - ACT-004 phase-04

- Pack generado inicialmente en modo docs-only y luego ejecutado en modo real.
- RULE_TEMPLATE_ID: se resolvio por SQL discovery para trazabilidad.
- Teardown phase-04: no se realizaron cambios destructivos.
- Regla de cierre: toda instancia levantada durante QA debe apagarse y verificarse como detenida.
- Ejecucion real completada el 2026-02-20 con `DRY_RUN=0` (setup/run/teardown PASS).
- SQL discovery ejecutado: `SELECT TOP 10 RuleTemplateId, Name FROM dbo.RuleTemplate WHERE IsDeleted=0 ORDER BY RuleTemplateId DESC;`
- RULE_TEMPLATE_ID seleccionado para trazabilidad: `4` (`qa-phase02-reusable-20260220120658`).
- Autodiscovery del script run: `TEST_RULE_TEMPLATE_VERSION_ID=6`, `TEST_DEVICE_ID=7`.
- API runtime temporal levantado para corrida integrada y detenido al cierre (`PID=28632`).
- Verificacion final: `STILL_RUNNING: none` para `Telemetric.Api`.
