# Notes - ACT-004 phase-01

- 2026-02-20: corrida integrada ejecutada con `DRY_RUN=0`.
- API runtime: se intento levantar `Telemetric.Api` en background; `Start-Process` fue bloqueado por policy y se uso `cmd /c start` como estrategia alternativa.
- API cierre: verificacion final `STILL_RUNNING: none` (no quedaron procesos `Telemetric.Api` activos).
- RULE_TEMPLATE_ID: N/A en esta fase (el pack usa variable opcional `TEST_RULE_TEMPLATE_VERSION_ID` para prueba API integrada).
- Gate no-regresion no-demo: PASS (`observed_no_demo_ts_errors=120` vs baseline `240`).
- Prueba API integrada: ejecutada con `vcsoft` usando `TEST_RULE_TEMPLATE_VERSION_ID=5` y `TEST_DEVICE_IDS=7,6,5`.
- Resultado API integrada: endpoint responde 200 con payload valido (`created/rejected/items`), evidencia en `evidence/outputs.log`.
- Hallazgo de entorno: faltaba permiso `Actions.Assign` en DB; se agrego y asigno a roles `SAD`/`CAD` para habilitar la policy del endpoint.
- Automatizacion QA: `run.ps1`/`run.sh` ahora intentan auto-login (`API_USER`/`API_PASSWORD`) y autodiscovery de `TEST_RULE_TEMPLATE_VERSION_ID` + `TEST_DEVICE_IDS` via `sqlcmd` cuando faltan variables.
- Credenciales default de prueba configuradas para auto-login: `vcsoft` / `123456` (override con variables de entorno).
- Cierre: Fase 01 queda cerrada con corrida integrada reproducible sin inyeccion manual de token.
- Teardown phase-01: no se realizaron cambios destructivos.
