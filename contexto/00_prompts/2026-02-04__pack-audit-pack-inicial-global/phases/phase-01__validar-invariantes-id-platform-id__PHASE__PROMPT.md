PackDir: contexto/00_prompts/2026-02-04__pack-audit-pack-inicial-global
ItemId: PHASE-01
IndexRef: contexto/00_prompts/2026-02-04__pack-audit-pack-inicial-global/INDEX.md
PromptPath: contexto/00_prompts/2026-02-04__pack-audit-pack-inicial-global/phases/phase-01__validar-invariantes-id-platform-id__PHASE__PROMPT.md

Modo: refactor-safe + change-control
Skills: telemetric-backend-style, telemetric-connectors-standard

Objetivo
Validar invariantes de ID (platform_id obligatorio para persistencia).

Alcance
- Limitar cambios a estos 5 archivos:
  - telemetric-api/src/Telemetric.Api/Features/Devices/CreateDevice/CreateDeviceCommandHandler.cs
  - telemetric-api/src/Telemetric.Api/Features/Devices/UpdateDevice/UpdateDeviceCommandHandler.cs
  - telemetric-hub/kiss/connectors/Telemetric.Connectors.Redis/RedisDeviceSyncService.cs
  - telemetric-hub/kiss/Telemetric.Worker.DTE/WorkerApplication.cs
  - telemetric-hub/kiss/connectors/Telemetric.Connectors.ClickHouse/ClickHouseTelemetryWriter.cs

Entregables
- contexto/02_changes/2026-02-04__phase-01__validar-invariantes-id-platform-id__plan.md usando contexto/01_overview/templates/TEMPLATE_CHANGE_PLAN.md.
- contexto/02_changes/2026-02-04__phase-01__validar-invariantes-id-platform-id__summary.md usando contexto/01_overview/templates/TEMPLATE_CHANGE_SUMMARY.md.
- Actualizar contexto/03_hallazgos/pending.md solo si hay hallazgos nuevos o si cambia el estado.

Guardrails
- Max 5 archivos: solo los listados en Alcance.
- No ampliar alcance.
- Prohibido cambiar contratos externos (Redis key patterns, Rabbit routing keys, SignalR group naming) sin migracion explicita.
- Regla de invariantes: si falta platform_id, no persistir / no publicar / no escribir; registrar log/warn/metric.
- Si algun path no existe: buscar y confirmar el path real antes de continuar.

No-go rules
- Tocar archivos fuera del Alcance o superar 5 archivos.
- Cambiar contratos externos sin migracion explicita.
- No poder cumplir la verificacion definida.

Verificacion (pasos manuales)
1. Accion: preparar un dispositivo con platform_id presente (fuente de configuracion actual) y enviar telemetria. API_CALL: <envio de serial.payload con platform_id presente>.
   Expected: el flujo persiste/publica normalmente y no se generan inserts con DeviceId=0.
2. Accion: preparar un dispositivo sin platform_id y enviar telemetria. API_CALL: <envio de serial.payload sin platform_id>.
   Expected: el flujo no persiste/publica; se registra log/warn/metric y no hay inserts con DeviceId=0.
3. Accion: CLICKHOUSE_SQL: <query para contar DeviceId=0 en el rango de prueba>.
   Expected: 0.

Done criteria
- No hay inserts con DeviceId=0 en el rango verificado.
- La telemetria sin platform_id no persiste/publica y deja evidencia (log/warn/metric).
- Plan y summary completados con evidencia de cambios en los archivos listados.

Post-step
- Marcar [x] PHASE-01 en IndexRef.
- Completar/actualizar links de Output (plan y summary) en IndexRef.
