# Operating Modes (contrato)

Estos **modos** son una convención del repo para controlar permisos y entregables al trabajar con IA.

## report-only
**Permisos**
- Prohibido crear/editar/mover/borrar archivos.
- Prohibido cambiar código.

**Output**
- Solo respuesta en chat (audit/report).

## docs-only
**Permisos**
- Permitido crear/editar **solo** dentro de `contexto/`.
- Prohibido cambiar código.

**Output**
- Archivos Markdown en `contexto/` (historial, pending, etc.).

## refactor-safe + change-control
**Permisos**
- Permitido cambiar código, con control estricto.

**Guardrails**
- Máx 5 archivos de código por fase.
- No cambiar contratos externos (Redis keys/fields, Rabbit routing keys, SignalR group naming) sin migración explícita.
- Si requiere >5 archivos: detenerse y dejar solo plan.
