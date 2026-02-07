# CHANGE PLAN – phase-01__frontend-http-axios-core-contrato-errores-fase-1 – Fase 01

## 0) Metadata
- Fecha: 2026-02-06
- Alcance: phase-01__frontend-http-axios-core-contrato-errores-fase-1
- Modo: refactor-safe + change-control
- Skills: telemetric-frontend-style, refactor-safe

## 0.1 Trazabilidad del pack
- PackDir: contexto/00_prompts/2026-02-04__pack-audit-pack-inicial-global/
- PhaseId: PHASE-01
- IndexRef: contexto/00_prompts/2026-02-04__pack-audit-pack-inicial-global/INDEX.md
- PromptSource: contexto/00_prompts/2026-02-04__pack-audit-pack-inicial-global/phases/phase-01__frontend-http-axios-core-contrato-errores-fase-1__PHASE__PROMPT.md

## 1) Objetivo
- Definir un solo AXIOS CORE canonico y un contrato de error unificado para auth/login/refresh/permisos dentro del alcance.

## 2) Archivos a tocar (máx 5)
- telemetric-front/src/core/utils/axios.ts
- telemetric-front/src/utils/axios.ts
- telemetric-front/src/core/index.ts
- telemetric-front/src/utils/helpers/fetch-wrapper.ts
- telemetric-front/src/features/auth/auth.service.ts

## 3) Evidencia (paths)
- AXIOS CORE actual: telemetric-front/src/core/utils/axios.ts
- Uso alterno (a unificar): telemetric-front/src/utils/axios.ts
- fetchWrapper actual (deprecado por estándar): telemetric-front/src/utils/helpers/fetch-wrapper.ts
- Services similares (referencia de patrón): telemetric-front/src/features/admin/clients/client.service.ts
- Services similares (referencia de patrón): telemetric-front/src/features/admin/units/unit.service.ts

## 4) Plan en 5 bullets
1) Definir contrato de error en AXIOS CORE (tipo + normalizador) y emitir eventos de error/éxito desde el core.
2) Reusar AXIOS CORE como único cliente: adaptar `src/utils/axios.ts` a re-export del core.
3) Reimplementar fetchWrapper para delegar al AXIOS CORE y mantener manejo 401/403 en el wrapper.
4) Migrar auth.service a AXIOS CORE y retornar `response.data` tipado.
5) Completar plan/summary + actualizar índice.

## 5) Riesgos y mitigaciones
- Riesgo: cambio de shape de error para consumidores existentes. Mitigación: normalizador con `message` + `status` y mantener fallback de strings.
- Riesgo: doble emisión de eventos. Mitigación: eventos sólo desde AXIOS CORE.

## 6) Cómo verificar (pasos manuales)
1) Login con credenciales válidas y observar flujo de autenticación. Expected: se obtiene token y se usa el mismo cliente canónico; no hay redirects inesperados.
2) Forzar refresh de token (expirar token y repetir acción). Expected: el refresh se procesa correctamente y los errores se reportan con el contrato unificado.
3) Acceder a un recurso con permisos insuficientes. Expected: el error 401/403 sigue el contrato unificado y el flujo de UI responde de forma consistente.

## 7) No-go rules (si pasa esto, parar)
- Tocar archivos fuera del alcance o superar 5 archivos.
- Cambiar contratos externos sin migración explícita.
- No poder completar verificación manual requerida.

## 8) Post-step (actualizar checklist)
- Marcar `[x]` en `IndexRef` para `PHASE-01`.
- Completar/actualizar links a Plan y Summary en el índice.

