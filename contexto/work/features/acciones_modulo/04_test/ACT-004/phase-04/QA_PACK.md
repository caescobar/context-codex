# QA PACK - acciones-modulo-act-004-phase-04

## 0) Metadata
- Fecha: 2026-02-20
- Tipo: QA PACK
- Objetivo: Validar Fase 04 de ACT-004 (flujo Device Detail customer para crear regla local/reusable, permisos y no-regresion).
- Entorno: frontend (`telemetric-front`) + API local opcional.
- Autor: Codex (asistido)

## 0.1 Trazabilidad del pack
- PackDir: `contexto/work/features/acciones_modulo/04_test/ACT-004/phase-04/`
- StoryId: `ACT-004`
- Requirement: `acciones_modulo`
- PhaseId: `04`
- ChangePlan: `contexto/work/features/acciones_modulo/02_plans/ACT-004.plan.md`
- ChangeSummary: `contexto/work/features/acciones_modulo/03_execution/ACT-004/phase-04.md`

---

## 1) Alcance
### 1.1 Incluye
- Verificacion de ruta customer objetivo: `'/my-devices/:id/edit'`.
- Verificacion del flujo local/reusable en `DeviceCustomerEditView.vue`:
  - selector de modo (`local`/`reusable`),
  - validacion `overridesJson` (JSON valido),
  - controles `isPaused`, `isLatchMode`, `cooldownSeconds`,
  - feedback de exito/error.
- Verificacion de gate UI por permiso `Actions.Assign`.
- Verificacion de uso de `actionsService.createRuleFromDevice` y contratos tipados asociados.
- Verificacion de no-regresion TypeScript no-demo.

### 1.2 No incluye
- E2E visual automatizado de navegador.
- Pruebas de carga.
- Cambios de codigo de producto.

---

## 2) Pre-requisitos
- Ejecutar desde raiz del repo.
- Herramientas: `rg`, `node`, `npm`.
- Frontend en `telemetric-front/`.
- API opcional en `http://localhost:5220` para validaciones integradas.

Variables esperadas para scripts:
- `DRY_RUN` (`1` por defecto)
- `FRONTEND_DIR` (default: `telemetric-front`)
- `API_BASE_URL` (default: `http://localhost:5220`)
- `API_AUTH_TOKEN` (opcional; si no existe, se intenta auto-login)
- `API_USER` / `API_PASSWORD` (defaults: `vcsoft` / `123456`)
- `SQLCMD_ARGS` (opcional)
- `TEST_DEVICE_ID` (opcional; autodiscovery si falta)
- `TEST_RULE_TEMPLATE_VERSION_ID` (opcional; autodiscovery si falta)

Baseline no-regresion (no-demo):
- `baseline.json`:
  - `scope: no-demo`
  - `ts_errors: 240`
  - `date: 2026-02-20`

---

## 2.5) Descubrimiento (fuentes y evidencia)

### Objetivo inferido (mandatorio por skill)
- Fuente: `contexto/work/features/acciones_modulo/02_plans/ACT-004.plan.md`
- Seccion: `Fase 4`
- Objetivo inferido: "Integrar flujo Device Detail sobre superficie customer decidida para local/reusable."

### Docker compose detectados
- `telemetric-hub/kiss/scripts/docker-compose.yml`
- `telemetric-api/old/docker-compose.yml`
- Decision: se documenta `telemetric-hub/kiss/scripts/docker-compose.yml` como compose operativo; `telemetric-api/old/` se considera legado.

### API base URL y runtime
- `http://localhost:5220`
- Evidencia:
  - `telemetric-api/src/Telemetric.Api/Properties/launchSettings.json`

### Evidencia funcional de fase 04
- Ruta customer:
  - `telemetric-front/src/router/MainRoutes.ts` (`/my-devices/:id/edit`)
- Vista principal del flujo:
  - `telemetric-front/src/features/customer/devices/views/DeviceCustomerEditView.vue`
- Servicio y contratos:
  - `telemetric-front/src/features/actions/actions.service.ts` (`createRuleFromDevice`)
  - `telemetric-front/src/features/actions/types.ts` (`CreateRuleFromDeviceRequest/Response`)
- Resumen de ejecucion:
  - `contexto/work/features/acciones_modulo/03_execution/ACT-004/phase-04.md`

### Comandos base y evidencia
- `rg --line-number -F '/my-devices/:id/edit' telemetric-front/src/router/MainRoutes.ts`
- `rg --line-number -F "ruleMode = ref<'local' | 'reusable'>('local')" telemetric-front/src/features/customer/devices/views/DeviceCustomerEditView.vue`
- `rg --line-number -F 'actionsService.createRuleFromDevice' telemetric-front/src/features/customer/devices/views/DeviceCustomerEditView.vue`
- `rg --line-number -F "permissions?.includes('Actions.Assign')" telemetric-front/src/features/customer/devices/views/DeviceCustomerEditView.vue`
- `rg --line-number -F 'Overrides JSON no es valido.' telemetric-front/src/features/customer/devices/views/DeviceCustomerEditView.vue`
- `npm --prefix telemetric-front run typecheck`

---

## 3) Setup
1. Ejecutar `scripts/setup.ps1` (Windows) o `scripts/setup.sh` (Linux/macOS).
2. Confirmar prerequisitos y discovery de artefactos de fase.
3. Verificar logs en `evidence/commands.log` y `evidence/outputs.log`.

## 4) Run
1. Ejecutar `scripts/run.ps1` o `scripts/run.sh`.
2. Flujo esperado:
- validar presencia de ruta customer y wiring de vista;
- validar gate de permiso `Actions.Assign`;
- validar flujo local/reusable y textos UI clave;
- validar parseo/normalizacion de `overridesJson`;
- validar traza de no-ruptura de edicion customer;
- evaluar gate no-regresion TypeScript no-demo contra `baseline.json`;
- registrar expected/observed en evidencia.

## 5) Teardown
- No-op seguro por defecto.
- No elimina datos ni artefactos de producto.
- Incluye nota explicita de cierre operativo y verificacion de runtime detenido cuando aplique.

## 6) Evidencia
- `evidence/commands.log`
- `evidence/outputs.log`
- `evidence/notes.md`

## 7) Resultados esperados (PASS)
- Ruta `'/my-devices/:id/edit'` sigue activa y apunta a `DeviceCustomerEditView`.
- Flujo local/reusable visible y operativo en `DeviceCustomerEditView`.
- Gate de permiso `Actions.Assign` presente en UI.
- `createRuleFromDevice` invocado con payload tipado y campos esperados.
- Mensajes UX clave en espanol y contratos internos en ingles.
- Gate no-regresion no-demo PASS (`observed <= baseline.ts_errors`).
