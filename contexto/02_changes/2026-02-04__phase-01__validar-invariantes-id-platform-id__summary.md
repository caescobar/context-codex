# CHANGE SUMMARY – validar-invariantes-id-platform-id – Fase 01

## 0) Metadata
- Fecha: 2026-02-04
- PR/Commit (si aplica):

## 0.1 Trazabilidad del pack
- PackDir: contexto/00_prompts/2026-02-04__pack-audit-pack-inicial-global
- PhaseId: PHASE-01        <!-- ej: PHASE-01 -->
- IndexRef: contexto/00_prompts/2026-02-04__pack-audit-pack-inicial-global/INDEX.md      <!-- ej: contexto/00_prompts/.../INDEX.md -->
- PromptSource: contexto/00_prompts/2026-02-04__pack-audit-pack-inicial-global/phases/phase-01__validar-invariantes-id-platform-id__PHASE__PROMPT.md <!-- ej: contexto/00_prompts/.../phase-01__...__PROMPT.md -->

## 1) Qué cambió
- Se agregó validación de `platform_id` en sync a Redis (Create/Update) con log/metric.
- DTE ahora exige `platform_id` antes de publicar (sin fallback a serial).
- ClickHouse writer descarta `DeviceId` inválido/<=0 para evitar inserts con 0.

## 2) Archivos tocados
- telemetric-api/src/Telemetric.Api/Features/Devices/CreateDevice/CreateDeviceCommandHandler.cs
- telemetric-api/src/Telemetric.Api/Features/Devices/UpdateDevice/UpdateDeviceCommandHandler.cs
- telemetric-hub/kiss/connectors/Telemetric.Connectors.Redis/RedisDeviceSyncService.cs
- telemetric-hub/kiss/Telemetric.Worker.DTE/WorkerApplication.cs
- telemetric-hub/kiss/connectors/Telemetric.Connectors.ClickHouse/ClickHouseTelemetryWriter.cs

## 3) Cómo probar
1) Preparar un dispositivo con `platform_id` presente y enviar telemetría (serial.payload con `platform_id`).
2) Preparar un dispositivo sin `platform_id` y enviar telemetría (serial.payload sin `platform_id`).
3) CLICKHOUSE_SQL: contar `DeviceId=0` en el rango de prueba (esperado 0).

## 4) Resultado esperado / observado
- Esperado: no se publica ni persiste telemetría sin `platform_id`; no hay `DeviceId=0` en ClickHouse.
- Observado: pendiente de verificación manual.

## 5) Hallazgos nuevos o pendientes
- HALL-20260204-001 (actualizado a In Progress en pending.md).

## 6) Riesgo de romper contratos
- No: no se modificaron keys de Redis ni routing keys; solo se corta el flujo cuando falta `platform_id`.

## 7) Post-step (actualizar checklist)
- Marcar `[x]` en `IndexRef` para `PHASE-01`.
- Completar/actualizar links a Summary en el índice.
