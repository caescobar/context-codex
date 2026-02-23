# Notes - ACT-005 phase-01

- Pack generado en modo docs-only.
- Scripts usan `DRY_RUN=1` por defecto.
- En `DRY_RUN=0`, `run` aplica gate no-regresion y registra auto-login/autodiscovery.
- Teardown phase-01: no se realizaron cambios destructivos.
- Cierre runtime pendiente de confirmar manualmente si se levantaron servicios en DRY_RUN=0.
- 2026-02-20 (execution DRY_RUN=0): setup/run/teardown ejecutados exitosamente.
- RuleTemplate usado: `TEST_RULE_TEMPLATE_ID=4`; version usada: `TEST_RULE_TEMPLATE_VERSION_ID=6` (resuelto por SQL previo).
- Gate no-regresion no-demo: PASS (`observed=118 <= baseline=240`), aunque `typecheck_exit_code=2` por errores fuera de scope no-demo.
- Auto-login API: FAIL (`Unable to connect to the remote server` en `http://localhost:5220/api/v1/auth/login`).
- Runtime API: no se pudo levantar instancia dedicada desde el runner (bloqueo de policy para procesos en background).
- Cierre final verificado: `STILL_RUNNING: none` para `Telemetric.Api`.
- Teardown phase-01: no se realizaron cambios destructivos.
- Cierre runtime pendiente de confirmar manualmente si se levantaron servicios en DRY_RUN=0.
