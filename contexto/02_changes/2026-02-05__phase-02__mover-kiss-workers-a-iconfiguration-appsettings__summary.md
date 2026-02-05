# CHANGE SUMMARY – mover-kiss-workers-a-iconfiguration-appsettings – Fase 02

## 0) Metadata
- Fecha: 2026-02-05
- PR/Commit (si aplica):

## 0.1 Trazabilidad del pack
- PackDir: contexto/00_prompts/2026-02-04__pack-audit-pack-inicial-global
- PhaseId: PHASE-02        <!-- ej: PHASE-01 -->
- IndexRef: contexto/00_prompts/2026-02-04__pack-audit-pack-inicial-global/INDEX.md      <!-- ej: contexto/00_prompts/.../INDEX.md -->
- PromptSource: contexto/00_prompts/2026-02-04__pack-audit-pack-inicial-global/phases/phase-02__mover-kiss-workers-a-iconfiguration-appsettings__PHASE__PROMPT.md <!-- ej: contexto/00_prompts/.../phase-01__...__PROMPT.md -->

## 1) Qué cambió
- Hub y Workers KISS ahora leen configuración de Redis/Rabbit/ClickHouse desde IConfiguration (secciones `Redis`, `Rabbit`, `ClickHouse`).
- DTE y Persist usan `Host.CreateApplicationBuilder` para acceso a `IConfiguration`.
- InputQueue/NormalizedRoutingKey en Workers se leen desde configuración y son requeridos.
- Se agregaron paquetes Microsoft.Extensions.* a los csproj de Workers para compilar.

## 1.1 Extra (documentado)
- Se agregaron `appsettings.json` mínimos en Hub y workers para incluir `Rabbit`/`Redis`/`ClickHouse`.
- Se configuró el copiado de `appsettings.json` al output en los workers.
- Nota de flujo: este paso debe agregarse al flujo de configuración por ambiente para KISS/Workers/Hub.

## 2) Archivos tocados
- telemetric-hub/kiss/Telemetric.Hub/Program.cs
- telemetric-hub/kiss/Telemetric.Worker.DTE/Program.cs
- telemetric-hub/kiss/Telemetric.Worker.Persist/Program.cs
- telemetric-hub/kiss/Telemetric.Worker.DTE/Telemetric.Worker.DTE.csproj
- telemetric-hub/kiss/Telemetric.Worker.Persist/Telemetric.Worker.Persist.csproj
- telemetric-hub/kiss/Telemetric.Worker.DTE/appsettings.json
- telemetric-hub/kiss/Telemetric.Worker.Persist/appsettings.json
- telemetric-hub/kiss/Telemetric.Hub/appsettings.json
- contexto/02_changes/2026-02-05__phase-02__mover-kiss-workers-a-iconfiguration-appsettings__plan.md
- contexto/02_changes/2026-02-05__phase-02__mover-kiss-workers-a-iconfiguration-appsettings__summary.md
- contexto/00_prompts/2026-02-04__pack-audit-pack-inicial-global/INDEX.md

## 3) Cómo probar
1) Iniciar Telemetric.Hub usando configuraciones por ambiente en appsettings/IConfiguration y observar logs de conexion. Expected: conexiones exitosas a Redis, Rabbit y ClickHouse con los mismos valores de ambiente.
2) Iniciar Telemetric.Worker.DTE usando configuraciones por ambiente en appsettings/IConfiguration y observar logs de conexion. Expected: conexiones exitosas a Redis, Rabbit y ClickHouse con los mismos valores de ambiente.
3) Iniciar Telemetric.Worker.Persist usando configuraciones por ambiente en appsettings/IConfiguration y observar logs de conexion. Expected: conexiones exitosas a Redis, Rabbit y ClickHouse con los mismos valores de ambiente.

## 4) Resultado esperado / observado
- Paso 1 (Hub): esperado = conexiones exitosas a Redis/Rabbit/ClickHouse con valores por ambiente; observado = no ejecutado.
- Paso 2 (Worker DTE): esperado = conexiones exitosas a Redis/Rabbit/ClickHouse con valores por ambiente; observado = no ejecutado.
- Paso 3 (Worker Persist): esperado = conexiones exitosas a Redis/Rabbit/ClickHouse con valores por ambiente; observado = no ejecutado.

## 5) Hallazgos nuevos o pendientes
- Sin hallazgos nuevos.

## 6) Riesgo de romper contratos
- No: no se modificaron keys, exchanges, routing keys o patrones; solo se movió la lectura a IConfiguration.

## 7) Post-step (actualizar checklist)
- Marcar `[x]` en `IndexRef` para `PHASE-02`.
- Completar/actualizar links a Summary en el índice.
