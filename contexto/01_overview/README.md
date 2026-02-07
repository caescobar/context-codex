# Guía de trabajo con IA (Codex) — Telemetric

Esta guía define **cómo trabajamos con IA** (Codex) de forma **controlada, auditable y replicable**, sin “prompts mágicos”.

La idea es simple:
- **Skills = reglas permanentes del proyecto**
- **Prompts = objetivo puntual (lo que queremos hoy)**
- **Entregables = archivos Markdown dentro de `contexto/`** para trazabilidad

---

## 1) Principios (no negociables)

### 1.1 Skills vs Prompts
- **Skills**: estándares que siempre aplican (contratos Redis/Rabbit/SignalR, estilo backend/front, etc.).
- **Prompts**: lo mínimo para describir el objetivo del momento y el output esperado.

> No repetimos todo en cada prompt.  
> El prompt debe ser **corto**, pero con guardrails cuando haga falta.

### 1.2 Modos de trabajo
- **report-only**: diagnóstico / auditoría. **No toca código**.
- **refactor-safe + change-control**: cambios controlados. **Plan → Cambios → Summary**.

### 1.3 Evidencia
- No se acepta “creo que…” o “asumo que…”.
- Toda conclusión importante debe citar **evidencia con paths** del repo (mínimo 2 cuando aplique).
- Si no se encuentra algo: escribir **“No encontrado”**.

### 1.4 Contratos
- Prohibido inventar o cambiar sin migración explícita:
  - Redis keys/fields
  - Rabbit exchanges/routing keys/queues
  - SignalR group naming
- Si un cambio toca contratos, debe documentarse como decisión y plan de migración.

### 1.5 Contrato canonico de Identidad/Telemetria
Basado en evidencia existente. Referencias:
- `contexto/01_audits/2026-02-04__audit-01__identidad-telemetria-serial-vs-sql-id.md`
- `contexto/03_hallazgos/pending.md` (HALL-20260204-001..003)

**Definiciones**
- `serial`: identificador natural del dispositivo (string). Es la identidad externa para routing y grupos.
- `platform_id` (SQL id): identidad interna (INT) usada para persistencia y payload.
- `TelemetryEnvelope.DeviceId`: string que representa el SQL id cuando `platform_id` existe.

**Routing / Group vs Payload vs Persistencia**
- RabbitMQ routing key: `telemetry.device.{serial}` (routing por serial).
- SignalR group: `device_{serial}` (suscripción por serial).
- Payload: `TelemetryEnvelope.DeviceId` = SQL id (cuando hay `platform_id`).
- Redis config: `device:{serial}` y campo `platform_id`.
- Redis last-value: `device:{id}:last` (id actual = `DeviceId` del payload).

**Mapeo serial <-> platform_id**
- Resolución primaria: Redis config `device:{serial}` contiene `platform_id`.
- DTE usa `platform_id` como `DeviceId` en el payload normalizado.
- Cuando falta `platform_id`, no se debe persistir ni publicar telemetry normalizada (ver invariantes).

**Invariantes (no-go)**
- Prohibido persistir telemetria con `DeviceId=0`.
- Si falta `platform_id`, el flujo normalizado debe abortar con evidencia (log/metric) y no publicar/persistir.
- No cambiar:
  - Redis key patterns (ej: `device:{serial}`, `device:{id}:last`)
  - Rabbit routing keys (ej: `telemetry.device.{serial}`)
  - SignalR group naming (ej: `device_{serial}`)
  sin migración explícita.

**Notas de riesgo conocidas**
- Mismatch serial vs SQL id puede dejar snapshots vacíos en Redis last-value (ver HALL-20260204-002).
- Semántica mixta de `DeviceId` en payload vs routing requiere documentación explícita (ver HALL-20260204-003).

---

## 2) Estructura de `contexto/`

> `contexto/` es la “memoria auditable” del proyecto (para humanos y para la IA).

Recomendado:

- `contexto/00_overview/`
  - `README.md` (este archivo)
  - `templates/` (plantillas Markdown)
  - `migration-log.md` (historial de reorganizaciones/documentos)
- `contexto/01_audits/`  
  - Auditorías **report-only** (diagnóstico).
- `contexto/02_changes/`  
  - Planes y resúmenes de fases (ejecución controlada).
- `contexto/03_hallazgos/`
  - `pending.md` (ledger único de hallazgos/bugs/pendientes).
- `contexto/04_specs/`
  - Story packs / requerimientos implementables.
- `contexto/05_evidencias/`
  - screenshots, logs, dumps, notas rápidas de pruebas.

---

## 3) Templates (plantillas)

Las plantillas viven en:
- `contexto/00_overview/templates/`

Plantillas esperadas:
- `TEMPLATE_AUDIT.md`
- `TEMPLATE_STORY.md`
- `TEMPLATE_CHANGE_PLAN.md`
- `TEMPLATE_CHANGE_SUMMARY.md`
- `TEMPLATE_PENDING.md`

> Regla: cuando se pida un AUDIT/STORY/PHASE, la IA debe usar estas plantillas.

---

## 4) Tipos de trabajo con IA (elige el correcto)

### A) AUDIT (diagnóstico, no tocar código)
Uso: entender cómo está hoy y qué se rompería.
Output: un reporte en `contexto/01_audits/` y hallazgos en `pending.md`.

### B) PHASE (ejecutar cambios acotados)
Uso: aplicar una fase concreta con cambios controlados.
Output: `phase_X_plan.md` + `phase_X_summary.md` en `contexto/02_changes/` + update de `pending.md`.

### C) REGISTRAR HALLAZGO (bug fuera de fase o encontrado al probar)
Uso: registrar un error para corregir después (aunque no esté relacionado con la fase).
Output: un item nuevo en `contexto/03_hallazgos/pending.md`.

### D) STORY PACK (requerimiento implementable)
Uso: convertir una conversación/idea en historia técnica con criterios de aceptación.
Output: un documento en `contexto/04_specs/`.

### E) DOC REORG (ordenar documentación)
Uso: mover/renombrar archivos dentro de `contexto/` sin cambiar contenido.
Output: `migration-log.md` actualizado con mapping origen→destino.

---

## 5) Prompts mínimos (copy/paste)

> IMPORTANTE: en cada prompt, reemplaza `YYYY-MM-DD` y `slug`.

### 5.1 AUDIT-min
Modo: report-only
Skills: telemetric-connectors-standard, telemetric-backend-style

Objetivo:
Confirmar el contrato real de identidad (serial vs sqlDeviceId) en Redis/Rabbit/SignalR/Payload.

Entregables:

contexto/01_audits/YYYY-MM-DD_audit-identidad-telemetria.md (usar TEMPLATE_AUDIT.md)

Actualizar contexto/03_hallazgos/pending.md (usar TEMPLATE_PENDING.md) si hay hallazgos

Scope:

Redis: device:{X} + fields (deviceId, platform_id)

Rabbit: exchange + routing keys (telemetry.device.{X})

SignalR: group naming (device_{X})

Payload: TelemetryEnvelope (significado de DeviceId hoy)

Guardrails:

No tocar código. Citar paths como evidencia.

---

## 4) Prompt Builder (generador de prompts)

Usamos el skill **`telemetric-prompt-builder`** para convertir una descripción natural (texto libre) en un **PROMPT FINAL** estandarizado (HALLAZGO | AUDIT | PHASE | STORY PACK) y dejar **historial** en `contexto/00_prompts/`.

**Reglas de modo:** ver `contexto/01_overview/MODES.md`.

### 4.1 Prompt para invocar Prompt Builder (copia/pega)

```txt
Modo: docs-only
Skills: telemetric-prompt-builder

Input (texto humano):
<PEGA AQUÍ TU DESCRIPCIÓN NATURAL>

Tarea:
1) Clasifica en: HALLAZGO | AUDIT | PHASE | STORY PACK (rationale en 2 bullets).
2) Determina el PackDir:
   - Si el input refiere a un pack existente, usar ese pack.
   - Si no, crear uno nuevo: contexto/00_prompts/YYYY-MM-DD__pack-{slug}/
3) Crea/actualiza el índice del pack:
   - contexto/00_prompts/YYYY-MM-DD__pack-{slug}/INDEX.md
   Reglas del índice:
   - Debe incluir checkboxes de estado del pack.
   - Debe incluir cada item con checkbox + links a Prompt y Output.
4) Guarda el prompt en:
   - contexto/00_prompts/YYYY-MM-DD__pack-{slug}/{itemId}__{slug}__{tipo}__PROMPT.md
5) (Si aplica) Actualiza en el INDEX el link de Output con ruta real esperada:
   - AUDIT -> contexto/01_audits/YYYY-MM-DD__{itemId}__{slug}.md
   - PHASE -> contexto/02_changes/YYYY-MM-DD__{itemId}__{slug}__phase-X_{plan|summary}.md
   - STORY -> contexto/04_storypacks/YYYY-MM-DD__{itemId}__{slug}.md
   - HALLAZGO -> contexto/03_hallazgos/pending.md (o item link)

Guardrails:
- Solo escribir en contexto/
- No tocar código
- No pedir confirmación: escribir los archivos en contexto/ directamente.
- No incluir `report-only` como skill si el prompt debe escribir en contexto/.
-PHASE: max 5 archivos de código.
-Prohibido cambiar contratos externos (Redis key patterns, Rabbit routing keys, SignalR group naming) sin migración explícita.

Salida obligatoria:
- CLASIFICACIÓN
- PROMPT FINAL (listo para copiar/pegar)
- ARCHIVO (PackDir + archivo prompt creado)
- INDEX actualizado

```

### 4.2 Uso recomendado (2 pasos)
1) **Builder:** genera PROMPT FINAL + archivo en `contexto/00_prompts/`.
2) **Executor:** copia/pega el PROMPT FINAL en Codex para ejecutar (AUDIT/PHASE/HALLAZGO/STORY).



---

## Packs de prompts y checklist
Trabajamos por **packs** en `contexto/00_prompts/YYYY-MM-DD__pack-<slug>/`.
Cada pack tiene un `INDEX.md` con checklist `[ ]` para ver progreso.

### Cómo iniciar (Prompt Builder)
Usa siempre este arranque:

```txt
Modo: docs-only
Skills: telemetric-prompt-builder
Input: <describe en texto libre lo que necesitas>
```

El builder generará:
- `pack_dir/INDEX.md`
- `pack_dir/_history.md`
- prompts ejecutables `audit-XX__...__PROMPT.md`, `phase-XX__...__PROMPT.md`, etc.

Los prompts ejecutores deben **marcar [x]** su item en `INDEX.md` al finalizar.

## Ejemplo de uso para fase
Aqui hay algunos ejemplos de uso

```txt
Modo: docs-only
Skills: telemetric-prompt-builder

Input (texto humano):
Usar PackDir existente: contexto/00_prompts/2026-02-04__pack-audit-pack-inicial-global/
Fuente obligatoria: contexto/01_audits/2026-02-05__audit-03__hardening-minimo-cors-jwt-ef-authorization-duplicada.md
Quiero generar el PROMPT FINAL para ejecutar PHASE-03 basada en la sección “Plan sugerido por fases”, Fase 3. 
Usa exactamente el objetivo/archivos/verificación definidos ahí, sin ampliar alcance.

Tarea:
1) Clasifica en: HALLAZGO | AUDIT | PHASE | STORY PACK (rationale en 2 bullets).
2) Determina el PackDir:
   - Si el input refiere a un pack existente, usar ese pack.
   - Si no, crear uno nuevo: contexto/00_prompts/YYYY-MM-DD__pack-{slug}/
3) Crea/actualiza el índice del pack:
   - contexto/00_prompts/YYYY-MM-DD__pack-{slug}/INDEX.md
   Reglas del índice:
   - Debe incluir checkboxes de estado del pack.
   - Debe incluir cada item con checkbox + links a Prompt y Output.
4) Guarda el prompt en:
   - contexto/00_prompts/YYYY-MM-DD__pack-{slug}/phases/phase-03__{slug}__PHASE__PROMPT.md 
5) (Si aplica) Actualiza en el INDEX el link de Output con ruta real esperada:
   - PHASE -> contexto/02_changes/YYYY-MM-DD__phase-02__{slug}__{plan|summary}.md

Guardrails:
- Solo escribir en contexto/
- No tocar código
- No pedir confirmación: escribir los archivos en contexto/ directamente.
- No incluir report-only como skill si el prompt debe escribir en contexto/.
- PHASE: max 5 archivos de código.
- Prohibido cambiar contratos externos (Redis key patterns, Rabbit routing keys, SignalR group naming) sin migración explícita.

Salida obligatoria:
- CLASIFICACIÓN
- PROMPT FINAL (listo para copiar/pegar)
- ARCHIVO (PackDir + archivo prompt creado)
- INDEX actualizado
```


### Ejemplo sugerido para generacion de QA

Modo: docs-only
Skills: telemetric-prompt-builder

Input (texto humano):
Usar PackDir existente: contexto/00_prompts/2026-02-04__pack-audit-pack-inicial-global/
Quiero generar el PROMPT FINAL de QA para validar PHASE-01 (2026-02-04__phase-01__validar-invariantes-id-platform-id).
Objetivo QA: comprobar que NO se generan inserts con DeviceId=0 y que sin platform_id NO se publica/persiste (deja evidencia log/warn/metric).
Contexto técnico: stack docker-compose; endpoint Hub: POST /api/v1/ingest-raw (formato 'serial.payload'); existe hostigador que simula dispositivo; Redis es fuente de config.

Tarea:
1) Clasifica en: HALLAZGO | AUDIT | PHASE | STORY PACK (rationale en 2 bullets).
2) Determina el PackDir:
   - Si el input refiere a un pack existente, usar ese pack.
   - Si no, crear uno nuevo: contexto/00_prompts/YYYY-MM-DD__pack-{slug}/
3) Crea/actualiza el índice del pack:
   - contexto/00_prompts/YYYY-MM-DD__pack-{slug}/INDEX.md
   Reglas del índice:
   - Debe incluir checkboxes de estado del pack.
   - Debe incluir cada item con checkbox + links a Prompt y Output.
4) Guarda el prompt en:
   - contexto/00_prompts/YYYY-MM-DD__pack-{slug}/{itemId}__{slug}__{tipo}__PROMPT.md
5) (Si aplica) Actualiza en el INDEX el link de Output con ruta real esperada:
   - AUDIT -> contexto/01_audits/YYYY-MM-DD__{itemId}__{slug}.md
   - PHASE -> contexto/02_changes/YYYY-MM-DD__{itemId}__{slug}__phase-X_{plan|summary}.md
   - STORY -> contexto/04_storypacks/YYYY-MM-DD__{itemId}__{slug}.md
   - HALLAZGO -> contexto/03_hallazgos/pending.md (o item link)
   - QA -> contexto/05_qa/YYYY-MM-DD__{itemId}__{slug}__qa.md

Guardrails:
- Solo escribir en contexto/
- No tocar código
- No pedir confirmación: escribir los archivos en contexto/ directamente.
- No incluir `report-only` como skill si el prompt debe escribir en contexto/.
- PHASE: max 5 archivos de código.
- Prohibido cambiar contratos externos (Redis key patterns, Rabbit routing keys, SignalR group naming) sin migración explícita.

Salida obligatoria:
- CLASIFICACIÓN
- PROMPT FINAL (listo para copiar/pegar)
- ARCHIVO (PackDir + archivo prompt creado)
- INDEX actualizado


### Ejemplo sugerido ejecucion de pack de QA

Modo: change-control (local-run permitido)
Skills: telemetric-qa-pack-builder

Objetivo:
Ejecutar el QA Pack y dejar evidencia reproducible (comandos + outputs + logs) para validar PHASE-01.

Input:
Usar QA Pack existente:
- QA Pack: contexto/05_tests/packs/2026-02-05__qa-audit-07-validar-invariantes-id-platform-id/QA_PACK.md
- Scripts: contexto/05_tests/packs/2026-02-05__qa-audit-07-validar-invariantes-id-platform-id/scripts/
- Evidence dir: contexto/05_tests/packs/2026-02-05__qa-audit-07-validar-invariantes-id-platform-id/evidence/

Tarea:
1) Leer el QA_PACK.md y ejecutar en orden:
   a) Setup (infra + hub + workers) siguiendo la sección 3.
   b) Preparación de datos A/B siguiendo sección 4.
   c) Ejecución sección 5 (pasos 1..7).
   d) Teardown (si aplica).
2) Capturar evidencia:
   - Registrar cada comando ejecutado en evidence/commands.log (una línea por comando).
   - Pegar outputs relevantes en evidence/outputs.log (con separadores claros por paso).
   - Guardar queries en evidence/clickhouse_queries.sql y resultados en evidence/clickhouse_results.txt.
   - Guardar notas de lo no automatizable en evidence/notes.md.
3) Completar la sección 6 y 7 del QA_PACK.md:
   - Reemplazar PENDIENTE por outputs reales (API/Rabbit/ClickHouse/Logs).
   - Completar Observed y marcar Done criteria con [x] o dejar [ ] si falla.
4) Si el QA pasa:
   - Marcar [x] AUDIT-07 en IndexRef indicado en el QA Pack.
5) Si el QA falla:
   - No inventar fixes.
   - Registrar un HALLAZGO nuevo en contexto/03_hallazgos/pending.md con evidencia exacta (logs/paths) y dejar estado Open.

Guardrails:
- No tocar código de producto (solo ejecutar y escribir evidencia en contexto/).
- No inventar resultados.
- Si un comando no existe o falla por entorno, documentarlo tal cual en evidence/notes.md y proponer el comando alternativo solo si está respaldado por el repo.
