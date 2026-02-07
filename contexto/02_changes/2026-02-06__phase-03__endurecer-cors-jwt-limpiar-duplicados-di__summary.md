# CHANGE SUMMARY – endurecer-cors-jwt-limpiar-duplicados-di – Fase 03

## 0) Metadata
- Fecha: 2026-02-06
- PR/Commit (si aplica):

## 0.1 Trazabilidad del pack
- PackDir: contexto/00_prompts/2026-02-04__pack-audit-pack-inicial-global
- PhaseId: PHASE-03
- IndexRef: contexto/00_prompts/2026-02-04__pack-audit-pack-inicial-global/INDEX.md
- PromptSource: contexto/00_prompts/2026-02-04__pack-audit-pack-inicial-global/phases/phase-03__endurecer-cors-jwt-limpiar-duplicados-di__PHASE__PROMPT.md

## 1) Qué cambió
- CORS ahora usa política por ambiente y restringe orígenes a `Cors:AllowedOrigins` en prod.
- JWT configura validación de issuer/audience usando `TokenValidationParameters`.
- Se eliminó el duplicado de registros de Authorization en DI.
- Se agregó `Cors:AllowedOrigins` en `appsettings.json`.

## 2) Archivos tocados
- telemetric-api/src/Telemetric.Api/Program.cs
- telemetric-api/src/Telemetric.Api/appsettings.json
- telemetric-api/src/Telemetric.Api/Infrastructure/DependencyInjection.cs
- contexto/02_changes/2026-02-06__phase-03__endurecer-cors-jwt-limpiar-duplicados-di__plan.md
- contexto/02_changes/2026-02-06__phase-03__endurecer-cors-jwt-limpiar-duplicados-di__summary.md
- contexto/00_prompts/2026-02-04__pack-audit-pack-inicial-global/INDEX.md

## 3) Cómo probar
1) Configurar entorno prod y ejecutar preflight CORS desde un origin no permitido.
2) Ejecutar preflight CORS desde un origin permitido.
3) Generar token con issuer o audience incorrectos y realizar una llamada protegida.
4) Generar token con issuer y audience válidos y realizar la misma llamada.
5) Revisar DI y registrar services para IAuthorizationPolicyProvider y IAuthorizationHandler.

## 4) Resultado esperado / observado
- Paso 1: Expected: Preflight falla; no se incluye el origin en la respuesta. Observado: No ejecutado (pendiente).
- Paso 2: Expected: Preflight pasa y se incluye el origin permitido. Observado: No ejecutado (pendiente).
- Paso 3: Expected: 401/unauthorized por issuer o audience inválido. Observado: No ejecutado (pendiente).
- Paso 4: Expected: 200/OK (o respuesta autorizada según permisos). Observado: No ejecutado (pendiente).
- Paso 5: Expected: No hay registros duplicados activos. Observado: Código actualizado; verificación manual pendiente.
- Done criteria - CORS solo permite origins esperados. Observado: No ejecutado (pendiente).
- Done criteria - JWT rechaza issuer/audience inválidos. Observado: No ejecutado (pendiente).
- Done criteria - DI sin duplicados. Observado: Código actualizado; verificación manual pendiente.

## 5) Hallazgos nuevos o pendientes
- Sin cambios en pending.md (fuera de alcance de esta fase).

## 6) Riesgo de romper contratos
- No. Cambios limitados a CORS/JWT/DI sin modificar contratos externos.

## 7) Post-step (actualizar checklist)
- Marcar `[x]` en `IndexRef` para `PHASE-03`.
- Completar/actualizar links a Summary en el índice.
