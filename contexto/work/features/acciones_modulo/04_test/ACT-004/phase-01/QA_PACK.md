# QA PACK - acciones-modulo-act-004-phase-01

## 0) Metadata
- Fecha: 2026-02-20
- Tipo: QA PACK
- Objetivo: Validar Fase 01 de ACT-004 (backend de asignacion masiva template-version -> devices con bloqueo de duplicados y scope por cliente).
- Entorno: API local (`telemetric-api`) + frontend para gate no-regresion (`telemetric-front`).
- Autor: Codex (asistido)

## 0.1 Trazabilidad del pack
- PackDir: `contexto/work/features/acciones_modulo/04_test/ACT-004/phase-01/`
- StoryId: `ACT-004`
- Requirement: `acciones_modulo`
- PhaseId: `01`
- ChangePlan: `contexto/work/features/acciones_modulo/02_plans/ACT-004.plan.md`
- ChangeSummary: `contexto/work/features/acciones_modulo/03_execution/ACT-004/phase-01.md`

---

## 1) Alcance
### 1.1 Incluye
- Verificacion de endpoint backend `POST /api/v1/actions/assignments/template-version`.
- Verificacion de policy `PermissionClaims.Actions.Assign`.
- Verificacion de resultados por device (`Created`, `RejectedDuplicate`, `RejectedNotFoundOrOutOfScope`).
- Verificacion de guardrails de duplicado/scope en handler y soporte SQL.
- Verificacion de gate no-regresion TypeScript no-demo (baseline fijo por requirement).
- Prueba integrada opcional de API (si hay token y datos de prueba).

### 1.2 No incluye
- Provisioning de datos/usuarios/permisos del entorno.
- Pruebas de carga o performance.
- Alteraciones de codigo de producto.

---

## 2) Pre-requisitos
- Ejecutar desde raiz del repo.
- Herramientas:
  - `rg`
  - `dotnet`
  - `node`
  - `npm`
- Opcional para corrida integrada:
  - API levantada en `http://localhost:5220`.
  - token bearer con claim `Actions.Assign`.
  - IDs de prueba validos (`RuleTemplateVersionId`, `DeviceIds`).

Variables esperadas para scripts:
- `DRY_RUN` (`1` por defecto)
- `API_BASE_URL` (default: `http://localhost:5220`)
- `API_AUTH_TOKEN` (opcional; si falta, `run` intenta auto-login)
- `API_USER` (default: `vcsoft`, usado para auto-login)
- `API_PASSWORD` (default: `123456`, usado para auto-login)
- `SQLCMD_ARGS` (opcional; default: `-S . -d TelemetricDb -U sa -P sa -C` para autodiscovery)
- `TEST_RULE_TEMPLATE_VERSION_ID` (opcional)
- `TEST_DEVICE_IDS` (opcional, csv: `1,2,3`)
- `FRONTEND_DIR` (default: `telemetric-front`)

Baseline de no-regresion (no-demo):
- `baseline.json`:
  - `scope: no-demo`
  - `ts_errors: 240`
  - `date: 2026-02-19`

---

## 2.5) Descubrimiento (fuentes y evidencia)

### Objetivo inferido (mandatorio por skill)
- Fuente: `contexto/work/features/acciones_modulo/02_plans/ACT-004.plan.md`
- Seccion: `Fase 1`
- Objetivo inferido: "Definir backend para asignacion masiva de template-version a devices con bloqueo de duplicados."

### Docker compose detectados
- `telemetric-hub/kiss/scripts/docker-compose.yml`
- `telemetric-api/old/docker-compose.yml`
- Decision: se selecciona `telemetric-hub/kiss/scripts/docker-compose.yml` como compose operativo; `telemetric-api/old/docker-compose.yml` queda como legado por ubicacion y nombre (`old`).
- Evidencia:
  - `telemetric-hub/kiss/scripts/docker-compose.yml`
  - `telemetric-api/old/docker-compose.yml`

### API base URL y runtime
- `http://localhost:5220`
- Evidencia:
  - `telemetric-api/src/Telemetric.Api/Properties/launchSettings.json`

### Endpoints/policies de fase 01
- Endpoint principal:
  - `POST /api/v1/actions/assignments/template-version`
  - Evidencia: `telemetric-api/src/Telemetric.Api/Features/Actions/Assignments/AssignTemplateToDevices/AssignTemplateToDevicesEndpoint.cs`
- Policy:
  - `PermissionClaims.Actions.Assign`
  - Evidencia: `telemetric-api/src/Telemetric.Api/Features/Actions/Assignments/AssignTemplateToDevices/AssignTemplateToDevicesEndpoint.cs`, `telemetric-api/src/Telemetric.Api/Domain/Constants/PermissionClaims.cs`
- OpenAPI:
  - Evidencia: `contexto/openapi/actions.yaml`

### Reglas de negocio validadas por descubrimiento
- Resultado por device:
  - `Created`
  - `RejectedDuplicate`
  - `RejectedNotFoundOrOutOfScope`
  - Evidencia: `telemetric-api/src/Telemetric.Api/Features/Actions/Assignments/AssignTemplateToDevices/AssignTemplateToDevicesCommandHandler.cs`
- Unicidad DB para duplicados:
  - `UQ_RuleInstance_Device_TemplateVersion`
  - Evidencia: `telemetric-api/scripts/012_create_actions_schema.sql`
- Scope por cliente autenticado:
  - uso de `_currentUserService.ClientId`
  - Evidencia: `telemetric-api/src/Telemetric.Api/Features/Actions/Assignments/AssignTemplateToDevices/AssignTemplateToDevicesCommandHandler.cs`

### Comandos base y evidencia
- Reuse-first / discover:
  - `rg --line-number -F "AssignTemplateToDevices" telemetric-api/src/Telemetric.Api/Features/Actions`
  - `rg --line-number -F "Reuse-first" contexto/work/features/acciones_modulo/03_execution/ACT-004/phase-01.md`
- Endpoint/policy:
  - `rg --line-number -F "template-version" telemetric-api/src/Telemetric.Api/Features/Actions/Assignments/AssignTemplateToDevices/AssignTemplateToDevicesEndpoint.cs`
  - `rg --line-number -F "PermissionClaims.Actions.Assign" telemetric-api/src/Telemetric.Api/Features/Actions/Assignments/AssignTemplateToDevices/AssignTemplateToDevicesEndpoint.cs telemetric-api/src/Telemetric.Api/Domain/Constants/PermissionClaims.cs`
- Duplicados/scope:
  - `rg --line-number -F "RejectedDuplicate" telemetric-api/src/Telemetric.Api/Features/Actions/Assignments/AssignTemplateToDevices/AssignTemplateToDevicesCommandHandler.cs`
  - `rg --line-number -F "ClientId" telemetric-api/src/Telemetric.Api/Features/Actions/Assignments/AssignTemplateToDevices/AssignTemplateToDevicesCommandHandler.cs`
  - `rg --line-number -F "UQ_RuleInstance_Device_TemplateVersion" telemetric-api/scripts/012_create_actions_schema.sql`
- OpenAPI:
  - `rg --line-number -F "/api/v1/actions/assignments/template-version" contexto/openapi/actions.yaml`
- Gate tecnico:
  - `npm --prefix telemetric-front run typecheck`
  - comparacion no-demo contra `baseline.json`.

---

## 3) Setup
1. Ejecutar `scripts/setup.ps1` (Windows) o `scripts/setup.sh` (Linux/macOS).
2. Confirmar prerequisitos, discovery y presencia de artefactos de fase.
3. Confirmar logs en `evidence/commands.log` y `evidence/outputs.log`.

---

## 4) Run
1. Ejecutar `scripts/run.ps1` o `scripts/run.sh`.
2. Flujo esperado:
   - validar artefactos de fase 01 (endpoint/handler/claims/openapi);
   - validar reglas de duplicado/scope (estatico);
   - validar traza `Reuse-first` en resumen de ejecucion;
   - ejecutar gate no-regresion TS no-demo;
   - opcional: prueba API real con token + IDs de prueba;
   - registrar PASS/PENDIENTE por criterio.

---

## 5) Teardown
- Ejecucion segura/no-op por defecto.
- No elimina datos ni artefactos de producto.
- Solo registra cierre operativo en evidencia.

---

## 6) Evidencia
- `evidence/commands.log`: comandos emitidos (ejecutados o planificados).
- `evidence/outputs.log`: expected/observed y resultados por criterio.
- `evidence/notes.md`: notas operativas y pendientes.

---

## 7) Resultados esperados (PASS)
- Endpoint y policy de asignacion masiva presentes y trazables.
- Handler reporta estados por device incluyendo duplicados.
- Guardrail de unicidad `(DeviceId, RuleTemplateVersionId)` trazable a SQL.
- Scope por cliente autenticado presente en handler.
- OpenAPI incluye `assignments/template-version`.
- Gate no-regresion no-demo pasa (`observed <= baseline.ts_errors`).
