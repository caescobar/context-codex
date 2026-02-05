param(
    [string]$DryRun = $(if ($env:DRY_RUN) { $env:DRY_RUN } else { '1' })
)

$ErrorActionPreference = 'Stop'

function Invoke-Step {
    param([string]$Command)

    if ($DryRun -eq '1') {
        Write-Host "[DRY_RUN] $Command"
        return
    }

    Write-Host "[RUN] $Command"
    Invoke-Expression $Command
}

Write-Host "== QA PACK run =="

# Redis prep (Case A/B)
Invoke-Step "redis-cli -h localhost -p 6379 HSET device:1001 platform_id 1001"
Invoke-Step "redis-cli -h localhost -p 6379 HDEL device:1002 platform_id"
Invoke-Step "redis-cli -h localhost -p 6379 HGET device:1001 platform_id"
Invoke-Step "redis-cli -h localhost -p 6379 HGET device:1002 platform_id"

# Case A API call
$frameA = '1001.{"ts":1700000000,"t":1,"sv":1,"data":{"lat":40.4168,"lng":-3.7038,"tmp":12.3,"bat":95}}'
$bodyA = @{ frame = $frameA } | ConvertTo-Json -Compress
Invoke-Step "curl.exe -k -X POST https://localhost:7008/api/v1/ingest-raw -H \"Content-Type: application/json\" -d `"$bodyA`""

# Rabbit queue check
Invoke-Step "curl.exe -u admin:admin123 http://localhost:15672/api/queues/ingesta/telemetry.validated"

# ClickHouse check (DeviceId=0)
Invoke-Step "docker exec -i telemetric-clickhouse clickhouse-client --user teleuser --password telepass123 --database telemetric --query \"SELECT count() AS cnt FROM TelemetryLog WHERE DeviceId = 0 AND Timestamp >= now() - INTERVAL 15 MINUTE\""

# Case B API call
$frameB = '1002.{"ts":1700000001,"t":1,"sv":1,"data":{"lat":40.4168,"lng":-3.7038,"tmp":12.3,"bat":95}}'
$bodyB = @{ frame = $frameB } | ConvertTo-Json -Compress
Invoke-Step "curl.exe -k -X POST https://localhost:7008/api/v1/ingest-raw -H \"Content-Type: application/json\" -d `"$bodyB`""

# ClickHouse check again
Invoke-Step "docker exec -i telemetric-clickhouse clickhouse-client --user teleuser --password telepass123 --database telemetric --query \"SELECT count() AS cnt FROM TelemetryLog WHERE DeviceId = 0 AND Timestamp >= now() - INTERVAL 15 MINUTE\""

Write-Host "== Manual logs check =="
Write-Host "Check console logs for DTE/Persist for platform_id warnings and metrics."
