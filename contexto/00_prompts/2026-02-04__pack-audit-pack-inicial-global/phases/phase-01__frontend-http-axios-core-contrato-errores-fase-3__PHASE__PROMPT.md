# PHASE-01 PROMPT - frontend-http-axios-core-contrato-errores-fase-3

PackDir: contexto/00_prompts/2026-02-04__pack-audit-pack-inicial-global/
ItemId: PHASE-01
IndexRef: contexto/00_prompts/2026-02-04__pack-audit-pack-inicial-global/INDEX.md
PromptPath: contexto/00_prompts/2026-02-04__pack-audit-pack-inicial-global/phases/phase-01__frontend-http-axios-core-contrato-errores-fase-3__PHASE__PROMPT.md

## Modo
refactor-safe + change-control

## Skills
- telemetric-frontend-style

## Objetivo
Migrar stores demo y limpiar imports residuales.

## Alcance (max 5 archivos)
- telemetric-front/src/stores/apps/blog.ts
- telemetric-front/src/stores/apps/chat.ts
- telemetric-front/src/stores/apps/email.ts
- telemetric-front/src/stores/apps/invoice/index.ts
- telemetric-front/src/stores/apps/notes.ts

## Entregables
- contexto/02_changes/2026-02-06__phase-01__frontend-http-axios-core-contrato-errores-fase-3__plan.md (usar contexto/01_overview/templates/TEMPLATE_CHANGE_PLAN.md)
- contexto/02_changes/2026-02-06__phase-01__frontend-http-axios-core-contrato-errores-fase-3__summary.md (usar contexto/01_overview/templates/TEMPLATE_CHANGE_SUMMARY.md)

## Guardrails
- Max 5 archivos (solo los listados en Alcance)
- No ampliar alcance
- Prohibido cambiar contratos externos (Redis key patterns, Rabbit routing keys, SignalR group naming) sin migracion explicita
- Si algun path no existe: buscar y confirmar el path real antes de continuar

## No-go rules
- Requiere tocar archivos fuera del Alcance o superar 5 archivos
- Implica cambiar contratos externos sin migracion explicita
- No se puede cumplir la verificacion

## Verificacion (pasos manuales)
1. Accion: Abrir la pantalla demo de Blog y ejecutar la carga/listado principal. Expected: La pantalla carga sin errores y no hay notificaciones de error inesperadas.
2. Accion: Abrir la pantalla demo de Chat y realizar la accion principal de lectura/carga. Expected: El flujo responde sin errores y el manejo de error es consistente.
3. Accion: Abrir la pantalla demo de Email e Invoice y ejecutar la carga inicial. Expected: La UI carga y los errores, si existen, se reportan con el contrato unificado (sin silencios).
4. Accion: Abrir la pantalla demo de Notes y provocar un error controlado (si aplica) usando el mecanismo disponible. Expected: Se muestra una notificacion de error consistente y no se silencian fallos.

## Done criteria
- Todos los cambios estan limitados a los 5 archivos del Alcance
- Las pantallas demo verificadas muestran manejo de error consistente y sin silencios
- La verificacion manual coincide con Expected en todos los pasos

## Tarea (ejecutor)
1) Ejecutar cambios minimos para cumplir el Objetivo limitado al Alcance
2) Completar plan + summary usando templates (con evidencia de paths)
3) En summary: resultado observado vs expected para cada paso de verificacion + Done criteria

## Post-step obligatorio
- Marcar [x] PHASE-01 en IndexRef
- Completar/actualizar links de Output (plan y summary) en el indice
