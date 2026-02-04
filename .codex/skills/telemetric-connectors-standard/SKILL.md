---
name: telemetric-connectors-standard
description: Estándares de conectores (Redis/Rabbit/ClickHouse) compartidos por API y KISS, con SQL como fuente de verdad.
---

MODELO DE VERDAD (NO NEGOCIABLE)
- SQL Server = fuente de verdad (transaccional).
- Redis = cache/lookup rápido para Hub/Workers + algunas consultas del front.
- ClickHouse = histórico/analítica/reportes.
- Hub/Workers no deben depender de SQL para procesar frames (usan Redis).

REGLAS DURAS
- No inventar nombres: Redis keys/fields, exchanges, routing keys, queues.
- Antes de escribir código: buscar y citar 2 ejemplos en el repo (paths).
- Toda configuración debe venir de IConfiguration/appsettings (no const strings en Program.cs).
- Prohibido duplicar DI: cada host registra conectores de UNA sola forma.
- Prohibido cambiar contratos (keys/routing) sin migración explícita.

CHECKLIST CANÓNICO
- Redis:
  - prefixes: DeviceHashPrefix, UsagePrefix
  - fields: estado, decryptor, decrypt_key, transformer, out_conn, cuotaMax, platform_id
  - Regla: updates a Redis vienen desde SQL (alta/edición de dispositivos) o jobs de rebuild.
- Rabbit:
  - exchange + routing keys + queues centralizados en Options/Constants
- ClickHouse:
  - connection string en Options; usado solo para persistir/leer histórico

SALIDA OBLIGATORIA ANTES DE CAMBIOS
- “Voy a tocar estos archivos: …”
- “Nombres canónicos encontrados: …”
- “Plan en 5 bullets”
- “Cómo verificar” (pasos manuales o script)
- “Riesgo de romper contratos” (sí/no + por qué)

SI HAY DUDA
- No asumir. Preguntar 1 vez con 2–3 opciones.


TTL POLICY
- Prohibido aplicar TTL a keys de configuración de dispositivo (device config). Deben ser persistentes.
- TTL solo permitido para caches/estado temporal (last_seen, locks, rate_limit, last_value, etc.).
- Si se introduce TTL, debe quedar documentado: key pattern + duración + motivo.
