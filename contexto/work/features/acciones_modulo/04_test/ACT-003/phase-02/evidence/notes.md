# Notes - ACT-003 phase-02

- Pack creado en modo docs-only dentro de `contexto/work/features/acciones_modulo/04_test/ACT-003/phase-02/`.
- Scripts iniciales usan `DRY_RUN=1` por defecto para evitar efectos no deseados.
- Para corrida real usar `DRY_RUN=0` y completar variables de entorno necesarias.
- SQL verification es opcional mediante `SQLCMD_ARGS`.
- Se detectaron dos compose en el repo:
  - `telemetric-hub/kiss/scripts/docker-compose.yml` (seleccionado para discovery operativo)
  - `telemetric-api/old/docker-compose.yml` (legado, no usado)
- Teardown phase-02: no se realizaron cambios destructivos.
- 2026-02-18: corrida parcial validada. Setup/teardown OK. Run bloqueado por API no disponible en http://localhost:5220 (error en login Invoke-RestMethod).
- Teardown phase-02: no se realizaron cambios destructivos.
- 2026-02-18: run exitoso con RULE_TEMPLATE_ID=3. Validado incremento de version (1->2) y preservacion de version previa en historial. Instancia API finalizada al cierre (PID 14692).
