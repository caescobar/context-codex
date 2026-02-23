# Requires -Version 5.1
$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$PackDir = Resolve-Path (Join-Path $ScriptDir "..")
$EvidenceDir = Join-Path $PackDir "evidence"
$RepoRoot = Resolve-Path (Join-Path $ScriptDir "..\..\..\..\..\..\..\..")

$DryRun = if ($env:DRY_RUN) { $env:DRY_RUN } else { "1" }
$FrontendDir = if ($env:FRONTEND_DIR) { $env:FRONTEND_DIR } else { "telemetric-front" }
$CommandsLog = Join-Path $EvidenceDir "commands.log"
$OutputsLog = Join-Path $EvidenceDir "outputs.log"

New-Item -ItemType Directory -Force -Path $EvidenceDir | Out-Null
if (!(Test-Path $CommandsLog)) { New-Item -ItemType File -Path $CommandsLog | Out-Null }
if (!(Test-Path $OutputsLog)) { New-Item -ItemType File -Path $OutputsLog | Out-Null }

function Write-CommandLog([string]$Command) {
    Add-Content -Path $CommandsLog -Value ("{0} | {1}" -f (Get-Date -Format s), $Command)
}

function Write-OutputLog([string]$Message) {
    Add-Content -Path $OutputsLog -Value ("{0} | {1}" -f (Get-Date -Format s), $Message)
}

function Invoke-Step([string]$Command) {
    Write-CommandLog $Command
    if ($DryRun -eq "1") {
        Write-Host "[DRY_RUN] $Command"
        Write-OutputLog "Observed (pendiente): DRY_RUN=1 no ejecuto comando."
        return
    }

    Write-Host "[EXEC] $Command"
    $output = Invoke-Expression $Command | Out-String
    if (-not [string]::IsNullOrWhiteSpace($output)) {
        Add-Content -Path $OutputsLog -Value $output.TrimEnd()
    }
}

Write-OutputLog "Expected: setup valida herramientas y discovery de frontend para ACT-003 phase-03."
Write-OutputLog "Observed: inicio setup (DRY_RUN=$DryRun, FRONTEND_DIR=$FrontendDir)."

$composePrimaryRel = "telemetric-hub/kiss/scripts/docker-compose.yml"
$composeLegacyRel = "telemetric-api/old/docker-compose.yml"
$composePrimary = Join-Path $RepoRoot $composePrimaryRel
$composeLegacy = Join-Path $RepoRoot $composeLegacyRel
$launchSettingsRel = "telemetric-api/src/Telemetric.Api/Properties/launchSettings.json"
$launchSettings = Join-Path $RepoRoot $launchSettingsRel
$frontendRoot = Join-Path $RepoRoot $FrontendDir

$toolChecks = @("node", "npm", "rg")
foreach ($tool in $toolChecks) {
    Write-CommandLog "Get-Command $tool -ErrorAction SilentlyContinue"
    $exists = Get-Command $tool -ErrorAction SilentlyContinue
    if ($null -eq $exists) {
        Write-OutputLog "Observed: herramienta faltante -> $tool"
    }
    else {
        Write-OutputLog "Observed: herramienta OK -> $tool"
    }
}

if (Test-Path $composePrimary) {
    Invoke-Step ("docker compose -f `"{0}`" config --services" -f $composePrimary)
}
else {
    Write-OutputLog "Observed: compose primario no encontrado ($composePrimaryRel)."
}

if (Test-Path $composeLegacy) {
    Write-OutputLog "Observed: compose legado detectado (no usado): $composeLegacyRel"
}

if (Test-Path $launchSettings) {
    Write-OutputLog "Observed: launchSettings encontrado ($launchSettingsRel)."
}
else {
    Write-OutputLog "Observed: launchSettings no encontrado ($launchSettingsRel)."
}

if (Test-Path (Join-Path $frontendRoot "package.json")) {
    Write-OutputLog "Observed: frontend package.json encontrado en $FrontendDir."
}
else {
    Write-OutputLog "Observed: frontend package.json no encontrado en $FrontendDir."
}

Push-Location $RepoRoot
try {
    Invoke-Step "rg --line-number -F '/actions' telemetric-front/src"
    Invoke-Step "rg --line-number -F '/actions/templates/:id' telemetric-front/src"
    Invoke-Step "rg --line-number -F 'features/actions' telemetric-front/src/router telemetric-front/src/features -g '*.ts'"
    Invoke-Step "rg --line-number -F '@/core/utils/axios' telemetric-front/src/features -g '*.ts'"
    Invoke-Step "npm --prefix telemetric-front run typecheck"
}
finally {
    Pop-Location
}

Write-OutputLog "Expected: setup deja evidencia en commands.log y outputs.log."
Write-OutputLog "Observed: setup finalizado."
