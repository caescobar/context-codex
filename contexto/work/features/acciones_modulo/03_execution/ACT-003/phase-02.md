# FASE 02 - ACT-003

## Estado
DONE

## Standards Lock Check
- Backend: ADOPTED (ref: audit A0)
- SQLServer: ADOPTED (ref: audit A0)

## Files touched (max 5)
- telemetric-api/src/Telemetric.Api/Features/Actions/Templates/GetTemplateById/GetTemplateByIdEndpoint.cs
- telemetric-api/src/Telemetric.Api/Features/Actions/Templates/GetTemplateById/GetTemplateByIdQueryHandler.cs
- telemetric-api/src/Telemetric.Api/Features/Actions/Templates/UpdateTemplate/UpdateTemplateEndpoint.cs
- telemetric-api/src/Telemetric.Api/Features/Actions/Templates/UpdateTemplate/UpdateTemplateCommandHandler.cs
- contexto/openapi/actions.yaml

## Changes summary
- Se implemento `GET /api/v1/actions/templates/{RuleTemplateId}` con `Tags("Actions")`, policy `PermissionClaims.Actions.View` y respuesta de detalle para tabs (`Definition`, `Versions`, `Assignments`, `Runs`) incluyendo `versions`, `assignmentsCount` y `failedRunsCount`.
- Se implemento `PUT /api/v1/actions/templates/{RuleTemplateId}` con `Tags("Actions")`, policy `PermissionClaims.Actions.Update` y validaciones de request.
- El update crea siempre una nueva `RuleTemplateVersion` inmutable con `VersionNumber` incremental (`max + 1`) y no muta las versiones previas.
- El update permite actualizar metadatos del template (`Name`, `Description`, `IsActive`) manteniendo tenant scoping por `CurrentUser.ClientId`.
- Se actualizo `contexto/openapi/actions.yaml` al delta ACT-003 (solo endpoints de templates de la historia).

## Verification checklist
- Build tecnico ejecutado:
  - `dotnet build telemetric-api/src/Telemetric.Api/Telemetric.Api.csproj -p:OutDir=telemetric-api/.tmp-build/ -p:UseAppHost=false`
  - Resultado: `0 Error(s)` y warnings preexistentes de nulabilidad.
- Verificacion de rutas/policies:
  - `GET /api/v1/actions/templates/{RuleTemplateId}` -> `PermissionClaims.Actions.View`.
  - `PUT /api/v1/actions/templates/{RuleTemplateId}` -> `PermissionClaims.Actions.Update`.
- Verificacion de inmutabilidad:
  - `UpdateTemplateCommandHandler` crea `RuleTemplateVersion` nueva con `nextVersionNumber`.
  - No hay escrituras sobre `DefinitionJson` de versiones previas.
- Verificacion OpenAPI:
  - `actions.yaml` contiene endpoints `GET/POST /api/v1/actions/templates` y `GET/PUT /api/v1/actions/templates/{ruleTemplateId}`.
  - Se retiro el delta anterior ACT-002 de este archivo para mantener alcance ACT-003.

## Notes / Risks
- No se ejecutaron pruebas HTTP/smoke de fase 02 en esta corrida; queda pendiente validacion integrada (auth + API + SQL).
- El endpoint de detalle responde `404` cuando no encuentra template (incluye casos fuera de tenant actual).

---
