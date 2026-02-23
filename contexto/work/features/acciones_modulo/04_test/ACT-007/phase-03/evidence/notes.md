# Notes - ACT-007 phase-03

- Pack generated in builder mode.
- Pending execution of `scripts/setup.*`, `scripts/run.*` and `scripts/teardown.*`.
- Runtime closure rule: any instance started during QA must be stopped and verified as not running.
- Teardown phase-03: no destructive actions were performed.
- If services were started during DRY_RUN=0, stop them and verify they are not running.
- Execution 2026-02-23:
- setup: OK (`DRY_RUN=0`)
- run: FAIL (`service_rules_patch_route=False` en `actions.service.ts`)
- teardown: OK (safe no-op)
- RuleTemplate SQL discovery: `SELECT TOP 10 RuleTemplateId, Name FROM dbo.RuleTemplate WHERE IsDeleted = 0 ORDER BY RuleTemplateId DESC;`
- RULE_TEMPLATE_ID selected: `4` (`qa-phase02-reusable-20260220120658`)
- API runtime started by executor: PID root `6624`
- API/runtime stopped by executor: `STOPPED_PIDS=6624,10540,11048,19748,19888,20324`
- STILL_RUNNING: none
- Teardown phase-03: no destructive actions were performed.
- If services were started during DRY_RUN=0, stop them and verify they are not running.
