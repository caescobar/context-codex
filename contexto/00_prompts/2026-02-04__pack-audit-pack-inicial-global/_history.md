# History

Fecha: 2026-02-04

Input original
Quiero reconstruir el set “inicial” de 6 auditorias globales de Telemetric (las que ya definimos antes) pero ahora en el flujo nuevo con packs + INDEX checklist.
No ejecutes auditorias, solo genera los prompts y el indice.

Auditorias a reconstruir (globales):
1) Backend: Contrato de Identidad y Telemetria (serial vs SQL id)
2) Backend: Unificacion DI/Configuracion de Connectors (API + KISS/Workers)
3) Backend: Hardening minimo (CORS/JWT/EF auditoria/Authorization duplicada)
4) Frontend: Estandar HTTP (AXIOS CORE unico) + contrato de errores
5) Frontend: Maps (estructura, lifecycle, performance, leaks)
6) Cleanup global (inventario, sin borrar)

Requisitos:
- Crear pack folder con slug: audit-pack-inicial-global
- Dentro del pack crear INDEX.md con checkboxes [ ] para los 6 AUDIT-01..AUDIT-06
- Generar 6 prompts executor (AUDIT) guardados en el pack, uno por auditoria
- Cada prompt debe:
  - Modo: docs-only
  - No tocar codigo
  - Crear su reporte en contexto/01_audits/YYYY-MM-DD__audit-XX__<slug>.md usando TEMPLATE_AUDIT_REPORT
  - Actualizar pending.md solo si hay hallazgos nuevos
  - Post-step: marcar [x] su item en el INDEX del pack y linkear el output

Guardrails:
- No inventar paths; obligar a encontrar y citar paths reales durante la ejecucion.
- No pedir confirmacion.

Clasificacion
AUDIT

Rationale
- El objetivo es generar prompts ejecutores de auditorias, no ejecutar cambios ni implementar funcionalidades.
- Se requiere un pack con multiples items AUDIT y su indice.

PROMPT FINAL
(Ver builder_prompt.md)

---

Fecha: 2026-02-04

Input original
Usar PackDir existente: contexto/00_prompts/2026-02-04__pack-audit-pack-inicial-global/
Quiero generar el PROMPT FINAL para ejecutar PHASE-01 basada en el AUDIT-01 (2026-02-04), seccion "Plan sugerido por fases", Fase 1.
Usa exactamente el objetivo/archivos/verificacion definidos ahi, sin ampliar alcance.

Clasificacion
PHASE

Rationale
- Se solicita ejecutar una fase concreta definida en un audit, con objetivo, archivos y verificacion ya delimitados.
- El alcance esta acotado a cambios en codigo con maximo 5 archivos y entregables de plan/summary.

PROMPT FINAL
PackDir: contexto/00_prompts/2026-02-04__pack-audit-pack-inicial-global/
ItemId: PHASE-01
IndexRef: contexto/00_prompts/2026-02-04__pack-audit-pack-inicial-global/INDEX.md
PromptPath: contexto/00_prompts/2026-02-04__pack-audit-pack-inicial-global/phase-01__validar-invariantes-id-platform-id__PHASE__PROMPT.md

Modo: refactor-safe + change-control
Skills: telemetric-backend-style, telemetric-connectors-standard

Objetivo
- Validar invariantes de ID (platform_id obligatorio para persistencia).

Alcance (archivos de codigo, max 5, exactos)
- telemetric-api/src/Telemetric.Api/Features/Devices/CreateDevice/CreateDeviceCommandHandler.cs
- telemetric-api/src/Telemetric.Api/Features/Devices/UpdateDevice/UpdateDeviceCommandHandler.cs
- telemetric-hub/kiss/connectors/Telemetric.Connectors.Redis/RedisDeviceSyncService.cs
- telemetric-hub/kiss/Telemetric.Worker.DTE/WorkerApplication.cs
- telemetric-hub/kiss/connectors/Telemetric.Connectors.ClickHouse/ClickHouseTelemetryWriter.cs

Entregables
- contexto/02_changes/2026-02-04__phase-01__validar-invariantes-id-platform-id__plan.md (usar contexto/01_overview/templates/TEMPLATE_CHANGE_PLAN.md)
- contexto/02_changes/2026-02-04__phase-01__validar-invariantes-id-platform-id__summary.md (usar contexto/01_overview/templates/TEMPLATE_CHANGE_SUMMARY.md)
- Actualizar contexto/03_hallazgos/pending.md solo si hay hallazgos nuevos

Guardrails
- No ampliar alcance: usar exactamente objetivo, archivos y verificacion indicados.
- Maximo 5 archivos de codigo: solo los listados en Alcance.
- Prohibido cambiar contratos externos (Redis key patterns, Rabbit routing keys, SignalR group naming) sin migracion explicita.
- Si algun path no existe, buscar y confirmar el path real antes de continuar.

Regla de invariantes
- Si falta platform_id: no persistir / no publicar / no escribir y registrar log/warn/metric (sin introducir nuevos contratos).

No-go rules
- Si requiere tocar un archivo fuera de Alcance o superar 5 archivos.
- Si implica cambiar contratos externos sin migracion explicita.
- Si no se puede cumplir la verificacion exacta.

Verificacion (pasos manuales)
1. Accion: enviar telemetria con platform_id presente (API_CALL: <curl/postman aqui> o flujo equivalente). Expected: la telemetria ingresa sin errores.
2. Accion: consultar ClickHouse para registros recientes del dispositivo y para DeviceId=0 (CLICKHOUSE_SQL: <query aqui>). Expected: hay registros para DeviceId valido y 0 registros nuevos con DeviceId=0.
3. Accion: enviar telemetria sin platform_id (API_CALL: <curl/postman aqui> o flujo equivalente). Expected: no se persiste en ClickHouse y se registra log/warn/metric de invariante.
4. Accion: volver a consultar ClickHouse para DeviceId=0 en el rango reciente (CLICKHOUSE_SQL: <query aqui>). Expected: sigue en 0 inserts con DeviceId=0.

Tarea
1) Ejecutar cambios minimos para hacer obligatorio platform_id antes de persistir, limitandote al Alcance.
2) Completar el plan y summary usando los templates indicados, con evidencia (paths) y resultados observados vs expected para cada paso de verificacion.

Post-step (obligatorio)
- Marcar [x] el item PHASE-01 en IndexRef.
- Completar/actualizar links de Output (plan y summary) en el indice.
