# PENDING / HALLAZGOS â€“ Telemetric

## Convenciones
- ID: HALL-YYYYMMDD-###
- Severidad: High | Medium | Low
- Estado: Open | In Progress | Done | Deferred

---

## HALL-YYYYMMDD-001 â€“ <tÃ­tulo>
- Severidad:
- Estado:
- Bloquea fase actual: SÃ­/No (Â¿cuÃ¡l?)
- SÃ­ntoma:
- Impacto:
- Evidencia (paths/logs):
- Repro:
- Causa raÃ­z (hipÃ³tesis):
- SoluciÃ³n propuesta:
- DecisiÃ³n:
- Notas:

## HALL-20260204-001 ï¿½ ClickHouse puede guardar DeviceId=0 si falta platform_id
- Severidad: High
- Estado: Done
- Bloquea fase actual: No
- Sï¿½ntoma: registros en ClickHouse con `DeviceId=0` cuando el device no tiene `platform_id`.
- Impacto: pï¿½rdida de trazabilidad por dispositivo y queries de histï¿½rico vacï¿½as para el DeviceId real.
- Evidencia (paths/logs): telemetric-hub/kiss/Telemetric.Worker.DTE/WorkerApplication.cs, telemetric-hub/kiss/connectors/Telemetric.Connectors.ClickHouse/ClickHouseTelemetryWriter.cs, telemetric-hub/kiss/scripts/clickhouse/init-clickhouse.sql
- Repro: crear dispositivo sin `platform_id` en Redis, enviar frame `serial.payload`, verificar inserciï¿½n en ClickHouse con `DeviceId=0`.
- Causa raï¿½z (hipï¿½tesis): fallback a serial en DTE + parse int en writer con fallback a 0.
- Soluciï¿½n propuesta: exigir `platform_id` antes de publicar; o persistir serial explï¿½cito y evitar coerciï¿½n a 0.
- Decisión: Aplicar guardas de `platform_id` en Redis sync, DTE y ClickHouse writer (PHASE-01).
- Notas: Cambios implementados; pendiente verificación manual.

## HALL-20260204-002 ï¿½ Redis last-value usa DeviceId del envelope (SQL id) mientras el Hub busca por serial
- Severidad: Medium
- Estado: Open
- Bloquea fase actual: No
- Sï¿½ntoma: snapshot inicial vacï¿½o al suscribirse por serial.
- Impacto: UI sin snapshot aunque exista telemetrï¿½a reciente.
- Evidencia (paths/logs): telemetric-hub/kiss/connectors/Telemetric.Connectors.Redis/RedisLastValueStore.cs, telemetric-hub/kiss/Telemetric.Worker.DTE/WorkerApplication.cs, telemetric-api/src/Telemetric.Api/Features/Telemetry/TelemetryHub.cs
- Repro: con `platform_id` presente, enviar telemetrï¿½a y luego suscribirse por serial; no existe `device:{serial}:last`.
- Causa raï¿½z (hipï¿½tesis): last-value usa `DeviceId` del envelope (SQL id) pero el Hub consulta por serial.
- Soluciï¿½n propuesta: alinear key de last-value con serial o resolver serial ? SQL id antes de consultar.
- Decisiï¿½n:
- Notas:

## HALL-20260204-003 ï¿½ Semï¿½ntica mixta de DeviceId en payload vs routing
- Severidad: Low
- Estado: Open
- Bloquea fase actual: No
- Sï¿½ntoma: `ReceiveTelemetry(DeviceId)` entrega SQL id mientras routing/group usa serial.
- Impacto: consumidores externos pueden asumir una semï¿½ntica equivocada si no mapean.
- Evidencia (paths/logs): telemetric-api/src/Telemetric.Api/Features/Telemetry/TelemetryWorker.cs, telemetric-hub/kiss/Telemetric.Worker.DTE/WorkerApplication.cs, telemetric-front/src/features/telemetry/telemetry.service.ts
- Repro: escuchar SignalR y comparar routing key vs payload.
- Causa raï¿½z (hipï¿½tesis): contrato no documentado explï¿½citamente.
- Soluciï¿½n propuesta: documentar contrato o unificar IDs en payload/routing.
- Decisiï¿½n:
- Notas:

## HALL-20260205-001 - QA AUDIT-07 no ejecutable por entorno local
- Severidad: Medium
- Estado: Open
- Bloquea fase actual: Si (PHASE-01)
- Sintoma: docker compose up/down falla con "Acceso denegado" al engine de Docker; redis-cli no instalado; dotnet run no compila; API https://localhost:7008 no disponible; clickhouse query via docker exec falla.
- Impacto: QA Pack audit-07 no pudo ejecutarse ni validar invariantes de platform_id / DeviceId=0.
- Evidencia (paths/logs): contexto/05_tests/packs/2026-02-05__qa-audit-07-validar-invariantes-id-platform-id/evidence/outputs.log, contexto/05_tests/packs/2026-02-05__qa-audit-07-validar-invariantes-id-platform-id/evidence/hub.err.log, contexto/05_tests/packs/2026-02-05__qa-audit-07-validar-invariantes-id-platform-id/evidence/dte.err.log, contexto/05_tests/packs/2026-02-05__qa-audit-07-validar-invariantes-id-platform-id/evidence/persist.err.log, contexto/05_tests/packs/2026-02-05__qa-audit-07-validar-invariantes-id-platform-id/evidence/clickhouse_results.txt, contexto/05_tests/packs/2026-02-05__qa-audit-07-validar-invariantes-id-platform-id/evidence/commands.log
- Repro: ejecutar QA Pack (setup/run) en este entorno segun QA_PACK.md; los comandos fallan con los errores anteriores.
- Causa raiz (hipotesis): permisos/restricciones de Docker Desktop en el entorno local y errores de compilacion no detallados en stdout.
- Solucion propuesta: habilitar Docker Desktop (permisos) o ejecutar como admin; instalar redis-cli o usar docker exec; correr dotnet build para capturar errores y corregirlos.
- Decision:
- Notas: Rabbit admin API responde OK (ver outputs.log).

## HALL-20260205-002 – Configuración de conectores no unificada entre API y KISS/Workers
- Severidad: Medium
- Estado: Open
- Bloquea fase actual: No
- Síntoma: API usa IConfiguration/appsettings para Redis/Rabbit/ClickHouse, mientras Hub/Workers usan constantes hardcoded.
- Impacto: drift de valores entre hosts; dificultad de reproducir entornos; riesgo de mismatch en despliegue.
- Evidencia (paths/logs): telemetric-api/src/Telemetric.Api/appsettings.json, telemetric-api/src/Telemetric.Api/Program.cs, telemetric-api/src/Telemetric.Api/Infrastructure/DependencyInjection.cs, telemetric-hub/kiss/Telemetric.Hub/Program.cs, telemetric-hub/kiss/Telemetric.Worker.DTE/Program.cs, telemetric-hub/kiss/Telemetric.Worker.Persist/Program.cs
- Repro: comparar valores de `RabbitSettings`/`RedisConnection`/`ClickHouseSettings` con constantes en KISS; no hay validación cruzada.
- Causa raíz (hipótesis): falta de esquema de configuración común por host.
- Solución propuesta: mover KISS/Workers a `IConfiguration` y consolidar Options por host.
- Decisión:
- Notas:

## HALL-20260205-003 – Duplicidad y orden-dependencia en DI de Redis/Rabbit
- Severidad: Medium
- Estado: Open
- Bloquea fase actual: No
- Síntoma: Redis se registra en Program.cs y en AddInfrastructure; Rabbit en Workers se registra dos veces con `TryAddSingleton`.
- Impacto: configuraciones redundantes; el segundo `configure` puede ser ignorado y ocultar divergencias.
- Evidencia (paths/logs): telemetric-api/src/Telemetric.Api/Program.cs, telemetric-api/src/Telemetric.Api/Infrastructure/DependencyInjection.cs, telemetric-hub/kiss/connectors/Telemetric.Connectors.RabbitMQ/RabbitServiceCollectionExtensions.cs, telemetric-hub/kiss/Telemetric.Worker.DTE/Program.cs, telemetric-hub/kiss/Telemetric.Worker.Persist/Program.cs
- Repro: modificar el segundo `configure` en Workers y observar que no aplica por `TryAddSingleton`.
- Causa raíz (hipótesis): falta de regla de “una sola forma de registrar conectores” por host.
- Solución propuesta: unificar en una única llamada por conector y host.
- Decisión:
- Notas:

## HALL-20260205-004 – Hardcodes de valores canónicos (prefix/keys) fuera de configuración
- Severidad: Low
- Estado: Open
- Bloquea fase actual: No
- Síntoma: valores canónicos (prefix/keys/exchange/routing) están embebidos en código.
- Impacto: cambios contractuales requieren despliegue y pueden producir drift si no se propagan.
- Evidencia (paths/logs): telemetric-api/src/Telemetric.Api/Program.cs, telemetric-hub/kiss/Telemetric.Hub/Program.cs, telemetric-hub/kiss/Telemetric.Worker.DTE/Program.cs, telemetric-hub/kiss/Telemetric.Worker.Persist/Program.cs
- Repro: no aplica.
- Causa raíz (hipótesis): configuración no centralizada en Options/appsettings.
- Solución propuesta: mover valores canónicos a configuración por ambiente y documentar contrato.
- Decisión:
- Notas:

## HALL-20260205-005 – Endpoints críticos con AllowAnonymous()
- Severidad: High
- Estado: Open
- Bloquea fase actual: No
- Síntoma: endpoints de Organizations, OrganizationNodes y Telemetry/History permiten acceso sin autenticación.
- Impacto: bypass de autenticación/autorización y exposición de operaciones sensibles.
- Evidencia (paths/logs): telemetric-api/src/Telemetric.Api/Features/Organizations/CreateOrganization/CreateOrganizationEndpoint.cs, telemetric-api/src/Telemetric.Api/Features/Organizations/GetOrganizationById/GetOrganizationByIdEndpoint.cs, telemetric-api/src/Telemetric.Api/Features/Organizations/UpdateOrganization/UpdateOrganizationEndpoint.cs, telemetric-api/src/Telemetric.Api/Features/Organizations/DeleteOrganization/DeleteOrganizationEndpoint.cs, telemetric-api/src/Telemetric.Api/Features/OrganizationNodes/CreateNode/CreateNodeEndpoint.cs, telemetric-api/src/Telemetric.Api/Features/OrganizationNodes/UpdateNode/UpdateNodeEndpoint.cs, telemetric-api/src/Telemetric.Api/Features/OrganizationNodes/DeleteNode/DeleteNodeEndpoint.cs, telemetric-api/src/Telemetric.Api/Features/OrganizationNodes/GetOrganizationTree/GetOrganizationTreeEndpoint.cs, telemetric-api/src/Telemetric.Api/Features/Telemetry/GetHistory/GetHistoryEndpoint.cs
- Repro: invocar endpoints anteriores sin token y observar respuesta 200/OK.
- Causa raíz (hipótesis): endpoints creados con TODO de autorización sin cerrar.
- Solución propuesta: reemplazar `AllowAnonymous()` por `Policies(...)` o requerir autenticación mínima.
- Decisión:
- Notas:

## HALL-20260205-006 – CORS AllowAll + credenciales sin separación por ambiente
- Severidad: Medium
- Estado: Open
- Bloquea fase actual: No
- Síntoma: política CORS “AllowAll” con `AllowCredentials()` y `SetIsOriginAllowed(_ => true)` aplicada globalmente.
- Impacto: cualquier origin puede hacer requests con credenciales en navegadores; riesgo en producción.
- Evidencia (paths/logs): telemetric-api/src/Telemetric.Api/Program.cs
- Repro: preflight desde origin no esperado retorna permitido.
- Causa raíz (hipótesis): política única sin split dev/prod.
- Solución propuesta: definir políticas por ambiente y restringir origins en prod.
- Decisión:
- Notas:

## HALL-20260205-007 – JWT sin validación explícita de Issuer/Audience
- Severidad: Medium
- Estado: Open
- Bloquea fase actual: No
- Síntoma: configuración JWT sólo establece SigningKey; Issuer/Audience existen en config pero no se validan.
- Impacto: tokens firmados con la misma key podrían aceptarse aunque issuer/audience sean incorrectos.
- Evidencia (paths/logs): telemetric-api/src/Telemetric.Api/Program.cs, telemetric-api/src/Telemetric.Api/appsettings.json
- Repro: generar token con issuer distinto y misma firma; verificar aceptación.
- Causa raíz (hipótesis): simplificación de configuración al migrar a FastEndpoints.
- Solución propuesta: configurar validación de Issuer/Audience en el bearer.
- Decisión:
- Notas:

## HALL-20260205-008 – Duplicidad de registro de Authorization en DI
- Severidad: Low
- Estado: Open
- Bloquea fase actual: No
- Síntoma: `IAuthorizationPolicyProvider` y `IAuthorizationHandler` se registran dos veces.
- Impacto: confusión y riesgo de drift si sólo se edita uno de los duplicados.
- Evidencia (paths/logs): telemetric-api/src/Telemetric.Api/Infrastructure/DependencyInjection.cs
- Repro: no aplica.
- Causa raíz (hipótesis): copia/pega durante refactor.
- Solución propuesta: dejar un solo registro por servicio.
- Decisión:
- Notas:

## HALL-20260205-009 – Configuración de hardening inconsistente entre `old/` y `src/`
- Severidad: Low
- Estado: Open
- Bloquea fase actual: No
- Síntoma: `old/` usa CORS restringido y `Jwt` con issuer/audience; `src/` usa `AllowAll` y `JwtSettings` sin validación explícita.
- Impacto: si se referencia `old/` o hay confusión de build, se aplican reglas distintas.
- Evidencia (paths/logs): telemetric-api/old/Telemetric.Api/Program.cs, telemetric-api/src/Telemetric.Api/Program.cs
- Repro: comparar políticas/keys en ambos Program.cs.
- Causa raíz (hipótesis): carpeta legado no aislada del flujo actual.
- Solución propuesta: marcar/retirar `old/` del build o documentar configuración vigente.
- Decisión:
- Notas:
