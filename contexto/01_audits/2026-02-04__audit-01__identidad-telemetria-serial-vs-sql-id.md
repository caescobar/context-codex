# AUDIT REPORT - audit-01__identidad-telemetria-serial-vs-sql-id

## 0) Metadata
- Fecha: 2026-02-04
- Modo: docs-only (audit-exec, sin cambios de codigo)
- Skills aplicadas: telemetric-backend-style
- Objetivo: Auditar el contrato de identidad y telemetria (serial vs SQL id) y documentar desviaciones o riesgos entre backend y fuentes de verdad.
- Repos/servicios: telemetric-api, telemetric-hub (kiss), telemetric-front
- Autor: Codex (asistido)

## 0.1 Trazabilidad del pack
- PackDir: contexto/00_prompts/2026-02-04__pack-audit-pack-inicial-global
- AuditId: AUDIT-01
- IndexRef: contexto/00_prompts/2026-02-04__pack-audit-pack-inicial-global/INDEX.md
- PromptSource: contexto/00_prompts/2026-02-04__pack-audit-pack-inicial-global/audit-01__identidad-telemetria-serial-vs-sql-id__AUDIT__PROMPT.md

## 1) Executive Summary (max 5 bullets)
- SQL define `DeviceId` como identidad (INT) y `SerialNumber` como identificador natural unico; ambos existen en dominio y EF Core.
- Redis de configuracion usa el serial como llave (`device:{serial}`) y guarda `platform_id` con el SQL id, lo que alinea DTE hacia ClickHouse.
- RabbitMQ y SignalR rutean por serial (`telemetry.device.{serial}` / `device_{serial}`), pero el payload (TelemetryEnvelope) usa `DeviceId` como SQL id cuando esta disponible.
- Redis last-value persiste con `device:{DeviceId}:last` usando el `DeviceId` del envelope, lo que puede divergir del serial usado por SignalR/Hubs.
- Existe un riesgo alto de escritura en ClickHouse con `DeviceId=0` si falta `platform_id`, y un riesgo medio de snapshots vacios en Redis por mismatch serial vs SQL id.

## 2) Alcance (Scope)
### 2.1 Paths/archivos analizados
- telemetric-api/scripts/000.telemetric-schema.sql
- telemetric-api/src/Telemetric.Api/Domain/Entities/Device.cs
- telemetric-api/src/Telemetric.Api/Infrastructure/Persistence/Contexts/TelemetricDbContext.cs
- telemetric-api/src/Telemetric.Api/Features/Devices/CreateDevice/CreateDeviceCommandHandler.cs
- telemetric-api/src/Telemetric.Api/Features/Devices/UpdateDevice/UpdateDeviceCommandHandler.cs
- telemetric-api/src/Telemetric.Api/Features/Devices/DeleteDevice/DeleteDeviceCommandHandler.cs
- telemetric-api/src/Telemetric.Api/Features/Telemetry/TelemetryWorker.cs
- telemetric-api/src/Telemetric.Api/Features/Telemetry/TelemetryHub.cs
- telemetric-api/src/Telemetric.Api/appsettings.json
- telemetric-hub/kiss/Telemetric.Hub/Program.cs
- telemetric-hub/kiss/Telemetric.Worker.DTE/WorkerApplication.cs
- telemetric-hub/kiss/Telemetric.Worker.Persist/PersistWorker.cs
- telemetric-hub/kiss/connectors/Telemetric.Connectors.Abstractions/Abstractions/TelemetryEnvelope.cs
- telemetric-hub/kiss/connectors/Telemetric.Connectors.Abstractions/Abstractions/DeviceConfig.cs
- telemetric-hub/kiss/connectors/Telemetric.Connectors.Abstractions/Options/RedisOptions.cs
- telemetric-hub/kiss/connectors/Telemetric.Connectors.Redis/RedisDeviceSyncService.cs
- telemetric-hub/kiss/connectors/Telemetric.Connectors.Redis/RedisDeviceCache.cs
- telemetric-hub/kiss/connectors/Telemetric.Connectors.Redis/RedisLastValueStore.cs
- telemetric-hub/kiss/connectors/Telemetric.Connectors.RabbitMQ/RawTelemetryPublisher.cs
- telemetric-hub/kiss/connectors/Telemetric.Connectors.RabbitMQ/NormalizedTelemetryPublisher.cs
- telemetric-hub/kiss/connectors/Telemetric.Connectors.ClickHouse/ClickHouseTelemetryWriter.cs
- telemetric-hub/kiss/scripts/rabbitmq/definitions.json
- telemetric-hub/kiss/scripts/clickhouse/init-clickhouse.sql
- telemetric-front/src/features/telemetry/telemetry.service.ts

### 2.2 Fuera de alcance
- Infra real de Redis/Rabbit/ClickHouse (solo scripts locales)
- Configs por ambiente fuera de `appsettings.json`
- Codigo en `telemetric-api/old/`

## 3) Contrato actual observado (Fuente: codigo)
> Tabla obligatoria. No asumir. Si algo no se encontro, escribir "No encontrado".

| Capa | Identidad externa (serial/id) | Key/Routing/Group | Campos/Shape | Evidencia (paths) |
|---|---|---|---|---|
| SQL | SerialNumber (natural) + DeviceId (INT identity PK) | N/A | DeviceId, SerialNumber, ModelId, etc. | telemetric-api/scripts/000.telemetric-schema.sql, telemetric-api/src/Telemetric.Api/Domain/Entities/Device.cs, telemetric-api/src/Telemetric.Api/Infrastructure/Persistence/Contexts/TelemetricDbContext.cs |
| Redis config | Serial (DeviceId = SerialNumber) | Hash: `device:{serial}`; Set: `devices` | Fields: `deviceId`, `estado`, `decryptor`, `decrypt_key`, `transformer`, `out_conn`, `clientId`, `cuotaMax`, `platform_id` | telemetric-hub/kiss/connectors/Telemetric.Connectors.Abstractions/Options/RedisOptions.cs, telemetric-hub/kiss/connectors/Telemetric.Connectors.Redis/RedisDeviceSyncService.cs, telemetric-hub/kiss/connectors/Telemetric.Connectors.Redis/RedisDeviceCache.cs |
| Redis last-value | DeviceId del envelope (string; SQL id si `platform_id` existe, si no serial) | Key: `device:{DeviceId}:last` | Hash fields: `ts` + metricas (MetricCode) | telemetric-hub/kiss/connectors/Telemetric.Connectors.Redis/RedisLastValueStore.cs, telemetric-hub/kiss/Telemetric.Worker.DTE/WorkerApplication.cs |
| Rabbit raw | Serial (en el frame `serial.payload`) | Exchange `telemetry.ingress`, routing key `validated`, queue `telemetry.validated` | Body: string plano `serial.payload` | telemetric-hub/kiss/Telemetric.Hub/Program.cs, telemetric-hub/kiss/connectors/Telemetric.Connectors.RabbitMQ/RawTelemetryPublisher.cs, telemetric-hub/kiss/scripts/rabbitmq/definitions.json |
| Rabbit normalized | Routing por Serial (`telemetry.device.{serial}`) | Exchange `telemetry.data`, routing key dinamico `telemetry.device.{serial}`, queue `telemetry.normalized` (binding `telemetry.device.#`) | JSON `TelemetryEnvelope` (DeviceId string) | telemetric-hub/kiss/Telemetric.Worker.DTE/WorkerApplication.cs, telemetric-hub/kiss/connectors/Telemetric.Connectors.RabbitMQ/NormalizedTelemetryPublisher.cs, telemetric-hub/kiss/scripts/rabbitmq/definitions.json |
| SignalR | Serial (suscripcion del frontend) | Group `device_{serial}` | Evento `ReceiveTelemetry(DeviceId, data, timestamp)` | telemetric-api/src/Telemetric.Api/Features/Telemetry/TelemetryHub.cs, telemetric-api/src/Telemetric.Api/Features/Telemetry/TelemetryWorker.cs, telemetric-front/src/features/telemetry/telemetry.service.ts |
| Payload | `TelemetryEnvelope.DeviceId` (string; preferentemente SQL id) | N/A | `DeviceId`, `DeviceType`, `TimestampUtc`, `Sensors[]` | telemetric-hub/kiss/connectors/Telemetric.Connectors.Abstractions/Abstractions/TelemetryEnvelope.cs, telemetric-hub/kiss/Telemetric.Worker.DTE/WorkerApplication.cs, telemetric-api/src/Telemetric.Api/Features/Telemetry/TelemetryWorker.cs |

## 4) Nombres canonicos encontrados (no inventar)
- Redis:
  - Devices set: `devices`
  - Device hash prefix: `device:`
  - Usage prefix: `usage:`
  - Last-value key: `device:{id}:last`
- Rabbit:
  - Exchanges: `telemetry.ingress`, `telemetry.data`
  - Queues: `telemetry.validated`, `telemetry.normalized`, `telemetry.actions`
  - Routing keys: `validated`, `telemetry.device.{serial}`, `telemetry.device.#`, `actions`
- SignalR:
  - Group naming: `device_{serial}`
**Evidencia:** telemetric-hub/kiss/connectors/Telemetric.Connectors.Abstractions/Options/RedisOptions.cs, telemetric-hub/kiss/connectors/Telemetric.Connectors.Redis/RedisLastValueStore.cs, telemetric-hub/kiss/Telemetric.Worker.DTE/WorkerApplication.cs, telemetric-hub/kiss/scripts/rabbitmq/definitions.json, telemetric-api/src/Telemetric.Api/Features/Telemetry/TelemetryWorker.cs

## 5) Hallazgos (con evidencia)
> Cada hallazgo debe tener: severidad, impacto, evidencia, repro si aplica, recomendacion.

### High
- **HALL-20260204-001 - ClickHouse puede guardar DeviceId=0 si falta platform_id**
  - Impacto: perdida de trazabilidad por dispositivo (datos mezclados en `DeviceId=0`), queries de historico quedan vacias para el DeviceId real.
  - Evidencia (paths): telemetric-hub/kiss/Telemetric.Worker.DTE/WorkerApplication.cs (fallback a serial), telemetric-hub/kiss/connectors/Telemetric.Connectors.ClickHouse/ClickHouseTelemetryWriter.cs (parse int y fallback a 0), telemetric-hub/kiss/scripts/clickhouse/init-clickhouse.sql (DeviceId Int32).
  - Repro (si aplica): crear dispositivo sin `platform_id` en Redis, enviar frame `serial.payload`, verificar insercion en ClickHouse con `DeviceId=0`.
  - Recomendacion: validar que `platform_id` exista antes de publicar normalizado, o registrar error y descartar; alternativamente persistir Serial en ClickHouse y evitar coercion a 0.

### Medium
- **HALL-20260204-002 - Redis last-value usa DeviceId del envelope (SQL id) mientras el Hub busca por serial**
  - Impacto: snapshot inicial por SignalR puede estar vacio aunque haya telemetria reciente (key lookup por serial no encuentra `device:{sqlId}:last`).
  - Evidencia (paths): telemetric-hub/kiss/connectors/Telemetric.Connectors.Redis/RedisLastValueStore.cs, telemetric-hub/kiss/Telemetric.Worker.DTE/WorkerApplication.cs, telemetric-api/src/Telemetric.Api/Features/Telemetry/TelemetryHub.cs.
  - Repro (si aplica): con `platform_id` presente, enviar telemetria y luego suscribirse por serial; el hash `device:{serial}:last` no existe.
  - Recomendacion: alinear key de last-value con serial (routing id) o hacer que el Hub resuelva serial -> SQL id y consulte `device:{sqlId}:last`.

### Low
- **HALL-20260204-003 - Semantica mixta de "DeviceId" en payload vs routing**
  - Impacto: consumidores externos pueden asumir que `DeviceId` == serial, pero el payload envia SQL id mientras el routing/group usa serial; requiere mapeo explicito (ya se hace en frontend).
  - Evidencia (paths): telemetric-api/src/Telemetric.Api/Features/Telemetry/TelemetryWorker.cs, telemetric-hub/kiss/Telemetric.Worker.DTE/WorkerApplication.cs, telemetric-front/src/features/telemetry/telemetry.service.ts.
  - Repro (si aplica): escuchar en SignalR y observar que `ReceiveTelemetry(DeviceId)` entrega SQL id, no serial.
  - Recomendacion: documentar explicitamente el contrato (routing por serial, payload por SQL id) o unificar ambos.

## 6) Riesgos de romper contratos
- Riesgo: cambiar el significado de `DeviceId` en TelemetryEnvelope afecta ClickHouse, Redis last-value, SignalR y frontend.
- Mitigacion: definir contrato canonico (serial vs SQL id) y agregar validaciones de invariantes en DTE/Persist/Hub.

## 7) Recomendacion priorizada
1) Definir y documentar el ID canonico para telemetria (routing vs payload) y hacerlo obligatorio en todo el pipeline.
2) Evitar escribir `DeviceId=0` en ClickHouse (validacion estricta o esquema con Serial explicito).
3) Alinear la key de Redis last-value con el mismo ID que usan los suscriptores de SignalR.

## 8) Plan sugerido por fases (sin ejecutar)
> Max 5 archivos por fase. No cambiar contratos sin migracion.

### Fase 1
- Objetivo: validar invariantes de ID (platform_id obligatorio para persistencia).
- Archivos potenciales (max 5):
  - telemetric-api/src/Telemetric.Api/Features/Devices/CreateDevice/CreateDeviceCommandHandler.cs
  - telemetric-api/src/Telemetric.Api/Features/Devices/UpdateDevice/UpdateDeviceCommandHandler.cs
  - telemetric-hub/kiss/connectors/Telemetric.Connectors.Redis/RedisDeviceSyncService.cs
  - telemetric-hub/kiss/Telemetric.Worker.DTE/WorkerApplication.cs
  - telemetric-hub/kiss/connectors/Telemetric.Connectors.ClickHouse/ClickHouseTelemetryWriter.cs
- Verificacion: enviar telemetria con/ sin platform_id y confirmar que no hay inserts con DeviceId=0.

### Fase 2
- Objetivo: unificar last-value con el ID de suscripcion.
- Archivos potenciales (max 5):
  - telemetric-hub/kiss/connectors/Telemetric.Connectors.Redis/RedisLastValueStore.cs
  - telemetric-api/src/Telemetric.Api/Features/Telemetry/TelemetryHub.cs
  - telemetric-api/src/Telemetric.Api/Features/Telemetry/TelemetryWorker.cs
- Verificacion: suscribirse por serial y recibir snapshot correcto.

### Fase 3
- Objetivo: documentar contrato canonico de identidad en telemetria.
- Archivos potenciales (max 5):
  - contexto/01_overview/README.md
- Verificacion: checklist de contrato actualizado con IDs y rutas.

## 9) Como verificar (smoke test)
1) Crear/actualizar dispositivo y verificar en Redis el hash `device:{serial}` con `platform_id` presente.
2) Enviar frame `serial.payload` al Hub y confirmar routing `telemetry.device.{serial}` en Rabbit.
3) Verificar Redis last-value: revisar tanto `device:{serial}:last` como `device:{sqlId}:last`.
4) Consultar ClickHouse `TelemetryLog` por `DeviceId` y confirmar que no se escribe `0`.
5) Suscribirse via SignalR con serial y validar evento `ReceiveTelemetry` y snapshot inicial.

## 10) Pendientes registrados
- Anadir/actualizar en `contexto/03_hallazgos/pending.md`: HALL-20260204-001, HALL-20260204-002, HALL-20260204-003




