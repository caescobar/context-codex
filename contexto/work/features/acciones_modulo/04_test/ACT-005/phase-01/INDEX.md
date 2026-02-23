# INDEX - ACT-005 phase-01 QA Pack

- [x] setup definido (`scripts/setup.ps1`, `scripts/setup.sh`)
- [x] run definido (`scripts/run.ps1`, `scripts/run.sh`)
- [x] teardown definido (`scripts/teardown.ps1`, `scripts/teardown.sh`)
- [x] checklist reproducible (`CHECKLIST.md`)
- [x] evidencia inicial creada (`evidence/commands.log`, `evidence/outputs.log`, `evidence/notes.md`)
- [x] ejecucion integrada completada (`DRY_RUN=0`)
- [x] evidencias reales adjuntadas y cierre de fase

Estado actual de corrida (2026-02-20):
- setup: OK (`DRY_RUN=0`)
- run: OK (`DRY_RUN=0`, `RULE_TEMPLATE_ID=4`, `TEST_RULE_TEMPLATE_VERSION_ID=6`)
- teardown: OK (`DRY_RUN=0`)
- still_running: none
- gate no-regresion: PASS (`observed_no_demo_ts_errors=118`, baseline `240`, scope `no-demo`)
