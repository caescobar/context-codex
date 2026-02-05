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

Write-Host "== QA PACK teardown =="
Invoke-Step "docker compose -f telemetric-hub/kiss/scripts/docker-compose.yml down"
