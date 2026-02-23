# Notes - ACT-007 phase-02

- Pack generated in builder mode.
- Pending execution of `scripts/setup.*`, `scripts/run.*` and `scripts/teardown.*`.
- Runtime closure rule: any instance started during QA must be stopped and verified as not running.
- Teardown phase-02: no destructive actions were performed.
- If services were started during DRY_RUN=0, stop them and verify they are not running.
- Teardown phase-02: no destructive actions were performed.
- If services were started during DRY_RUN=0, stop them and verify they are not running.
- Teardown phase-02: no destructive actions were performed.
- If services were started during DRY_RUN=0, stop them and verify they are not running.
- 2026-02-23 execution: setup/run/teardown executed with DRY_RUN=0.
- RULE_TEMPLATE_ID selected from SQL: 4 (`SELECT TOP 10 RuleTemplateId, Name FROM dbo.RuleTemplate WHERE IsDeleted = 0 ORDER BY RuleTemplateId DESC;`).
- API runtime strategy: blocked by environment policy for background process launch (`Start-Process` and `cmd start` rejected).
- Auto-login during run: FAIL (`Unable to connect to the remote server`) because API runtime was not available.
- Final process check: STILL_RUNNING for Telemetric.Api = none.
- QA closure status for phase-02: PARCIAL/BLOQUEADO (pending integrated HTTP run with API up).
