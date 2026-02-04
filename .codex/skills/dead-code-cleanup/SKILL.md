---
name: dead-code-cleanup
description: Limpieza de código muerto con evidencia. Evita borrar usos dinámicos.
---

REGLAS DURAS
- La limpieza va en PR separado del refactor funcional.
- Máx 10 eliminaciones por PR.
- Si hay duda: NO borrar. Marcar como “candidato”.
- Por cada archivo eliminado se requiere evidencia de NO uso:
  1) No importado (búsqueda global).
  2) No usado en router (lazy imports).
  3) No referenciado dinámicamente (registries/keys/strings).
  4) No requerido por build/test scripts.
- En Vue: asumir que puede haber usos dinámicos.
  Si no puedes demostrar que NO se usa, no lo borres.

FORMATO
- Lista “Candidatos a borrar” con:
  Path | Evidencia | Riesgo (low/med/high) | Cómo confirmar
- Para PR de borrado:
  Tabla “Eliminado” con Path + evidencia.
