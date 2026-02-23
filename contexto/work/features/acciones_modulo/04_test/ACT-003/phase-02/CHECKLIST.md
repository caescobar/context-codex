# CHECKLIST - ACT-003 phase-02

## Objetivo
Validar la Fase 02 de ACT-003: detalle de template + update con versionado inmutable.

## Precondiciones
1. API levantada y accesible en `http://localhost:5220`.
2. Usuario con permisos `Actions.View` y `Actions.Update`.
3. Existe al menos un `RuleTemplate` utilizable (`RULE_TEMPLATE_ID`).

## Setup
1. Ejecutar `scripts/setup.ps1` o `scripts/setup.sh`.
2. Verificar que se actualizan:
   - `evidence/commands.log`
   - `evidence/outputs.log`

## Verificaciones funcionales
1. Contract check en codigo
- Accion: `rg` de rutas/policies/tags en endpoints de templates.
- PASS: aparecen `Get/Put` sobre `/api/v1/actions/templates/{RuleTemplateId}`, `Tags("Actions")`, policies `Actions.View/Update`.

2. OpenAPI check
- Accion: verificar `contexto/openapi/actions.yaml`.
- PASS: contiene `GET/PUT /api/v1/actions/templates/{ruleTemplateId}`.

3. GET detalle
- Accion: `GET /api/v1/actions/templates/{RuleTemplateId}` con bearer token.
- PASS: HTTP 200 + payload con `versions`, `assignmentsCount`, `failedRunsCount`.

4. PUT update
- Accion: `PUT /api/v1/actions/templates/{RuleTemplateId}` con `name`, `description`, `definitionJson`, `isActive`.
- PASS: HTTP 200 + `ruleTemplateVersionId` y `versionNumber`.

5. Inmutabilidad/versionado
- Accion: GET antes y despues del PUT.
- PASS:
  - `versionNumber_post = versionNumber_pre + 1`
  - la version previa sigue en `versions`.

6. SQL opcional (si hay `sqlcmd`)
- Accion: ejecutar `queries.sql` con `RuleTemplateId`.
- PASS:
  - no hay duplicados por `(RuleTemplateId, VersionNumber)`
  - existe historial de versiones para el template probado.

## Teardown
1. Ejecutar `scripts/teardown.ps1` o `scripts/teardown.sh`.
2. Registrar observaciones finales en `evidence/notes.md`.

## Estado de corrida
- [x] Setup ejecutado (2026-02-18)
- [x] Run ejecutado completo (2026-02-18, `RULE_TEMPLATE_ID=3`)
- [x] Teardown ejecutado (2026-02-18)
- [x] Evidencia completa en logs (`commands.log`, `outputs.log`)
- [x] QA cerrada
