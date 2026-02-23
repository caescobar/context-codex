# ACT-002 - Checklist QA runtime anti-spam y rehidratacion (Fase 04)

## Objetivo
Validar de forma reproducible los AC de runtime de `ACT-002`: flapping sin spam, cooldown, latch + `Resolve manual`, rehidratacion por `RuleCheckpoint` y trazabilidad en `ActionAttempt`.

## Precondiciones
1. Ejecutar desde la raiz del repo.
2. Tener `dotnet`, `sqlcmd`, `docker` y acceso a Redis (`redis-cli` local o en contenedor).
3. Servicios activos: API, worker de acciones, SQL Server, Redis y RabbitMQ.
4. Contar con usuario API valido con permiso `Actions.ResolveManual`.

## Setup
1. Seed de datos para latch y permiso:
   - Comando: `sqlcmd -S . -d TelemetricDb -E -i contexto/work/features/acciones_modulo/04_test/ACT-002-phase-03-seed.sql`
   - Esperado: salida con `RuleInstanceId_ReadyForSmoke`.
2. Levantar/confirmar worker de acciones:
   - Comando: `dotnet run --project telemetric-hub/kiss/Telemetric.Worker.Actions/Telemetric.Worker.Actions.csproj`
3. Levantar/confirmar API:
   - Comando: `dotnet run --project telemetric-api/src/Telemetric.Api/Telemetric.Api.csproj`

## Ejecucion y verificaciones
1. AC flapping sin spam (auto-reset)
   - Publicar secuencia `OK -> VIOLATION -> VIOLATION -> OK -> VIOLATION` para la misma `RuleInstance`.
   - Verificar en DB que no hay duplicados de disparo durante violacion continua:
     - `SELECT RuleInstanceId, COUNT(*) AS Attempts FROM ActionAttempt WHERE RuleInstanceId = <RULE_INSTANCE_ID> GROUP BY RuleInstanceId;`
   - Esperado: solo se incrementa en transiciones validas `OK -> VIOLATION`.

2. AC cooldown (supresion temporal)
   - Provocar dos violaciones dentro de la ventana `CooldownSeconds`.
   - Verificar en `RuleCheckpoint.StateJson` ventana activa:
     - `SELECT TOP 1 StateJson FROM RuleCheckpoint WHERE RuleInstanceId = <RULE_INSTANCE_ID>;`
   - Esperado: el segundo disparo queda suprimido dentro de la ventana.

3. AC latch + resolve invalido (permanece ACTIVE)
   - Ejecutar smoke del endpoint para forzar `resolveRequested=1`:
     - `powershell -ExecutionPolicy Bypass -File contexto/work/features/acciones_modulo/04_test/ACT-002-phase-03-smoke.ps1 -RuleInstanceId <RULE_INSTANCE_ID>`
   - Mantener condicion en violacion y verificar que no rearma:
     - Redis: `HGET actions:runtime:rule:<RULE_INSTANCE_ID> latchActive`
     - Redis: `HGET actions:runtime:rule:<RULE_INSTANCE_ID> resolveRequested`
   - Esperado: `latchActive=1` mientras la condicion sigue en violacion.

4. AC latch + resolve valido (rearme en OK)
   - Llevar condicion a `OK` y volver a solicitar resolve manual.
   - Verificar limpieza de latch en Redis y continuidad de evaluacion:
     - `HGET actions:runtime:rule:<RULE_INSTANCE_ID> latchActive`
   - Esperado: `latchActive=0` tras resolve valido con condicion `OK`.

5. AC rehidratacion tras caida Redis
   - Reiniciar Redis (o limpiar key runtime de la regla):
     - `docker restart telemetric-redis`
   - Enviar nueva telemetria para la regla.
   - Verificar que el estado se reconstruye desde SQL:
     - `SELECT TOP 1 CheckpointedAt, StateJson FROM RuleCheckpoint WHERE RuleInstanceId = <RULE_INSTANCE_ID> ORDER BY RuleCheckpointId DESC;`
   - Esperado: el flujo continua sin perder semantica de lifecycle.

6. AC trazabilidad de `ActionAttempt` success/fail
   - Consultar intentos recientes:
     - `SELECT TOP 20 ActionAttemptId, RuleInstanceId, Status, Error, AttemptedAt FROM ActionAttempt WHERE RuleInstanceId = <RULE_INSTANCE_ID> ORDER BY ActionAttemptId DESC;`
   - Esperado:
     - `Status` solo en (`Success`, `Fail`).
     - Si `Status='Fail'`, `Error` no nulo.

## Evidencia minima a adjuntar
1. Log del worker mostrando evaluacion y eventos de latch/rearme.
2. Salida PASS/FAIL del smoke `ACT-002-phase-03-smoke.ps1`.
3. Resultados SQL de `RuleCheckpoint` y `ActionAttempt`.
4. Captura de valores Redis (`latchActive`, `resolveRequested`).
