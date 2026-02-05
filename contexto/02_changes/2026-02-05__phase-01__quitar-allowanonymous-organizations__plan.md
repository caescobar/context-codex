# CHANGE PLAN – phase-01__quitar-allowanonymous-organizations – Fase 01

## 0) Metadata
- Fecha: 2026-02-05
- Alcance: PHASE-01 Quitar AllowAnonymous en Organizations
- Modo: refactor-safe + change-control
- Skills: telemetric-backend-style

## 0.1 Trazabilidad del pack
- PackDir: contexto/00_prompts/2026-02-04__pack-audit-pack-inicial-global
- PhaseId: PHASE-01
- IndexRef: contexto/00_prompts/2026-02-04__pack-audit-pack-inicial-global/INDEX.md
- PromptSource: contexto/00_prompts/2026-02-04__pack-audit-pack-inicial-global/phases/phase-01__quitar-allowanonymous-organizations__PHASE__PROMPT.md

## 1) Objetivo
- Quitar AllowAnonymous() en endpoints de Organizations y exigir autenticación/autorización con Policies apropiadas.

## 2) Archivos a tocar (máx 5)
- telemetric-api/src/Telemetric.Api/Features/Organizations/CreateOrganization/CreateOrganizationEndpoint.cs
- telemetric-api/src/Telemetric.Api/Features/Organizations/GetOrganizationById/GetOrganizationByIdEndpoint.cs
- telemetric-api/src/Telemetric.Api/Features/Organizations/UpdateOrganization/UpdateOrganizationEndpoint.cs
- telemetric-api/src/Telemetric.Api/Features/Organizations/DeleteOrganization/DeleteOrganizationEndpoint.cs

## 3) Evidencia (paths)
- telemetric-api/src/Telemetric.Api/Features/Organizations/GetOrganizations/GetOrganizationsEndpoint.cs
- telemetric-api/src/Telemetric.Api/Features/Clients/CreateClient/CreateClientEndpoint.cs
- telemetric-api/src/Telemetric.Api/Domain/Constants/PermissionClaims.cs

## 4) Plan en 5 bullets
1) Revisar endpoints similares con Policies para mantener el estilo del repo.
2) Reemplazar AllowAnonymous() por Policies(PermissionClaims.Organizations.*) según el tipo de operación.
3) Verificar imports de PermissionClaims en los 4 endpoints.
4) Documentar cambios en plan y summary usando templates.
5) Actualizar INDEX.md con links y checkbox de la fase.

## 5) Riesgos y mitigaciones
- Riesgo: clientes sin token válido recibirán 401/403.
- Mitigación: validar con los pasos manuales de verificación y confirmar permisos correctos.

## 6) Cómo verificar (pasos manuales)
1) API_CALL: POST /organizations (sin Authorization) y GET /organizations/{id} (sin Authorization). Expected: 401 o 403 en ambos.
2) API_CALL: PUT /organizations/{id} y DELETE /organizations/{id} sin token. Expected: 401 o 403 en ambos.
3) API_CALL: POST/GET/PUT/DELETE con token válido y permisos adecuados. Expected: 200/OK o 204 según endpoint.

## 7) No-go rules (si pasa esto, parar)
- Requiere tocar archivos fuera del Alcance o superar 5 archivos.
- Implica cambiar contratos externos sin migración explícita.
- No se puede cumplir la verificación.

## 8) Post-step (actualizar checklist)
- Marcar `[x]` en `IndexRef` para `PHASE-01`.
- Completar/actualizar links a Plan y Summary en el índice.
