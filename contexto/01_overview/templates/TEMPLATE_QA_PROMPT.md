# TEMPLATE_QA_PROMPT – {{slug}}

PackDir: {{pack_dir}}
ItemId: {{QaId}}                         <!-- ej: QA-01 -->
IndexRef: {{pack_dir}}/INDEX.md
PromptPath: {{pack_dir}}/qa/{{qa_prompt_filename}}  <!-- ej: qa-01__...__QA__PROMPT.md -->

Modo: docs-only
Skills: {{skills}}                       <!-- ej: telemetric-backend-style, telemetric-connectors-standard -->

Objetivo
{{objetivo}}

Alcance
- No tocar código.
- Solo escribir en `contexto/`.
- Cubrir casos/escenarios definidos para la fase.
- Endpoint(s) clave: {{endpoints}}
- Servicios/stack: {{stack}}             <!-- ej: docker-compose + redis + rabbit + clickhouse + hub + hostigador -->

Entregables
- `contexto/05_qa/{{YYYY-MM-DD}}__{{QaIdLower}}__{{slug}}__qa.md` usando `contexto/01_overview/templates/TEMPLATE_QA_PACK.md`
- Actualizar `contexto/03_hallazgos/pending.md` **solo** si aparecen hallazgos nuevos
- Actualizar `IndexRef`:
  - marcar `[x] {{QaId}}`
  - completar/actualizar link de Output del QA

Guardrails
- Solo escribir en `contexto/`
- Prohibido modificar código o configuraciones fuera de `contexto/`
- No inventar comandos/queries exactos si no se conocen:
  - usar placeholders accionables: `DOCKER:`, `REDIS_CLI:`, `CLICKHOUSE_SQL:`, `SQL:`, `API_CALL:`, `RABBIT:`, `SIGNALR:`
- No pedir confirmación: escribir los archivos en `contexto/` directamente

No-go rules
- Ejecutar pruebas reales (solo documentar pasos)
- Cambiar contratos externos (Redis keys / Rabbit routing / SignalR groups)
- Escribir fuera de `contexto/`

Verificación (pasos manuales)
1) Accion: DOCKER: `<comando aqui>`
   Expected: <resultado esperado>

2) Accion: REDIS_CLI: `<comando aqui>`
   Expected: <resultado esperado>

3) Accion: API_CALL: `<comando aqui>`
   Expected: <resultado esperado>

4) Accion: CLICKHOUSE_SQL: `<query aqui>`
   Expected: <resultado esperado>

Post-step
- Marcar `[x] {{QaId}}` en `IndexRef`
- Completar/actualizar link de Output del QA en `IndexRef`
