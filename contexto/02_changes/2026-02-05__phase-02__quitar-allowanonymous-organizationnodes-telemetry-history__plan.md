# CHANGE PLAN - phase-02__quitar-allowanonymous-organizationnodes-telemetry-history - Fase 02

## 0) Metadata
- Fecha: 2026-02-05
- Alcance: PHASE-02 Quitar AllowAnonymous en OrganizationNodes y Telemetry/History
- Modo: refactor-safe + change-control
- Skills: telemetric-backend-style

## 0.1 Trazabilidad del pack
- PackDir: contexto/00_prompts/2026-02-04__pack-audit-pack-inicial-global
- PhaseId: PHASE-02
- IndexRef: contexto/00_prompts/2026-02-04__pack-audit-pack-inicial-global/INDEX.md
- PromptSource: contexto/00_prompts/2026-02-04__pack-audit-pack-inicial-global/phases/phase-02__quitar-allowanonymous-organizationnodes-telemetry-history__PHASE__PROMPT.md

## 1) Objetivo
- Quitar AllowAnonymous() en endpoints de OrganizationNodes y Telemetry/History para exigir autenticacion.

## 2) Archivos a tocar (max 5)
- telemetric-api/src/Telemetric.Api/Features/OrganizationNodes/CreateNode/CreateNodeEndpoint.cs
- telemetric-api/src/Telemetric.Api/Features/OrganizationNodes/UpdateNode/UpdateNodeEndpoint.cs
- telemetric-api/src/Telemetric.Api/Features/OrganizationNodes/DeleteNode/DeleteNodeEndpoint.cs
- telemetric-api/src/Telemetric.Api/Features/OrganizationNodes/GetOrganizationTree/GetOrganizationTreeEndpoint.cs
- telemetric-api/src/Telemetric.Api/Features/Telemetry/GetHistory/GetHistoryEndpoint.cs

## 3) Evidencia (paths)
- telemetric-api/src/Telemetric.Api/Features/Metrics/CreateMetric/CreateMetricEndpoint.cs
- telemetric-api/src/Telemetric.Api/Features/Maps/GetMapsList/GetMapsListEndpoint.cs

## 4) Plan en 5 bullets
1) Revisar endpoints similares con Policies para mantener el estilo del repo.
2) Remover AllowAnonymous() en los 5 endpoints definidos en el alcance.
3) Confirmar que no se agregan contratos ni cambios fuera del alcance.
4) Documentar cambios en plan y summary usando templates.
5) Actualizar INDEX.md con links y checkbox de la fase.

## 5) Riesgos y mitigaciones
- Riesgo: clientes sin token valido recibiran 401/403.
- Mitigacion: validar con los pasos manuales de verificacion y confirmar comportamiento esperado.

## 6) Como verificar (pasos manuales)
1) API_CALL: endpoints de OrganizationNodes sin token. Expected: 401/403.
2) API_CALL: /api/v1/telemetry/history sin token. Expected: 401/403.
3) API_CALL: OrganizationNodes y Telemetry/History con token valido. Expected: 200 OK.

## 7) No-go rules (si pasa esto, parar)
- Requiere tocar archivos fuera del Alcance o superar 5 archivos.
- Implica cambiar contratos externos sin migracion explicita.
- No se puede cumplir la verificacion.

## 8) Post-step (actualizar checklist)
- Marcar `[x]` en `IndexRef` para `PHASE-02`.
- Completar/actualizar links a Plan y Summary en el indice.
