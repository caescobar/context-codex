PackDir: contexto/00_prompts/2026-02-04__pack-audit-pack-inicial-global
ItemId: PHASE-03
IndexRef: contexto/00_prompts/2026-02-04__pack-audit-pack-inicial-global/INDEX.md
PromptPath: contexto/00_prompts/2026-02-04__pack-audit-pack-inicial-global/phases/phase-03__endurecer-cors-jwt-limpiar-duplicados-di__PHASE__PROMPT.md

Modo: refactor-safe + change-control
Skills: telemetric-backend-style

Objetivo
- Endurecer CORS/JWT y limpiar duplicados en DI.

Alcance (max 5 archivos)
- telemetric-api/src/Telemetric.Api/Program.cs
- telemetric-api/src/Telemetric.Api/appsettings.json
- telemetric-api/src/Telemetric.Api/Infrastructure/DependencyInjection.cs

Entregables
- contexto/02_changes/2026-02-06__phase-03__endurecer-cors-jwt-limpiar-duplicados-di__plan.md
- contexto/02_changes/2026-02-06__phase-03__endurecer-cors-jwt-limpiar-duplicados-di__summary.md
- Actualizar contexto/03_hallazgos/pending.md solo si hay hallazgos nuevos o cambio de estado.

Guardrails
- Maximo 5 archivos y solo los del Alcance.
- No ampliar alcance.
- Prohibido cambiar contratos externos (Redis key patterns, Rabbit routing keys, SignalR group naming) sin migracion explicita.
- Si algun path no existe: buscar y confirmar el path real antes de continuar.

No-go rules
- Requiere tocar archivos fuera del Alcance o superar 5 archivos.
- Implica cambiar contratos externos sin migracion explicita.
- No se puede cumplir la verificacion.

Verificacion (pasos manuales)
1. Accion: Configurar entorno prod y ejecutar preflight CORS desde un origin no permitido.
   Expected: Preflight falla; no se incluye el origin en la respuesta.
2. Accion: Ejecutar preflight CORS desde un origin permitido.
   Expected: Preflight pasa y se incluye el origin permitido.
3. Accion: Generar token con issuer o audience incorrectos y realizar una llamada protegida.
   Expected: 401/unauthorized por issuer o audience invalido.
4. Accion: Generar token con issuer y audience validos y realizar la misma llamada.
   Expected: 200/OK (o respuesta autorizada segun permisos).
5. Accion: Revisar DI y registrar services para IAuthorizationPolicyProvider y IAuthorizationHandler.
   Expected: No hay registros duplicados activos.

Done criteria
- CORS solo permite origins esperados.
- JWT rechaza issuer/audience invalidos.
- DI sin duplicados.

Tarea
1) Ejecutar cambios minimos para cumplir el Objetivo limitado al Alcance.
2) Completar plan y summary usando templates con evidencia (paths exactos).
3) En summary: resultado observado vs expected para cada paso de verificacion + Done criteria.

Post-step
- Marcar [x] PHASE-03 en IndexRef.
- Completar/actualizar links de Output (plan y summary) en el indice.
