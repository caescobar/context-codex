# INDEX - ACT-005 phase-02 QA Pack

- [x] setup definido (`scripts/setup.ps1`, `scripts/setup.sh`)
- [x] run definido (`scripts/run.ps1`, `scripts/run.sh`)
- [x] teardown definido (`scripts/teardown.ps1`, `scripts/teardown.sh`)
- [x] checklist reproducible (`CHECKLIST.md`)
- [x] evidencia inicial creada (`evidence/commands.log`, `evidence/outputs.log`, `evidence/notes.md`)
- [x] ejecucion integrada completada (`DRY_RUN=0`)
- [x] evidencias reales adjuntadas y cierre de fase

Estado actual de corrida (2026-02-20):
- setup: OK (`DRY_RUN=0`)
- run: OK (`DRY_RUN=0`)
- teardown: OK (`DRY_RUN=0`)
- still_running: none
- rule_template_id: 4 (`dbo.RuleTemplate`, `IsDeleted=0`)
- auto_rule_template_version_id: 6
- auto_test_device_ids: 7,6,5
- gate no-regresion: PASS (`observed_no_demo_ts_errors=118 <= baseline=240`)
