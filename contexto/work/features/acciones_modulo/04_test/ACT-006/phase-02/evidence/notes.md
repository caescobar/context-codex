# Notes - ACT-006 phase-02

- Pack regenerated on 2026-02-23.
- Default execution mode is DRY_RUN=1.
- Runtime closure rule applies if any service is started during QA execution.
- Teardown phase-02: no destructive actions were performed.
- If services were started during DRY_RUN=0, stop them and verify they are not running.
- Execution date: 2026-02-23.
- Setup/Run/Teardown executed with DRY_RUN=0.
- RuleTemplate discovery (sqlcmd): selected RuleTemplateId=4 (qa-phase02-reusable-20260220120658).
- Run script autodiscovery: RuleTemplateVersionId=6, TestDeviceIds=7,6,5.
- Auto-login to API failed at http://localhost:5220 (connection refused), but static/backend checks passed and run completed.
- Typecheck executed: exit_code=2, no_demo_ts_errors=118, BASELINE_TS_ERRORS not provided (numeric no-regression gate skipped as WARN).
- STILL_RUNNING: none (Telemetric.Api).
