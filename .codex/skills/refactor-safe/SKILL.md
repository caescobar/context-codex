---
name: refactor-safe
description: Refactor seguro por fases pequeñas. Cada fase debe compilar.
---

REGLAS DURAS
- Máx 5 archivos por fase (salvo que el usuario autorice).
- No cambiar comportamiento funcional salvo que se pida.
- Prohibido borrar archivos en fases 1–3 (solo en fase limpieza).
- Cada fase debe:
  1) compilar,
  2) pasar lint/build si existe,
  3) mantener UI/outputs iguales.

PROCESO
1) Diagnóstico con evidencia (paths).
2) Plan por fases (Fase 1 ahora, Fase 2 luego…).
3) Ejecutar SOLO la fase actual.
4) Resumen + checklist de verificación.
5) Esperar siguiente instrucción.
