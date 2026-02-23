# SPEC v1 - Frontend Health

## 0) Objetivo
Reducir deuda tecnica de TypeScript en frontend sin bloquear el delivery funcional de features de negocio.

## 1) Alcance
### Incluye
- Estrategia de no-regresion de typecheck por fases.
- Reduccion progresiva de errores TypeScript en alcance no-demo.
- Priorizacion por impacto tecnico (contratos HTTP, maps, customer, core/ui, legacy).

### Excluye
- Refactors masivos no acotados por fase.
- Cambios funcionales de negocio fuera de corregir tipado/regresiones tecnicas.

## 2) Politica operativa
- Alcance principal: `telemetric-front/src/**` excluyendo `telemetric-front/src/_demo/**`.
- Baseline inicial no-demo: `240` errores (2026-02-19).
- Una fase pasa si:
  - no aumenta el conteo no-demo respecto al baseline vigente;
  - y no introduce errores en archivos tocados.

## 3) Fuentes de verdad
- Backlog canonico:
  - `contexto/work/backlogs/front-typecheck/FRONT-TYPECHECK_v1.md`
- Evidencia de baseline inicial:
  - `contexto/work/features/acciones_modulo/04_test/ACT-003/phase-03/evidence/outputs.log`

## 4) Entregables por historia
- Plan de cambios por fase.
- Evidencia Before/After de conteo no-demo.
- QA pack por fase con gate no-regresion.

## 5) Guardrails
- Maximo 5 archivos de codigo por fase.
- No mezclar con delivery de historias de negocio.
- Reuse-first de patrones tipados existentes.
