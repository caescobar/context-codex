PackDir: contexto/00_prompts/2026-02-04__pack-audit-pack-inicial-global
ItemId: AUDIT-07
IndexRef: contexto/00_prompts/2026-02-04__pack-audit-pack-inicial-global/INDEX.md
PromptPath: contexto/00_prompts/2026-02-04__pack-audit-pack-inicial-global/audits/audit-07__qa-pack-validar-invariantes-id-platform-id__AUDIT__PROMPT.md

Modo: docs-only
Skills: telemetric-backend-style, telemetric-connectors-standard

Objetivo
Generar un QA PACK reproducible para validar PHASE-01 (2026-02-04__phase-01__validar-invariantes-id-platform-id), con foco en:
- No generar inserts con DeviceId=0
- Si falta platform_id: no persistir / no publicar y dejar evidencia (log/warn/metric)

Contexto tecnico (fuentes)
- PHASE-01 prompt: contexto/00_prompts/2026-02-04__pack-audit-pack-inicial-global/phases/phase-01__validar-invariantes-id-platform-id__PHASE__PROMPT.md
- CHANGE SUMMARY: contexto/02_changes/2026-02-04__phase-01__validar-invariantes-id-platform-id__summary.md
- Stack: docker-compose + hub + hostigador (simula dispositivo) + redis + rabbit + clickhouse
- Endpoint: POST /api/v1/ingest-raw (formato "serial.payload")
- Redis es fuente de config

Alcance
- Solo documentacion QA en `contexto/05_qa`.
- No tocar codigo ni infra.
- Usar `contexto/01_overview/templates/TEMPLATE_QA_PACK.md` como base.
- Cubrir casos con y sin platform_id.

Entregables
- `contexto/05_qa/2026-02-05__audit-07__qa-pack-validar-invariantes-id-platform-id__qa.md`

Guardrails
- Solo escribir en `contexto/`
- No inventar comandos/queries exactos: buscar y confirmar los reales
- Si no conoces un comando exacto, usar placeholders accionables:
  - DOCKER_COMPOSE: <comando aqui>
  - API_CALL: <curl/postman aqui>
  - REDIS_CLI: <comando aqui>
  - RABBIT_ADMIN: <comando aqui>
  - CLICKHOUSE_SQL: <query aqui>
  - SQL: <query aqui>
  - LOGS: <comando o ubicacion aqui>
- No cambiar contratos externos (Redis key patterns, Rabbit routing keys, SignalR group naming)
- No pedir confirmacion: escribir los archivos en `contexto/` directamente

No-go rules
- Ejecutar pruebas reales (solo documentar pasos)
- Requerir cambios de codigo o superar el alcance docs-only
- No poder derivar pasos reproducibles desde las fuentes base

Tarea
1) Crear el QA PACK en el archivo de entregables con la estructura del TEMPLATE_QA_PACK.md.
2) Incluir Datos de prueba para dos casos:
   - Caso A: con platform_id
   - Caso B: sin platform_id
3) Incluir Verificacion (pasos manuales) con 4-7 pasos, cada paso con Accion + Expected.
   - Debe cubrir: envio con platform_id, envio sin platform_id, verificacion en Redis, verificacion en Rabbit, verificacion en ClickHouse, evidencia en logs/metric
4) Incluir consultas/chequeos que evidencien:
   - No hay inserts nuevos con DeviceId=0
   - Sin platform_id no persiste/publica y deja log/warn/metric
5) Referenciar explicitamente las fuentes (prompt de PHASE y summary) en la seccion "Fuentes".

Post-step
- Marcar [x] AUDIT-07 en IndexRef.
- Completar/actualizar el link de Output en IndexRef.
- Si aparecen hallazgos nuevos, actualizar `contexto/03_hallazgos/pending.md`.
