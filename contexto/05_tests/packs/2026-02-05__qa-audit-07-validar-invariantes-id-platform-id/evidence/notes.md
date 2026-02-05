# Notes

- Si `redis-cli` no está instalado localmente, alternativa reproducible:
  - `docker exec -i telemetric-redis redis-cli HSET device:1001 platform_id 1001`
  - `docker exec -i telemetric-redis redis-cli HDEL device:1002 platform_id`
  - `docker exec -i telemetric-redis redis-cli HGET device:1001 platform_id`
  - `docker exec -i telemetric-redis redis-cli HGET device:1002 platform_id`
- Los procesos de `dotnet run` (Hub/DTE/Persist) deben iniciarse en terminales separadas y mantenerse activos durante la ejecución.

## Ejecucion 2026-02-05
- docker compose up/down fallo: Acceso denegado al engine de Docker (ver evidence/outputs.log).
- redis-cli no instalado; alternativa docker exec no disponible por mismo error de Docker.
- dotnet run (Hub/DTE/Persist) iniciado via Start-Process con stdout/stderr en evidence/*.log; compilacion fallo (ver hub.err.log, dte.err.log, persist.err.log).
- API https://localhost:7008 no disponible: curl failed to connect.
- Rabbit admin API responde OK (ver evidence/outputs.log).

## Ejecucion 2026-02-05 10:37
- Docker Desktop sigue sin permisos (Acceso denegado a dockerDesktopLinuxEngine) al hacer pull de clickhouse.
- dotnet run (Hub/DTE/Persist) sigue sin compilar (ver evidence/hub.err.log, dte.err.log, persist.err.log).

## Ejecucion 2026-02-05 10:41
- Desde esta terminal, docker compose sigue con "Acceso denegado" al engine (ver outputs.log).
- Necesito que ejecutes los comandos del pack en tu terminal o que habilites permisos para este proceso.

## Ejecucion 2026-02-05 10:43 (con permisos Docker)
- docker compose up -d OK (ver outputs.log).
- redis/clickhouse operativos via docker exec.
- dotnet run (Hub/DTE/Persist) no compila; se capturaron logs en evidence/hub.err.log, dte.err.log, persist.err.log.
- dotnet build tambien falla sin detalle de errores (ver evidence/build-hub.log, build-dte.log, build-persist.log).
- API https://localhost:7008 no disponible por fallo de compilacion del Hub.
- En esta ejecucion se usaron comandos `docker exec` para Redis/ClickHouse (redis-cli local no usado).
