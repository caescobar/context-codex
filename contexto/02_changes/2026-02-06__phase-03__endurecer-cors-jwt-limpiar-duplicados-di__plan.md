# CHANGE PLAN – endurecer-cors-jwt-limpiar-duplicados-di – Fase 03

## 0) Metadata
- Fecha: 2026-02-06
- Alcance: PHASE-03
- Modo: refactor-safe + change-control
- Skills: telemetric-backend-style, refactor-safe

## 0.1 Trazabilidad del pack
- PackDir: contexto/00_prompts/2026-02-04__pack-audit-pack-inicial-global
- PhaseId: PHASE-03
- IndexRef: contexto/00_prompts/2026-02-04__pack-audit-pack-inicial-global/INDEX.md
- PromptSource: contexto/00_prompts/2026-02-04__pack-audit-pack-inicial-global/phases/phase-03__endurecer-cors-jwt-limpiar-duplicados-di__PHASE__PROMPT.md

## 1) Objetivo
- Endurecer CORS/JWT y limpiar duplicados en DI, manteniendo cambios mínimos dentro del alcance.

## 2) Archivos a tocar (máx 5)
- telemetric-api/src/Telemetric.Api/Program.cs
- telemetric-api/src/Telemetric.Api/appsettings.json
- telemetric-api/src/Telemetric.Api/Infrastructure/DependencyInjection.cs

## 3) Evidencia (paths)
- CORS AllowAll + credenciales en `telemetric-api/src/Telemetric.Api/Program.cs`.
- JWT solo con SigningKey en `telemetric-api/src/Telemetric.Api/Program.cs` y settings en `telemetric-api/src/Telemetric.Api/appsettings.json`.
- Duplicado de `IAuthorizationPolicyProvider` y `IAuthorizationHandler` en `telemetric-api/src/Telemetric.Api/Infrastructure/DependencyInjection.cs`.

## 4) Plan en 5 bullets
1) Ajustar CORS por ambiente y leer orígenes permitidos desde configuración.
2) Endurecer validación JWT (issuer/audience) con `TokenValidationParameters`.
3) Añadir `Cors:AllowedOrigins` en `appsettings.json` con valores por defecto de desarrollo.
4) Eliminar duplicado de registros de Authorization en DI.
5) Actualizar plan/summary e índice del pack según change-control.

## 5) Riesgos y mitigaciones
- Riesgo: tokens emitidos sin issuer/audience podrían fallar en validación.
- Mitigación: asegurar que el emisor/audiencia configurados coincidan con la emisión real de tokens; ajustar emisión si aplica en una fase posterior.

## 6) Cómo verificar (pasos manuales)
1) Configurar entorno prod y ejecutar preflight CORS desde un origin no permitido. Expected: Preflight falla; no se incluye el origin en la respuesta.
2) Ejecutar preflight CORS desde un origin permitido. Expected: Preflight pasa y se incluye el origin permitido.
3) Generar token con issuer o audience incorrectos y realizar una llamada protegida. Expected: 401/unauthorized por issuer o audience inválido.
4) Generar token con issuer y audience válidos y realizar la misma llamada. Expected: 200/OK (o respuesta autorizada según permisos).
5) Revisar DI y registrar services para IAuthorizationPolicyProvider y IAuthorizationHandler. Expected: No hay registros duplicados activos.

## 7) No-go rules (si pasa esto, parar)
- Requiere tocar archivos fuera del Alcance o superar 5 archivos.
- Implica cambiar contratos externos sin migración explícita.
- No se puede cumplir la verificación.

## 8) Post-step (actualizar checklist)
- Marcar `[x]` en `IndexRef` para `PHASE-03`.
- Completar/actualizar links a Plan y Summary en el índice.
