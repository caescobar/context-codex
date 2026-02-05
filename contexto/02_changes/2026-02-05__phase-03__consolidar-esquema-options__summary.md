# CHANGE SUMMARY – phase-03__consolidar-esquema-options – Fase 03

## 0) Metadata
- Fecha: 2026-02-05
- PR/Commit (si aplica):

## 0.1 Trazabilidad del pack
- PackDir: contexto/00_prompts/2026-02-04__pack-audit-pack-inicial-global
- PhaseId: PHASE-03
- IndexRef: contexto/00_prompts/2026-02-04__pack-audit-pack-inicial-global/INDEX.md
- PromptSource: contexto/00_prompts/2026-02-04__pack-audit-pack-inicial-global/phases/phase-03__consolidar-esquema-options__PHASE__PROMPT.md

## 1) Qué cambió
- Se agregaron SectionName y defaults explícitos en Options.
- RabbitOptions ahora incluye InputQueue para cubrir esquema usado en appsettings.

## 2) Archivos tocados
- telemetric-hub/kiss/connectors/Telemetric.Connectors.Abstractions/Options/RedisOptions.cs
- telemetric-hub/kiss/connectors/Telemetric.Connectors.Abstractions/Options/RabbitOptions.cs
- telemetric-hub/kiss/connectors/Telemetric.Connectors.Abstractions/Options/ClickHouseOptions.cs
- contexto/02_changes/2026-02-05__phase-03__consolidar-esquema-options__plan.md
- contexto/02_changes/2026-02-05__phase-03__consolidar-esquema-options__summary.md

## 3) Cómo probar
1) Iniciar Hub/Workers/API con un unico set de parametros (Redis/Rabbit/ClickHouse) ya consolidado en Options. Expected: los tres procesos arrancan sin errores de configuracion.
2) API_CALL: <enviar frame serial.payload al Hub>. Expected: el Hub publica en Rabbit con exchange/routing esperado.
3) RABBIT_CHECK: <inspeccionar mensaje en exchange/queue de telemetry.data con routing correcto>. Expected: se observa mensaje con routing coherente.
4) CLICKHOUSE_SQL: <query de verificacion de insercion reciente>. Expected: existe al menos 1 registro nuevo asociado al frame enviado.
5) API_CALL: <consultar historico desde API>. Expected: el API devuelve el registro asociado al frame enviado.

## 4) Resultado esperado / observado
- Paso 1: Expected: arranque sin errores. Observado: no ejecutado (pendiente).
- Paso 2: Expected: publica en Rabbit con exchange/routing esperado. Observado: no ejecutado (pendiente).
- Paso 3: Expected: mensaje con routing coherente. Observado: no ejecutado (pendiente).
- Paso 4: Expected: registro nuevo en ClickHouse. Observado: no ejecutado (pendiente).
- Paso 5: Expected: API devuelve registro asociado. Observado: no ejecutado (pendiente).
- Done criteria: smoke test end-to-end con routing correcto + ClickHouse inserta + API lee. Observado: no ejecutado (pendiente).

## 5) Hallazgos nuevos o pendientes
- Sin hallazgos nuevos.

## 6) Riesgo de romper contratos
- No: no se cambiaron keys/routing/queues ni DI; solo defaults/metadata.

## 7) Post-step (actualizar checklist)
- Marcar `[x]` en `IndexRef` para `PHASE-03`.
- Completar/actualizar links a Summary en el índice.
