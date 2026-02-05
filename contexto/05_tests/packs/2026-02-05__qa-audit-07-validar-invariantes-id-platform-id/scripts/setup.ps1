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

Write-Host "== QA PACK setup =="
Invoke-Step "docker compose -f telemetric-hub/kiss/scripts/docker-compose.yml up -d"

Write-Host "== Manual starts (run in separate terminals) =="
Write-Host "dotnet run --project telemetric-hub/kiss/Telemetric.Hub/Telemetric.Hub.csproj"
Write-Host "dotnet run --project telemetric-hub/kiss/Telemetric.Worker.DTE/Telemetric.Worker.DTE.csproj"
Write-Host "dotnet run --project telemetric-hub/kiss/Telemetric.Worker.Persist/Telemetric.Worker.Persist.csproj"
