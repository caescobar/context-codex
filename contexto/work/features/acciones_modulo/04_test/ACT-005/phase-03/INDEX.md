# INDEX - ACT-005 phase-03 QA Pack

- [x] setup definido (`scripts/setup.ps1`, `scripts/setup.sh`)
- [x] run definido (`scripts/run.ps1`, `scripts/run.sh`)
- [x] teardown definido (`scripts/teardown.ps1`, `scripts/teardown.sh`)
- [x] checklist reproducible (`CHECKLIST.md`)
- [x] evidencia inicial creada (`evidence/commands.log`, `evidence/outputs.log`, `evidence/notes.md`)
- [x] baseline no-regresion definido (`baseline.json`)

Estado actual de corrida (2026-02-20):
- setup: ejecutado (`DRY_RUN=0`)
- run: ejecutado (`gate_no_regresion=PASS`, `observed_no_demo_ts_errors=118`, baseline `240`)
- teardown: ejecutado (`safe no-op`)
- still_running: none (no instancia `Telemetric.Api.csproj` detectada en `dotnet.exe`)
- estado global: CERRADO/PASS (`API_BOOT_FOR_QA_CLOSE=True`, `auto_login_token=OK`, `STILL_RUNNING: none`)
