---
name: telemetric-backend-style
description: Estándar backend Telemetric (FastEndpoints + Command/Handler + Result + Connectors).
---

REGLAS DURAS
- No introducir Controllers: solo FastEndpoints.
- Antes de crear/modificar endpoints: buscar 2 endpoints similares y citar paths.
- Mantener patrón: Endpoint -> Command -> Handler -> Result<T>.
- No inventar métodos/sintaxis. Copiar el estilo real del repo.

CONNECTORS
- Prohibido registrar Redis/Rabbit/ClickHouse “a mano” si existe extensión estándar.
- Usar Options desde IConfiguration (sin hardcode).

SEGURIDAD
- CORS por ambiente (dev vs prod).
- JWT debe usar configuración real (Secret + Issuer + Audience si están definidos).

SALIDA OBLIGATORIA
- Lista de archivos a tocar antes de tocar código.
- Cómo probar (pasos).
