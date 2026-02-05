# PHASE PROMPT — phase-03__consolidar-esquema-options

PackDir: contexto/00_prompts/2026-02-04__pack-audit-pack-inicial-global
ItemId: PHASE-03
IndexRef: contexto/00_prompts/2026-02-04__pack-audit-pack-inicial-global/INDEX.md
PromptPath: contexto/00_prompts/2026-02-04__pack-audit-pack-inicial-global/phases/phase-03__consolidar-esquema-options__PHASE__PROMPT.md

## Modo
refactor-safe + change-control

## Skills
telemetric-backend-style, telemetric-connectors-standard

## Objetivo
Consolidar un esquema unico de Options (reusar extensiones de conectores y validar defaults).

## Alcance (max 5 archivos de codigo)
- telemetric-hub/kiss/connectors/Telemetric.Connectors.Abstractions/Options/RedisOptions.cs
- telemetric-hub/kiss/connectors/Telemetric.Connectors.Abstractions/Options/RabbitOptions.cs
- telemetric-hub/kiss/connectors/Telemetric.Connectors.Abstractions/Options/ClickHouseOptions.cs

## Entregables
- contexto/02_changes/2026-02-05__phase-03__consolidar-esquema-options__plan.md (usar contexto/01_overview/templates/TEMPLATE_CHANGE_PLAN.md)
- contexto/02_changes/2026-02-05__phase-03__consolidar-esquema-options__summary.md (usar contexto/01_overview/templates/TEMPLATE_CHANGE_SUMMARY.md)

## Guardrails
- Max 5 archivos (solo los listados en Alcance)
- No ampliar alcance
- Prohibido cambiar contratos externos (Redis key patterns, Rabbit routing keys, SignalR group naming) sin migracion explicita
- Si algun path no existe: buscar y confirmar el path real antes de continuar

## No-go rules
- Requiere tocar archivos fuera del Alcance o superar 5 archivos
- Implica cambiar contratos externos sin migracion explicita
- No se puede cumplir la verificacion definida

## Verificacion (pasos manuales)
1. Accion: iniciar Hub/Workers/API con un unico set de parametros (Redis/Rabbit/ClickHouse) ya consolidado en Options. Expected: los tres procesos arrancan sin errores de configuracion.
2. Accion: API_CALL: <enviar frame serial.payload al Hub>. Expected: el Hub publica en Rabbit con exchange/routing esperado.
3. Accion: RABBIT_CHECK: <inspeccionar mensaje en exchange/queue de telemetry.data con routing correcto>. Expected: se observa mensaje con routing coherente.
4. Accion: CLICKHOUSE_SQL: <query de verificacion de insercion reciente>. Expected: existe al menos 1 registro nuevo asociado al frame enviado.
5. Accion: API_CALL: <consultar historico desde API>. Expected: el API devuelve el registro asociado al frame enviado.

## Done criteria
- El smoke test end-to-end pasa con routing correcto en Rabbit.
- ClickHouse registra el evento y el API lo puede leer.
- No se cambiaron contratos externos ni se toco fuera del Alcance.

## Tarea (ejecutor)
1. Ejecutar cambios minimos para cumplir el objetivo limitado al Alcance.
2. Completar plan + summary usando templates (con evidencia paths).
3. En summary: resultado observado vs expected para cada paso de verificacion + Done criteria.

## Post-step obligatorio
- Marcar [x] PHASE-03 en IndexRef
- Completar/actualizar links de Output (plan y summary) en el indice
- Actualizar contexto/03_hallazgos/pending.md solo si hay hallazgos nuevos o si el estado cambia
