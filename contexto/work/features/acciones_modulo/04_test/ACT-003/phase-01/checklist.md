# ACT-003 - Phase 01 Checklist (Templates list/create)

## Objetivo
Validar los endpoints de la fase 01 de ACT-003 para listado y creacion de templates:
- `GET /api/v1/actions/templates`
- `POST /api/v1/actions/templates`

## Precondiciones
1. Ejecutar desde raiz de repo.
2. API levantada (`telemetric-api`).
3. Base SQL disponible y con schema de Actions aplicado.
4. Usuario autenticado con permisos:
   - `Actions.View`
   - `Actions.Create`

## Reuse-first (evidencia requerida)
1. Verificar patron de referencia existente:
   - Archivo: `telemetric-api/src/Telemetric.Api/Features/Actions/ResolveManual/ResolveManualEndpoint.cs`
   - Esperado: ruta versionada `/api/v1/...`, `Tags("Actions")`, `Policies(...)`, `Send.OkAsync/Send.ErrorsAsync`.
2. Verificar que phase 01 sigue el mismo patron:
   - `telemetric-api/src/Telemetric.Api/Features/Actions/Templates/GetTemplates/GetTemplatesEndpoint.cs`
   - `telemetric-api/src/Telemetric.Api/Features/Actions/Templates/CreateTemplate/CreateTemplateEndpoint.cs`

## Checklist funcional
1. Endpoint de listado
   - Ejecutar `GET /api/v1/actions/templates?pageNumber=1&pageSize=10`.
   - Esperado:
     - HTTP 200.
     - Respuesta tipada paginada (`items`, `pageNumber`, `pageSize`, `totalPages`, `totalCount`).
     - Cada item incluye: `ruleTemplateId`, `name`, `latestVersionNumber`.

2. Endpoint de creacion
   - Ejecutar `POST /api/v1/actions/templates` con payload valido:
```json
{
  "name": "Temp alta presion",
  "description": "Template v1",
  "definitionJson": "{\"trigger\":{\"metricCode\":\"pressure\"},\"condition\":{\"operator\":\">\",\"value\":80}}",
  "isActive": true
}
```
   - Esperado:
     - HTTP 200.
     - Respuesta con `ruleTemplateId`, `ruleTemplateVersionId`, `versionNumber`.
     - `versionNumber = 1`.

3. Validaciones basicas de create
   - Enviar `name` vacio o `definitionJson` vacio.
   - Esperado: HTTP 400 con errores de validacion.

4. Persistencia SQL
   - Verificar en DB:
     - Existe fila en `RuleTemplate` para el `ruleTemplateId` creado.
     - Existe fila en `RuleTemplateVersion` para el `ruleTemplateVersionId` con `VersionNumber = 1`.

5. Policies y tags
   - Verificar en codigo:
     - List usa `PermissionClaims.Actions.View`.
     - Create usa `PermissionClaims.Actions.Create`.
     - Ambos endpoints usan `Tags("Actions")`.

## Comandos sugeridos (manual)
1. Build rapido API:
   - `dotnet build telemetric-api/src/Telemetric.Api/Telemetric.Api.csproj -p:OutDir=telemetric-api/.tmp-build/ -p:UseAppHost=false`
2. Buscar policies/rutas:
   - `rg --line-number 'api/v1/actions/templates|PermissionClaims.Actions.View|PermissionClaims.Actions.Create|Tags\("Actions"\)' telemetric-api/src/Telemetric.Api/Features/Actions/Templates -g '*.cs'`
3. Verificar permisos nuevos:
   - `rg --line-number 'Actions.View|Actions.Create|Actions.Update' telemetric-api/src/Telemetric.Api/Domain/Constants/PermissionClaims.cs`

## Validacion ejecutada (esta corrida)
- Build API: OK (`0 Error(s)`, warnings preexistentes de nulabilidad).
- Reuse-first (patron): OK (referencia `ResolveManualEndpoint` verificada).
- Rutas y policies en endpoints nuevos: OK (`/api/v1/actions/templates`, `Actions.View`, `Actions.Create`).
- Permisos `Actions.View/Create/Update`: OK en `PermissionClaims`.
- Pruebas HTTP reales:
  - `POST /api/v1/auth/login`: OK (token emitido para `admin`).
  - `GET /api/v1/actions/templates?pageNumber=1&pageSize=10`: OK (HTTP 200).
  - `POST /api/v1/actions/templates` (payload valido): OK (HTTP 200, `versionNumber=1`).
  - `POST /api/v1/actions/templates` (payload invalido): OK (HTTP 400).
- Persistencia SQL:
  - `RuleTemplate` creado: OK.
  - `RuleTemplateVersion` creada y asociada: OK (`VersionNumber=1`).
- Nota de entorno:
  - Fue necesario insertar permisos `Actions.View/Create/Update` en DB y asignarlos al rol del usuario `admin` (`SAD`) para habilitar autorizacion de endpoints nuevos.

## Resultado
- [x] Reuse-first documentado
- [x] GET templates OK
- [x] POST create OK
- [x] Validaciones 400 OK
- [x] Persistencia SQL OK
- [x] Policies/tags OK
