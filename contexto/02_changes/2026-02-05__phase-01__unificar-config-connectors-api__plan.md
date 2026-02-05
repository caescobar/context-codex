# CHANGE PLAN - phase-01__unificar-config-connectors-api - Fase 01

## 0) Metadata
- Fecha: 2026-02-05
- Alcance: PHASE-01
- Modo: refactor-safe + change-control
- Skills: telemetric-backend-style, telemetric-connectors-standard

## 0.1 Trazabilidad del pack
- PackDir: contexto/00_prompts/2026-02-04__pack-audit-pack-inicial-global
- PhaseId: PHASE-01
- IndexRef: contexto/00_prompts/2026-02-04__pack-audit-pack-inicial-global/INDEX.md
- PromptSource: contexto/00_prompts/2026-02-04__pack-audit-pack-inicial-global/phases/phase-01__unificar-config-connectors-api__PHASE__PROMPT.md

## 1) Objetivo
- Unificar el origen de configuracion en API para Redis/Rabbit/ClickHouse y eliminar duplicidad de registro.

## 2) Archivos a tocar (max 5, excepcion autorizada para entregables e indice)
- telemetric-api/src/Telemetric.Api/Program.cs
- telemetric-api/src/Telemetric.Api/Infrastructure/DependencyInjection.cs
- telemetric-api/src/Telemetric.Api/appsettings.json
- contexto/02_changes/2026-02-05__phase-01__unificar-config-connectors-api__plan.md
- contexto/02_changes/2026-02-05__phase-01__unificar-config-connectors-api__summary.md
- contexto/00_prompts/2026-02-04__pack-audit-pack-inicial-global/INDEX.md

## 3) Evidencia (paths)
- Duplicidad Redis/Rabbit en Program: telemetric-api/src/Telemetric.Api/Program.cs
- Registro Redis/ClickHouse en infraestructura: telemetric-api/src/Telemetric.Api/Infrastructure/DependencyInjection.cs
- Config actual Redis/Rabbit/ClickHouse: telemetric-api/src/Telemetric.Api/appsettings.json

## 4) Plan en 5 bullets
1) Mover valores Redis canonicos a appsettings y bindearlos desde IConfiguration.
2) Registrar Redis solo via AddRedisDeviceSyncService en AddInfrastructure.
3) Registrar Rabbit solo via AddRabbitConnection en AddInfrastructure con opciones desde IConfiguration.
4) Eliminar registros manuales duplicados en Program.cs.
5) Documentar cambios en summary e indice.

## 5) Riesgos y mitigaciones
- Riesgo: mala vinculacion de configuracion. Mitigacion: mantener las mismas claves/valores, usar Bind + ConnectionStrings existentes.

## 6) Como verificar (pasos manuales)
1) Accion: levantar la API con los mismos valores de Redis/Rabbit/ClickHouse que antes. Expected: la API inicia sin errores de configuracion y registra conexiones exitosas.
2) Accion: REDIS_CLI: <comando aqui> (ej. `PING` o `INFO`) usando el host/puerto configurado. Expected: respuesta valida desde Redis con la misma configuracion previa.
3) Accion: RABBIT: <verificar conexion o canal> (ej. revisar logs de conexion o management UI). Expected: conexion activa con el broker y sin cambios en exchange/routing.
4) Accion: CLICKHOUSE_SQL: <query aqui> (ej. `SELECT 1`). Expected: respuesta OK desde ClickHouse con la misma cadena de conexion previa.

## 7) No-go rules (si pasa esto, parar)
- Requiere tocar archivos fuera del alcance aprobado.
- Implica cambiar contratos externos sin migracion explicita.
- No se puede cumplir la verificacion manual.

## 8) Post-step (actualizar checklist)
- Marcar `[x]` en `IndexRef` para `PHASE-01`.
- Completar/actualizar links a Plan y Summary en el indice.
