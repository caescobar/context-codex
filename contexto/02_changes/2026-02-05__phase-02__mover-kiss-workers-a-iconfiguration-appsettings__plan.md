# CHANGE PLAN – mover-kiss-workers-a-iconfiguration-appsettings – Fase 02

## 0) Metadata
- Fecha: 2026-02-05
- Alcance: KISS Hub + Workers (config Redis/Rabbit/ClickHouse)
- Modo: refactor-safe + change-control
- Skills: refactor-safe, telemetric-backend-style, telemetric-connectors-standard

## 0.1 Trazabilidad del pack
- PackDir: contexto/00_prompts/2026-02-04__pack-audit-pack-inicial-global
- PhaseId: PHASE-02        <!-- ej: PHASE-01 -->
- IndexRef: contexto/00_prompts/2026-02-04__pack-audit-pack-inicial-global/INDEX.md      <!-- ej: contexto/00_prompts/.../INDEX.md -->
- PromptSource: contexto/00_prompts/2026-02-04__pack-audit-pack-inicial-global/phases/phase-02__mover-kiss-workers-a-iconfiguration-appsettings__PHASE__PROMPT.md <!-- ej: contexto/00_prompts/.../phase-01__...__PROMPT.md -->

## 1) Objetivo
- Mover la configuración de Redis/Rabbit/ClickHouse en Hub y Workers KISS a IConfiguration/appsettings sin hardcodes en Program.cs.

## 2) Archivos a tocar (máx 5)
- telemetric-hub/kiss/Telemetric.Hub/Program.cs
- telemetric-hub/kiss/Telemetric.Worker.DTE/Program.cs
- telemetric-hub/kiss/Telemetric.Worker.Persist/Program.cs
- telemetric-hub/kiss/Telemetric.Worker.DTE/Telemetric.Worker.DTE.csproj
- telemetric-hub/kiss/Telemetric.Worker.Persist/Telemetric.Worker.Persist.csproj

## 2.1 Extra (alcance ampliado)
- telemetric-hub/kiss/Telemetric.Worker.DTE/appsettings.json
- telemetric-hub/kiss/Telemetric.Worker.Persist/appsettings.json
- telemetric-hub/kiss/Telemetric.Hub/appsettings.json

## 3) Evidencia (paths)
- telemetric-hub/kiss/Telemetric.Hub/Program.cs (consts hardcode de Redis/Rabbit)
- telemetric-hub/kiss/Telemetric.Worker.DTE/Program.cs (consts hardcode de Redis/Rabbit + queue/routing)
- telemetric-hub/kiss/Telemetric.Worker.Persist/Program.cs (consts hardcode de Redis/Rabbit/ClickHouse)
- telemetric-hub/kiss/Telemetric.Worker.DTE/Telemetric.Worker.DTE.csproj (faltan paquetes Hosting/Configuration + copiar appsettings)
- telemetric-hub/kiss/Telemetric.Worker.Persist/Telemetric.Worker.Persist.csproj (faltan paquetes Hosting/Configuration + copiar appsettings)
- telemetric-hub/kiss/Telemetric.Worker.DTE/appsettings.json (config requerida por InputQueue/NormalizedRoutingKey)
- telemetric-hub/kiss/Telemetric.Worker.Persist/appsettings.json (config requerida por InputQueue/NormalizedRoutingKey)
- telemetric-hub/kiss/Telemetric.Hub/appsettings.json (config requerida por Rabbit/Redis)
- telemetric-hub/kiss/connectors/Telemetric.Connectors.Abstractions/Options/RedisOptions.cs (nombres canónicos)
- telemetric-hub/kiss/connectors/Telemetric.Connectors.Abstractions/Options/RabbitOptions.cs (nombres canónicos)
- telemetric-hub/kiss/connectors/Telemetric.Connectors.Abstractions/Options/ClickHouseOptions.cs (nombres canónicos)

## 4) Plan en 5 bullets
1) Introducir IConfiguration en Hub y bindear secciones Rabbit/Redis para DI.
2) Migrar DTE a Host.CreateApplicationBuilder + IConfiguration y bindear Rabbit/Redis.
3) Migrar Persist a Host.CreateApplicationBuilder + IConfiguration y bindear Rabbit/Redis/ClickHouse.
4) Leer InputQueue/NormalizedRoutingKey desde IConfiguration y validar que existan.
5) Agregar paquetes Microsoft.Extensions.* requeridos en csproj de workers.

## 4.1 Extra
- Agregar `appsettings.json` mínimos en Hub y workers con `Rabbit`/`Redis`/`ClickHouse` según corresponda.
- Copiar `appsettings.json` al output para que IConfiguration lo cargue en ejecución.

## 5) Riesgos y mitigaciones
- Riesgo: claves de configuración faltantes impidan iniciar los workers.
- Mitigación: documentar claves requeridas en appsettings/env y verificar conexiones por ambiente.

## 6) Cómo verificar (pasos manuales)
1) Iniciar Telemetric.Hub usando configuraciones por ambiente en appsettings/IConfiguration y observar logs de conexion. Expected: conexiones exitosas a Redis, Rabbit y ClickHouse con los mismos valores de ambiente.
2) Iniciar Telemetric.Worker.DTE usando configuraciones por ambiente en appsettings/IConfiguration y observar logs de conexion. Expected: conexiones exitosas a Redis, Rabbit y ClickHouse con los mismos valores de ambiente.
3) Iniciar Telemetric.Worker.Persist usando configuraciones por ambiente en appsettings/IConfiguration y observar logs de conexion. Expected: conexiones exitosas a Redis, Rabbit y ClickHouse con los mismos valores de ambiente.

## 7) No-go rules (si pasa esto, parar)
- Requiere tocar archivos fuera del Alcance o superar 5 archivos (excepto el extra documentado).
- Implica cambiar contratos externos (Redis keys / Rabbit routing / SignalR groups) sin migración explícita.
- No se puede cumplir la verificación.

## 8) Post-step (actualizar checklist)
- Marcar `[x]` en `IndexRef` para `PHASE-02`.
- Completar/actualizar links a Plan y Summary en el índice.
