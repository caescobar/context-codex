# CHANGE PLAN – frontend-http-axios-core-contrato-errores-fase-2 – Fase 02

## 0) Metadata
- Fecha: 2026-02-06
- Alcance: PHASE-02
- Modo: refactor-safe + change-control
- Skills: telemetric-frontend-style

## 0.1 Trazabilidad del pack
- PackDir: contexto/00_prompts/2026-02-04__pack-audit-pack-inicial-global/
- PhaseId: PHASE-02
- IndexRef: contexto/00_prompts/2026-02-04__pack-audit-pack-inicial-global/INDEX.md
- PromptSource: contexto/00_prompts/2026-02-04__pack-audit-pack-inicial-global/phases/phase-02__frontend-http-axios-core-contrato-errores-fase-2__PHASE__PROMPT.md

## 1) Objetivo
- Migrar servicios principales y telemetry history a axios core con contrato de error unificado, sin cambiar contratos externos.

## 2) Archivos a tocar (máx 5)
- telemetric-front/src/services/organization.service.ts
- telemetric-front/src/features/telemetry/telemetry.service.ts
- telemetric-front/src/features/admin/devices/device.service.ts
- telemetric-front/src/features/admin/security/security.service.ts
- telemetric-front/src/features/admin/units/unit.service.ts

## 3) Evidencia (paths)
- Axios core canónico: telemetric-front/src/core/utils/axios.ts
- Ejemplo de service con axios core: telemetric-front/src/features/auth/auth.service.ts
- Ejemplo adicional usando axios core: telemetric-front/src/stores/apps/notes.ts
- Uso actual de fetchWrapper en servicios de alcance: telemetric-front/src/services/organization.service.ts, telemetric-front/src/features/admin/devices/device.service.ts, telemetric-front/src/features/admin/security/security.service.ts, telemetric-front/src/features/admin/units/unit.service.ts
- Telemetry history con fetch() y silenciamiento de errores: telemetric-front/src/features/telemetry/telemetry.service.ts

## 4) Plan en 5 bullets
1) Reemplazar fetchWrapper por axios core en organization.service y mantener manejo 401/403 con ApiError.
2) Migrar device/user/role/permission/unit services a axios core tipado y manejo de error unificado.
3) Reescribir telemetry history con httpClient, sin fetch(), y propagar ApiError.
4) Verificar tipado mínimo (payloads y respuestas) sin usar any.
5) Documentar cambios y actualizar IndexRef (check + links).

## 5) Riesgos y mitigaciones
- Riesgo: cambio en manejo de 401/403 al salir de fetchWrapper. Mitigación: replicar logout + redirect /forbidden con ApiError.
- Riesgo: respuesta de history no-Array. Mitigación: lanzar ApiError con mensaje explícito.

## 6) Cómo verificar (pasos manuales)
1) Acción: API_CALL: listar organizations con un usuario válido. Expected: la llamada usa axios core y los errores 401/403 siguen el contrato unificado.
2) Acción: API_CALL: ejecutar telemetry history y forzar un 500. Expected: el error se reporta con el contrato unificado (sin devolver [] silencioso).
3) Acción: API_CALL: acceder a listados de admin devices/units/security con permisos insuficientes. Expected: el manejo 401/403 es consistente con el contrato unificado.

## 7) No-go rules (si pasa esto, parar)
- Tocar archivos fuera del alcance o superar 5 archivos de código.
- Cambiar contratos externos (Redis/Rabbit/SignalR) sin migración explícita.
- No poder cumplir la verificación manual.

## 8) Post-step (actualizar checklist)
- Marcar `[x]` en `IndexRef` para `PHASE-02`.
- Completar/actualizar links a Plan y Summary en el índice.
