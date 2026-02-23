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

Write-OutputLog "Expected: setup valida prerequisitos y discovery ACT-005 phase-02."
Write-OutputLog "Observed: inicio setup (DRY_RUN=$DryRun, FRONTEND_DIR=$FrontendDir)."

$composePrimaryRel = "telemetric-hub/kiss/scripts/docker-compose.yml"
$composeLegacyRel = "telemetric-api/old/docker-compose.yml"
$launchSettingsRel = "telemetric-api/src/Telemetric.Api/Properties/launchSettings.json"
$phaseSummaryRel = "contexto/work/features/acciones_modulo/03_execution/ACT-005/phase-02.md"
$createHandlerRel = "telemetric-api/src/Telemetric.Api/Features/Actions/Templates/CreateTemplate/CreateTemplateCommandHandler.cs"
$updateHandlerRel = "telemetric-api/src/Telemetric.Api/Features/Actions/Templates/UpdateTemplate/UpdateTemplateCommandHandler.cs"
$createFromDeviceHandlerRel = "telemetric-api/src/Telemetric.Api/Features/Actions/Assignments/CreateRuleFromDevice/CreateRuleFromDeviceCommandHandler.cs"
$frontendPackageRel = "$FrontendDir/package.json"

foreach ($tool in @("rg", "dotnet", "node", "npm")) {
    Write-CommandLog "Get-Command $tool -ErrorAction SilentlyContinue"
    $exists = Get-Command $tool -ErrorAction SilentlyContinue
    if ($null -eq $exists) {
        Write-OutputLog "Observed: herramienta faltante -> $tool"
    }
    else {
        Write-OutputLog "Observed: herramienta OK -> $tool"
    }
}

if (Test-Path (Join-Path $RepoRoot $composePrimaryRel)) {
    Invoke-Step ("docker compose -f `"{0}`" config --services" -f (Join-Path $RepoRoot $composePrimaryRel))
}
else {
    Write-OutputLog "Observed: compose primario no encontrado ($composePrimaryRel)."
}

if (Test-Path (Join-Path $RepoRoot $composeLegacyRel)) {
    Write-OutputLog "Observed: compose legado detectado (no usado): $composeLegacyRel"
}

foreach ($rel in @($launchSettingsRel, $phaseSummaryRel, $createHandlerRel, $updateHandlerRel, $createFromDeviceHandlerRel, $frontendPackageRel)) {
    $exists = Test-Path (Join-Path $RepoRoot $rel)
    Write-CommandLog "Test-Path $rel"
    Write-OutputLog "Observed: path_exists[$rel]=$exists"
}

Push-Location $RepoRoot
try {
    Invoke-Step "rg --line-number -F 'ValidateAndNormalizeDefinitionJson(' telemetric-api/src/Telemetric.Api/Features/Actions/Templates/CreateTemplate/CreateTemplateCommandHandler.cs telemetric-api/src/Telemetric.Api/Features/Actions/Templates/UpdateTemplate/UpdateTemplateCommandHandler.cs telemetric-api/src/Telemetric.Api/Features/Actions/Assignments/CreateRuleFromDevice/CreateRuleFromDeviceCommandHandler.cs"
    Invoke-Step "rg --line-number -F 'evaluation.durationSeconds must be less than or equal to evaluation.windowSeconds.' telemetric-api/src/Telemetric.Api/Features/Actions/Templates/CreateTemplate/CreateTemplateCommandHandler.cs telemetric-api/src/Telemetric.Api/Features/Actions/Templates/UpdateTemplate/UpdateTemplateCommandHandler.cs telemetric-api/src/Telemetric.Api/Features/Actions/Assignments/CreateRuleFromDevice/CreateRuleFromDeviceCommandHandler.cs"
    Invoke-Step "rg --line-number -F 'missingDataPolicy.ttlSeconds is required when mode is HOLD_LAST_VALUE.' telemetric-api/src/Telemetric.Api/Features/Actions/Templates/CreateTemplate/CreateTemplateCommandHandler.cs telemetric-api/src/Telemetric.Api/Features/Actions/Templates/UpdateTemplate/UpdateTemplateCommandHandler.cs telemetric-api/src/Telemetric.Api/Features/Actions/Assignments/CreateRuleFromDevice/CreateRuleFromDeviceCommandHandler.cs"
    Invoke-Step "rg --line-number -F 'missingDataPolicy.ttlSeconds must be null or omitted when mode is INSUFFICIENT_DATA.' telemetric-api/src/Telemetric.Api/Features/Actions/Templates/CreateTemplate/CreateTemplateCommandHandler.cs telemetric-api/src/Telemetric.Api/Features/Actions/Templates/UpdateTemplate/UpdateTemplateCommandHandler.cs telemetric-api/src/Telemetric.Api/Features/Actions/Assignments/CreateRuleFromDevice/CreateRuleFromDeviceCommandHandler.cs"
    Invoke-Step "rg --line-number -F 'action.recipients[' telemetric-api/src/Telemetric.Api/Features/Actions/Templates/CreateTemplate/CreateTemplateCommandHandler.cs telemetric-api/src/Telemetric.Api/Features/Actions/Templates/UpdateTemplate/UpdateTemplateCommandHandler.cs telemetric-api/src/Telemetric.Api/Features/Actions/Assignments/CreateRuleFromDevice/CreateRuleFromDeviceCommandHandler.cs"
    Invoke-Step "rg --line-number -F 'Send.ErrorsAsync(400' telemetric-api/src/Telemetric.Api/Features/Actions/Templates/CreateTemplate/CreateTemplateEndpoint.cs telemetric-api/src/Telemetric.Api/Features/Actions/Templates/UpdateTemplate/UpdateTemplateEndpoint.cs telemetric-api/src/Telemetric.Api/Features/Actions/Assignments/CreateRuleFromDevice/CreateRuleFromDeviceEndpoint.cs"
    Invoke-Step "npm --prefix $FrontendDir run typecheck"
}
finally {
    Pop-Location
}

Write-OutputLog "Expected: setup deja evidencia en commands.log y outputs.log."
Write-OutputLog "Observed: setup finalizado."
