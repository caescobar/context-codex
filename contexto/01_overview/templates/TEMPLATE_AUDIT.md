# AUDIT REPORT – {{slug}}

## 0) Metadata
- Fecha: {{YYYY-MM-DD}}
- Modo: docs-only (audit-exec, sin cambios de código)
- Skills aplicadas: {{skills}}
- Objetivo: {{objetivo}}
- Repos/servicios: {{repos}}
- Autor: Codex (asistido)

## 0.1 Trazabilidad del pack
- PackDir: {{pack_dir}}
- AuditId: {{audit_id}}        <!-- ej: AUDIT-01 -->
- IndexRef: {{index_ref}}      <!-- ej: contexto/00_prompts/.../INDEX.md -->
- PromptSource: {{prompt_path}} <!-- ej: contexto/00_prompts/.../audit-01__...__PROMPT.md -->

## 1) Executive Summary (máx 5 bullets)
- ...
- ...

## 2) Alcance (Scope)
### 2.1 Paths/archivos analizados
- {{path}}
- {{path}}

### 2.2 Fuera de alcance
- ...

## 3) Contrato actual observado (Fuente: código)
> Tabla obligatoria. No asumir. Si algo no se encontró, escribir “No encontrado”.

| Capa | Identidad externa (serial/id) | Key/Routing/Group | Campos/Shape | Evidencia (paths) |
|---|---|---|---|---|
| SQL |  |  |  |  |
| Redis config |  |  |  |  |
| Redis last-value |  |  |  |  |
| Rabbit raw |  |  |  |  |
| Rabbit normalized |  |  |  |  |
| SignalR |  |  |  |  |
| Payload |  |  |  |  |

## 4) Nombres canónicos encontrados (no inventar)
- Redis: prefixes, fields
- Rabbit: exchanges, routing keys, queues
- SignalR: group naming
**Evidencia:** (paths)

## 5) Hallazgos (con evidencia)
> Cada hallazgo debe tener: severidad, impacto, evidencia, repro si aplica, recomendación.

### High
- **HALL-{{id}} – {{título}}**
  - Impacto:
  - Evidencia (paths):
  - Repro (si aplica):
  - Recomendación:

### Medium
- ...

### Low
- ...

## 6) Riesgos de romper contratos
- Riesgo:
- Mitigación:

## 7) Recomendación priorizada
1) ...
2) ...

## 8) Plan sugerido por fases (sin ejecutar)
> Máx 5 archivos por fase. No cambiar contratos sin migración.

### Fase 1
- Objetivo:
- Archivos potenciales (máx 5):
- Verificación:

### Fase 2
- ...

### Fase 3
- ...

## 9) Cómo verificar (smoke test)
1) ...
2) ...

## 10) Pendientes registrados
- Añadir/actualizar en `contexto/03_hallazgos/pending.md`: HALL-...
