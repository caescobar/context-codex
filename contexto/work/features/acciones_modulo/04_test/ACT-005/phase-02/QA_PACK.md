# QA PACK - acciones-modulo-act-005-phase-02

## 0) Metadata
- Fecha: 2026-02-20
- Tipo: QA PACK
- Objetivo: Validar Fase 02 de ACT-005 (validacion semantica DSL server-side para create/update template y create-from-device reusable).
- Entorno: API local (`telemetric-api`) + frontend para gate no-regresion (`telemetric-front`).
- Autor: Codex (asistido)

## 0.1 Trazabilidad del pack
- PackDir: `contexto/work/features/acciones_modulo/04_test/ACT-005/phase-02/`
- StoryId: `ACT-005`
- Requirement: `acciones_modulo`
- PhaseId: `02`
- ChangePlan: `contexto/work/features/acciones_modulo/02_plans/ACT-005.plan.md`
- ChangeSummary: `contexto/work/features/acciones_modulo/03_execution/ACT-005/phase-02.md`

---

## 1) Alcance
### 1.1 Incluye
- Verificacion de validacion semantica en handlers de `CreateTemplate`, `UpdateTemplate` y `CreateRuleFromDevice` (reusable).
- Verificacion de reglas temporales: `evaluation.durationSeconds <= evaluation.windowSeconds` cuando aplica.
- Verificacion de missing data policy: `HOLD_LAST_VALUE` requiere `ttlSeconds` valido y `INSUFFICIENT_DATA` rechaza `ttlSeconds` con valor.
- Verificacion de recipients con path indexado (`action.recipients[i]`) y formato de email.
- Verificacion de estilo backend de errores HTTP 400 (`Send.ErrorsAsync(400)`).
- Verificacion de gate no-regresion TypeScript no-demo (baseline fijo por requirement).

### 1.2 No incluye
- Provisioning de datos/usuarios/permisos del entorno.
- Pruebas de performance.
- Cambios de codigo de producto.

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
  - credenciales validas para auto-login (`API_USER`, `API_PASSWORD`).
  - `sqlcmd` disponible para autodiscovery.

Variables esperadas para scripts:
- `DRY_RUN` (`1` por defecto)
- `API_BASE_URL` (default: `http://localhost:5220`)
- `API_AUTH_TOKEN` (opcional; si falta, `run` intenta auto-login)
- `API_USER` (default: `vcsoft`, usado para auto-login)
- `API_PASSWORD` (default: `123456`, usado para auto-login)
- `SQLCMD_ARGS` (opcional; default: `-S . -d TelemetricDb -U sa -P sa -C` para autodiscovery)
- `TEST_RULE_TEMPLATE_VERSION_ID` (opcional; `run` intenta autodiscovery)
- `TEST_DEVICE_IDS` (opcional; `run` intenta autodiscovery)
- `FRONTEND_DIR` (default: `telemetric-front`)

Baseline de no-regresion (no-demo):
- `baseline.json`:
  - `scope: no-demo`
  - `ts_errors: 240`
  - `date: 2026-02-20`

---

## 2.5) Descubrimiento (fuentes y evidencia)

### Objetivo inferido (mandatorio por skill)
- Fuente: `contexto/work/features/acciones_modulo/02_plans/ACT-005.plan.md`
- Seccion: `Fase 2`
- Objetivo inferido: "Implementar validacion semantica DSL server-side para create/update template y create-from-device reusable."

### Docker compose detectados
- `telemetric-hub/kiss/scripts/docker-compose.yml`
- `telemetric-api/old/docker-compose.yml`
- Decision: se selecciona `telemetric-hub/kiss/scripts/docker-compose.yml` como compose operativo; `telemetric-api/old/docker-compose.yml` se trata como legado.

### API base URL y runtime
- `http://localhost:5220`
- Evidencia:
  - `telemetric-api/src/Telemetric.Api/Properties/launchSettings.json`

### Endpoints/policies relacionados con fase 02
- `POST /api/v1/actions/templates` + `Policies(PermissionClaims.Actions.Create)`
  - Evidencia: `telemetric-api/src/Telemetric.Api/Features/Actions/Templates/CreateTemplate/CreateTemplateEndpoint.cs`
- `PUT /api/v1/actions/templates/{ruleTemplateId}` + `Policies(PermissionClaims.Actions.Update)`
  - Evidencia: `telemetric-api/src/Telemetric.Api/Features/Actions/Templates/UpdateTemplate/UpdateTemplateEndpoint.cs`
- `POST /api/v1/actions/assignments/create-from-device` + `Policies(PermissionClaims.Actions.Assign)`
  - Evidencia: `telemetric-api/src/Telemetric.Api/Features/Actions/Assignments/CreateRuleFromDevice/CreateRuleFromDeviceEndpoint.cs`
- Login para auto-token: `POST /api/v1/auth/login`
  - Evidencia: `telemetric-api/src/Telemetric.Api/Features/Auth/Login/LoginEndpoint.cs`

### Handlers y reglas semanticas verificadas
- `telemetric-api/src/Telemetric.Api/Features/Actions/Templates/CreateTemplate/CreateTemplateCommandHandler.cs`
- `telemetric-api/src/Telemetric.Api/Features/Actions/Templates/UpdateTemplate/UpdateTemplateCommandHandler.cs`
- `telemetric-api/src/Telemetric.Api/Features/Actions/Assignments/CreateRuleFromDevice/CreateRuleFromDeviceCommandHandler.cs`
- Señales concretas:
  - `ValidateAndNormalizeDefinitionJson(...)`
  - `evaluation.durationSeconds must be less than or equal to evaluation.windowSeconds.`
  - `missingDataPolicy.ttlSeconds is required when mode is HOLD_LAST_VALUE.`
  - `missingDataPolicy.ttlSeconds must be null or omitted when mode is INSUFFICIENT_DATA.`
  - `action.recipients[` (path indexado)

### Scripts/comandos base
- Discovery backend fase 02:
  - `rg --line-number -F "ValidateAndNormalizeDefinitionJson(" telemetric-api/src/Telemetric.Api/Features/Actions/Templates/CreateTemplate/CreateTemplateCommandHandler.cs telemetric-api/src/Telemetric.Api/Features/Actions/Templates/UpdateTemplate/UpdateTemplateCommandHandler.cs telemetric-api/src/Telemetric.Api/Features/Actions/Assignments/CreateRuleFromDevice/CreateRuleFromDeviceCommandHandler.cs`
  - `rg --line-number -F "evaluation.durationSeconds must be less than or equal to evaluation.windowSeconds." ...`
  - `rg --line-number -F "missingDataPolicy.ttlSeconds is required when mode is HOLD_LAST_VALUE." ...`
  - `rg --line-number -F "missingDataPolicy.ttlSeconds must be null or omitted when mode is INSUFFICIENT_DATA." ...`
  - `rg --line-number -F "action.recipients[" ...`
- Estilo de errores:
  - `rg --line-number -F "Send.ErrorsAsync(400" telemetric-api/src/Telemetric.Api/Features/Actions/Templates/CreateTemplate/CreateTemplateEndpoint.cs telemetric-api/src/Telemetric.Api/Features/Actions/Templates/UpdateTemplate/UpdateTemplateEndpoint.cs telemetric-api/src/Telemetric.Api/Features/Actions/Assignments/CreateRuleFromDevice/CreateRuleFromDeviceEndpoint.cs`
- Gate tecnico:
  - `npm --prefix telemetric-front run typecheck`
  - comparacion no-demo contra `baseline.json`

---

## 3) Setup
1. Ejecutar `scripts/setup.ps1` (Windows) o `scripts/setup.sh` (Linux/macOS).
2. Confirmar prerequisitos, discovery y presencia de artefactos de fase 02.
3. Confirmar logs en `evidence/commands.log` y `evidence/outputs.log`.

---

## 4) Run
1. Ejecutar `scripts/run.ps1` o `scripts/run.sh`.
2. Flujo esperado:
   - validar artefactos de fase 02 (handlers/endpoints/summary);
   - validar reglas semanticas DSL (`T <= W`, TTL, recipients indexado);
   - validar estilo backend de errores (`Send.ErrorsAsync(400)`);
   - ejecutar gate no-regresion TS no-demo;
   - intentar auto-login si no existe `API_AUTH_TOKEN`;
   - intentar autodiscovery SQL de `TEST_RULE_TEMPLATE_VERSION_ID` y `TEST_DEVICE_IDS`;
   - registrar PASS/PENDIENTE por criterio.

---

## 5) Teardown
- Ejecucion segura/no-op por defecto.
- No elimina datos ni artefactos de producto.
- Regla de cierre runtime: toda instancia levantada durante QA debe apagarse y verificarse como detenida.

---

## 6) Evidencia
- `evidence/commands.log`: comandos emitidos (ejecutados o planificados).
- `evidence/outputs.log`: expected/observed y resultados por criterio.
- `evidence/notes.md`: notas operativas y pendientes.

---

## 7) Resultados esperados (PASS)
- Handlers `CreateTemplate` y `UpdateTemplate` validan semantica DSL con errores deterministas.
- `CreateRuleFromDevice` valida y normaliza `DefinitionJson` cuando `CreateReusableTemplate=true`.
- Se rechaza `evaluation.durationSeconds > evaluation.windowSeconds`.
- Se rechaza `HOLD_LAST_VALUE` sin `ttlSeconds` o fuera de rango.
- Se rechaza `INSUFFICIENT_DATA` con `ttlSeconds` informado.
- Se rechazan recipients invalidos con path indexado (`action.recipients[i]`).
- Endpoints mantienen `Send.ErrorsAsync(400)` para errores de negocio.
- Gate no-regresion no-demo pasa (`observed <= baseline.ts_errors`).
