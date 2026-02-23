# CHECKLIST - ACT-005 phase-02

## Objetivo
Validar la Fase 02 de ACT-005: validacion semantica DSL server-side en create/update template y create-from-device reusable.

## Precondiciones
1. API disponible en `telemetric-api`.
2. Entorno con `dotnet`, `rg`, `node`, `npm`.
3. Frontend disponible en `telemetric-front/` para gate no-regresion no-demo.
4. (Opcional) Credenciales para auto-login (`API_USER`/`API_PASSWORD`) y `sqlcmd`.

## Setup
1. Ejecutar `scripts/setup.ps1` o `scripts/setup.sh`.
2. Verificar que se actualizan:
   - `evidence/commands.log`
   - `evidence/outputs.log`

## Verificaciones funcionales
1. Objetivo fase y traza de ejecucion
- Accion: revisar `contexto/work/features/acciones_modulo/03_execution/ACT-005/phase-02.md`.
- PASS: existe resumen de cambios de validacion semantica para fase 02.

2. Validacion semantica en create/update
- Accion: inspeccionar handlers `CreateTemplate` y `UpdateTemplate`.
- PASS: existe `ValidateAndNormalizeDefinitionJson` previo a persistencia.

3. Validacion semantica en create-from-device reusable
- Accion: inspeccionar `CreateRuleFromDeviceCommandHandler`.
- PASS: cuando `CreateReusableTemplate=true`, se valida/normaliza `DefinitionJson`.

4. Regla temporal `T <= W`
- Accion: inspeccionar mensajes de validacion en handlers.
- PASS: aparece rechazo para `evaluation.durationSeconds > evaluation.windowSeconds`.

5. Regla missing data `HOLD_LAST_VALUE`
- Accion: inspeccionar mensajes de validacion.
- PASS: se rechaza ausencia/valor invalido de `missingDataPolicy.ttlSeconds`.

6. Regla missing data `INSUFFICIENT_DATA`
- Accion: inspeccionar mensajes de validacion.
- PASS: se rechaza `missingDataPolicy.ttlSeconds` con valor cuando modo es `INSUFFICIENT_DATA`.

7. Validacion de recipients indexada
- Accion: inspeccionar mensajes de validacion.
- PASS: errores de recipients incluyen path por indice `action.recipients[i]`.

8. Estilo backend de errores
- Accion: inspeccionar endpoints create/update/create-from-device.
- PASS: endpoints mantienen `Send.ErrorsAsync(400)`.

9. Typecheck no-regresion no-demo (obligatorio en DRY_RUN=0)
- Accion: ejecutar `npm --prefix telemetric-front run typecheck`.
- PASS: `observed_no_demo_ts_errors <= baseline.ts_errors`.
- FAIL: `observed_no_demo_ts_errors > baseline.ts_errors`.

10. Auto-login/autodiscovery (trazabilidad operativa)
- Accion: en `DRY_RUN=0`, revisar logs de auto-login y autodiscovery SQL.
- PASS: `outputs.log` registra resultado (OK/FAIL) de auto-login y autodiscovery de `TEST_RULE_TEMPLATE_VERSION_ID` y `TEST_DEVICE_IDS`.

## Teardown
1. Ejecutar `scripts/teardown.ps1` o `scripts/teardown.sh`.
2. Registrar observaciones finales en `evidence/notes.md`.
3. Confirmar cierre runtime: toda instancia levantada durante QA fue apagada y verificada como detenida.

## Estado de corrida
- [x] Setup ejecutado
- [x] Run ejecutado completo
- [x] Teardown ejecutado
- [x] Evidencia completa en logs (`commands.log`, `outputs.log`)
- [x] QA cerrada
