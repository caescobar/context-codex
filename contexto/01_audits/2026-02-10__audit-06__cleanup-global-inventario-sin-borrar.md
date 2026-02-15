# AUDIT REPORT – audit-06__cleanup-global-inventario-sin-borrar

## 0) Metadata
- Fecha: 2026-02-10
- Modo: docs-only (audit-exec, sin cambios de código)
- Skills aplicadas: dead-code-cleanup
- Objetivo: Inventariar codigo y assets candidatos a cleanup global, sin borrar ni refactorizar.
- Repos/servicios: telemetric-api, telemetric-front, telemetric-hub, contexto, context-codex
- Autor: Codex (asistido)

## 0.1 Trazabilidad del pack
- PackDir: contexto/00_prompts/2026-02-04__pack-audit-pack-inicial-global
- AuditId: AUDIT-06
- IndexRef: contexto/00_prompts/2026-02-04__pack-audit-pack-inicial-global/INDEX.md
- PromptSource: contexto/00_prompts/2026-02-04__pack-audit-pack-inicial-global/audit-06__cleanup-global-inventario-sin-borrar__AUDIT__PROMPT.md

## 1) Executive Summary (máx 5 bullets)
- Se detectaron artefactos de IDE (.vs) y un zip de respaldo en frontend, sin referencias en el repo.
- Existen carpetas “legacy/plantilla” (telemetric-api/old, telemetric-front/template-project) sin uso observable en build/scripts.
- Se identifica un repo paralelo (context-codex) con contexto duplicado y sin referencias desde el workspace principal.
- No se realizaron cambios de código; se documenta inventario y evidencia de no uso.

## 2) Alcance (Scope)
### 2.1 Paths/archivos analizados
- telemetric-front/
- telemetric-front/template-project/
- telemetric-front/src.zip
- telemetric-api/old/
- telemetric-api/src/.vs/
- telemetric-hub/kiss/.vs/
- telemetric-hub/kiss/Telemetric.Hostigador/.vs/
- context-codex/

### 2.2 Fuera de alcance
- node_modules/** (dependencias de terceros)
- Carpeta `contexto/` (documentación interna, no candidata de cleanup de código)

## 3) Contrato actual observado (Fuente: código)
> Tabla obligatoria. No asumir. Si algo no se encontró, escribir “No encontrado”.

| Capa | Identidad externa (serial/id) | Key/Routing/Group | Campos/Shape | Evidencia (paths) |
|---|---|---|---|---|
| SQL | No encontrado | No encontrado | No encontrado | No encontrado |
| Redis config | No encontrado | No encontrado | No encontrado | No encontrado |
| Redis last-value | No encontrado | No encontrado | No encontrado | No encontrado |
| Rabbit raw | No encontrado | No encontrado | No encontrado | No encontrado |
| Rabbit normalized | No encontrado | No encontrado | No encontrado | No encontrado |
| SignalR | No encontrado | No encontrado | No encontrado | No encontrado |
| Payload | No encontrado | No encontrado | No encontrado | No encontrado |

## 4) Nombres canónicos encontrados (no inventar)
- No encontrado.
**Evidencia:** No encontrado.

## 5) Hallazgos (con evidencia)
> Cada hallazgo debe tener: severidad, impacto, evidencia, repro si aplica, recomendación.

### High
- Sin hallazgos High.

### Medium
- Sin hallazgos Medium.

### Low
- Sin hallazgos Low.

## 5.1 Inventario de candidatos a cleanup (sin borrar)
> Formato “Candidatos a borrar” (dead-code-cleanup). Evidencia basada en búsqueda global sin matches.

| Path | Evidencia | Riesgo | Cómo confirmar |
|---|---|---|---|
| telemetric-front/src.zip | No hay referencias a `src.zip` en el workspace (búsqueda global). | Low | Confirmar que no hay scripts de build/deploy que consuman el zip. |
| telemetric-front/template-project/ | No hay referencias a `template-project` en el workspace. | Medium | Verificar si es plantilla oficial y si existe uso en onboarding/documentación interna. |
| telemetric-api/old/ | No hay referencias a `old/` dentro de `telemetric-api` (sólo aparece en docs). | Medium | Confirmar que no participa en build/CI y que no se usa como referencia contractual. |
| telemetric-api/src/.vs/ | No hay referencias a `.vs` en el workspace. | Low | Confirmar que no se versiona en git y agregar a ignore si aplica. |
| telemetric-hub/kiss/.vs/ | No hay referencias a `.vs` en el workspace. | Low | Confirmar que no se versiona en git y agregar a ignore si aplica. |
| telemetric-hub/kiss/Telemetric.Hostigador/.vs/ | No hay referencias a `.vs` en el workspace. | Low | Confirmar que no se versiona en git y agregar a ignore si aplica. |
| context-codex/ | No hay referencias a `context-codex` en el workspace; contiene `.git` propio y `contexto/` duplicado. | High | Confirmar si es repo separado o backup; si no se usa, mover fuera del workspace. |

## 6) Riesgos de romper contratos
- Riesgo: borrar `telemetric-api/old/` o `template-project/` podría eliminar referencias históricas usadas en comparativas/manuales.
- Mitigación: validar uso real en CI/docs y, si aplica, archivar fuera del repo antes de eliminar.

## 7) Recomendación priorizada
1) Limpiar artefactos IDE (`.vs`) si están versionados o moverlos fuera del repo.
2) Confirmar que `telemetric-front/src.zip` es un backup local y eliminarlo del repo si no se usa.
3) Definir si `telemetric-front/template-project` y `telemetric-api/old` son legacy útiles o deben archivarse.
4) Clarificar propósito de `context-codex/` y si debe vivir fuera del workspace principal.

## 8) Plan sugerido por fases (sin ejecutar)
> Máx 5 archivos por fase. No cambiar contratos sin migración.

### Fase 1
- Objetivo: retirar artefactos de IDE no versionables.
- Archivos potenciales (máx 5): telemetric-api/src/.vs/, telemetric-hub/kiss/.vs/, telemetric-hub/kiss/Telemetric.Hostigador/.vs/
- Verificación: confirmar que la solución abre y compila sin caches previas.

### Fase 2
- Objetivo: eliminar backups locales en frontend.
- Archivos potenciales (máx 5): telemetric-front/src.zip
- Verificación: `npm run build` y validar que no hay referencias al zip.

### Fase 3
- Objetivo: resolver legacy/duplicados.
- Archivos potenciales (máx 5): telemetric-front/template-project/, telemetric-api/old/, context-codex/
- Verificación: validar CI/build y revisar documentación interna de plantillas/legacy.

## 9) Cómo verificar (smoke test)
1) `dotnet build` en `telemetric-api/src/`.
2) `dotnet build` en `telemetric-hub/kiss/`.
3) `npm run build` en `telemetric-front/`.

## 10) Pendientes registrados
- Sin nuevos hallazgos registrados en `contexto/03_hallazgos/pending.md`.
