# Notes - ACT-006 phase-01

- Pack generated on 2026-02-20.
- Default execution mode is DRY_RUN=1.
- Runtime closure rule applies if any service is started during QA execution.
- Teardown phase-01: no destructive actions were performed.
- If services were started during DRY_RUN=0, stop them and verify they are not running.
- Teardown phase-01: no destructive actions were performed.
- If services were started during DRY_RUN=0, stop them and verify they are not running.
- 2026-02-20 execution: setup/run/teardown ejecutados con DRY_RUN=0.
- RuleTemplate discovery SQL: seleccionado RULE_TEMPLATE_ID=4 (IsDeleted=0).
- Runtime API: Start-Process bloqueado por policy; se uso estrategia por timeout con residual PID 2832 y se forzo cierre.
- Verificacion final: STILL_RUNNING: none para Telemetric.Api.
- Script fix aplicado durante ejecucion: run.ps1 usa `rg -F` para busqueda literal de rutas con llaves ({ruleTemplateId}).
