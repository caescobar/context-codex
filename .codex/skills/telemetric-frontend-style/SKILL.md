---
name: telemetric-frontend-style
description: Estándar frontend Telemetric (Vue 3 + features + AXIOS CORE único + tipos).
---

DECISIÓN DE PROYECTO (NO NEGOCIABLE)
- El cliente HTTP estándar es AXIOS CORE.
- Prohibido usar fetch() directo.
- Prohibido usar fetchWrapper.
- Prohibido importar axios directamente desde features.
- Prohibido crear axios instances fuera del core.

REGLAS DURAS DE IMPLEMENTACIÓN
1) Toda llamada HTTP debe pasar por el core:
   - Importar SIEMPRE desde: core/http/httpClient (o el path real del proyecto).
2) Todo service debe ser tipado:
   - No usar payload:any en features nuevos.
   - Definir Request/Response types en *.types.ts dentro del feature.
3) No inventar patrones:
   - Antes de implementar, buscar 2 ejemplos similares y citar paths.
4) No reestructurar:
   - Prohibido mover carpetas/renames masivos sin orden explícita.
5) Manejo de errores unificado:
   - Los services no deben “inventar” shapes de error.
   - Usar el error-mapping estándar del core.

PROTOCOLO OBLIGATORIO (ANTES DE CODEAR)
1) Encontrar 2 services similares existentes y citar paths.
2) Confirmar el path del axios core (core/http/...) y citarlo.
3) Definir types (Request/Response).
4) Implementar service con axios core.
5) En componentes/composables:
   - cleanup obligatorio (abort/cancel si aplica; remove listeners/subs).
6) Resumen:
   - archivos tocados
   - cómo probar (pasos manuales)

ANTI-DESVÍO
- Si aparece deuda técnica no pedida, NO desviarse.
- Registrar en “Hallazgos” y seguir el objetivo.
