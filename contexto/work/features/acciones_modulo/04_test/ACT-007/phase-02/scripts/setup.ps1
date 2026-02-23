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

Write-OutputLog "Expected: setup validates prerequisites and discovery for ACT-007 phase-02."
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
$planRel = "contexto/work/features/acciones_modulo/02_plans/ACT-007.plan.md"
$summaryRel = "contexto/work/features/acciones_modulo/03_execution/ACT-007/phase-02.md"
$openapiRel = "contexto/openapi/actions.yaml"
$endpointGetRulesRel = "telemetric-api/src/Telemetric.Api/Features/Actions/Rules/GetRules/GetRulesEndpoint.cs"
$queryGetRulesRel = "telemetric-api/src/Telemetric.Api/Features/Actions/Rules/GetRules/GetRulesQueryHandler.cs"
$endpointUpdateRel = "telemetric-api/src/Telemetric.Api/Features/Actions/Rules/UpdateRuleState/UpdateRuleStateEndpoint.cs"
$commandUpdateRel = "telemetric-api/src/Telemetric.Api/Features/Actions/Rules/UpdateRuleState/UpdateRuleStateCommandHandler.cs"
$dbContextRel = "telemetric-api/src/Telemetric.Api/Common/Interfaces/IApplicationDbContext.cs"

foreach ($rel in @(
    $composePrimaryRel,
    $composeLegacyRel,
    $launchSettingsRel,
    $planRel,
    $summaryRel,
    $openapiRel,
    $endpointGetRulesRel,
    $queryGetRulesRel,
    $endpointUpdateRel,
    $commandUpdateRel,
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
    Invoke-Step "rg --line-number -F -e '/api/v1/actions/rules:' -e '/api/v1/actions/devices/{deviceId}/rules:' -e '/api/v1/actions/rules/{ruleInstanceId}/state:' contexto/openapi/actions.yaml"
    Invoke-Step "rg --line-number -F -e 'Get(""/api/v1/actions/rules"")' telemetric-api/src/Telemetric.Api/Features/Actions/Rules/GetRules/GetRulesEndpoint.cs"
    Invoke-Step "rg --line-number -F -e 'Patch(""/api/v1/actions/rules/{RuleInstanceId}/state"")' telemetric-api/src/Telemetric.Api/Features/Actions/Rules/UpdateRuleState/UpdateRuleStateEndpoint.cs"
    Invoke-Step "rg --line-number -F -e 'Policies(PermissionClaims.Actions.View)' -e 'Policies(PermissionClaims.Actions.Update)' telemetric-api/src/Telemetric.Api/Features/Actions/Rules/GetRules/GetRulesEndpoint.cs telemetric-api/src/Telemetric.Api/Features/Actions/Rules/UpdateRuleState/UpdateRuleStateEndpoint.cs"
    Invoke-Step "rg --line-number -F -e 'DeviceId' -e 'Status' -e 'ClientId' -e 'ActionAttempts' -e 'StatusFail' telemetric-api/src/Telemetric.Api/Features/Actions/Rules/GetRules/GetRulesQueryHandler.cs"
    Invoke-Step "rg --line-number -F -e 'SaveChangesAsync' -e 'UpdatedAt' -e 'UpdatedBy' -e 'ClientId' telemetric-api/src/Telemetric.Api/Features/Actions/Rules/UpdateRuleState/UpdateRuleStateCommandHandler.cs"
}
finally {
    Pop-Location
}

Write-OutputLog "Observed: setup finished."
