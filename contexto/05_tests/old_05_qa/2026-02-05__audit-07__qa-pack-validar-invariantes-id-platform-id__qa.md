# QA PACK - audit-07__qa-pack-validar-invariantes-id-platform-id

## 0) Metadata
- Fecha: 2026-02-05
- Tipo: QA PACK
- Objetivo: validar invariantes de ID (platform_id obligatorio) y no inserts con DeviceId=0.
- Entorno: docker-compose (redis/rabbit/clickhouse) + dotnet run local (Hub/DTE/Persist; hostigador opcional)
- Autor: Codex (asistido)

## 0.1 Trazabilidad del pack
- PackDir: contexto/00_prompts/2026-02-04__pack-audit-pack-inicial-global
- ItemId: AUDIT-07
- IndexRef: contexto/00_prompts/2026-02-04__pack-audit-pack-inicial-global/INDEX.md
- PromptSource: contexto/00_prompts/2026-02-04__pack-audit-pack-inicial-global/audits/audit-07__qa-pack-validar-invariantes-id-platform-id__AUDIT__PROMPT.md
- Relacionado: PhaseId=PHASE-01 | ChangePlan=contexto/02_changes/2026-02-04__phase-01__validar-invariantes-id-platform-id__plan.md | ChangeSummary=contexto/02_changes/2026-02-04__phase-01__validar-invariantes-id-platform-id__summary.md

## 0.2 Fuentes
- PHASE-01 prompt: contexto/00_prompts/2026-02-04__pack-audit-pack-inicial-global/phases/phase-01__validar-invariantes-id-platform-id__PHASE__PROMPT.md
- CHANGE SUMMARY: contexto/02_changes/2026-02-04__phase-01__validar-invariantes-id-platform-id__summary.md

---

## 1) Alcance (que valida / que no)
### 1.1 Incluye
- Flujo con platform_id presente y sin platform_id.
- Verificacion de no inserts con DeviceId=0 en ClickHouse.

### 1.2 No incluye
- Performance / carga / soak.
- Validacion de integridad en SQL Server.

---

## 2) Pre-requisitos
> Si no se conoce un comando exacto, dejar placeholder accionable.

- Docker / Docker Compose: pendiente
- Servicios esperados arriba: redis, rabbit, clickhouse, hub, hostigador
- Variables/config relevantes: HUB_URL=https://localhost:7008/api/v1/ingest-raw | REDIS=localhost:6379 | RABBIT=localhost:5672 (vhost=ingesta) | CLICKHOUSE=Host=localhost;Port=8123;Username=teleuser;Password=telepass123;Database=telemetric

---

## 3) Setup (arranque y estado)
### 3.1 Levantar stack infra (redis/rabbit/clickhouse)
- DOCKER_COMPOSE: `docker compose -f telemetric-hub/kiss/scripts/docker-compose.yml up -d`
- Evidencia: telemetric-hub/kiss/scripts/docker-compose.yml
- Expected: servicios redis/rabbit/clickhouse en running/healthy.

### 3.2 Levantar Hub (local)
- HUB: `dotnet run --project telemetric-hub/kiss/Telemetric.Hub/Telemetric.Hub.csproj`
- Evidencia: telemetric-hub/kiss/Telemetric.Hub/Telemetric.Hub.csproj, telemetric-hub/kiss/Telemetric.Hub/Program.cs
- Expected: Hub expuesto en http://localhost:5262 y/o https://localhost:7008.

### 3.3 Levantar Workers (DTE + Persist)
- DTE: `dotnet run --project telemetric-hub/kiss/Telemetric.Worker.DTE/Telemetric.Worker.DTE.csproj`
- Evidencia: telemetric-hub/kiss/Telemetric.Worker.DTE/Program.cs
- Persist: `dotnet run --project telemetric-hub/kiss/Telemetric.Worker.Persist/Telemetric.Worker.Persist.csproj`
- Evidencia: telemetric-hub/kiss/Telemetric.Worker.Persist/Program.cs
- Expected: consola indica que los workers estan escuchando.

### 3.4 Smoke de conectividad
- REDIS_CLI: `redis-cli -h localhost -p 6379 ping`
- Evidencia: telemetric-hub/kiss/scripts/docker-compose.yml, telemetric-hub/kiss/scripts/redis/init-devices.sh
- Expected: `PONG`

- RABBIT_ADMIN: `curl -u admin:admin123 http://localhost:15672/api/queues/ingesta/telemetry.validated`
- Evidencia: telemetric-hub/kiss/scripts/docker-compose.yml, telemetric-hub/kiss/scripts/rabbitmq/definitions.json
- Expected: JSON con la cola `telemetry.validated`.

- CLICKHOUSE_SQL: `docker exec -it telemetric-clickhouse clickhouse-client --user teleuser --password telepass123 --database telemetric --query "SELECT count() FROM TelemetryLog"`
- Evidencia: telemetric-hub/kiss/scripts/docker-compose.yml, telemetric-hub/kiss/scripts/clickhouse/init-clickhouse.sql
- Expected: resultado numerico (0 si no hay datos).

---

## 4) Datos de prueba (preparacion)
> Objetivo: tener 2 casos:
> A) device con platform_id presente
> B) device sin platform_id

### 4.1 Caso A - con platform_id
- Identidad: serial=1001, platform_id=1001
- Preparacion:
  - REDIS_CLI: `redis-cli -h localhost -p 6379 HSET device:1001 platform_id 1001`
  - Evidencia: telemetric-hub/kiss/scripts/redis/init-devices.sh, telemetric-hub/kiss/connectors/Telemetric.Connectors.Abstractions/Options/RedisOptions.cs, telemetric-hub/kiss/connectors/Telemetric.Connectors.Redis/RedisDeviceSyncService.cs
  - Expected: `device:1001` contiene `platform_id=1001`.

### 4.2 Caso B - sin platform_id
- Identidad: serial=1002
- Preparacion:
  - REDIS_CLI: `redis-cli -h localhost -p 6379 HGET device:1002 platform_id`
  - Evidencia: telemetric-hub/kiss/scripts/redis/init-devices.sh, telemetric-hub/kiss/connectors/Telemetric.Connectors.Abstractions/Options/RedisOptions.cs, telemetric-hub/kiss/connectors/Telemetric.Connectors.Redis/RedisDeviceSyncService.cs
  - Expected: `(nil)` o vacio (sin platform_id).

---

## 5) Ejecucion - Pasos manuales (Accion + Expected)
> 4-7 pasos. Cada paso debe tener evidencia capturable (logs/queries/outputs).

1) Accion: verificar Redis para casos A/B.
   REDIS_CLI: `redis-cli -h localhost -p 6379 HGET device:1001 platform_id && redis-cli -h localhost -p 6379 HGET device:1002 platform_id`
   Evidencia: telemetric-hub/kiss/scripts/redis/init-devices.sh, telemetric-hub/kiss/connectors/Telemetric.Connectors.Abstractions/Options/RedisOptions.cs, telemetric-hub/kiss/connectors/Telemetric.Connectors.Redis/RedisDeviceSyncService.cs
   Expected: 1001 devuelve un entero > 0; 1002 devuelve (nil) o vacio.

2) Accion: enviar telemetria para Caso A (con platform_id).
   API_CALL: `curl -k -X POST https://localhost:7008/api/v1/ingest-raw -H "Content-Type: application/json" -d "{\"frame\":\"1001.{\\\"ts\\\":1700000000,\\\"t\\\":1,\\\"sv\\\":1,\\\"data\\\":{\\\"lat\\\":40.4168,\\\"lng\\\":-3.7038,\\\"tmp\\\":12.3,\\\"bat\\\":95}}\"}"`
   Evidencia: telemetric-hub/kiss/Telemetric.Hub/Program.cs, telemetric-hub/kiss/Telemetric.Hostigador/Program.cs, telemetric-hub/kiss/Telemetric.Worker.DTE/Entities/IngressV1PayloadDto.cs, telemetric-hub/kiss/Telemetric.Hub/Properties/launchSettings.json
   Expected: HTTP 200/OK y el pipeline procesa sin bloquear.

3) Accion: verificar Rabbit (cola raw consumida por DTE).
   RABBIT_ADMIN: `curl -u admin:admin123 http://localhost:15672/api/queues/ingesta/telemetry.validated`
   Evidencia: telemetric-hub/kiss/scripts/docker-compose.yml, telemetric-hub/kiss/scripts/rabbitmq/definitions.json
   Expected: `messages`/`messages_ready` en 0 (si DTE esta corriendo).

4) Accion: verificar ClickHouse (no inserts DeviceId=0) tras Caso A.
   CLICKHOUSE_SQL: `docker exec -it telemetric-clickhouse clickhouse-client --user teleuser --password telepass123 --database telemetric --query "SELECT count() AS cnt FROM TelemetryLog WHERE DeviceId = 0 AND Timestamp >= now() - INTERVAL 15 MINUTE"`
   Evidencia: telemetric-hub/kiss/scripts/docker-compose.yml, telemetric-hub/kiss/scripts/clickhouse/init-clickhouse.sql
   Expected: cnt = 0.

5) Accion: enviar telemetria para Caso B (sin platform_id).
   API_CALL: `curl -k -X POST https://localhost:7008/api/v1/ingest-raw -H "Content-Type: application/json" -d "{\"frame\":\"1002.{\\\"ts\\\":1700000001,\\\"t\\\":1,\\\"sv\\\":1,\\\"data\\\":{\\\"lat\\\":40.4168,\\\"lng\\\":-3.7038,\\\"tmp\\\":12.3,\\\"bat\\\":95}}\"}"`
   Evidencia: telemetric-hub/kiss/Telemetric.Hub/Program.cs, telemetric-hub/kiss/Telemetric.Hostigador/Program.cs, telemetric-hub/kiss/Telemetric.Worker.DTE/Entities/IngressV1PayloadDto.cs, telemetric-hub/kiss/Telemetric.Hub/Properties/launchSettings.json
   Expected: HTTP 200/OK pero el pipeline NO persiste/publica.

6) Accion: verificar ClickHouse nuevamente tras Caso B.
   CLICKHOUSE_SQL: `docker exec -it telemetric-clickhouse clickhouse-client --user teleuser --password telepass123 --database telemetric --query "SELECT count() AS cnt FROM TelemetryLog WHERE DeviceId = 0 AND Timestamp >= now() - INTERVAL 15 MINUTE"`
   Evidencia: telemetric-hub/kiss/scripts/docker-compose.yml, telemetric-hub/kiss/scripts/clickhouse/init-clickhouse.sql
   Expected: cnt sigue en 0.

7) Accion: verificar evidencia en logs/metricas.
   LOGS: revisar consola de `dotnet run --project telemetric-hub/kiss/Telemetric.Worker.DTE/Telemetric.Worker.DTE.csproj` y `dotnet run --project telemetric-hub/kiss/Telemetric.Worker.Persist/Telemetric.Worker.Persist.csproj` y buscar `[WARN][DTE] platform_id missing` / `[WARN][ClickHouse] Invalid DeviceId` / `platform_id_missing=1`.
   Evidencia: telemetric-hub/kiss/Telemetric.Worker.DTE/WorkerApplication.cs, telemetric-hub/kiss/connectors/Telemetric.Connectors.ClickHouse/ClickHouseTelemetryWriter.cs
   Expected: existe evidencia de bloqueo por invariante para el Caso B.

---

## 6) Evidencias (pegar outputs)
- API responses Caso A: ```txt
PENDIENTE
```
- API responses Caso B: ```txt
PENDIENTE
```
- ClickHouse query usada: ```sql
PENDIENTE
```
- ClickHouse resultado: ```txt
PENDIENTE
```
- Logs: ```txt
PENDIENTE
```

---

## 7) Resultados (Expected vs Observed)
- Caso A: Expected = pipeline ok sin DeviceId=0 | Observed = PENDIENTE
- Caso B: Expected = no persist/publica + log/metric | Observed = PENDIENTE

---

## 8) Done criteria
- [ ] No hay inserts con `DeviceId=0` en el rango de prueba.
- [ ] Telemetria sin `platform_id` no persiste/publica.
- [ ] Existe evidencia (log/warn/metric) de bloqueo por invariante.
- [ ] Los pasos son reproducibles (comandos/queries listados).

---

## 9) Post-step (para trazabilidad)
- Actualizar `contexto/00_prompts/2026-02-04__pack-audit-pack-inicial-global/INDEX.md`: marcar `[x]` AUDIT-07 y completar Output si faltaba.
- Si se detectan hallazgos nuevos: actualizar `contexto/03_hallazgos/pending.md`.

---

## Inventario de fuentes (repo)
- telemetric-hub/kiss/scripts/docker-compose.yml
- telemetric-hub/kiss/scripts/redis/init-devices.sh
- telemetric-hub/kiss/scripts/rabbitmq/definitions.json
- telemetric-hub/kiss/scripts/clickhouse/init-clickhouse.sql
- telemetric-hub/kiss/Telemetric.Hub/Program.cs
- telemetric-hub/kiss/Telemetric.Hub/Properties/launchSettings.json
- telemetric-hub/kiss/Telemetric.Hostigador/Program.cs
- telemetric-hub/kiss/Telemetric.Worker.DTE/Program.cs
- telemetric-hub/kiss/Telemetric.Worker.DTE/WorkerApplication.cs
- telemetric-hub/kiss/Telemetric.Worker.DTE/Entities/IngressV1PayloadDto.cs
- telemetric-hub/kiss/Telemetric.Worker.Persist/Program.cs
- telemetric-hub/kiss/connectors/Telemetric.Connectors.Abstractions/Options/RedisOptions.cs
- telemetric-hub/kiss/connectors/Telemetric.Connectors.Redis/RedisDeviceSyncService.cs
- telemetric-hub/kiss/connectors/Telemetric.Connectors.ClickHouse/ClickHouseTelemetryWriter.cs
