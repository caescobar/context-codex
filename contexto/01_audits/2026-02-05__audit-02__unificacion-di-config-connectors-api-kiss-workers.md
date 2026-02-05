# AUDIT REPORT – audit-02__unificacion-di-config-connectors-api-kiss-workers

## 0) Metadata
- Fecha: 2026-02-05
- Modo: docs-only (audit-exec, sin cambios de código)
- Skills aplicadas: telemetric-backend-style, telemetric-connectors-standard
- Objetivo: Auditar la unificacion de DI/configuracion de connectors entre API y KISS/Workers para detectar duplicidades, divergencias y riesgos de drift.
- Repos/servicios: telemetric-api, telemetric-hub (kiss/connectors, Hub, Workers)
- Autor: Codex (asistido)

## 0.1 Trazabilidad del pack
- PackDir: contexto/00_prompts/2026-02-04__pack-audit-pack-inicial-global
- AuditId: AUDIT-02
- IndexRef: contexto/00_prompts/2026-02-04__pack-audit-pack-inicial-global/INDEX.md
- PromptSource: contexto/00_prompts/2026-02-04__pack-audit-pack-inicial-global/audit-02__unificacion-di-config-connectors-api-kiss-workers__AUDIT__PROMPT.md

## 1) Executive Summary (máx 5 bullets)
- La configuración de conectores está dispersa entre API y KISS/Workers (Program.cs, DependencyInjection y opciones), sin unificación ni fuente única de verdad.
- KISS/Workers usan constantes hardcoded para Redis/Rabbit/ClickHouse, mientras API usa appsettings/IConfiguration; esto crea alto riesgo de drift entre hosts.
- En API hay duplicidad de registro/definición para Redis (Program.cs + AddInfrastructure), y en Workers se invocan extensiones Rabbit múltiples veces con `TryAddSingleton`, lo que oculta diferencias si se diverge.

## 2) Alcance (Scope)
### 2.1 Paths/archivos analizados
- telemetric-api/src/Telemetric.Api/Program.cs
- telemetric-api/src/Telemetric.Api/Infrastructure/DependencyInjection.cs
- telemetric-api/src/Telemetric.Api/appsettings.json
- telemetric-api/src/Telemetric.Api/Infrastructure/ClickHouse/TelemetryRepository.cs
- telemetric-api/src/Telemetric.Api/Features/Telemetry/TelemetryWorker.cs
- telemetric-hub/kiss/Telemetric.Hub/Program.cs
- telemetric-hub/kiss/Telemetric.Worker.DTE/Program.cs
- telemetric-hub/kiss/Telemetric.Worker.Persist/Program.cs
- telemetric-hub/kiss/connectors/Telemetric.Connectors.Redis/RedisServiceCollectionExtensions.cs
- telemetric-hub/kiss/connectors/Telemetric.Connectors.RabbitMQ/RabbitServiceCollectionExtensions.cs
- telemetric-hub/kiss/connectors/Telemetric.Connectors.ClickHouse/ClickHouseServiceCollectionExtensions.cs
- telemetric-hub/kiss/connectors/Telemetric.Connectors.Abstractions/Options/RedisOptions.cs
- telemetric-hub/kiss/connectors/Telemetric.Connectors.Abstractions/Options/RabbitOptions.cs
- telemetric-hub/kiss/connectors/Telemetric.Connectors.Abstractions/Options/ClickHouseOptions.cs
- telemetric-hub/kiss/connectors/Telemetric.Connectors.Redis/RedisDeviceSyncService.cs
- telemetric-hub/kiss/connectors/Telemetric.Connectors.Redis/RedisLastValueStore.cs

### 2.2 Fuera de alcance
- telemetric-api/old/** (configuración legacy)
- telemetric-front/**
- Configs por ambiente externas (secrets/infra)

## 3) Contrato actual observado (Fuente: código)
> Tabla obligatoria. No asumir. Si algo no se encontró, escribir “No encontrado”.

| Capa | Identidad externa (serial/id) | Key/Routing/Group | Campos/Shape | Evidencia (paths) |
|---|---|---|---|---|
| SQL | No encontrado | No encontrado | No encontrado | No encontrado |
| Redis config | DeviceId (string; origen no definido aquí) | `device:{DeviceId}` + set `devices` | `deviceId`, `estado`, `decryptor`, `decrypt_key`, `transformer`, `out_conn`, `clientId`, `cuotaMax`, `platform_id` | telemetric-hub/kiss/connectors/Telemetric.Connectors.Redis/RedisDeviceSyncService.cs, telemetric-hub/kiss/connectors/Telemetric.Connectors.Abstractions/Options/RedisOptions.cs |
| Redis last-value | `envelope.DeviceId` | `device:{DeviceId}:last` | `ts` + métricas por `MetricCode` | telemetric-hub/kiss/connectors/Telemetric.Connectors.Redis/RedisLastValueStore.cs |
| Rabbit raw | No encontrado | Exchange `telemetry.ingress` + routing `validated` | Body `serial.payload` (no tipado aquí) | telemetric-hub/kiss/Telemetric.Hub/Program.cs |
| Rabbit normalized | No encontrado | Exchange `telemetry.data` + routing `telemetry.device.*` | JSON `TelemetryEnvelope` | telemetric-hub/kiss/Telemetric.Worker.DTE/Program.cs |
| SignalR | Serial (derivado de routing key) | Group `device_{serial}` | Payload: `ReceiveTelemetry(DeviceId, data, TimestampUtc)` | telemetric-api/src/Telemetric.Api/Features/Telemetry/TelemetryWorker.cs |
| Payload | `DeviceId` (string) | No aplica | `TelemetryEnvelope` | telemetric-api/src/Telemetric.Api/Features/Telemetry/TelemetryWorker.cs |

## 4) Nombres canónicos encontrados (no inventar)
- Redis: prefixes `device:` y `usage:`; set `devices`; fields `deviceId`, `estado`, `decryptor`, `decrypt_key`, `transformer`, `out_conn`, `clientId`, `cuotaMax`, `platform_id`
- Rabbit: exchanges `telemetry.ingress`, `telemetry.data`; routing keys `validated`, `telemetry.device.*`; queues `telemetry.validated`, `telemetry.normalized` (referenciadas en workers)
- SignalR: group naming `device_{serial}`
**Evidencia:** telemetric-hub/kiss/connectors/Telemetric.Connectors.Abstractions/Options/RedisOptions.cs, telemetric-hub/kiss/connectors/Telemetric.Connectors.Redis/RedisDeviceSyncService.cs, telemetric-hub/kiss/Telemetric.Hub/Program.cs, telemetric-hub/kiss/Telemetric.Worker.DTE/Program.cs, telemetric-hub/kiss/Telemetric.Worker.Persist/Program.cs, telemetric-api/src/Telemetric.Api/Features/Telemetry/TelemetryWorker.cs

## 5) Hallazgos (con evidencia)
> Cada hallazgo debe tener: severidad, impacto, evidencia, repro si aplica, recomendación.

### Medium
- **HALL-20260205-002 – Configuración de conectores no unificada entre API y KISS/Workers**
  - Impacto: drift de valores (host/puerto/exchange/routing/connection strings) entre hosts; difícil reproducir entornos; riesgo de mismatches en despliegue.
  - Evidencia (paths):
    - API usa IConfiguration/appsettings: telemetric-api/src/Telemetric.Api/appsettings.json, telemetric-api/src/Telemetric.Api/Program.cs, telemetric-api/src/Telemetric.Api/Infrastructure/DependencyInjection.cs
    - KISS/Workers usan constantes hardcoded: telemetric-hub/kiss/Telemetric.Hub/Program.cs, telemetric-hub/kiss/Telemetric.Worker.DTE/Program.cs, telemetric-hub/kiss/Telemetric.Worker.Persist/Program.cs
  - Repro (si aplica): comparar `RabbitSettings`/`RedisConnection`/`ClickHouseSettings` vs constantes en KISS; diferencias no se validan ni se comparten.
  - Recomendación: mover KISS/Workers a `IConfiguration`/appsettings y consolidar fuente de opciones (por host) usando extensiones estándar de conectores.

- **HALL-20260205-003 – Duplicidad y orden-dependencia en DI de Redis/Rabbit**
  - Impacto: configuraciones redundantes y potencialmente divergentes; el uso de `TryAddSingleton` en extensiones puede ignorar el segundo `configure` y esconder diferencias.
  - Evidencia (paths):
    - API: Redis se registra manualmente en `Program.cs` y también vía `AddRedisDeviceSyncService` en `DependencyInjection.cs`.
    - Workers: `AddRabbitConnection` + `AddNormalizedTelemetryPublisher` se invocan en el mismo host con el mismo `configure`, ambos llaman `EnsureRabbit` con `TryAddSingleton`.
    - Paths: telemetric-api/src/Telemetric.Api/Program.cs, telemetric-api/src/Telemetric.Api/Infrastructure/DependencyInjection.cs, telemetric-hub/kiss/connectors/Telemetric.Connectors.RabbitMQ/RabbitServiceCollectionExtensions.cs, telemetric-hub/kiss/Telemetric.Worker.DTE/Program.cs, telemetric-hub/kiss/Telemetric.Worker.Persist/Program.cs
  - Repro (si aplica): cambiar un valor en el segundo `configure` y observar que no aplica por `TryAddSingleton`.
  - Recomendación: unificar un solo punto de registro por host (una única llamada por conector y una única fuente de opciones).

### Low
- **HALL-20260205-004 – Hardcodes de valores canónicos (prefix/keys) fuera de configuración**
  - Impacto: cambios en contratos Redis/Rabbit requieren cambios en código y redeploy, no en configuración; aumenta riesgo de drift.
  - Evidencia (paths): telemetric-api/src/Telemetric.Api/Program.cs (DeviceHashPrefix/DevicesSetKey), telemetric-hub/kiss/Telemetric.Hub/Program.cs (exchange/routing), telemetric-hub/kiss/Telemetric.Worker.DTE/Program.cs, telemetric-hub/kiss/Telemetric.Worker.Persist/Program.cs
  - Repro (si aplica): no aplica.
  - Recomendación: mover estos valores a `appsettings` por host y consolidar con Options.

## 6) Riesgos de romper contratos
- Riesgo: cambios en la configuración de exchanges/routing keys/keys de Redis pueden romper consumidores externos o integraciones.
- Mitigación: centralizar contratos en Options y documentar migraciones; validar con QA pack y pruebas de integración antes de desplegar.

## 7) Recomendación priorizada
1) Consolidar la configuración de conectores por host (API, Hub, DTE, Persist) con `IConfiguration` y Options compartidas.
2) Eliminar registros duplicados en DI (una sola llamada por conector y por host).
3) Introducir un esquema de configuración común o plantilla de `appsettings` para los hosts KISS.

## 8) Plan sugerido por fases (sin ejecutar)
> Máx 5 archivos por fase. No cambiar contratos sin migración.

### Fase 1
- Objetivo: unificar el origen de configuración en API (Redis/Rabbit/ClickHouse) y eliminar duplicidad.
- Archivos potenciales (máx 5):
  - telemetric-api/src/Telemetric.Api/Program.cs
  - telemetric-api/src/Telemetric.Api/Infrastructure/DependencyInjection.cs
  - telemetric-api/src/Telemetric.Api/appsettings.json
- Verificación: levantar API y validar conexión Redis/Rabbit/ClickHouse con los mismos valores que antes.

### Fase 2
- Objetivo: mover KISS/Workers a `IConfiguration`/appsettings.
- Archivos potenciales (máx 5):
  - telemetric-hub/kiss/Telemetric.Hub/Program.cs
  - telemetric-hub/kiss/Telemetric.Worker.DTE/Program.cs
  - telemetric-hub/kiss/Telemetric.Worker.Persist/Program.cs
- Verificación: ejecutar Hub/Workers con configs por ambiente y confirmar conectividad con Redis/Rabbit/ClickHouse.

### Fase 3
- Objetivo: consolidar un esquema único de Options (reusar extensiones de conectores y validar defaults).
- Archivos potenciales (máx 5):
  - telemetric-hub/kiss/connectors/Telemetric.Connectors.Abstractions/Options/RedisOptions.cs
  - telemetric-hub/kiss/connectors/Telemetric.Connectors.Abstractions/Options/RabbitOptions.cs
  - telemetric-hub/kiss/connectors/Telemetric.Connectors.Abstractions/Options/ClickHouseOptions.cs
- Verificación: smoke test de ingestión end-to-end con routing correcto.

## 9) Cómo verificar (smoke test)
1) Iniciar API/Hub/Workers con un único set de parámetros (Redis/Rabbit/ClickHouse) y confirmar conexiones exitosas.
2) Enviar un frame `serial.payload` al Hub y confirmar publicación en Rabbit (exchange/routing esperado).
3) Confirmar que el Worker Persist escribe en ClickHouse y que el API puede leer histórico.

## 10) Pendientes registrados
- Añadir/actualizar en `contexto/03_hallazgos/pending.md`: HALL-20260205-002, HALL-20260205-003, HALL-20260205-004
