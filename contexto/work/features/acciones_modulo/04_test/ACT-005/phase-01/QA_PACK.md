# QA PACK - acciones-modulo-act-005-phase-01

## 0) Metadata
- Fecha: 2026-02-20
- Tipo: QA PACK
- Objetivo: Validar Fase 01 de ACT-005 (alineacion de contratos FE/BE/OpenAPI al DSL canonico v1).
- Entorno: API local (`telemetric-api`) + frontend para gate no-regresion (`telemetric-front`).
- Autor: Codex (asistido)

## 0.1 Trazabilidad del pack
- PackDir: `contexto/work/features/acciones_modulo/04_test/ACT-005/phase-01/`
- StoryId: `ACT-005`
- Requirement: `acciones_modulo`
- PhaseId: `01`
- ChangePlan: `contexto/work/features/acciones_modulo/02_plans/ACT-005.plan.md`
- ChangeSummary: `contexto/work/features/acciones_modulo/03_execution/ACT-005/phase-01.md`

---

## 1) Alcance
### 1.1 Incluye
- Verificacion de contrato OpenAPI `DefinitionJsonV1` con `discriminator` por `ruleType`.
- Verificacion de 5 variantes DSL (`INSTANT_THRESHOLD`, `CONTINUOUS_DURATION`, `ACCUMULATED_DURATION_WINDOW`, `AGGREGATION_WINDOW`, `COUNT_OCCURRENCES_WINDOW`).
- Verificacion de validacion backend en create/update para aceptar solo `DefinitionJson` como objeto JSON.
- Verificacion de normalizacion backend con `GetRawText()` para persistir DSL serializado.
- Verificacion de token de ruta `ruleTemplateId` alineado entre endpoint y OpenAPI.
- Verificacion de contratos FE de tipos (`RuleType`, `durationSeconds` condicionado por tipo).
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
- `TEST_RULE_TEMPLATE_ID` (opcional; `run` intenta autodiscovery)
- `TEST_RULE_TEMPLATE_VERSION_ID` (opcional; `run` intenta autodiscovery)
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
- Seccion: `Fase 1`
- Objetivo inferido: "Alinear contratos FE/BE/OpenAPI al DSL canonico ya decidido para ACT-005."

### Docker compose detectados
- `telemetric-hub/kiss/scripts/docker-compose.yml`
- `telemetric-api/old/docker-compose.yml`
- Decision: se selecciona `telemetric-hub/kiss/scripts/docker-compose.yml` como compose operativo; el compose de `telemetric-api/old` se trata como legado.

### API base URL y runtime
- `http://localhost:5220`
- Evidencia:
  - `telemetric-api/src/Telemetric.Api/Properties/launchSettings.json`

### Endpoints/contratos de fase 01
- Endpoint create template:
  - `POST /api/v1/actions/templates`
  - Evidencia: `telemetric-api/src/Telemetric.Api/Features/Actions/Templates/CreateTemplate/CreateTemplateEndpoint.cs`
- Endpoint update template:
  - `PUT /api/v1/actions/templates/{ruleTemplateId}`
  - Evidencia: `telemetric-api/src/Telemetric.Api/Features/Actions/Templates/UpdateTemplate/UpdateTemplateEndpoint.cs`
- Login para auto-token:
  - `POST /api/v1/auth/login`
  - Evidencia: `telemetric-api/src/Telemetric.Api/Features/Auth/Login/LoginEndpoint.cs`

### Reglas de contrato validadas por descubrimiento
- OpenAPI usa `DefinitionJsonV1` en create/update.
- `DefinitionJsonV1` tiene `discriminator.propertyName=ruleType`.
- Backend valida `JsonValueKind.Object` para `DefinitionJson` en create/update.
- Backend normaliza `DefinitionJson` con `GetRawText()`.
- FE define `RuleType` y modela `durationSeconds` por tipo de regla.

### Comandos base y evidencia
- Descubrimiento de OpenAPI:
  - `rg --line-number -F "DefinitionJsonV1" contexto/openapi/actions.yaml`
  - `rg --line-number -F "discriminator" contexto/openapi/actions.yaml`
  - `rg --line-number -F "ruleType" contexto/openapi/actions.yaml`
- Descubrimiento backend:
  - `rg --line-number -F "JsonValueKind.Object" telemetric-api/src/Telemetric.Api/Features/Actions/Templates/CreateTemplate/CreateTemplateEndpoint.cs telemetric-api/src/Telemetric.Api/Features/Actions/Templates/UpdateTemplate/UpdateTemplateEndpoint.cs`
  - `rg --line-number -F "GetRawText" telemetric-api/src/Telemetric.Api/Features/Actions/Templates/CreateTemplate/CreateTemplateEndpoint.cs telemetric-api/src/Telemetric.Api/Features/Actions/Templates/UpdateTemplate/UpdateTemplateEndpoint.cs`
  - `rg --line-number -F "Put(\"/api/v1/actions/templates/{ruleTemplateId}\")" telemetric-api/src/Telemetric.Api/Features/Actions/Templates/UpdateTemplate/UpdateTemplateEndpoint.cs`
- Descubrimiento frontend:
  - `rg --line-number -F "export type RuleType" telemetric-front/src/features/actions/types.ts`
  - `rg --line-number -F "durationSeconds" telemetric-front/src/features/actions/types.ts`
- Gate tecnico:
  - `npm --prefix telemetric-front run typecheck`
  - comparacion no-demo contra `baseline.json`

---

## 3) Setup
1. Ejecutar `scripts/setup.ps1` (Windows) o `scripts/setup.sh` (Linux/macOS).
2. Confirmar prerequisitos, discovery y presencia de artefactos de fase.
3. Confirmar logs en `evidence/commands.log` y `evidence/outputs.log`.

---

## 4) Run
1. Ejecutar `scripts/run.ps1` o `scripts/run.sh`.
2. Flujo esperado:
   - validar artefactos de fase 01 (openapi/endpoints/types/summary);
   - validar tokens y reglas de contrato DSL acordadas;
   - ejecutar gate no-regresion TS no-demo;
   - intentar auto-login si no existe `API_AUTH_TOKEN`;
   - intentar autodiscovery SQL de IDs de prueba;
   - registrar PASS/PENDIENTE por criterio.

---

## 5) Teardown
- Ejecucion segura/no-op por defecto.
- No elimina datos ni artefactos de producto.
- Incluye regla de cierre runtime: si durante ejecucion real se levantaron instancias, deben apagarse y verificarse como detenidas.

---

## 6) Evidencia
- `evidence/commands.log`: comandos emitidos (ejecutados o planificados).
- `evidence/outputs.log`: expected/observed y resultados por criterio.
- `evidence/notes.md`: notas operativas y pendientes.

---

## 7) Resultados esperados (PASS)
- OpenAPI referencia `DefinitionJsonV1` en create/update.
- `DefinitionJsonV1` declara `discriminator.propertyName=ruleType`.
- OpenAPI declara las 5 variantes de `ruleType` del DSL canonico.
- Endpoints create/update validan `DefinitionJson` como objeto (`JsonValueKind.Object`).
- Endpoints create/update normalizan `DefinitionJson` con `GetRawText()`.
- `PUT` usa `{ruleTemplateId}` y coincide con OpenAPI.
- Tipos FE de Actions exponen `RuleType` y `durationSeconds` por tipo.
- Gate no-regresion no-demo pasa (`observed <= baseline.ts_errors`).
