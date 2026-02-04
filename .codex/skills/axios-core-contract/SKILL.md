---
name: axios-core-contract
description: Contrato de uso de axios core: una sola instancia, interceptors, cancelación, error mapping.
---

REGLAS DURAS
- Debe existir una sola instancia de axios.
- Features NO importan axios directo.
- Cancelación: si el core tiene patrón (AbortController / signal / cancel token), usar el patrón existente.
- Errores: el core debe mapear a un formato estándar consumible por UI.

SALIDA OBLIGATORIA (ANTES DE CAMBIOS)
1) Identificar el archivo del axios core (path).
2) Resumir:
   - baseURL de dónde sale (env/config)
   - cómo agrega Authorization
   - cómo maneja 401/403
   - cómo expone errores (shape)
3) Solo después proponer cambios o services nuevos.
