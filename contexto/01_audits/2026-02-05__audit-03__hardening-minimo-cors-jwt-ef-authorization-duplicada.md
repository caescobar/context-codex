# AUDIT REPORT – hardening-minimo-cors-jwt-ef-authorization-duplicada

## 0) Metadata
- Fecha: 2026-02-05
- Modo: docs-only (audit-exec, sin cambios de código)
- Skills aplicadas: telemetric-backend-style
- Objetivo: Auditar hardening minimo (CORS/JWT/EF auditoria/Authorization duplicada) y documentar riesgos o gaps.
- Repos/servicios: telemetric-api (telemetric-hub sin hallazgos de CORS/JWT/Authorization en búsqueda)
- Autor: Codex (asistido)

## 0.1 Trazabilidad del pack
- PackDir: contexto/00_prompts/2026-02-04__pack-audit-pack-inicial-global
- AuditId: AUDIT-03
- IndexRef: contexto/00_prompts/2026-02-04__pack-audit-pack-inicial-global/INDEX.md
- PromptSource: contexto/00_prompts/2026-02-04__pack-audit-pack-inicial-global/audit-03__hardening-minimo-cors-jwt-ef-authorization-duplicada__AUDIT__PROMPT.md

## 1) Executive Summary (máx 5 bullets)
- CORS está configurado con política “AllowAll” + credenciales y se aplica globalmente sin separación por ambiente. Evidencia en `telemetric-api/src/Telemetric.Api/Program.cs`.
- JWT se configura solo con `SigningKey` aunque `Issuer/Audience` existen en `appsettings.json`; no se observa validación explícita de issuer/audience. Evidencia en `telemetric-api/src/Telemetric.Api/Program.cs` y `telemetric-api/src/Telemetric.Api/appsettings.json`.
- Existen endpoints sensibles con `AllowAnonymous()` (Organizations, OrganizationNodes y Telemetry/History), lo que puede permitir bypass de autorización. Evidencia en endpoints listados en sección 2.
- Se registra dos veces `IAuthorizationPolicyProvider` y `IAuthorizationHandler` en DI. Evidencia en `telemetric-api/src/Telemetric.Api/Infrastructure/DependencyInjection.cs`.
- EF auditing está implementado vía `AuditableEntityInterceptor` y se inyecta en `TelemetricDbContext`; si el contexto se construye sin DI, el interceptor no se aplica. Evidencia en `telemetric-api/src/Telemetric.Api/Infrastructure/Persistence/Interceptors/AuditableEntityInterceptor.cs` y `telemetric-api/src/Telemetric.Api/Infrastructure/Persistence/Contexts/TelemetricDbContext.cs`.

## 2) Alcance (Scope)
### 2.1 Paths/archivos analizados
- `telemetric-api/src/Telemetric.Api/Program.cs`
- `telemetric-api/src/Telemetric.Api/appsettings.json`
- `telemetric-api/src/Telemetric.Api/Infrastructure/DependencyInjection.cs`
- `telemetric-api/src/Telemetric.Api/Infrastructure/Security/PermissionPolicyProvider.cs`
- `telemetric-api/src/Telemetric.Api/Infrastructure/Security/PermissionAuthorizationHandler.cs`
- `telemetric-api/src/Telemetric.Api/Infrastructure/Security/ClaimsTransformation.cs`
- `telemetric-api/src/Telemetric.Api/Infrastructure/Persistence/Interceptors/AuditableEntityInterceptor.cs`
- `telemetric-api/src/Telemetric.Api/Infrastructure/Persistence/Contexts/TelemetricDbContext.cs`
- `telemetric-api/src/Telemetric.Api/Features/**/Endpoint.cs` (AllowAnonymous/Policies)
- `telemetric-api/old/Telemetric.Api/Program.cs`

### 2.2 Fuera de alcance
- `telemetric-front/**`
- `telemetric-hub/**` (sin referencias a CORS/JWT/Authorization encontradas por búsqueda)

## 3) Contrato actual observado (Fuente: código)
> Tabla obligatoria. No asumir. Si algo no se encontró, escribir “No encontrado”.

| Capa | Identidad externa (serial/id) | Key/Routing/Group | Campos/Shape | Evidencia (paths) |
|---|---|---|---|---|
| SQL | No encontrado | No encontrado | No encontrado | No encontrado |
| Redis config | No encontrado | No encontrado | No encontrado | No encontrado |
| Redis last-value | No encontrado | No encontrado | No encontrado | No encontrado |
| Rabbit raw | No encontrado | No encontrado | No encontrado | No encontrado |
| Rabbit normalized | No encontrado | No encontrado | No encontrado | No encontrado |
| SignalR | No encontrado | No encontrado | No encontrado | No encontrado |
| Payload | No encontrado | No encontrado | No encontrado | No encontrado |

## 4) Nombres canónicos encontrados (no inventar)
- Redis: No encontrado
- Rabbit: No encontrado
- SignalR: No encontrado
**Evidencia:** No encontrado

## 5) Hallazgos (con evidencia)
> Cada hallazgo debe tener: severidad, impacto, evidencia, repro si aplica, recomendación.

### High
- **HALL-20260205-005 – Endpoints críticos con AllowAnonymous()**
  - Impacto: Bypass total de autenticación/autorización para operaciones de Organizations/OrganizationNodes y Telemetry History.
  - Evidencia (paths):  
    - `telemetric-api/src/Telemetric.Api/Features/Organizations/CreateOrganization/CreateOrganizationEndpoint.cs`  
    - `telemetric-api/src/Telemetric.Api/Features/Organizations/GetOrganizationById/GetOrganizationByIdEndpoint.cs`  
    - `telemetric-api/src/Telemetric.Api/Features/Organizations/UpdateOrganization/UpdateOrganizationEndpoint.cs`  
    - `telemetric-api/src/Telemetric.Api/Features/Organizations/DeleteOrganization/DeleteOrganizationEndpoint.cs`  
    - `telemetric-api/src/Telemetric.Api/Features/OrganizationNodes/CreateNode/CreateNodeEndpoint.cs`  
    - `telemetric-api/src/Telemetric.Api/Features/OrganizationNodes/UpdateNode/UpdateNodeEndpoint.cs`  
    - `telemetric-api/src/Telemetric.Api/Features/OrganizationNodes/DeleteNode/DeleteNodeEndpoint.cs`  
    - `telemetric-api/src/Telemetric.Api/Features/OrganizationNodes/GetOrganizationTree/GetOrganizationTreeEndpoint.cs`  
    - `telemetric-api/src/Telemetric.Api/Features/Telemetry/GetHistory/GetHistoryEndpoint.cs`
  - Repro (si aplica): Invocar endpoints anteriores sin token y verificar respuesta 200/OK.
  - Recomendación: Reemplazar `AllowAnonymous()` por `Policies(...)` o exigir autenticación mínima (ej. “Authenticated”), alineando con `PermissionClaims`.

### Medium
- **HALL-20260205-006 – CORS AllowAll + credenciales sin separación por ambiente**
  - Impacto: Cualquier origen puede hacer solicitudes con credenciales si el navegador lo permite, ampliando superficie de ataque en producción.
  - Evidencia (paths): `telemetric-api/src/Telemetric.Api/Program.cs`
  - Repro (si aplica): Verificar que `SetIsOriginAllowed(_ => true)` permite cualquier origin y `AllowCredentials()` está activo.
  - Recomendación: Definir políticas por ambiente (dev/prod) y restringir orígenes en producción.

- **HALL-20260205-007 – JWT sin validación explícita de Issuer/Audience**
  - Impacto: Tokens firmados con la misma key podrían ser aceptados aunque provengan de issuer/audience distintos a los esperados.
  - Evidencia (paths):  
    - `telemetric-api/src/Telemetric.Api/Program.cs`  
    - `telemetric-api/src/Telemetric.Api/appsettings.json`
  - Repro (si aplica): Generar token con issuer distinto y misma firma; evaluar aceptación.
  - Recomendación: Configurar validación explícita de `Issuer` y `Audience` en el bearer.

### Low
- **HALL-20260205-008 – Duplicidad de registro de Authorization en DI**
  - Impacto: Confusión operativa y riesgo de drift al editar uno de los registros duplicados.
  - Evidencia (paths): `telemetric-api/src/Telemetric.Api/Infrastructure/DependencyInjection.cs`
  - Repro (si aplica): No aplica.
  - Recomendación: Mantener una única registración de `IAuthorizationPolicyProvider` y `IAuthorizationHandler`.

- **HALL-20260205-009 – Configuración de hardening inconsistente entre `old/` y `src/`**
  - Impacto: Si se reutiliza o referencia `old/`, se aplican políticas distintas (CORS restringido vs AllowAll; `Jwt` vs `JwtSettings`).
  - Evidencia (paths): `telemetric-api/old/Telemetric.Api/Program.cs`, `telemetric-api/src/Telemetric.Api/Program.cs`
  - Repro (si aplica): Comparar políticas/keys en ambos `Program.cs`.
  - Recomendación: Marcar `old/` como legado o eliminarlo del path de build, y documentar cuál configuración es la vigente.

## 6) Riesgos de romper contratos
- Riesgo: Al endurecer CORS y exigir autenticación en endpoints hoy públicos, clientes existentes pueden fallar.
- Mitigación: Release con comunicación previa, feature flags o ventana de migración con métricas de uso.

## 7) Recomendación priorizada
1) Cerrar `AllowAnonymous()` en endpoints sensibles (Organizations, OrganizationNodes, Telemetry).
2) Definir políticas CORS por ambiente (prod restringido, dev permisivo).
3) Endurecer validación JWT (Issuer/Audience) acorde a `JwtSettings`.
4) Eliminar duplicidad de DI para Authorization y documentar configuración vigente.

## 8) Plan sugerido por fases (sin ejecutar)
> Máx 5 archivos por fase. No cambiar contratos sin migración.

### Fase 1
- Objetivo: Quitar `AllowAnonymous()` en Organizations.
- Archivos potenciales (máx 5):
  - `telemetric-api/src/Telemetric.Api/Features/Organizations/CreateOrganization/CreateOrganizationEndpoint.cs`
  - `telemetric-api/src/Telemetric.Api/Features/Organizations/GetOrganizationById/GetOrganizationByIdEndpoint.cs`
  - `telemetric-api/src/Telemetric.Api/Features/Organizations/UpdateOrganization/UpdateOrganizationEndpoint.cs`
  - `telemetric-api/src/Telemetric.Api/Features/Organizations/DeleteOrganization/DeleteOrganizationEndpoint.cs`
- Verificación: 401/403 sin token, 200 con token válido.

### Fase 2
- Objetivo: Quitar `AllowAnonymous()` en OrganizationNodes y Telemetry/History.
- Archivos potenciales (máx 5):
  - `telemetric-api/src/Telemetric.Api/Features/OrganizationNodes/CreateNode/CreateNodeEndpoint.cs`
  - `telemetric-api/src/Telemetric.Api/Features/OrganizationNodes/UpdateNode/UpdateNodeEndpoint.cs`
  - `telemetric-api/src/Telemetric.Api/Features/OrganizationNodes/DeleteNode/DeleteNodeEndpoint.cs`
  - `telemetric-api/src/Telemetric.Api/Features/OrganizationNodes/GetOrganizationTree/GetOrganizationTreeEndpoint.cs`
  - `telemetric-api/src/Telemetric.Api/Features/Telemetry/GetHistory/GetHistoryEndpoint.cs`
- Verificación: 401/403 sin token, 200 con token válido.

### Fase 3
- Objetivo: Endurecer CORS/JWT y limpiar duplicados en DI.
- Archivos potenciales (máx 5):
  - `telemetric-api/src/Telemetric.Api/Program.cs`
  - `telemetric-api/src/Telemetric.Api/appsettings.json`
  - `telemetric-api/src/Telemetric.Api/Infrastructure/DependencyInjection.cs`
- Verificación: CORS solo permite origins esperados; JWT rechaza issuer/audience inválidos; DI sin duplicados.

## 9) Cómo verificar (smoke test)
1) Ejecutar API y probar endpoints de Organizations sin token: debe devolver 401/403.
2) Probar endpoints con token válido y permisos: deben devolver 200/OK.
3) Probar token con issuer/audience incorrectos: debe devolver 401.
4) Probar CORS desde origen no permitido (prod): debe fallar en preflight.

## 10) Pendientes registrados
- Añadir/actualizar en `contexto/03_hallazgos/pending.md`: HALL-20260205-005, HALL-20260205-006, HALL-20260205-007, HALL-20260205-008, HALL-20260205-009
