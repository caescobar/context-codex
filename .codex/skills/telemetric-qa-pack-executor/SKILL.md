---
name: telemetric-qa-pack-executor
description: Ejecuta y valida un QA Pack ya creado en contexto/work/features/.../04_test/.../phase-XX, incluyendo setup/run/teardown, deteccion de RuleTemplateId, actualizacion de checklist/index y cierre limpio apagando cualquier instancia levantada durante la corrida (minimo API).
---

# Telemetric QA Pack Executor

## Proposito
Ejecutar un QA Pack existente y dejar la corrida cerrada con evidencia, estado actualizado y procesos limpios.

## Modo permitido
- `execution`: puede ejecutar comandos del entorno.
- Edicion permitida solo en artefactos QA dentro de `contexto/`.

## Cuando usar
Usar cuando el pack ya existe y se necesita:
- correr `setup/run/teardown`,
- validar PASS/FAIL,
- actualizar `CHECKLIST.md` e `INDEX.md`,
- apagar API al finalizar.

## Inputs
Obligatorio:
- `requirement_slug`
- `story_id`
- `phase_id`

Opcional:
- `rule_template_id`
- `api_base_url` (default `http://localhost:5220`)
- `sqlcmd_args` (si se quiere bloque SQL)

## Paths canonicos
- `pack_dir = contexto/work/features/{requirement_slug}/04_test/{story_id}/phase-{phase_id}/`
- `checklist = {pack_dir}/CHECKLIST.md`
- `index = {pack_dir}/INDEX.md`
- `commands_log = {pack_dir}/evidence/commands.log`
- `outputs_log = {pack_dir}/evidence/outputs.log`
- `notes = {pack_dir}/evidence/notes.md`

## Flujo operativo (mandatorio)
1. Validar existencia de pack y scripts.
2. Ejecutar `setup` con `DRY_RUN=0`.
3. Resolver `RULE_TEMPLATE_ID`:
- si llega por input, usarlo;
- si no, consultar SQL (`RuleTemplate` no borrado) y elegir uno valido.
4. Levantar API temporalmente.
5. Ejecutar `run` con `DRY_RUN=0` y `RULE_TEMPLATE_ID`.
6. Ejecutar `teardown`.
7. Matar toda instancia levantada por el executor (minimo `Telemetric.Api`; incluir otros procesos auxiliares si aplica).
8. Verificar `STILL_RUNNING: none` para `Telemetric.Api` y registrar residuals si existieran otros procesos.
9. Actualizar checklist/index/notes segun resultado.

## SQL discovery (RuleTemplateId)
Prioridad:
1. `sqlcmd_args` explicito.
2. Parsear `telemetric-api/src/Telemetric.Api/appsettings.json` (`DefaultConnection`).
3. Si no se puede resolver conexion: `NECESITO 1 RESPUESTA`.

Consulta sugerida:
- `SELECT TOP 10 RuleTemplateId, Name FROM dbo.RuleTemplate WHERE IsDeleted = 0 ORDER BY RuleTemplateId DESC;`

### Busqueda manual guiada (sin autodetect)
Si el usuario prefiere control manual, el executor debe usar y/o sugerir esta secuencia:
1. Verificar `sqlcmd`:
- `Get-Command sqlcmd -ErrorAction SilentlyContinue`
2. Intentar conexion local tipica (Telemetric):
- `sqlcmd -S . -d TelemetricDb -U sa -P sa -C -Q "SET NOCOUNT ON; SELECT TOP 10 RuleTemplateId, Name, IsDeleted FROM dbo.RuleTemplate ORDER BY RuleTemplateId DESC;"`
3. Si no hay filas o falla conexion, buscar alternativas de host/puerto en repo:
- `telemetric-api/src/Telemetric.Api/appsettings.json`
- `docker-compose*.yml`
4. Elegir `RuleTemplateId` con `IsDeleted = 0` y pasarlo a `run` como `RULE_TEMPLATE_ID`.
5. Registrar en `evidence/notes.md` la consulta usada y el id elegido.

## Estrategia de runtime API
1. Intentar estrategia principal del entorno para correr API.
2. Si el entorno bloquea procesos en background (`Start-Process` policy), usar alternativa compatible del runner.
3. Si ninguna estrategia es posible, dejar estado `BLOQUEADO` con evidencia y no marcar QA cerrada.

## Kill obligatorio al cierre
Detener procesos `dotnet` de `Telemetric.Api.csproj` y cualquier runtime lanzado durante la corrida.
Verificacion final obligatoria:
- `STILL_RUNNING: none`

## Criterios de exito de corrida
Minimo para `run` exitoso:
- login OK
- GET/PUT/GET ejecutados para template valido
- evidencia de versionado inmutable en `outputs.log`:
  - `Expected: versionNumber post = pre + 1`
  - `Observed: pre=..., post=...`
  - `previousVersionPresent=True`

## Actualizacion de estado
Si todo OK:
- marcar en `CHECKLIST.md`: setup/run/teardown/evidencia/QA cerrada en `[x]`.
- marcar en `INDEX.md` ejecucion integrada y cierre en `[x]`.
- registrar en `notes.md` fecha, `RULE_TEMPLATE_ID`, resultado y PID terminado.

Si falla parcialmente:
- dejar estado parcial con bloqueo exacto (causa tecnica + comando).
- no marcar QA cerrada.

## Reglas duras
1. No modificar codigo de producto.
2. No borrar evidencia previa; agregar evidencia incremental.
3. No terminar sin intentar apagar todas las instancias lanzadas por el executor.
4. No declarar cierre sin `run` exitoso y `STILL_RUNNING: none`.

## Output en respuesta
1. `PackDir`
2. Resultado setup/run/teardown
3. `RULE_TEMPLATE_ID` usado
4. Estado de API al final (`STILL_RUNNING`)
5. Archivos QA actualizados
