# QA PACK – {{slug}}

## 0) Metadata
- Fecha: {{YYYY-MM-DD}}
- Tipo: QA PACK
- Objetivo: {{objetivo}}
- Entorno: {{entorno}} (docker-compose / local / CI)
- Autor: Codex (asistido)

## 0.1 Trazabilidad del pack
- PackDir: {{PackDir}}
- ItemId: {{QAId}}               <!-- ej: QA-01 -->
- IndexRef: {{IndexRef}}         <!-- ej: contexto/00_prompts/.../INDEX.md -->
- PromptSource: {{PromptSource}} <!-- ej: contexto/00_prompts/.../__QA__PROMPT.md -->
- Relacionado:
  - PhaseId: {{PhaseId}}         <!-- ej: PHASE-01 -->
  - ChangePlan: {{ChangePlanPath}}
  - ChangeSummary: {{ChangeSummaryPath}}

---

## 1) Alcance (qué valida / qué no)
### 1.1 Incluye
- {{incluye-1}}
- {{incluye-2}}

### 1.2 No incluye
- {{no-incluye-1}}
- {{no-incluye-2}}

---

## 2) Pre-requisitos
> Si no se conoce un comando exacto, dejar placeholder accionable.

- Docker / Docker Compose: {{ok|pendiente}}
- Servicios esperados arriba: {{redis}}, {{rabbit}}, {{clickhouse}}, {{hub}}, {{hostigador}}
- Variables/config relevantes:
  - {{var-1}}: {{valor|placeholder}}
  - {{var-2}}: {{valor|placeholder}}

---

## 2.5) Descubrimiento (fuentes y evidencia)
> Antes de escribir comandos finales, encontrar y citar evidencias del repo (no inventar puertos, servicios, rutas ni comandos).

- Docker compose:
  - Path: {{composePath}}
  - Evidencia (paths exactos): {{composeEvidencePaths}}
- Nombres de servicios (compose):
  - redis: {{serviceRedis}}
  - rabbit: {{serviceRabbit}}
  - clickhouse: {{serviceClickhouse}}
  - hub: {{serviceHub}}
  - hostigador: {{serviceHostigador}}
  - Evidencia (paths exactos): {{servicesEvidencePaths}}
- Puertos / endpoints:
  - Hub base URL: {{hubBaseUrl}}
  - Endpoint objetivo: {{endpoint}}
  - Evidencia (paths exactos): {{endpointsEvidencePaths}}
- Scripts existentes (si hay):
  - {{scriptPath1}}
  - {{scriptPath2}}

---

## 3) Setup (arranque y estado)
### 3.1 Levantar stack
- DOCKER_COMPOSE: `<comando aqui>`
- Expected:
  - Servicios en “healthy” / corriendo
  - Logs sin errores fatales

### 3.2 Smoke de conectividad
- REDIS_CLI: `<comando aqui>`
  - Expected: `<resultado esperado>`
- RABBIT_ADMIN: `<comando aqui o verificacion aqui>`
  - Expected: `<resultado esperado>`
- CLICKHOUSE_SQL: `<query aqui>`
  - Expected: `<resultado esperado>`

---

## 4) Datos de prueba (preparación)
> Objetivo: tener 2 casos:
> A) device con platform_id presente
> B) device sin platform_id

### 4.1 Caso A – con platform_id
- Identidad:
  - serial: `{{serialA}}`
  - platform_id: `{{platformIdA}}`
- Redis (fuente esperada):
  - Key esperada: `device:{{serialA}}`
  - Field esperado: `platform_id`
- Preparación:
  - REDIS_CLI: `<comando para setear device:{{serialA}} platform_id>`
  - Expected: `device:{{serialA}}` contiene `platform_id={{platformIdA}}`

### 4.2 Caso B – sin platform_id
- Identidad:
  - serial: `{{serialB}}`
- Redis (fuente esperada):
  - Key esperada: `device:{{serialB}}`
  - Field esperado: `platform_id`
- Preparación:
  - REDIS_CLI: `<comando para setear device:{{serialB}} sin platform_id>`
  - Expected: `device:{{serialB}}` NO contiene `platform_id`

---

## 5) Ejecución – Pasos manuales (Acción + Expected)
> 3–7 pasos. Cada paso debe tener evidencia capturable (logs/queries/outputs).

1) **Acción**: Enviar telemetría para Caso A (con platform_id).  
   API_CALL: `<curl/postman aqui> (POST {{endpoint}} con frame "serialA.payload")`  
   **Expected**: HTTP 200/OK y el pipeline procesa sin bloquear.

2) **Acción**: Verificar NO inserts `DeviceId=0` tras Caso A.  
   CLICKHOUSE_SQL: `<query contar DeviceId=0 en rango reciente>`  
   **Expected**: 0 inserts nuevos con `DeviceId=0`.

3) **Acción**: Enviar telemetría para Caso B (sin platform_id).  
   API_CALL: `<curl/postman aqui> (POST {{endpoint}} con frame "serialB.payload")`  
   **Expected**: el pipeline NO persiste/publica; queda evidencia en logs/warn/metric.

4) **Acción**: Verificar que Caso B no publicó a Rabbit (o fue descartado antes).  
   RABBIT_ADMIN: `<comando aqui (conteo cola / bindings / rate)>`  
   **Expected**: no aumenta el conteo de mensajes normalizados para `serialB` (o no aparece routing).

5) **Acción**: Verificar nuevamente ClickHouse para `DeviceId=0` tras Caso B.  
   CLICKHOUSE_SQL: `<query contar DeviceId=0 en rango reciente>`  
   **Expected**: sigue en 0 inserts nuevos con `DeviceId=0`.

6) **Acción**: Verificar evidencia en logs/metric.  
   LOGS: `<comando o ubicacion de logs>`  
   **Expected**: existe mensaje/metric de “invariante platform_id” para Caso B.

---

## 6) Evidencias (pegar outputs)
- API responses:
  - Caso A: ```txt
    {{pegar-output-caso-a}}
    ```
  - Caso B: ```txt
    {{pegar-output-caso-b}}
    ```
- ClickHouse:
  - ```sql
    {{query-usada}}
    ```
  - Resultado: ```txt
    {{pegar-output-clickhouse}}
    ```
- Rabbit:
  - ```txt
    {{pegar-output-rabbit}}
    ```
- Logs:
  - ```txt
    {{pegar-log}}
    ```

---

## 7) Resultados (Expected vs Observed)
- Caso A:
  - Expected: {{expectedA}}
  - Observed: {{observedA}}
- Caso B:
  - Expected: {{expectedB}}
  - Observed: {{observedB}}

---

## 8) Done criteria
- [ ] No hay inserts con `DeviceId=0` en el rango de prueba.
- [ ] Telemetría sin `platform_id` no persiste/publica.
- [ ] Existe evidencia (log/warn/metric) de bloqueo por invariante.
- [ ] Los pasos son reproducibles (comandos/queries listados).
- [ ] Evidencias pegadas en la sección 6 (API/Rabbit/ClickHouse/Logs).

---

## 9) Post-step (para trazabilidad)
- Actualizar `{{IndexRef}}`:
  - Marcar `[x] {{QAId}}`
  - Completar link de Output si faltaba
- Si se detectan hallazgos nuevos:
  - Actualizar `contexto/03_hallazgos/pending.md`
