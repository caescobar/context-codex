# QA PACK - acciones-modulo-act-004-phase-03

## 0) Metadata
- Fecha: 2026-02-20
- Tipo: QA PACK
- Objetivo: Validar Fase 03 de ACT-004 (frontend de asignacion masiva de template-version a dispositivos con feedback de duplicados).
- Entorno: frontend (`telemetric-front`) + API local opcional.
- Autor: Codex (asistido)

## 0.1 Trazabilidad del pack
- PackDir: `contexto/work/features/acciones_modulo/04_test/ACT-004/phase-03/`
- StoryId: `ACT-004`
- Requirement: `acciones_modulo`
- PhaseId: `03`
- ChangePlan: `contexto/work/features/acciones_modulo/02_plans/ACT-004.plan.md`
- ChangeSummary: `contexto/work/features/acciones_modulo/03_execution/ACT-004/phase-03.md`

---

## 1) Alcance
### 1.1 Incluye
- Verificacion de contratos frontend para asignacion masiva (`AssignTemplateToDevices*`, `AssignableDevice`).
- Verificacion de servicio con:
  - `POST /actions/assignments/template-version`.
  - `GET /devices` para dispositivos asignables.
- Verificacion de UI en `ActionsTemplatesView.vue` y `ActionTemplateDetailView.vue`:
  - seleccion multiple de dispositivos;
  - accion "Asignar seleccionados";
  - feedback por estado (`Asignado`, `Duplicado`, `Fuera de alcance`);
  - conteos `createdCount/rejectedCount`.
- Verificacion de gate no-regresion TypeScript no-demo.

### 1.2 No incluye
- Pruebas E2E visuales automatizadas de navegador.
- Pruebas de carga.
- Cambios de codigo de producto.

---

## 2) Pre-requisitos
- Ejecutar desde raiz del repo.
- Herramientas: `rg`, `node`, `npm`.
- Frontend en `telemetric-front/`.
- API opcional en `http://localhost:5220` para validaciones manuales integradas.

Variables esperadas para scripts:
- `DRY_RUN` (`1` por defecto)
- `FRONTEND_DIR` (default: `telemetric-front`)

Baseline de no-regresion (no-demo):
- `baseline.json`:
  - `scope: no-demo`
  - `ts_errors: 240`
  - `date: 2026-02-20`

---

## 2.5) Descubrimiento (fuentes y evidencia)

### Objetivo inferido (mandatorio por skill)
- Fuente: `contexto/work/features/acciones_modulo/02_plans/ACT-004.plan.md`
- Seccion: `Fase 3`
- Objetivo inferido: "Extender frontend Actions para asignacion masiva y feedback de duplicados."

### Docker compose detectados
- `telemetric-hub/kiss/scripts/docker-compose.yml`
- `telemetric-api/old/docker-compose.yml`
- Decision: se documenta `telemetric-hub/kiss/scripts/docker-compose.yml` como compose operativo; el compose en `telemetric-api/old/` se considera legado por ubicacion.

### API base URL y runtime
- `http://localhost:5220`
- Evidencia:
  - `telemetric-api/src/Telemetric.Api/Properties/launchSettings.json`

### Endpoints backend de soporte (fases 01/02)
- `POST /api/v1/actions/assignments/template-version`
- `POST /api/v1/actions/assignments/create-from-device`
- `GET /api/v1/actions/templates/{RuleTemplateId}`
- OpenAPI: `contexto/openapi/actions.yaml`

### Frontend de fase 03 (evidencia principal)
- Servicio:
  - `telemetric-front/src/features/actions/actions.service.ts`
  - operaciones `assignTemplateToDevices` y `getAssignableDevices`.
- Contratos:
  - `telemetric-front/src/features/actions/types.ts`
  - estados `Created`, `RejectedDuplicate`, `RejectedNotFoundOrOutOfScope`.
- Vistas:
  - `telemetric-front/src/features/actions/views/ActionsTemplatesView.vue`
  - `telemetric-front/src/features/actions/views/ActionTemplateDetailView.vue`
- Resumen de ejecucion de fase:
  - `contexto/work/features/acciones_modulo/03_execution/ACT-004/phase-03.md`

### Comandos base y evidencia
- `rg --line-number -F "assignTemplateToDevices" telemetric-front/src/features/actions`
- `rg --line-number -F "/actions/assignments/template-version" telemetric-front/src/features/actions/actions.service.ts`
- `rg --line-number -F "getAssignableDevices" telemetric-front/src/features/actions/actions.service.ts`
- `rg --line-number -F "RejectedDuplicate" telemetric-front/src/features/actions`
- `rg --line-number -F "Fuera de alcance" telemetric-front/src/features/actions/views`
- `npm --prefix telemetric-front run typecheck`

---

## 3) Setup
1. Ejecutar `scripts/setup.ps1` (Windows) o `scripts/setup.sh` (Linux/macOS).
2. Confirmar prerequisitos y discovery de archivos de fase.
3. Verificar logs en `evidence/commands.log` y `evidence/outputs.log`.

## 4) Run
1. Ejecutar `scripts/run.ps1` o `scripts/run.sh`.
2. Flujo esperado:
- validar contratos y servicio de asignacion masiva;
- validar strings/estados de feedback en UI;
- validar traza de `Reuse-first` en resumen de fase;
- ejecutar gate no-regresion TS no-demo contra `baseline.json`;
- registrar expected/observed en evidencia.

## 5) Teardown
- No-op seguro por defecto.
- No elimina datos ni artefactos de producto.
- Solo registra cierre operativo en evidencia.

## 6) Evidencia
- `evidence/commands.log`
- `evidence/outputs.log`
- `evidence/notes.md`

## 7) Resultados esperados (PASS)
- Existen contratos tipados de asignacion masiva en `types.ts`.
- Servicio de Actions incluye asignacion por template-version y carga de dispositivos.
- UI presenta feedback de estados por dispositivo (`Asignado`, `Duplicado`, `Fuera de alcance`).
- Conteos de `createdCount` y `rejectedCount` se muestran en UI.
- Gate no-regresion no-demo PASS (`observed <= baseline.ts_errors`).
