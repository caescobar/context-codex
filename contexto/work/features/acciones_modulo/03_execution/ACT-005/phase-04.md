# FASE 04 — ACT-005

## Estado
DONE

## Standards Lock Check
- Backend: ADOPTED (ref: audit A0)
- SQLServer: ADOPTED (ref: audit A0)
- Frontend: ADOPTED (ref: audit A0)

## FIX Mode
- is_fix: 0
- fix_id: NA
- fix_pack_used: NA

## Files touched (max 5)
- telemetric-front/src/features/customer/devices/views/DeviceCustomerEditView.vue
- telemetric-front/src/features/actions/types.ts
- telemetric-front/src/features/actions/actions.service.ts
- contexto/openapi/actions.yaml
- contexto/work/features/acciones_modulo/03_execution/ACT-005/phase-04.md

## Changes summary
- Se alineó `/my-devices/:id/edit` al contrato DSL canonico ACT-005 para `create-from-device` en modo reusable: builder guiado con `ruleType`, condicion, evaluacion, missing data policy, lifecycle y recipients email.
- Se eliminó la captura libre de `Definition JSON` y `Overrides JSON` en Device Customer, reemplazandola por campos estructurados y validaciones previas al submit.
- Se tipó `CreateRuleFromDeviceRequest` en frontend para usar `definitionJson: RuleDefinitionV1` y `overridesJson: RuleInstanceOverridesV1`.
- Se agregó adaptador en `actions.service` para serializar `definitionJson`/`overridesJson` al formato backend actual (string JSON), manteniendo compatibilidad sin cambiar endpoint backend.
- Se actualizó `contexto/openapi/actions.yaml` para reflejar contrato tipado de `create-from-device` (`DefinitionJsonV1` + `RuleInstanceOverridesV1`).

## Verification checklist
- `npm --prefix telemetric-front run typecheck` ejecutado.
- Resultado observado: `total_errors=139`, `non_demo_errors=118`.
- Gate no-regresion FE no-demo: PASS (se mantiene baseline `118` del phase-03).
- Flujo local mantiene seleccion de template/version y no altera guardado general de Device Customer.
- Flujo reusable usa el mismo contrato DSL canonico de ACT-005 y valida `T <= W`, `HOLD_LAST_VALUE` con TTL > 0 y recipients email validos.
- Overrides v1 quedan acotados a `threshold` y `email.recipients` mediante formulario tipado.

## Notes / Risks
- El backend `create-from-device` sigue recibiendo strings JSON internamente; el frontend cubre compatibilidad via serializacion en servicio.
- Persisten errores de typecheck global fuera de alcance de la historia (incluye `_demo` y modulos no relacionados), sin incremento en no-demo.
