# CHANGE SUMMARY - phase-02__quitar-allowanonymous-organizationnodes-telemetry-history - Fase 02

## 0) Metadata
- Fecha: 2026-02-05
- PR/Commit (si aplica):

## 0.1 Trazabilidad del pack
- PackDir: contexto/00_prompts/2026-02-04__pack-audit-pack-inicial-global
- PhaseId: PHASE-02
- IndexRef: contexto/00_prompts/2026-02-04__pack-audit-pack-inicial-global/INDEX.md
- PromptSource: contexto/00_prompts/2026-02-04__pack-audit-pack-inicial-global/phases/phase-02__quitar-allowanonymous-organizationnodes-telemetry-history__PHASE__PROMPT.md

## 1) Que cambio
- Se removio AllowAnonymous() en endpoints de OrganizationNodes y Telemetry/History para exigir autenticacion.

## 2) Archivos tocados
- telemetric-api/src/Telemetric.Api/Features/OrganizationNodes/CreateNode/CreateNodeEndpoint.cs
- telemetric-api/src/Telemetric.Api/Features/OrganizationNodes/UpdateNode/UpdateNodeEndpoint.cs
- telemetric-api/src/Telemetric.Api/Features/OrganizationNodes/DeleteNode/DeleteNodeEndpoint.cs
- telemetric-api/src/Telemetric.Api/Features/OrganizationNodes/GetOrganizationTree/GetOrganizationTreeEndpoint.cs
- telemetric-api/src/Telemetric.Api/Features/Telemetry/GetHistory/GetHistoryEndpoint.cs

## 3) Como probar
1) API_CALL: endpoints de OrganizationNodes sin token. Expected: 401/403.
2) API_CALL: /api/v1/telemetry/history sin token. Expected: 401/403.
3) API_CALL: OrganizationNodes y Telemetry/History con token valido. Expected: 200 OK.

## 4) Resultado esperado / observado
- Paso 1: Expected 401/403. Observado: no ejecutado (pendiente).
- Paso 2: Expected 401/403. Observado: no ejecutado (pendiente).
- Paso 3: Expected 200 OK. Observado: no ejecutado (pendiente).
- Done criteria: pendiente de verificacion manual.

## 5) Hallazgos nuevos o pendientes
- Sin hallazgos nuevos.

## 6) Riesgo de romper contratos
- No. No se cambiaron patrones Redis/Rabbit/SignalR ni contratos externos.

## 7) Post-step (actualizar checklist)
- Marcar `[x]` en `IndexRef` para `PHASE-02`.
- Completar/actualizar links a Summary en el indice.
