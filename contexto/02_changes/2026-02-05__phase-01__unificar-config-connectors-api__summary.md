# CHANGE SUMMARY - phase-01__unificar-config-connectors-api - Fase 01

## 0) Metadata
- Fecha: 2026-02-05
- PR/Commit (si aplica):

## 0.1 Trazabilidad del pack
- PackDir: contexto/00_prompts/2026-02-04__pack-audit-pack-inicial-global
- PhaseId: PHASE-01
- IndexRef: contexto/00_prompts/2026-02-04__pack-audit-pack-inicial-global/INDEX.md
- PromptSource: contexto/00_prompts/2026-02-04__pack-audit-pack-inicial-global/phases/phase-01__unificar-config-connectors-api__PHASE__PROMPT.md

## 1) Que cambio
- Redis y Rabbit pasan a registrarse solo en AddInfrastructure usando extensiones estandar.
- RedisOptions se alimenta desde appsettings (RedisSettings) + ConnectionStrings.
- Se removio el registro manual duplicado en Program.cs.

## 2) Archivos tocados
- telemetric-api/src/Telemetric.Api/Program.cs
- telemetric-api/src/Telemetric.Api/Infrastructure/DependencyInjection.cs
- telemetric-api/src/Telemetric.Api/appsettings.json
- contexto/02_changes/2026-02-05__phase-01__unificar-config-connectors-api__plan.md
- contexto/02_changes/2026-02-05__phase-01__unificar-config-connectors-api__summary.md
- contexto/00_prompts/2026-02-04__pack-audit-pack-inicial-global/INDEX.md

## 3) Como probar
1) Accion: levantar la API con los mismos valores de Redis/Rabbit/ClickHouse que antes. Expected: la API inicia sin errores de configuracion y registra conexiones exitosas.
2) Accion: REDIS_CLI: <comando aqui> (ej. `PING` o `INFO`) usando el host/puerto configurado. Expected: respuesta valida desde Redis con la misma configuracion previa.
3) Accion: RABBIT: <verificar conexion o canal> (ej. revisar logs de conexion o management UI). Expected: conexion activa con el broker y sin cambios en exchange/routing.
4) Accion: CLICKHOUSE_SQL: <query aqui> (ej. `SELECT 1`). Expected: respuesta OK desde ClickHouse con la misma cadena de conexion previa.

## 4) Resultado esperado / observado
- Paso 1: Expected: API inicia sin errores de configuracion y registra conexiones exitosas. Observado: no ejecutado.
- Paso 2: Expected: respuesta valida desde Redis con la misma configuracion previa. Observado: no ejecutado.
- Paso 3: Expected: conexion activa con el broker y sin cambios en exchange/routing. Observado: no ejecutado.
- Paso 4: Expected: respuesta OK desde ClickHouse con la misma cadena de conexion previa. Observado: no ejecutado.

## 4.1) Done criteria
- Configuracion unificada en una sola fuente por conector dentro de API sin duplicidad de registro: cumplido.
- La API arranca y valida conectividad Redis/Rabbit/ClickHouse con los mismos valores que antes: no verificado (no ejecutado).
- La verificacion manual coincide con Expected en todos los pasos: no verificado (no ejecutado).

## 5) Hallazgos nuevos o pendientes
- Ninguno.

## 6) Riesgo de romper contratos
- No. No se cambiaron keys, routing keys ni nombres de grupos.

## 7) Post-step (actualizar checklist)
- Marcar `[x]` en `IndexRef` para `PHASE-01`.
- Completar/actualizar links a Summary en el indice.
