# FASE 01 - ACT-003

## Estado
DONE

## Standards Lock Check
- Backend: ADOPTED (ref: audit A0)
- SQLServer: ADOPTED (ref: audit A0)

## Files touched (max 5)
- telemetric-api/src/Telemetric.Api/Features/Actions/Templates/GetTemplates/GetTemplatesEndpoint.cs
- telemetric-api/src/Telemetric.Api/Features/Actions/Templates/GetTemplates/GetTemplatesQueryHandler.cs
- telemetric-api/src/Telemetric.Api/Features/Actions/Templates/CreateTemplate/CreateTemplateEndpoint.cs
- telemetric-api/src/Telemetric.Api/Features/Actions/Templates/CreateTemplate/CreateTemplateCommandHandler.cs
- telemetric-api/src/Telemetric.Api/Domain/Constants/PermissionClaims.cs

## Changes summary
- Se implemento endpoint `GET /api/v1/actions/templates` con request tipado, respuesta paginada y policy `PermissionClaims.Actions.View`.
- Se implemento query handler para listado de `RuleTemplate` con filtros por cliente actual, `ClientId` opcional y `SearchTerm`, incluyendo `LatestVersionNumber` por template.
- Se implemento endpoint `POST /api/v1/actions/templates` con request/response tipados, validacion basica y policy `PermissionClaims.Actions.Create`.
- Se implemento command handler para crear `RuleTemplate` y su `RuleTemplateVersion` inicial inmutable (`VersionNumber = 1`).
- Se actualizaron permisos de Actions para ACT-003 (`View`, `Create`, `Update`) segun decision `D-ACT-003-PERMISSIONS`.
- Evidencia reuse-first: se tomo como referencia el patron existente `Features/Actions/ResolveManual` para route versioning, tags, policies, `Result<T>`, `Mapster`, `Send.OkAsync` y `Send.ErrorsAsync`.

## Verification checklist
- Verificar que `GET /api/v1/actions/templates` responde `PaginatedList<RuleTemplateListItemDto>` y respeta filtro por tenant (`CurrentUser.ClientId`).
- Verificar que `POST /api/v1/actions/templates` crea una fila en `RuleTemplate` y una fila en `RuleTemplateVersion` con `VersionNumber=1`.
- Verificar que los endpoints exponen `Tags("Actions")` y policies `PermissionClaims.Actions.View/Create`.
- Verificar que request/response son tipados y que se usa `Result<T>` + `Send.OkAsync`/`Send.ErrorsAsync`.
- Verificacion tecnica ejecutada: `dotnet build src/Telemetric.Api/Telemetric.Api.csproj -p:OutDir=... -p:UseAppHost=false` (0 errores).

## Notes / Risks
- El build normal a `bin/Debug/net10.0` falla en este entorno porque `Telemetric.Api` esta corriendo y bloquea `Telemetric.Api.dll/.exe`.
- Quedaron warnings preexistentes de nulabilidad en el proyecto; no son introducidos por esta fase.