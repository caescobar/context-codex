# QA PACK - acciones-modulo-act-003-phase-02

## 0) Metadata
- Fecha: 2026-02-18
- Tipo: QA PACK
- Objetivo: Validar Fase 02 de ACT-003 (detalle de template y update con versionado inmutable).
- Entorno: local API + SQL (opcionalmente infraestructura con docker compose en `telemetric-hub/kiss/scripts/docker-compose.yml`)
- Autor: Codex (asistido)

## 0.1 Trazabilidad del pack
- PackDir: `contexto/work/features/acciones_modulo/04_test/ACT-003/phase-02/`
- StoryId: `ACT-003`
- Requirement: `acciones_modulo`
- PhaseId: `02`
- ChangePlan: `contexto/work/features/acciones_modulo/02_plans/ACT-003.plan.md`
- ChangeSummary: `contexto/work/features/acciones_modulo/03_execution/ACT-003/phase-02.md`

---

## 1) Alcance
### 1.1 Incluye
- Verificacion de contrato/ruta/policy para:
  - `GET /api/v1/actions/templates/{RuleTemplateId}`
  - `PUT /api/v1/actions/templates/{RuleTemplateId}`
- Verificacion funcional de update con nueva version (`VersionNumber` incremental).
- Verificacion de inmutabilidad: la version previa permanece en historial.
- Verificacion de delta OpenAPI ACT-003 para templates.

### 1.2 No incluye
- Cobertura de frontend (`/actions`, `/actions/templates/:id`) de fase 03.
- Pruebas de carga/performance.

---

## 2) Pre-requisitos
- Ejecutar desde raiz del repo.
- Herramientas:
  - `dotnet`
  - `rg`
  - `curl`
  - `sqlcmd` (opcional para verificacion SQL directa)
- API disponible en `http://localhost:5220` (segun `launchSettings.json`).
- Usuario autenticable (`admin/admin123` de seed base) y permisos `Actions.View` + `Actions.Update` asignados al rol del usuario.

Variables esperadas para scripts:
- `DRY_RUN` (`1` por defecto)
- `API_BASE_URL` (default: `http://localhost:5220`)
- `API_USER` (default: `admin`)
- `API_PASSWORD` (default: `admin123`)
- `RULE_TEMPLATE_ID` (default: `1`)
- `SQLCMD_ARGS` (opcional; ejemplo: `-S . -d TelemetricDb -U sa -P sa -C`)

---

## 2.5) Descubrimiento (fuentes y evidencia)

### Objetivo inferido (mandatorio por skill)
- Fuente: `contexto/work/features/acciones_modulo/02_plans/ACT-003.plan.md`
- Seccion: `Fase 2`
- Objetivo inferido: "Definir endpoints BE para detalle y versionado inmutable al editar template".

### Docker compose detectados
- `telemetric-hub/kiss/scripts/docker-compose.yml`
- `telemetric-api/old/docker-compose.yml`
- Decision: para esta fase se toma como compose operativo el de `telemetric-hub/kiss/scripts/docker-compose.yml` (servicios redis/rabbitmq/clickhouse). El compose en `telemetric-api/old/` se considera legado por ubicacion/nombre (`old`).
- Evidencia:
  - `telemetric-hub/kiss/scripts/docker-compose.yml`
  - `telemetric-api/old/docker-compose.yml`

### API base URL y runtime
- `http://localhost:5220`
- Evidencia:
  - `telemetric-api/src/Telemetric.Api/Properties/launchSettings.json`

### Endpoints/policies/tags de fase 02
- GET detalle: `Get("/api/v1/actions/templates/{RuleTemplateId}")`
- PUT update: `Put("/api/v1/actions/templates/{RuleTemplateId}")`
- Policies: `PermissionClaims.Actions.View`, `PermissionClaims.Actions.Update`
- Tags: `Tags("Actions")`
- Evidencia:
  - `telemetric-api/src/Telemetric.Api/Features/Actions/Templates/GetTemplateById/GetTemplateByIdEndpoint.cs`
  - `telemetric-api/src/Telemetric.Api/Features/Actions/Templates/UpdateTemplate/UpdateTemplateEndpoint.cs`
  - `telemetric-api/src/Telemetric.Api/Domain/Constants/PermissionClaims.cs`

### Inmutabilidad y versionado
- `UpdateTemplateCommandHandler` calcula `nextVersionNumber = max + 1` y crea nueva entidad `RuleTemplateVersion`.
- No muta `DefinitionJson` de versiones previas.
- Evidencia:
  - `telemetric-api/src/Telemetric.Api/Features/Actions/Templates/UpdateTemplate/UpdateTemplateCommandHandler.cs`

### Evidencia DB para unicidad de version
- Indice unico `UQ_RuleTemplateVersion_Template_Version` sobre `(RuleTemplateId, VersionNumber)`.
- Evidencia:
  - `telemetric-api/scripts/012_create_actions_schema.sql`

### OpenAPI de ACT-003
- Contiene `GET/POST /api/v1/actions/templates` y `GET/PUT /api/v1/actions/templates/{ruleTemplateId}`.
- Evidencia:
  - `contexto/openapi/actions.yaml`

### Login endpoint para smoke autenticado
- `POST /api/v1/auth/login` (`LoginRequest(string Username, string Password)`).
- Evidencia:
  - `telemetric-api/src/Telemetric.Api/Features/Auth/Login/LoginEndpoint.cs`
  - `telemetric-api/scripts/000.telemetric-schema.sql` (seed: usuario `admin`, password comentado `admin123`)

### Comandos clave y evidencia
- Build tecnico:
  - `dotnet build telemetric-api/src/Telemetric.Api/Telemetric.Api.csproj -p:OutDir=telemetric-api/.tmp-build/ -p:UseAppHost=false`
  - Evidencia: `contexto/work/features/acciones_modulo/03_execution/ACT-003/phase-02.md`
- Verificacion de rutas/policies/tags:
  - `rg --line-number "api/v1/actions/templates/{RuleTemplateId}|PermissionClaims.Actions.View|PermissionClaims.Actions.Update|Tags(\"Actions\")" telemetric-api/src/Telemetric.Api/Features/Actions/Templates -g "*.cs"`
  - Evidencia: paths de endpoints de templates.

---

## 3) Setup
1. Ejecutar `scripts/setup.ps1` (Windows) o `scripts/setup.sh` (Linux/macOS).
2. Confirmar prerequisitos y registrar evidencia inicial.
3. Con `DRY_RUN=0`, ejecutar build tecnico y checks de descubrimiento.

---

## 4) Run
1. Ejecutar `scripts/run.ps1` o `scripts/run.sh`.
2. Flujo esperado:
   - login y token;
   - GET detalle pre-update;
   - PUT update;
   - GET detalle post-update;
   - validaciones de incremento de version e historial;
   - verificacion OpenAPI y checks de codigo;
   - verificacion SQL opcional con `queries.sql`.

---

## 5) Teardown
- Ejecucion segura/no-op por defecto.
- No elimina datos productivos.
- Solo deja instrucciones de limpieza manual opcional en `evidence/notes.md`.

---

## 6) Evidencia
- `evidence/commands.log`: comandos emitidos (ejecutados o planificados).
- `evidence/outputs.log`: expected/observed y resultado de validaciones.
- `evidence/notes.md`: notas operativas y pendientes.

---

## 7) Resultados esperados (PASS)
- GET detalle responde `200` para template valido del tenant.
- PUT update responde `200` y retorna `versionNumber` nuevo.
- `versionNumber` post-update = `versionNumber` previo + 1.
- La version previa sigue presente en `versions` del detalle.
- OpenAPI de `contexto/openapi/actions.yaml` refleja endpoints ACT-003 de templates.
