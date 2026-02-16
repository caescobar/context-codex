---
name: telemetric-qa-pack-builder
description: Genera un QA Pack reproducible (scripts + evidencias) para validar una PHASE/AUDIT en Telemetric. Produce setup/run/teardown + checklist + capturas de evidencia en contexto/05_tests/.
---

# Telemetric QA Pack Builder — Skill

## Propósito
Crear un **QA Pack reproducible** para validar cambios (PHASE) o validar hallazgos (AUDIT) con:
- scripts (setup/run/teardown),
- pasos manuales cuando no sea automatizable,
- y **evidencia replicable** guardada en `contexto/05_tests/`.

Este skill **NO implementa cambios de código**. Solo crea artefactos de QA.

---

## Modos permitidos
- `docs-only` (obligatorio): solo escribir/editar archivos dentro de `contexto/`.

---

## REGLAS DURAS
1) NO tocar código de producto (fuera de `contexto/`).
2) Solo escribir en `contexto/`.
3) No inventar puertos, nombres de containers, rutas o comandos:
   - debe **descubrirlos** leyendo el repo (docker-compose, launchSettings, env files),
   - si no es posible, pedir **NECESITO 1 RESPUESTA**.
4) Todo QA Pack debe incluir: setup, run, teardown, evidencia, checklist.
5) Slugs y filenames en ASCII (a-z0-9-). Prohibido tildes/ñ.
6) El QA Pack debe ser reproducible por un humano: si Codex no puede ejecutar algo, debe dejar comandos/pasos claros.
7) En `QA_PACK.md` debe existir una sección **"Descubrimiento (fuentes y evidencia)"** donde:
   - liste los archivos del repo usados para inferir comandos (compose, env, launchSettings, Program.cs, README, scripts),
   - y para cada comando importante incluya `Evidencia:` con paths exactos.

8) Los scripts (setup/run/teardown) deben ser **seguro-no-op por defecto**:
   - incluir un flag `DRY_RUN=1` (o equivalente) y,
   - si `DRY_RUN=1`, solo imprime comandos sin ejecutarlos.
   - si el entorno no permite esto, dejarlo documentado en `notes.md`.

9) La evidencia siempre debe generarse aunque sea “manual”:
   - `evidence/commands.log` debe contener los comandos (reales o a ejecutar),
   - `evidence/outputs.log` debe tener “Expected” y un bloque “Observed (pendiente)” si no se ejecutó.

10) Si el repo tiene un `docker-compose*.yml`, los scripts deben usarlo por path exacto.
    Si hay múltiples, escoger el que corresponda y justificar en `QA_PACK.md` (Evidencia).
---

## SALIDA / ENTREGABLES OBLIGATORIOS
Crear un directorio:

`pack_dir = contexto/05_tests/packs/YYYY-MM-DD__qa-<slug>/`

Dentro, crear SIEMPRE:

1) `{pack_dir}/INDEX.md`
   - checklist `[ ]` / `[x]` por etapa (setup/run/verify/evidence/teardown/close)
2) `{pack_dir}/QA_PACK.md`
   - usando TEMPLATE_QA_PACK (ver en `contexto/01_overview/templates/`; si no existe, crear uno local dentro del pack)
3) `{pack_dir}/scripts/`
   - `setup.(ps1|sh)` (según entorno detectado; si hay Windows+Linux, crear ambos)
   - `run.(ps1|sh)`
   - `teardown.(ps1|sh)`
4) `{pack_dir}/evidence/`
   - `commands.log` (comandos ejecutados o a ejecutar)
   - `outputs.log` (salidas esperadas/observadas)
   - `notes.md` (qué no se pudo automatizar y por qué)

Opcional (si aplica):
- `{pack_dir}/evidence/docker_logs_*.log`
- `{pack_dir}/evidence/redis_dump_*.txt`
- `{pack_dir}/evidence/clickhouse_queries.sql`
- `{pack_dir}/evidence/clickhouse_results.txt`

---

## INPUT CONTRACT (lo que debe venir en el input humano)
El usuario debe proveer al menos:
- Referencia a PHASE o AUDIT (PackDir + ItemId + Prompt/Output si existe)
- Objetivo a validar (Done Criteria)
- Restricciones relevantes (ej: no cambiar contratos externos)
Si falta el target endpoint o compose/puertos y no se puede detectar, pedir **NECESITO 1 RESPUESTA**.

---

## OUTPUT FORMAT (en la respuesta)
1) `PackDir: ...`
2) Archivos creados (lista)
3) Qué se puede ejecutar automático vs manual (2 listas cortas)
