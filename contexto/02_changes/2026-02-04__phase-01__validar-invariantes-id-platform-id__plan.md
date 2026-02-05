# CHANGE PLAN – validar-invariantes-id-platform-id – Fase 01

## 0) Metadata
- Fecha: 2026-02-04
- Alcance: PHASE-01
- Modo: refactor-safe + change-control
- Skills: refactor-safe, telemetric-backend-style, telemetric-connectors-standard

## 0.1 Trazabilidad del pack
- PackDir: contexto/00_prompts/2026-02-04__pack-audit-pack-inicial-global
- PhaseId: PHASE-01        <!-- ej: PHASE-01 -->
- IndexRef: contexto/00_prompts/2026-02-04__pack-audit-pack-inicial-global/INDEX.md      <!-- ej: contexto/00_prompts/.../INDEX.md -->
- PromptSource: contexto/00_prompts/2026-02-04__pack-audit-pack-inicial-global/phases/phase-01__validar-invariantes-id-platform-id__PHASE__PROMPT.md <!-- ej: contexto/00_prompts/.../phase-01__...__PROMPT.md -->

## 1) Objetivo
- Validar invariantes de ID: `platform_id` obligatorio para persistencia/publicación.

## 2) Archivos a tocar (máx 5)
- telemetric-api/src/Telemetric.Api/Features/Devices/CreateDevice/CreateDeviceCommandHandler.cs
- telemetric-api/src/Telemetric.Api/Features/Devices/UpdateDevice/UpdateDeviceCommandHandler.cs
- telemetric-hub/kiss/connectors/Telemetric.Connectors.Redis/RedisDeviceSyncService.cs
- telemetric-hub/kiss/Telemetric.Worker.DTE/WorkerApplication.cs
- telemetric-hub/kiss/connectors/Telemetric.Connectors.ClickHouse/ClickHouseTelemetryWriter.cs

## 3) Evidencia (paths)
- telemetric-hub/kiss/Telemetric.Worker.DTE/WorkerApplication.cs
- telemetric-hub/kiss/connectors/Telemetric.Connectors.ClickHouse/ClickHouseTelemetryWriter.cs
- telemetric-hub/kiss/connectors/Telemetric.Connectors.Redis/RedisDeviceSyncService.cs
- telemetric-hub/kiss/connectors/Telemetric.Connectors.Redis/RedisDeviceCache.cs
- telemetric-hub/kiss/connectors/Telemetric.Connectors.Redis/RedisLastValueStore.cs

## 4) Plan en 5 bullets
1) Agregar guardas de `platform_id` en sync a Redis desde API (Create/Update) con warn/metric.
2) En DTE, exigir `platform_id` antes de publicar y eliminar fallback a serial.
3) En ClickHouse writer, rechazar `DeviceId` inválido/<=0 y evitar inserts con 0.
4) Completar plan/summary y actualizar `pending.md`/IndexRef según change-control.
5) Ejecutar verificación manual con telemetría con/sin `platform_id`.

## 5) Riesgos y mitigaciones
- Riesgo: dispositivos legacy sin `platform_id` dejarán de persistir.
- Mitigación: logs/metricas para detectar y proceso de re-sync desde SQL para completar `platform_id`.

## 6) Cómo verificar (pasos manuales)
1) Preparar un dispositivo con `platform_id` presente y enviar telemetría (serial.payload con `platform_id`).
2) Preparar un dispositivo sin `platform_id` y enviar telemetría (serial.payload sin `platform_id`).
3) CLICKHOUSE_SQL: contar `DeviceId=0` en el rango de prueba (esperado 0).

## 7) No-go rules (si pasa esto, parar)
- Tocar archivos fuera del Alcance o superar 5 archivos.
- Cambiar contratos externos sin migración explícita.
- No poder cumplir la verificación definida.

## 8) Post-step (actualizar checklist)
- Marcar `[x]` en `IndexRef` para `PHASE-01`.
- Completar/actualizar links a Plan y Summary en el índice.
