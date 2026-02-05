# CHANGE PLAN – phase-03__consolidar-esquema-options – Fase 03

## 0) Metadata
- Fecha: 2026-02-05
- Alcance: PHASE-03
- Modo: refactor-safe + change-control
- Skills: telemetric-backend-style, telemetric-connectors-standard

## 0.1 Trazabilidad del pack
- PackDir: contexto/00_prompts/2026-02-04__pack-audit-pack-inicial-global
- PhaseId: PHASE-03
- IndexRef: contexto/00_prompts/2026-02-04__pack-audit-pack-inicial-global/INDEX.md
- PromptSource: contexto/00_prompts/2026-02-04__pack-audit-pack-inicial-global/phases/phase-03__consolidar-esquema-options__PHASE__PROMPT.md

## 1) Objetivo
- Consolidar el esquema unico de Options agregando defaults/SectionName consistentes y cubrir campos usados en config.

## 2) Archivos a tocar (máx 5)
- telemetric-hub/kiss/connectors/Telemetric.Connectors.Abstractions/Options/RedisOptions.cs
- telemetric-hub/kiss/connectors/Telemetric.Connectors.Abstractions/Options/RabbitOptions.cs
- telemetric-hub/kiss/connectors/Telemetric.Connectors.Abstractions/Options/ClickHouseOptions.cs

## 3) Evidencia (paths)
- telemetric-hub/kiss/connectors/Telemetric.Connectors.Redis/RedisServiceCollectionExtensions.cs
- telemetric-hub/kiss/connectors/Telemetric.Connectors.RabbitMQ/RabbitServiceCollectionExtensions.cs
- telemetric-hub/kiss/connectors/Telemetric.Connectors.ClickHouse/ClickHouseServiceCollectionExtensions.cs
- telemetric-hub/kiss/Telemetric.Worker.DTE/appsettings.json
- telemetric-hub/kiss/Telemetric.Worker.Persist/appsettings.json
- telemetric-hub/kiss/Telemetric.Hub/appsettings.json

## 4) Plan en 5 bullets
1) Revisar options actuales y appsettings para detectar gaps de esquema.
2) Definir defaults y SectionName consistentes en las tres Options.
3) Incluir campos faltantes de config (p.ej. InputQueue) sin alterar contratos.
4) Mantener behavior igual (solo defaults/metadata) y sin tocar DI/extensiones.
5) Documentar cambios y preparar summary + actualizar indice.

## 5) Riesgos y mitigaciones
- Riesgo: bajo; solo defaults/metadata. Mitigación: no cambiar nombres de keys/routing ni DI.

## 6) Cómo verificar (pasos manuales)
1) Iniciar Hub/Workers/API con un unico set de parametros (Redis/Rabbit/ClickHouse) ya consolidado en Options. Expected: los tres procesos arrancan sin errores de configuracion.
2) API_CALL: <enviar frame serial.payload al Hub>. Expected: el Hub publica en Rabbit con exchange/routing esperado.
3) RABBIT_CHECK: <inspeccionar mensaje en exchange/queue de telemetry.data con routing correcto>. Expected: se observa mensaje con routing coherente.
4) CLICKHOUSE_SQL: <query de verificacion de insercion reciente>. Expected: existe al menos 1 registro nuevo asociado al frame enviado.
5) API_CALL: <consultar historico desde API>. Expected: el API devuelve el registro asociado al frame enviado.

## 7) No-go rules (si pasa esto, parar)
- Requiere tocar archivos fuera del Alcance o superar 5 archivos.
- Implica cambiar contratos externos sin migracion explicita.
- No se puede cumplir la verificacion definida.

## 8) Post-step (actualizar checklist)
- Marcar `[x]` en `IndexRef` para `PHASE-03`.
- Completar/actualizar links a Plan y Summary en el índice.
