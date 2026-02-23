# QA PACK - acciones-modulo-act-004-phase-02

## 0) Metadata
- Fecha: 2026-02-20
- Tipo: QA PACK
- Objetivo: Validar Fase 02 de ACT-004 (backend create-from-device local/reusable + whitelist de overrides v1).
- Entorno: API local (`telemetric-api`) + frontend para gate no-regresion (`telemetric-front`).
- Autor: Codex (asistido)

## 0.1 Trazabilidad del pack
- PackDir: `contexto/work/features/acciones_modulo/04_test/ACT-004/phase-02/`
- StoryId: `ACT-004`
- Requirement: `acciones_modulo`
- PhaseId: `02`
- ChangePlan: `contexto/work/features/acciones_modulo/02_plans/ACT-004.plan.md`
- ChangeSummary: `contexto/work/features/acciones_modulo/03_execution/ACT-004/phase-02.md`

---

## 1) Alcance
### 1.1 Incluye
- Verificacion de endpoint backend `POST /api/v1/actions/assignments/create-from-device`.
- Verificacion de policy `PermissionClaims.Actions.Assign`.
- Verificacion de rutas local/reusable en el handler.
- Verificacion de whitelist de overrides v1 sobre `OverridesJson`.
- Verificacion de guardrail de duplicado `(DeviceId, RuleTemplateVersionId)` en create-from-device.
- Verificacion de gate no-regresion TypeScript no-demo.
- Pruebas integradas opcionales para override permitido/no permitido y local/reusable.

### 1.2 No incluye
- Provisioning de datos/usuarios/permisos del entorno.
- Pruebas de carga o performance.
- Alteraciones de codigo de producto.

---

## 2) Pre-requisitos
- Ejecutar desde raiz del repo.
- Herramientas: `rg`, `dotnet`, `node`, `npm`.
- Opcional para corrida integrada:
  - API levantada en `http://localhost:5220`.
  - token bearer con claim `Actions.Assign`.

Variables esperadas para scripts:
- `DRY_RUN` (`1` por defecto)
- `API_BASE_URL` (default: `http://localhost:5220`)
- `API_AUTH_TOKEN` (opcional; si falta, `run` intenta auto-login)
- `API_USER` (default: `vcsoft`)
- `API_PASSWORD` (default: `123456`)
- `SQLCMD_ARGS` (opcional; default: `-S . -d TelemetricDb -U sa -P sa -C`)
- `TEST_DEVICE_ID` (opcional)
- `TEST_RULE_TEMPLATE_VERSION_ID` (opcional)
- `FRONTEND_DIR` (default: `telemetric-front`)

Baseline de no-regresion:
- `baseline.json` (`scope=no-demo`, `ts_errors=240`).

---

## 2.5) Descubrimiento (fuentes y evidencia)

### Objetivo inferido (mandatorio por skill)
- Fuente: `contexto/work/features/acciones_modulo/02_plans/ACT-004.plan.md`
- Seccion: `Fase 2`
- Objetivo inferido: "Definir backend create-from-device (local/reusable) con whitelist de overrides v1."

### Docker compose detectados
- `telemetric-hub/kiss/scripts/docker-compose.yml`
- `telemetric-api/old/docker-compose.yml`
- Decision: se selecciona `telemetric-hub/kiss/scripts/docker-compose.yml` como compose operativo; `telemetric-api/old/docker-compose.yml` queda como legado.

### API base URL y runtime
- `http://localhost:5220`
- Evidencia: `telemetric-api/src/Telemetric.Api/Properties/launchSettings.json`

### Endpoints/policies de fase 02
- Endpoint: `POST /api/v1/actions/assignments/create-from-device`
- Policy: `PermissionClaims.Actions.Assign`
- Evidencia:
  - `telemetric-api/src/Telemetric.Api/Features/Actions/Assignments/CreateRuleFromDevice/CreateRuleFromDeviceEndpoint.cs`
  - `telemetric-api/src/Telemetric.Api/Domain/Constants/PermissionClaims.cs`
  - `contexto/openapi/actions.yaml`

### Reglas de negocio validadas por descubrimiento
- Whitelist overrides v1:
  - `threshold` numerico.
  - `email.recipients` array de strings no vacios.
  - rechazo explicito de claves fuera de whitelist.
- Flujo local/reusable:
  - `CreateReusableTemplate=false` usa `RuleTemplateVersionId` existente.
  - `CreateReusableTemplate=true` crea `RuleTemplate` + `RuleTemplateVersion` y luego `RuleInstance`.
- Duplicados:
  - rechazo cuando ya existe `RuleInstance` para `(DeviceId, RuleTemplateVersionId)`.
- Evidencia:
  - `telemetric-api/src/Telemetric.Api/Features/Actions/Assignments/CreateRuleFromDevice/CreateRuleFromDeviceCommandHandler.cs`
  - `telemetric-api/scripts/012_create_actions_schema.sql`

### Comandos base y evidencia
- `rg --line-number -F "CreateRuleFromDevice" telemetric-api/src/Telemetric.Api/Features/Actions`
- `rg --line-number -F "Reuse-first" contexto/work/features/acciones_modulo/03_execution/ACT-004/phase-02.md`
- `rg --line-number -F "/api/v1/actions/assignments/create-from-device" telemetric-api/src/Telemetric.Api/Features/Actions/Assignments/CreateRuleFromDevice/CreateRuleFromDeviceEndpoint.cs contexto/openapi/actions.yaml`
- `rg --line-number -F "PermissionClaims.Actions.Assign" telemetric-api/src/Telemetric.Api/Features/Actions/Assignments/CreateRuleFromDevice/CreateRuleFromDeviceEndpoint.cs telemetric-api/src/Telemetric.Api/Domain/Constants/PermissionClaims.cs`
- `rg --line-number -F "threshold" telemetric-api/src/Telemetric.Api/Features/Actions/Assignments/CreateRuleFromDevice/CreateRuleFromDeviceCommandHandler.cs`
- `rg --line-number -F "email.recipients" telemetric-api/src/Telemetric.Api/Features/Actions/Assignments/CreateRuleFromDevice/CreateRuleFromDeviceCommandHandler.cs`
- `rg --line-number -F "is not allowed in v1" telemetric-api/src/Telemetric.Api/Features/Actions/Assignments/CreateRuleFromDevice/CreateRuleFromDeviceCommandHandler.cs`
- `npm --prefix telemetric-front run typecheck`

---

## 3) Setup
1. Ejecutar `scripts/setup.ps1` (Windows) o `scripts/setup.sh` (Linux/macOS).
2. Confirmar prerequisitos y discovery de fase.
3. Confirmar logs en `evidence/commands.log` y `evidence/outputs.log`.

## 4) Run
1. Ejecutar `scripts/run.ps1` o `scripts/run.sh`.
2. Flujo esperado:
- checks estaticos de endpoint/policy/whitelist/reuse-first;
- gate no-regresion TS no-demo;
- pruebas API integradas opcionales;
- registro de expected/observed en evidencia.

## 5) Teardown
- No-op seguro por defecto.
- Regla de cierre: toda instancia levantada durante QA debe apagarse y verificarse como detenida.

## 6) Evidencia
- `evidence/commands.log`
- `evidence/outputs.log`
- `evidence/notes.md`

## 7) Resultados esperados (PASS)
- Endpoint y policy presentes y trazables.
- Whitelist de overrides v1 aplicada en permitidos/no permitidos.
- Flujo local con `createdReusableTemplate=false`.
- Flujo reusable con `createdReusableTemplate=true`.
- Guardrail de duplicado trazable a handler + SQL.
- Gate no-regresion no-demo PASS.
