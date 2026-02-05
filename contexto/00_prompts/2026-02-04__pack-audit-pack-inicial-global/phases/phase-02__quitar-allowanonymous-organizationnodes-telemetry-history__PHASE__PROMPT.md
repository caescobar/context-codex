# PHASE PROMPT â€“ quitar-allowanonymous-organizationnodes-telemetry-history

PackDir: contexto/00_prompts/2026-02-04__pack-audit-pack-inicial-global/
ItemId: PHASE-02
IndexRef: contexto/00_prompts/2026-02-04__pack-audit-pack-inicial-global/INDEX.md
PromptPath: contexto/00_prompts/2026-02-04__pack-audit-pack-inicial-global/phases/phase-02__quitar-allowanonymous-organizationnodes-telemetry-history__PHASE__PROMPT.md

## Modo
refactor-safe + change-control

## Skills
- telemetric-backend-style

## Objetivo
Quitar `AllowAnonymous()` en OrganizationNodes y Telemetry/History.

## Alcance (max 5 archivos de codigo)
- telemetric-api/src/Telemetric.Api/Features/OrganizationNodes/CreateNode/CreateNodeEndpoint.cs
- telemetric-api/src/Telemetric.Api/Features/OrganizationNodes/UpdateNode/UpdateNodeEndpoint.cs
- telemetric-api/src/Telemetric.Api/Features/OrganizationNodes/DeleteNode/DeleteNodeEndpoint.cs
- telemetric-api/src/Telemetric.Api/Features/OrganizationNodes/GetOrganizationTree/GetOrganizationTreeEndpoint.cs
- telemetric-api/src/Telemetric.Api/Features/Telemetry/GetHistory/GetHistoryEndpoint.cs

## Entregables (archivos exactos)
- contexto/02_changes/2026-02-05__phase-02__quitar-allowanonymous-organizationnodes-telemetry-history__plan.md
- contexto/02_changes/2026-02-05__phase-02__quitar-allowanonymous-organizationnodes-telemetry-history__summary.md

## Guardrails
- No ampliar alcance fuera de los archivos listados.
- Maximo 5 archivos de codigo (solo los listados en Alcance).
- Prohibido cambiar contratos externos (Redis key patterns, Rabbit routing keys, SignalR group naming) sin migracion explicita.
- Si algun path no existe: buscar y confirmar el path real antes de continuar.

## No-go rules
- Si requiere tocar archivos fuera del Alcance o superar 5 archivos.
- Si implica cambiar contratos externos sin migracion explicita.
- Si no se puede cumplir la verificacion.

## Regla de invariantes
- Si falta autenticacion: no ejecutar la accion y devolver 401/403 (sin introducir nuevos contratos).

## Verificacion (pasos manuales)
1. Accion: API_CALL: llamar a endpoints de OrganizationNodes sin token. Expected: 401/403.
2. Accion: API_CALL: llamar a Telemetry/History sin token. Expected: 401/403.
3. Accion: API_CALL: llamar a OrganizationNodes y Telemetry/History con token valido. Expected: 200 OK.

## Done criteria
- Todos los endpoints listados rechazan requests sin token con 401/403.
- Los endpoints listados responden 200 OK con token valido.
- Summary incluye resultado observado vs expected para cada paso de verificacion.

## Tarea (ejecutor)
1) Ejecutar cambios minimos para cumplir el objetivo limitado al Alcance.
2) Completar plan + summary usando templates (con evidencia y paths).
3) En summary: resultado observado vs expected para cada paso de verificacion + Done criteria.

## Post-step obligatorio
- Marcar [x] PHASE-02 en IndexRef.
- Completar/actualizar links de Output (plan y summary) en el indice.
- Actualizar contexto/03_hallazgos/pending.md solo si hay hallazgos nuevos o cambio de estado.
