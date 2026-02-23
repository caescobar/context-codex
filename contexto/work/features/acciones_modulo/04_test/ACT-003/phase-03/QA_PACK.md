# QA PACK - acciones-modulo-act-003-phase-03

## 0) Metadata
- Fecha: 2026-02-19
- Tipo: QA PACK
- Objetivo: Validar Fase 03 de ACT-003 (feature frontend de Templates en `/actions` y `/actions/templates/:id`).
- Entorno: frontend (`telemetric-front`) + API local opcional.
- Autor: Codex (asistido)

## 0.1 Trazabilidad del pack
- PackDir: `contexto/work/features/acciones_modulo/04_test/ACT-003/phase-03/`
- StoryId: `ACT-003`
- Requirement: `acciones_modulo`
- PhaseId: `03`
- ChangePlan: `contexto/work/features/acciones_modulo/02_plans/ACT-003.plan.md`
- ChangeSummary: `contexto/work/features/acciones_modulo/03_execution/ACT-003/phase-03.md`

---

## 1) Alcance
### 1.1 Incluye
- Verificacion de existencia/registro de rutas frontend de ACT-003:
  - `/actions`
  - `/actions/templates/:id`
- Verificacion de estructura de feature (`routes/service/types/views`) para Templates.
- Verificacion de integracion de servicio con cliente HTTP core (`@/core/utils/axios`).
- Verificacion de coherencia de idioma:
  - labels UI en espanol
  - nombres de tipos/contratos en ingles
- Verificacion de trazabilidad con endpoints backend de fases 01/02.

### 1.2 No incluye
- Pruebas E2E visuales automatizadas de navegador.
- Benchmark de performance frontend.

---

## 2) Pre-requisitos
- Ejecutar desde raiz del repo.
- Herramientas:
  - `rg`
  - `node`
  - `npm`
- Frontend principal localizado en `telemetric-front/`.
- API opcional en `http://localhost:5220` para pruebas de integracion manual.

Variables esperadas para scripts:
- `DRY_RUN` (`1` por defecto)
- `FRONTEND_DIR` (default: `telemetric-front`)

Baseline de no-regresion (no-demo):
- `baseline.json`:
  - `scope: no-demo`
  - `ts_errors: 240`
  - `date: 2026-02-19`

---

## 2.5) Descubrimiento (fuentes y evidencia)

### Objetivo inferido (mandatorio por skill)
- Fuente: `contexto/work/features/acciones_modulo/02_plans/ACT-003.plan.md`
- Seccion: `Fase 3`
- Objetivo inferido: "Disenar feature frontend de Templates en rutas `/actions` y `/actions/templates/:id`."

### Docker compose detectados
- `telemetric-hub/kiss/scripts/docker-compose.yml`
- `telemetric-api/old/docker-compose.yml`
- Decision: se documenta como compose operativo `telemetric-hub/kiss/scripts/docker-compose.yml`; el compose bajo `telemetric-api/old/` se considera legado por ubicacion.
- Evidencia:
  - `telemetric-hub/kiss/scripts/docker-compose.yml`
  - `telemetric-api/old/docker-compose.yml`

### API base URL y runtime
- `http://localhost:5220`
- Evidencia:
  - `telemetric-api/src/Telemetric.Api/Properties/launchSettings.json`

### Endpoints backend de soporte para fase 03
- Listado/create:
  - `GET /api/v1/actions/templates`
  - `POST /api/v1/actions/templates`
  - Evidencia: `telemetric-api/src/Telemetric.Api/Features/Actions/Templates/GetTemplates/GetTemplatesEndpoint.cs`, `telemetric-api/src/Telemetric.Api/Features/Actions/Templates/CreateTemplate/CreateTemplateEndpoint.cs`
- Detalle/update:
  - `GET /api/v1/actions/templates/{RuleTemplateId}`
  - `PUT /api/v1/actions/templates/{RuleTemplateId}`
  - Evidencia: `telemetric-api/src/Telemetric.Api/Features/Actions/Templates/GetTemplateById/GetTemplateByIdEndpoint.cs`, `telemetric-api/src/Telemetric.Api/Features/Actions/Templates/UpdateTemplate/UpdateTemplateEndpoint.cs`
- OpenAPI:
  - Evidencia: `contexto/openapi/actions.yaml`

### Frontend routing y convenciones detectadas
- Router principal:
  - Evidencia: `telemetric-front/src/router/index.ts`
- Registro de rutas de Actions en router:
  - Evidencia: `telemetric-front/src/router/AdminRoutes.ts`, `telemetric-front/src/features/actions/actions.routes.ts`
- Cliente HTTP core existente:
  - Evidencia: `telemetric-front/src/core/utils/axios.ts`
- Patron de servicio feature (uso de core axios + `types.ts`):
  - Evidencia: `telemetric-front/src/features/admin/units/unit.service.ts`, `telemetric-front/src/features/admin/units/types.ts`, `telemetric-front/src/features/admin/units/unit.routes.ts`

### Estado de archivos candidatos de Fase 03
- Paths del plan:
  - `telemetric-front/src/features/actions/actions.routes.ts`
  - `telemetric-front/src/features/actions/actions.service.ts`
  - `telemetric-front/src/features/actions/types.ts`
  - `telemetric-front/src/features/actions/views/ActionsTemplatesView.vue`
  - `telemetric-front/src/features/actions/views/ActionTemplateDetailView.vue`
- Resultado de descubrimiento:
  - Encontrados e implementados.
- Evidencia:
  - `contexto/work/features/acciones_modulo/02_plans/ACT-003.plan.md`
  - Busqueda en `telemetric-front/src/features/`

### Comandos base y evidencia
- Chequeo de rutas esperadas:
  - `rg --line-number -F "/actions" telemetric-front/src`
  - `rg --line-number -F "/actions/templates/:id" telemetric-front/src`
- Chequeo de feature ACT-003:
  - `rg --line-number -F "features/actions" telemetric-front/src/router telemetric-front/src/features -g "*.ts"`
  - `rg --line-number -F "@/core/utils/axios" telemetric-front/src/features -g "*.ts"`
- Chequeo tecnico opcional:
  - `npm --prefix telemetric-front run typecheck`
- Gate no-regresion (obligatorio en `DRY_RUN=0`):
  - contar errores TypeScript no-demo desde salida de typecheck;
  - comparar contra `baseline.json`;
  - FAIL si sube, PASS si baja o se mantiene.

---

## 3) Setup
1. Ejecutar `scripts/setup.ps1` (Windows) o `scripts/setup.sh` (Linux/macOS).
2. Confirmar prerequisitos y discovery de rutas/archivos.
3. En `DRY_RUN=0`, correr `typecheck` tecnico del frontend.

---

## 4) Run
1. Ejecutar `scripts/run.ps1` o `scripts/run.sh`.
2. Flujo esperado:
   - validar existencia de archivos candidatos de fase 03;
   - validar presencia de rutas `/actions` y `/actions/templates/:id`;
   - validar uso de cliente core HTTP en servicio de Actions;
   - validar evidencia de labels ES y tipos EN en vistas/tipos de Actions;
   - ejecutar gate de no-regresion TS no-demo contra `baseline.json`;
   - registrar resultado PASS/PENDIENTE por cada criterio.

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
- Existen rutas frontend `/actions` y `/actions/templates/:id`.
- Existe feature `actions` con archivos `routes/service/types/views`.
- Vistas de Actions muestran labels en espanol.
- Tipos de Actions mantienen naming en ingles.
- Servicio de Actions consume endpoints de templates (fases 01/02) via cliente core `@/core/utils/axios`.
- El gate de no-regresion no-demo pasa (`observed <= baseline.ts_errors`).
