# CHANGE SUMMARY – frontend-http-axios-core-contrato-errores-fase-2 – Fase 02

## 0) Metadata
- Fecha: 2026-02-06
- PR/Commit (si aplica):

## 0.1 Trazabilidad del pack
- PackDir: contexto/00_prompts/2026-02-04__pack-audit-pack-inicial-global/
- PhaseId: PHASE-02
- IndexRef: contexto/00_prompts/2026-02-04__pack-audit-pack-inicial-global/INDEX.md
- PromptSource: contexto/00_prompts/2026-02-04__pack-audit-pack-inicial-global/phases/phase-02__frontend-http-axios-core-contrato-errores-fase-2__PHASE__PROMPT.md

## 1) Qué cambió
- Servicios principales migrados de fetchWrapper a axios core con manejo de error unificado (ApiError + 401/403).
- Telemetry history reimplementado con httpClient y propagación de errores sin silencios.

## 2) Archivos tocados
- telemetric-front/src/services/organization.service.ts
- telemetric-front/src/features/telemetry/telemetry.service.ts
- telemetric-front/src/features/admin/devices/device.service.ts
- telemetric-front/src/features/admin/security/security.service.ts
- telemetric-front/src/features/admin/units/unit.service.ts
- contexto/02_changes/2026-02-06__phase-02__frontend-http-axios-core-contrato-errores-fase-2__plan.md
- contexto/02_changes/2026-02-06__phase-02__frontend-http-axios-core-contrato-errores-fase-2__summary.md
- contexto/00_prompts/2026-02-04__pack-audit-pack-inicial-global/INDEX.md

## 3) Cómo probar
1) Acción: API_CALL: listar organizations con un usuario válido. Expected: la llamada usa axios core y los errores 401/403 siguen el contrato unificado.
2) Acción: API_CALL: ejecutar telemetry history y forzar un 500. Expected: el error se reporta con el contrato unificado (sin devolver [] silencioso).
3) Acción: API_CALL: acceder a listados de admin devices/units/security con permisos insuficientes. Expected: el manejo 401/403 es consistente con el contrato unificado.

## 4) Resultado esperado / observado
- Paso 1: Expected: usa axios core + contrato 401/403. Observado: no ejecutado (pendiente de verificación manual).
- Paso 2: Expected: error unificado (no [] silencioso). Observado: no ejecutado (pendiente de verificación manual).
- Paso 3: Expected: manejo 401/403 consistente. Observado: no ejecutado (pendiente de verificación manual).

## 5) Hallazgos nuevos o pendientes
- Ninguno.

## 6) Riesgo de romper contratos
- No. No se tocaron contratos externos; solo cliente HTTP y manejo de error.

## 7) Post-step (actualizar checklist)
- Marcar `[x]` en `IndexRef` para `PHASE-02`.
- Completar/actualizar links a Summary en el índice.
