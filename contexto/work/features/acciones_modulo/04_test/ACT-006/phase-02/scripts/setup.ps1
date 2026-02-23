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
        Write-OutputLog "Observed (pending): DRY_RUN=1 skipped command."
        return
    }

    Write-Host "[EXEC] $Command"
    $output = Invoke-Expression $Command | Out-String
    if (-not [string]::IsNullOrWhiteSpace($output)) {
        Add-Content -Path $OutputsLog -Value $output.TrimEnd()
    }
}

Write-OutputLog "Expected: setup validates prerequisites and discovery for ACT-006 phase-02."
Write-OutputLog "Observed: setup start (DRY_RUN=$DryRun, FRONTEND_DIR=$FrontendDir)."

foreach ($tool in @("rg", "dotnet", "node", "npm")) {
    Write-CommandLog "Get-Command $tool -ErrorAction SilentlyContinue"
    $exists = Get-Command $tool -ErrorAction SilentlyContinue
    if ($null -eq $exists) {
        Write-OutputLog "Observed: missing tool -> $tool"
    }
    else {
        Write-OutputLog "Observed: tool OK -> $tool"
    }
}

$composePrimaryRel = "telemetric-hub/kiss/scripts/docker-compose.yml"
$composeLegacyRel = "telemetric-api/old/docker-compose.yml"
$launchSettingsRel = "telemetric-api/src/Telemetric.Api/Properties/launchSettings.json"
$planRel = "contexto/work/features/acciones_modulo/02_plans/ACT-006.plan.md"
$summaryRel = "contexto/work/features/acciones_modulo/03_execution/ACT-006/phase-02.md"
$openapiRel = "contexto/openapi/actions.yaml"
$endpointGlobalRel = "telemetric-api/src/Telemetric.Api/Features/Actions/Runs/GetRuns/GetRunsEndpoint.cs"
$queryGlobalRel = "telemetric-api/src/Telemetric.Api/Features/Actions/Runs/GetRuns/GetRunsQueryHandler.cs"
$endpointTemplateRel = "telemetric-api/src/Telemetric.Api/Features/Actions/Templates/GetTemplateRuns/GetTemplateRunsEndpoint.cs"
$queryTemplateRel = "telemetric-api/src/Telemetric.Api/Features/Actions/Templates/GetTemplateRuns/GetTemplateRunsQueryHandler.cs"
$dbContextRel = "telemetric-api/src/Telemetric.Api/Common/Interfaces/IApplicationDbContext.cs"

foreach ($rel in @(
    $composePrimaryRel,
    $composeLegacyRel,
    $launchSettingsRel,
    $planRel,
    $summaryRel,
    $openapiRel,
    $endpointGlobalRel,
    $queryGlobalRel,
    $endpointTemplateRel,
    $queryTemplateRel,
    $dbContextRel
)) {
    $exists = Test-Path (Join-Path $RepoRoot $rel)
    Write-CommandLog "Test-Path $rel"
    Write-OutputLog "Observed: path_exists[$rel]=$exists"
}

if (Test-Path (Join-Path $RepoRoot $composePrimaryRel)) {
    Invoke-Step ("docker compose -f `"{0}`" config --services" -f (Join-Path $RepoRoot $composePrimaryRel))
}

Push-Location $RepoRoot
try {
    Invoke-Step "rg --line-number -F -e '/api/v1/actions/runs:' -e '/api/v1/actions/templates/{ruleTemplateId}/runs:' contexto/openapi/actions.yaml"
    Invoke-Step "rg --line-number -F -e 'Get(""/api/v1/actions/runs"")' telemetric-api/src/Telemetric.Api/Features/Actions/Runs/GetRuns/GetRunsEndpoint.cs"
    Invoke-Step "rg --line-number -F -e 'Get(""/api/v1/actions/templates/{RuleTemplateId}/runs"")' telemetric-api/src/Telemetric.Api/Features/Actions/Templates/GetTemplateRuns/GetTemplateRunsEndpoint.cs"
    Invoke-Step "rg --line-number -F -e 'Policies(PermissionClaims.Actions.View)' telemetric-api/src/Telemetric.Api/Features/Actions/Runs/GetRuns/GetRunsEndpoint.cs telemetric-api/src/Telemetric.Api/Features/Actions/Templates/GetTemplateRuns/GetTemplateRunsEndpoint.cs"
    Invoke-Step "rg --line-number -F -e '_context.ActionAttempts' -e '.AsNoTracking()' -e 'OrderByDescending' -e 'ClientId' telemetric-api/src/Telemetric.Api/Features/Actions/Runs/GetRuns/GetRunsQueryHandler.cs telemetric-api/src/Telemetric.Api/Features/Actions/Templates/GetTemplateRuns/GetTemplateRunsQueryHandler.cs"
    Invoke-Step "rg --line-number -F -e 'DbSet<ActionAttempt> ActionAttempts' telemetric-api/src/Telemetric.Api/Common/Interfaces/IApplicationDbContext.cs"
}
finally {
    Pop-Location
}

Write-OutputLog "Observed: setup finished."
