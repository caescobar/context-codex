# PHASE PROMPT — phase-01__unificar-config-connectors-api

PackDir: contexto/00_prompts/2026-02-04__pack-audit-pack-inicial-global
ItemId: PHASE-01
IndexRef: contexto/00_prompts/2026-02-04__pack-audit-pack-inicial-global/INDEX.md
PromptPath: contexto/00_prompts/2026-02-04__pack-audit-pack-inicial-global/phases/phase-01__unificar-config-connectors-api__PHASE__PROMPT.md

## Modo
refactor-safe + change-control

## Skills
- telemetric-backend-style
- telemetric-connectors-standard

## Objetivo
Unificar el origen de configuración en API (Redis/Rabbit/ClickHouse) y eliminar duplicidad.

## Alcance (max 5 archivos)
- telemetric-api/src/Telemetric.Api/Program.cs
- telemetric-api/src/Telemetric.Api/Infrastructure/DependencyInjection.cs
- telemetric-api/src/Telemetric.Api/appsettings.json

## Entregables (archivos exactos)
- contexto/02_changes/2026-02-05__phase-01__unificar-config-connectors-api__plan.md (usar contexto/01_overview/templates/TEMPLATE_CHANGE_PLAN.md)
- contexto/02_changes/2026-02-05__phase-01__unificar-config-connectors-api__summary.md (usar contexto/01_overview/templates/TEMPLATE_CHANGE_SUMMARY.md)

## Guardrails
- Max 5 archivos y solo los listados en Alcance
- No ampliar alcance
- Prohibido cambiar contratos externos (Redis key patterns, Rabbit routing keys, SignalR group naming) sin migracion explicita
- Si algun path no existe: buscar y confirmar el path real antes de continuar

## No-go rules
- Si requiere tocar archivos fuera del Alcance o superar 5 archivos
- Si implica cambiar contratos externos sin migracion explicita
- Si no se puede cumplir la verificacion

## Verificacion (pasos manuales)
1. Accion: levantar la API con los mismos valores de Redis/Rabbit/ClickHouse que antes. Expected: la API inicia sin errores de configuracion y registra conexiones exitosas.
2. Accion: REDIS_CLI: <comando aqui> (ej. `PING` o `INFO`) usando el host/puerto configurado. Expected: respuesta valida desde Redis con la misma configuracion previa.
3. Accion: RABBIT: <verificar conexion o canal> (ej. revisar logs de conexion o management UI). Expected: conexion activa con el broker y sin cambios en exchange/routing.
4. Accion: CLICKHOUSE_SQL: <query aqui> (ej. `SELECT 1`). Expected: respuesta OK desde ClickHouse con la misma cadena de conexion previa.

## Done criteria
- Configuracion unificada en una sola fuente por conector dentro de API sin duplicidad de registro
- La API arranca y valida conectividad Redis/Rabbit/ClickHouse con los mismos valores que antes
- La verificacion manual coincide con Expected en todos los pasos

## Tarea (ejecutor)
1) Ejecutar cambios minimos para cumplir el objetivo limitado al Alcance.
2) Completar plan y summary usando los templates indicados, con evidencia y paths exactos.
3) En el summary: resultado observado vs expected para cada paso de verificacion + Done criteria.

## Post-step obligatorio
- Marcar `[x]` PHASE-01 en IndexRef
- Completar/actualizar links de Output (plan y summary) en el indice
