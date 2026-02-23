param(
    [string]$ApiBaseUrl = "http://localhost:5000",
    [string]$Username = "admin",
    [string]$Password = "admin123",
    [string]$SqlServer = ".",
    [string]$Database = "TelemetricDb",
    [string]$RedisCli = "redis-cli",
    [string]$RedisContainerName = "telemetric-redis",
    [switch]$UseRedisContainer = $true,
    [string]$RedisRuntimePrefix = "actions:runtime:rule:",
    [int]$RuleInstanceId = 0
)

$ErrorActionPreference = "Stop"

function Write-Step($msg) {
    Write-Host "[STEP] $msg" -ForegroundColor Cyan
}

function Write-Pass($msg) {
    Write-Host "[PASS] $msg" -ForegroundColor Green
}

function Write-Fail($msg) {
    Write-Host "[FAIL] $msg" -ForegroundColor Red
}

function Get-SqlValue([string]$query) {
    $args = @("-S", $SqlServer, "-d", $Database, "-E", "-h", "-1", "-W", "-Q", $query)
    $out = & sqlcmd @args
    if ($LASTEXITCODE -ne 0) {
        throw "sqlcmd fallo ejecutando query: $query"
    }
    $rawText = [string]($out | Out-String)
    $lines = @([System.Text.RegularExpressions.Regex]::Split($rawText, "`r?`n"))
    $clean = $lines |
        ForEach-Object { ([string]$_).Trim() } |
        Where-Object { $_ -and $_ -notmatch "^\(\d+\s+rows affected\)$" }

    $rows = @($clean)
    if (-not $rows -or $rows.Count -eq 0) {
        return ""
    }

    return ([string]$rows[0]).Trim()
}

function Get-RedisHashValue([string]$key, [string]$field) {
    if ($UseRedisContainer) {
        $out = & docker exec -i $RedisContainerName redis-cli HGET $key $field
        if ($LASTEXITCODE -ne 0) {
            throw "No se pudo consultar Redis en contenedor '$RedisContainerName'."
        }
        return ([string]($out | Out-String)).Trim()
    }

    $out = & $RedisCli HGET $key $field
    if ($LASTEXITCODE -ne 0) {
        throw "No se pudo ejecutar redis-cli local. Verifica -RedisCli o usa -UseRedisContainer."
    }
    return ([string]($out | Out-String)).Trim()
}

try {
    Write-Step "Seleccionando RuleInstance latch para prueba"
    if ($RuleInstanceId -le 0) {
        $candidate = Get-SqlValue "SET NOCOUNT ON; SELECT TOP 1 RuleInstanceId FROM RuleInstance WHERE IsDeleted=0 AND IsLatchMode=1 ORDER BY RuleInstanceId DESC;"
        if ([string]::IsNullOrWhiteSpace($candidate)) {
            throw "No existe RuleInstance con IsLatchMode=1. Pasa -RuleInstanceId o prepara data de prueba."
        }
        if (-not [int]::TryParse($candidate, [ref]$RuleInstanceId)) {
            throw "No se pudo parsear RuleInstanceId desde SQL. Valor recibido: '$candidate'."
        }
    }
    Write-Pass "RuleInstanceId seleccionado: $RuleInstanceId"

    Write-Step "Autenticando en API"
    $loginBody = @{ username = $Username; password = $Password } | ConvertTo-Json
    $loginResp = Invoke-RestMethod -Method Post -Uri "$ApiBaseUrl/api/v1/auth/login" -ContentType "application/json" -Body $loginBody
    if (-not $loginResp.token) {
        throw "Login no devolvio token."
    }
    $token = $loginResp.token
    Write-Pass "Login OK"

    Write-Step "Llamando endpoint Resolve manual"
    $headers = @{ Authorization = "Bearer $token" }
    $endpoint = "$ApiBaseUrl/api/v1/actions/rules/$RuleInstanceId/resolve-manual"
    $resolveBody = @{ ruleInstanceId = $RuleInstanceId } | ConvertTo-Json
    $resp = Invoke-RestMethod -Method Post -Uri $endpoint -Headers $headers -ContentType "application/json" -Body $resolveBody

    if (-not $resp.resolveRequested) {
        throw "La respuesta no trae resolveRequested=true."
    }
    if ([int]$resp.ruleInstanceId -ne $RuleInstanceId) {
        throw "ruleInstanceId en respuesta no coincide."
    }
    Write-Pass "Endpoint OK (ruleInstanceId=$($resp.ruleInstanceId), resolveRequested=$($resp.resolveRequested))"

    Write-Step "Verificando checkpoint en SQL"
    $stateJson = Get-SqlValue "SET NOCOUNT ON; SELECT TOP 1 StateJson FROM RuleCheckpoint WHERE RuleInstanceId = $RuleInstanceId ORDER BY RuleCheckpointId DESC;"
    if ([string]::IsNullOrWhiteSpace($stateJson)) {
        throw "No se encontro RuleCheckpoint para RuleInstanceId=$RuleInstanceId."
    }
    if ($stateJson -notmatch "resolveRequested") {
        throw "StateJson no contiene resolveRequested."
    }
    Write-Pass "Checkpoint SQL OK"

    Write-Step "Verificando flag runtime en Redis"
    $redisKey = "$RedisRuntimePrefix$RuleInstanceId"
    $redisValue = Get-RedisHashValue -key $redisKey -field "resolveRequested"
    if ($redisValue -ne "1") {
        throw "Redis resolveRequested esperado=1 actual=$redisValue."
    }
    Write-Pass "Redis runtime OK"

    Write-Host ""
    Write-Host "RESULTADO FINAL: PASS" -ForegroundColor Green
    exit 0
}
catch {
    Write-Fail $_.Exception.Message
    Write-Host ""
    Write-Host "RESULTADO FINAL: FAIL" -ForegroundColor Red
    exit 1
}
