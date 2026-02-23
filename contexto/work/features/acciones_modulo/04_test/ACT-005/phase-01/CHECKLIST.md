# CHECKLIST - ACT-005 phase-01

## Objetivo
Validar la Fase 01 de ACT-005: alineacion de contratos FE/BE/OpenAPI al DSL canonico v1.

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
- Accion: revisar `contexto/work/features/acciones_modulo/03_execution/ACT-005/phase-01.md`.
- PASS: existe resumen de cambios de contrato DSL para fase 01.

2. OpenAPI con contrato DSL v1
- Accion: inspeccionar `contexto/openapi/actions.yaml`.
- PASS: create/update referencian `DefinitionJsonV1`.

3. Discriminator por `ruleType`
- Accion: inspeccionar `DefinitionJsonV1`.
- PASS: existe `discriminator.propertyName=ruleType`.

4. Cobertura de `ruleType` canonicos
- Accion: inspeccionar schema OpenAPI.
- PASS: aparecen los 5 tipos acordados en decisiones ACT-005.

5. Validacion backend de objeto JSON
- Accion: inspeccionar endpoints create/update.
- PASS: validadores usan `JsonValueKind.Object`.

6. Normalizacion backend de `DefinitionJson`
- Accion: inspeccionar endpoints create/update.
- PASS: se usa `GetRawText()` para persistencia consistente.

7. Token de ruta update alineado
- Accion: comparar endpoint update vs OpenAPI.
- PASS: ambos usan `{ruleTemplateId}`.

8. Tipos FE alineados al DSL
- Accion: inspeccionar `telemetric-front/src/features/actions/types.ts`.
- PASS: existe `RuleType` y modelado de `durationSeconds` acorde a tipos con duracion.

9. Typecheck no-regresion no-demo (obligatorio en DRY_RUN=0)
- Accion: ejecutar `npm --prefix telemetric-front run typecheck`.
- PASS: `observed_no_demo_ts_errors <= baseline.ts_errors`.
- FAIL: `observed_no_demo_ts_errors > baseline.ts_errors`.

10. Auto-login/autodiscovery (trazabilidad operativa)
- Accion: en `DRY_RUN=0`, revisar logs de auto-login y autodiscovery SQL.
- PASS: `outputs.log` registra resultado (OK/FAIL) de ambos intentos sin romper corrida de contrato.

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
