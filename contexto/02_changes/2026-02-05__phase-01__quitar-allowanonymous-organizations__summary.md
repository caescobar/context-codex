# CHANGE SUMMARY – phase-01__quitar-allowanonymous-organizations – Fase 01

## 0) Metadata
- Fecha: 2026-02-05
- PR/Commit (si aplica):

## 0.1 Trazabilidad del pack
- PackDir: contexto/00_prompts/2026-02-04__pack-audit-pack-inicial-global
- PhaseId: PHASE-01
- IndexRef: contexto/00_prompts/2026-02-04__pack-audit-pack-inicial-global/INDEX.md
- PromptSource: contexto/00_prompts/2026-02-04__pack-audit-pack-inicial-global/phases/phase-01__quitar-allowanonymous-organizations__PHASE__PROMPT.md

## 1) Qué cambió
- Se removió AllowAnonymous() en endpoints de Organizations y se añadieron Policies(PermissionClaims.Organizations.*) para exigir autorización.

## 2) Archivos tocados
- telemetric-api/src/Telemetric.Api/Features/Organizations/CreateOrganization/CreateOrganizationEndpoint.cs
- telemetric-api/src/Telemetric.Api/Features/Organizations/GetOrganizationById/GetOrganizationByIdEndpoint.cs
- telemetric-api/src/Telemetric.Api/Features/Organizations/UpdateOrganization/UpdateOrganizationEndpoint.cs
- telemetric-api/src/Telemetric.Api/Features/Organizations/DeleteOrganization/DeleteOrganizationEndpoint.cs

## 3) Cómo probar
1) API_CALL: POST /organizations (sin Authorization) y GET /organizations/{id} (sin Authorization). Expected: 401 o 403 en ambos.
2) API_CALL: PUT /organizations/{id} y DELETE /organizations/{id} sin token. Expected: 401 o 403 en ambos.
3) API_CALL: POST/GET/PUT/DELETE con token válido y permisos adecuados. Expected: 200/OK o 204 según endpoint.

## 4) Resultado esperado / observado
- Paso 1: Expected 401/403. Observado: no ejecutado (pendiente).
- Paso 2: Expected 401/403. Observado: no ejecutado (pendiente).
- Paso 3: Expected 200/OK o 204. Observado: no ejecutado (pendiente).
- Done criteria: pendiente de verificación manual.

## 5) Hallazgos nuevos o pendientes
- Sin hallazgos nuevos.

## 6) Riesgo de romper contratos
- No. No se cambiaron patrones Redis/Rabbit/SignalR ni contratos externos.

## 7) Post-step (actualizar checklist)
- Marcar `[x]` en `IndexRef` para `PHASE-01`.
- Completar/actualizar links a Summary en el índice.
