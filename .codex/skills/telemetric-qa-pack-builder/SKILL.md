---
name: telemetric-qa-pack-builder
description: Genera un QA Pack reproducible (setup/run/teardown + evidencia + checklist) para una fase de Telemetric bajo contexto/work/features/.../04_test/. Usar cuando se necesita CREAR o REGENERAR el pack, incluyendo scripts ps1/sh robustos en quoting y DRY_RUN seguro.
---

# Telemetric QA Pack Builder

## Proposito
Crear o regenerar un QA Pack reproducible para validar una fase (`PHASE`) o auditoria (`AUDIT`) sin tocar codigo de producto.

## Modo permitido
- `docs-only`: solo escribir dentro de `contexto/`.

## Paths canonicos (obligatorios)
- `pack_dir = contexto/work/features/{requirement_slug}/04_test/{story_id}/phase-{phase_id}/`
- `story_index = contexto/work/features/{requirement_slug}/04_test/{story_id}/STORY_QA.md`

Reglas:
- `story_id` tipo `ACT-00N`.
- `phase_id` siempre a 2 digitos (`01..99`).
- Nunca usar rutas legacy (`contexto/05_tests/...`).

## Input contract
Obligatorio:
- `requirement_slug`
- `story_id`
- `phase_id`

Opcional:
- objetivo explicito de validacion
- restricciones operativas

## Inferencia de objetivo (mandatoria)
Si no llega objetivo:
1. Leer `contexto/work/features/{requirement_slug}/02_plans/{story_id}.plan.md`.
2. Buscar la seccion de la fase.
3. Prioridad de extraccion:
- `Objetivo:`
- `Cambios esperados (alto nivel)`
- `Checklist de verificacion (concreto)` resumido.
4. Si no se puede inferir: pedir `NECESITO 1 RESPUESTA` (maximo 1 pregunta).

## Reglas duras
1. No tocar nada fuera de `contexto/`.
2. No inventar puertos, compose, endpoints o credenciales: descubrir en repo y citar evidencia.
3. El pack debe incluir siempre: setup, run, teardown, checklist, evidencia.
4. `DRY_RUN=1` por defecto en scripts.
5. `evidence/commands.log` y `evidence/outputs.log` siempre presentes.
6. Si hay multiples `docker-compose*`, elegir uno y justificarlo en `QA_PACK.md`.
7. Si falta un dato critico no inferible: `NECESITO 1 RESPUESTA`.
8. Si el entorno define credenciales QA estables en evidencia previa, incluir defaults en `run.ps1/run.sh` (override por variables de entorno).
9. Si `API_AUTH_TOKEN` no viene por input, `run` debe intentar auto-login y registrar resultado.
10. Si faltan IDs de prueba (`TEST_RULE_TEMPLATE_VERSION_ID`, `TEST_DEVICE_IDS`), `run` debe intentar autodiscovery via `sqlcmd` y registrar evidencia.
11. Documentar regla de cierre: toda instancia levantada durante QA debe apagarse y verificarse como detenida.

## Entregables obligatorios
Dentro de `{pack_dir}`:
1. `INDEX.md`
2. `QA_PACK.md`
3. `CHECKLIST.md`
4. `scripts/setup.ps1`, `scripts/run.ps1`, `scripts/teardown.ps1`
5. `scripts/setup.sh`, `scripts/run.sh`, `scripts/teardown.sh`
6. `evidence/commands.log`, `evidence/outputs.log`, `evidence/notes.md`

Opcional:
- `queries.sql`
- `seed.sql`
- evidencia adicional

## Generacion robusta de scripts (MANDATORIO)
Aplicar estas reglas al crear scripts:

### PowerShell (`*.ps1`)
1. Evitar regex fragil con llaves `{}` en `rg`; usar literal con `-F -e`:
- Bueno: `rg --line-number -F -e '/api/v1/actions/templates/{RuleTemplateId}' ...`
- Evitar patrones regex con `{}` sin escape.
2. Para HTTP JSON en ejecucion real, preferir `Invoke-RestMethod` + `ConvertTo-Json` (hashtable) en vez de strings `curl` con quoting complejo.
3. Mantener branch `DRY_RUN=1` sin strings con escaping profundo que rompan parseo.
4. Registrar todos los comandos en `commands.log` y expected/observed en `outputs.log`.
5. Si no hay `API_AUTH_TOKEN`, intentar login automático con `API_USER`/`API_PASSWORD` (defaults descubiertos, con override).
6. Si faltan IDs de prueba, autodetectar con `sqlcmd` (top no borrados) y dejar trazabilidad en `outputs.log`.

### Bash (`*.sh`)
1. Mantener `set -euo pipefail`.
2. Si `DRY_RUN=0` requiere parser JSON (`jq`), validar presencia y fallar con mensaje claro si falta.
3. Guardar scripts en UTF-8 sin BOM para no romper shebang.
4. Si no hay `API_AUTH_TOKEN`, intentar login automático con `API_USER`/`API_PASSWORD` (defaults descubiertos, con override).
5. Si faltan IDs de prueba, autodetectar con `sqlcmd` (top no borrados) y registrar evidencia.

### Cross-platform
1. Usar paths relativos al repo cuando sea posible.
2. No asumir que se puede crear procesos en background; eso pertenece al executor.
3. El builder solo crea scripts y documenta limitaciones en `evidence/notes.md`.

## Contenido minimo por script
- `setup`: prerequisitos + discovery + build/checks basicos.
- `run`: checks funcionales de la fase + evidencia.
- `teardown`: limpieza segura no destructiva (o no-op documentado).
- `teardown`: incluir nota explicita de cierre de runtime (si se levantaron instancias en ejecución, deben apagarse y verificarse).

## QA_PACK.md obligatorio
Debe incluir seccion `Descubrimiento (fuentes y evidencia)` con paths exactos:
- compose
- launch settings
- endpoints/policies
- scripts/comandos base

## STORY_QA.md
Crear o actualizar indice por fase en:
- `contexto/work/features/{requirement_slug}/04_test/{story_id}/STORY_QA.md`

## Output en respuesta
1. `PackDir: ...`
2. Archivos creados/actualizados
3. Automatizable vs manual
4. Resumen de descubrimiento con evidencia (paths)
