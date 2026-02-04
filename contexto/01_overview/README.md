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

Input:
{{pega aquí tu descripción natural del problema o feature}}

Tarea:
Genera un PROMPT FINAL estandarizado (clasifica: HALLAZGO | AUDIT | PHASE | STORY PACK) y REGÍSTRALO además en:
- contexto/00_prompts/{{YYYY-MM-DD}}__{{slug}}__{{tipo}}.md

Regla:
Tu salida debe incluir un bloque PROMPT FINAL listo para copiar/pegar.
No ejecutes cambios de código.
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
