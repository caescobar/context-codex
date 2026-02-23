# Requires -Version 5.1
$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$PackDir = Resolve-Path (Join-Path $ScriptDir "..")
$EvidenceDir = Join-Path $PackDir "evidence"
$RepoRoot = Resolve-Path (Join-Path $ScriptDir "..\..\..\..\..\..\..\..")

$DryRun = if ($env:DRY_RUN) { $env:DRY_RUN } else { "1" }
$FrontendDir = if ($env:FRONTEND_DIR) { $env:FRONTEND_DIR } else { "telemetric-front" }
$ApiBaseUrl = if ($env:API_BASE_URL) { $env:API_BASE_URL.TrimEnd("/") } else { "http://localhost:5220" }
$ApiAuthToken = if ($env:API_AUTH_TOKEN) { $env:API_AUTH_TOKEN } else { "" }
$ApiUser = if ($env:API_USER) { $env:API_USER } else { "vcsoft" }
$ApiPassword = if ($env:API_PASSWORD) { $env:API_PASSWORD } else { "123456" }
$SqlcmdArgs = if ($env:SQLCMD_ARGS) { $env:SQLCMD_ARGS } else { "-S . -d TelemetricDb -U sa -P sa -C" }
$TestRuleTemplateVersionId = if ($env:TEST_RULE_TEMPLATE_VERSION_ID) { $env:TEST_RULE_TEMPLATE_VERSION_ID } else { "" }
$TestDeviceIds = if ($env:TEST_DEVICE_IDS) { $env:TEST_DEVICE_IDS } else { "" }
$BaselineTsErrors = if ($env:BASELINE_TS_ERRORS) { $env:BASELINE_TS_ERRORS } else { "" }

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

function Test-Contains([string]$Path, [string]$Text) {
    if (!(Test-Path $Path)) { return $false }
    $match = Select-String -Path $Path -SimpleMatch -Pattern $Text -ErrorAction SilentlyContinue
    return $null -ne $match
}

function Invoke-Step([string]$Command) {
    Write-CommandLog $Command
    if ($DryRun -eq "1") {
        Write-Host "[DRY_RUN] $Command"
        Write-OutputLog "Observed (pending): DRY_RUN=1 skipped command."
        return @()
    }

    Write-Host "[EXEC] $Command"
    return @(Invoke-Expression $Command 2>&1)
}

function Try-QuerySqlFirstId([string]$Query) {
    try {
        Write-CommandLog "sqlcmd $SqlcmdArgs ($Query)"
        $raw = Invoke-Expression ("sqlcmd {0} -h -1 -W -Q `"SET NOCOUNT ON; {1}`"" -f $SqlcmdArgs, $Query) | Out-String
        return ($raw -split "`r?`n" | ForEach-Object { $_.Trim() } | Where-Object { $_ -match '^\d+$' } | Select-Object -First 1)
    }
    catch {
        return $null
    }
}

function Try-QuerySqlIdList([string]$Query) {
    try {
        Write-CommandLog "sqlcmd $SqlcmdArgs ($Query)"
        $raw = Invoke-Expression ("sqlcmd {0} -h -1 -W -Q `"SET NOCOUNT ON; {1}`"" -f $SqlcmdArgs, $Query) | Out-String
        $ids = @($raw -split "`r?`n" | ForEach-Object { $_.Trim() } | Where-Object { $_ -match '^\d+$' })
        if ($ids.Count -eq 0) { return $null }
        return ($ids -join ",")
    }
    catch {
        return $null
    }
}

function Try-AutoResolveIntegrationInputs() {
    if ([string]::IsNullOrWhiteSpace($ApiAuthToken)) {
        try {
            $loginUri = "$ApiBaseUrl/api/v1/auth/login"
            Write-CommandLog "Invoke-RestMethod POST $loginUri (auto token)"
            $loginBody = @{ username = $ApiUser; password = $ApiPassword } | ConvertTo-Json -Compress
            $login = Invoke-RestMethod -Method Post -Uri $loginUri -ContentType "application/json" -Body $loginBody
            if ($login.token) {
                $script:ApiAuthToken = [string]$login.token
                Write-OutputLog "Observed: auto_login_token=OK (API_USER=$ApiUser)"
            }
            else {
                Write-OutputLog "Observed: auto_login_token=FAIL (empty token)"
            }
        }
        catch {
            Write-OutputLog "Observed: auto_login_token=FAIL ($($_.Exception.Message))"
        }
    }

    $sqlcmd = Get-Command sqlcmd -ErrorAction SilentlyContinue
    if ($null -eq $sqlcmd) {
        Write-OutputLog "Observed: sqlcmd unavailable for autodiscovery."
        return
    }

    if ([string]::IsNullOrWhiteSpace($TestRuleTemplateVersionId)) {
        $id = Try-QuerySqlFirstId "SELECT TOP 1 RuleTemplateVersionId FROM dbo.RuleTemplateVersion WHERE IsDeleted=0 ORDER BY RuleTemplateVersionId DESC;"
        if ($id) {
            $script:TestRuleTemplateVersionId = $id
            Write-OutputLog "Observed: auto_rule_template_version_id=$id"
        }
        else {
            Write-OutputLog "Observed: auto_rule_template_version_id=FAIL"
        }
    }

    if ([string]::IsNullOrWhiteSpace($TestDeviceIds)) {
        $ids = Try-QuerySqlIdList "SELECT TOP 3 DeviceId FROM dbo.Device WHERE IsDeleted=0 ORDER BY DeviceId DESC;"
        if (-not $ids) {
            $ids = Try-QuerySqlIdList "SELECT TOP 3 DeviceId FROM dbo.Devices WHERE IsDeleted=0 ORDER BY DeviceId DESC;"
        }
        if ($ids) {
            $script:TestDeviceIds = $ids
            Write-OutputLog "Observed: auto_test_device_ids=$ids"
        }
        else {
            Write-OutputLog "Observed: auto_test_device_ids=FAIL"
        }
    }
}

Write-OutputLog "Expected: run validates ACT-006 phase-01 discovery/equivalence and OpenAPI contract."
Write-OutputLog "Observed: run start (DRY_RUN=$DryRun, API_BASE_URL=$ApiBaseUrl)."

$openapiFile = Join-Path $RepoRoot "contexto/openapi/actions.yaml"
$endpointFile1 = Join-Path $RepoRoot "telemetric-api/src/Telemetric.Api/Features/Actions/Templates/GetTemplates/GetTemplatesEndpoint.cs"
$endpointFile2 = Join-Path $RepoRoot "telemetric-api/src/Telemetric.Api/Features/Actions/Templates/GetTemplateById/GetTemplateByIdEndpoint.cs"
$phaseSummaryFile = Join-Path $RepoRoot "contexto/work/features/acciones_modulo/03_execution/ACT-006/phase-01.md"

$hasSummary = Test-Contains $phaseSummaryFile "no existe endpoint equivalente de runs"
$hasOpenApiRunsGlobal = Test-Contains $openapiFile "/api/v1/actions/runs:"
$hasOpenApiRunsTemplate = Test-Contains $openapiFile "/api/v1/actions/templates/{ruleTemplateId}/runs:"
$hasPolicy = Test-Contains $openapiFile "x-required-policy: Actions.View"
$hasItemSchema = Test-Contains $openapiFile "ActionRunListItem"
$hasStatus = Test-Contains $openapiFile "ActionRunStatus"
$hasContext = Test-Contains $openapiFile "ActionRunContext"
$hasFieldStatus = Test-Contains $openapiFile "status:"
$hasFieldError = Test-Contains $openapiFile "error:"
$hasFieldAttemptedAt = Test-Contains $openapiFile "attemptedAt:"
$hasFieldRuleInstanceId = Test-Contains $openapiFile "ruleInstanceId:"
$hasFieldContext = Test-Contains $openapiFile "context:"
$hasV1Prefix = Test-Contains $openapiFile "/api/v1/actions/"
$hasBackendPolicy1 = Test-Contains $endpointFile1 "Policies(PermissionClaims.Actions.View)"
$hasBackendPolicy2 = Test-Contains $endpointFile2 "Policies(PermissionClaims.Actions.View)"

Write-OutputLog "Observed: phase_summary_equivalence_note=$hasSummary"
Write-OutputLog "Observed: openapi_runs_global=$hasOpenApiRunsGlobal"
Write-OutputLog "Observed: openapi_runs_template=$hasOpenApiRunsTemplate"
Write-OutputLog "Observed: openapi_policy_actions_view=$hasPolicy"
Write-OutputLog "Observed: openapi_schema_action_run_list_item=$hasItemSchema"
Write-OutputLog "Observed: openapi_schema_action_run_status=$hasStatus"
Write-OutputLog "Observed: openapi_schema_action_run_context=$hasContext"
Write-OutputLog "Observed: payload_field_status=$hasFieldStatus"
Write-OutputLog "Observed: payload_field_error=$hasFieldError"
Write-OutputLog "Observed: payload_field_attemptedAt=$hasFieldAttemptedAt"
Write-OutputLog "Observed: payload_field_ruleInstanceId=$hasFieldRuleInstanceId"
Write-OutputLog "Observed: payload_field_context=$hasFieldContext"
Write-OutputLog "Observed: openapi_v1_prefix=$hasV1Prefix"
Write-OutputLog "Observed: backend_policy_templates_get=$hasBackendPolicy1"
Write-OutputLog "Observed: backend_policy_template_by_id=$hasBackendPolicy2"

Push-Location $RepoRoot
try {
    $runMatches = @(Invoke-Step "rg --line-number -F -g ""*.cs"" -e ""/api/v1/actions/runs"" -e ""/api/v1/actions/templates/{ruleTemplateId}/runs"" telemetric-api/src/Telemetric.Api/Features/Actions")
    if ($DryRun -eq "0") {
        if ($runMatches.Count -eq 0) {
            Write-OutputLog "Observed: backend_runs_equivalence=PASS (no equivalent endpoint found)."
        }
        else {
            Write-OutputLog "Observed: backend_runs_equivalence=FAIL (unexpected matches found)."
            Add-Content -Path $OutputsLog -Value ($runMatches | Out-String).TrimEnd()
            throw "Equivalent runs endpoint found in backend."
        }
    }
    else {
        Write-OutputLog "Observed (pending): backend_runs_equivalence requires DRY_RUN=0 execution."
    }

    $policyMatches = @(Invoke-Step "rg --line-number -F -e ""x-required-policy: Actions.View"" contexto/openapi/actions.yaml")
    if ($DryRun -eq "0" -and $policyMatches.Count -eq 0) {
        throw "Missing x-required-policy: Actions.View in OpenAPI."
    }

    if ($DryRun -eq "0") {
        Write-CommandLog "npm --prefix $FrontendDir run typecheck"
        $typecheckOut = @(npm --prefix $FrontendDir run typecheck 2>&1)
        $typecheckExit = $LASTEXITCODE
        if ($typecheckOut.Count -gt 0) {
            Add-Content -Path $OutputsLog -Value ($typecheckOut | Out-String).TrimEnd()
        }

        $nonDemoErrors = @(
            $typecheckOut | Where-Object {
                ($_ -match '^(src[\\/]).*error TS[0-9]+:') -and
                ($_ -notmatch '^(src[\\/]_demo[\\/])')
            }
        )
        $observedErrors = $nonDemoErrors.Count
        Write-OutputLog "Observed: typecheck_exit_code=$typecheckExit"
        Write-OutputLog "Observed: no_demo_ts_errors=$observedErrors"

        if (-not [string]::IsNullOrWhiteSpace($BaselineTsErrors)) {
            $baseline = [int]$BaselineTsErrors
            Write-OutputLog "Expected: no regression no-demo -> observed <= baseline ($baseline)"
            if ($observedErrors -gt $baseline) {
                Write-OutputLog "Observed: gate_no_regression=FAIL (observed=$observedErrors > baseline=$baseline)"
                throw "No-regression gate failed: observed=$observedErrors baseline=$baseline"
            }
            Write-OutputLog "Observed: gate_no_regression=PASS (observed=$observedErrors <= baseline=$baseline)"
        }
        else {
            Write-OutputLog "Observed: baseline missing (BASELINE_TS_ERRORS). Numeric gate skipped."
        }

        Try-AutoResolveIntegrationInputs
    }
    else {
        Write-OutputLog "Observed (pending): typecheck and auto-login/sql autodiscovery skipped by DRY_RUN=1."
    }
}
finally {
    Pop-Location
}

Write-OutputLog "Observed: run finished."
