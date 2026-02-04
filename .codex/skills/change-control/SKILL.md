---
name: change-control
description: Control estricto: plan y límites antes de modificar código.
---

ANTES DE CAMBIAR CÓDIGO (OBLIGATORIO)
- Lista exacta de archivos a tocar (paths).
- Qué función/clase se afecta.
- Qué cambio harás y por qué.
- Cómo verificar (pasos manuales o comandos).

REGLAS DURAS
- No mover carpetas.
- No renombrar masivamente.
- No reformatear masivamente.
- Si aparece un problema nuevo fuera del objetivo:
  NO cambiar de objetivo. Registrar en “Hallazgos” y seguir el plan.

SALIDA AL FINAL
- Resumen tipo PR: qué se cambió, archivos tocados, cómo probar.
