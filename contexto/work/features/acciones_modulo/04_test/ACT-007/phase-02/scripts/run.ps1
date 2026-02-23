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

Write-OutputLog "Expected: run validates ACT-007 phase-02 backend Rules endpoints/handlers + no-regression."
Write-OutputLog "Observed: run start (DRY_RUN=$DryRun, API_BASE_URL=$ApiBaseUrl)."

$getEndpointFile = Join-Path $RepoRoot "telemetric-api/src/Telemetric.Api/Features/Actions/Rules/GetRules/GetRulesEndpoint.cs"
$getQueryFile = Join-Path $RepoRoot "telemetric-api/src/Telemetric.Api/Features/Actions/Rules/GetRules/GetRulesQueryHandler.cs"
$updateEndpointFile = Join-Path $RepoRoot "telemetric-api/src/Telemetric.Api/Features/Actions/Rules/UpdateRuleState/UpdateRuleStateEndpoint.cs"
$updateCommandFile = Join-Path $RepoRoot "telemetric-api/src/Telemetric.Api/Features/Actions/Rules/UpdateRuleState/UpdateRuleStateCommandHandler.cs"
$openapiFile = Join-Path $RepoRoot "contexto/openapi/actions.yaml"
$phaseSummaryFile = Join-Path $RepoRoot "contexto/work/features/acciones_modulo/03_execution/ACT-007/phase-02.md"
$dbContextFile = Join-Path $RepoRoot "telemetric-api/src/Telemetric.Api/Common/Interfaces/IApplicationDbContext.cs"

$paths = @(
    $getEndpointFile,
    $getQueryFile,
    $updateEndpointFile,
    $updateCommandFile,
    $openapiFile,
    $phaseSummaryFile,
    $dbContextFile
)

foreach ($path in $paths) {
    $exists = Test-Path $path
    Write-CommandLog "Test-Path $path"
    Write-OutputLog "Observed: file_exists[$path]=$exists"
}

$hasSummaryRulesGet = Test-Contains $phaseSummaryFile "GET /api/v1/actions/rules"
$hasSummaryRulesPatch = Test-Contains $phaseSummaryFile "PATCH /api/v1/actions/rules/{ruleInstanceId}/state"
$hasOpenApiRules = Test-Contains $openapiFile "/api/v1/actions/rules:"
$hasOpenApiDeviceRules = Test-Contains $openapiFile "/api/v1/actions/devices/{deviceId}/rules:"
$hasOpenApiRuleState = Test-Contains $openapiFile "/api/v1/actions/rules/{ruleInstanceId}/state:"
$hasOpenApiPolicyView = Test-Contains $openapiFile "x-required-policy: Actions.View"
$hasOpenApiPolicyUpdate = Test-Contains $openapiFile "x-required-policy: Actions.Update"
$hasOpenApiRulesResponse = Test-Contains $openapiFile "GetRulesResponse"
$hasOpenApiRuleListItem = Test-Contains $openapiFile "RuleListItem"
$hasOpenApiUpdateReq = Test-Contains $openapiFile "UpdateRuleStateRequest"
$hasOpenApiUpdateRes = Test-Contains $openapiFile "UpdateRuleStateResponse"
$hasOpenApiRulesStatusParam = Test-Contains $openapiFile "- name: status"
$hasGetRoute = Test-Contains $getEndpointFile "Get(""/api/v1/actions/rules"")"
$hasGetPolicy = Test-Contains $getEndpointFile "Policies(PermissionClaims.Actions.View)"
$hasUpdateRoute = Test-Contains $updateEndpointFile "Patch(""/api/v1/actions/rules/{RuleInstanceId}/state"")"
$hasUpdatePolicy = Test-Contains $updateEndpointFile "Policies(PermissionClaims.Actions.Update)"
$hasQueryDeviceId = Test-Contains $getQueryFile "DeviceId"
$hasQueryStatus = Test-Contains $getQueryFile "Status"
$hasQueryTenantScope = Test-Contains $getQueryFile "ClientId"
$hasQueryActionAttempts = Test-Contains $getQueryFile "ActionAttempts"
$hasQueryAsNoTracking = Test-Contains $getQueryFile ".AsNoTracking()"
$hasQueryLastAttempt = Test-Contains $getQueryFile "LastAttempt"
$hasQueryStatusFail = Test-Contains $getQueryFile "StatusFail"
$hasUpdateValidateId = Test-Contains $updateCommandFile "RuleInstanceId <= 0"
$hasUpdateTenantScope = Test-Contains $updateCommandFile "ClientId"
$hasUpdateSaveChanges = Test-Contains $updateCommandFile "SaveChangesAsync"
$hasUpdateUpdatedAt = Test-Contains $updateCommandFile "UpdatedAt"
$hasUpdateUpdatedBy = Test-Contains $updateCommandFile "UpdatedBy"
$hasDbRuleInstances = Test-Contains $dbContextFile "DbSet<RuleInstance> RuleInstances"
$hasDbActionAttempts = Test-Contains $dbContextFile "DbSet<ActionAttempt> ActionAttempts"

Write-OutputLog "Observed: phase_summary_rules_get=$hasSummaryRulesGet"
Write-OutputLog "Observed: phase_summary_rules_patch=$hasSummaryRulesPatch"
Write-OutputLog "Observed: openapi_rules_route=$hasOpenApiRules"
Write-OutputLog "Observed: openapi_device_rules_route=$hasOpenApiDeviceRules"
Write-OutputLog "Observed: openapi_rule_state_route=$hasOpenApiRuleState"
Write-OutputLog "Observed: openapi_policy_actions_view=$hasOpenApiPolicyView"
Write-OutputLog "Observed: openapi_policy_actions_update=$hasOpenApiPolicyUpdate"
Write-OutputLog "Observed: openapi_schema_get_rules_response=$hasOpenApiRulesResponse"
Write-OutputLog "Observed: openapi_schema_rule_list_item=$hasOpenApiRuleListItem"
Write-OutputLog "Observed: openapi_schema_update_rule_state_request=$hasOpenApiUpdateReq"
Write-OutputLog "Observed: openapi_schema_update_rule_state_response=$hasOpenApiUpdateRes"
Write-OutputLog "Observed: openapi_rules_status_param=$hasOpenApiRulesStatusParam"
Write-OutputLog "Observed: endpoint_get_rules_route=$hasGetRoute"
Write-OutputLog "Observed: endpoint_get_rules_policy=$hasGetPolicy"
Write-OutputLog "Observed: endpoint_update_rule_state_route=$hasUpdateRoute"
Write-OutputLog "Observed: endpoint_update_rule_state_policy=$hasUpdatePolicy"
Write-OutputLog "Observed: query_device_id_filter=$hasQueryDeviceId"
Write-OutputLog "Observed: query_status_filter=$hasQueryStatus"
Write-OutputLog "Observed: query_tenant_scope_client_id=$hasQueryTenantScope"
Write-OutputLog "Observed: query_action_attempts_source=$hasQueryActionAttempts"
Write-OutputLog "Observed: query_as_no_tracking=$hasQueryAsNoTracking"
Write-OutputLog "Observed: query_last_attempt_projection=$hasQueryLastAttempt"
Write-OutputLog "Observed: query_status_fail_signal=$hasQueryStatusFail"
Write-OutputLog "Observed: command_validate_rule_instance_id=$hasUpdateValidateId"
Write-OutputLog "Observed: command_tenant_scope_client_id=$hasUpdateTenantScope"
Write-OutputLog "Observed: command_save_changes=$hasUpdateSaveChanges"
Write-OutputLog "Observed: command_updates_updated_at=$hasUpdateUpdatedAt"
Write-OutputLog "Observed: command_updates_updated_by=$hasUpdateUpdatedBy"
Write-OutputLog "Observed: dbcontext_rule_instances_dbset=$hasDbRuleInstances"
Write-OutputLog "Observed: dbcontext_action_attempts_dbset=$hasDbActionAttempts"

if ($DryRun -eq "1") {
    Write-CommandLog "npm --prefix $FrontendDir run typecheck"
    Write-OutputLog "Observed (pending): typecheck and auto-login/sql autodiscovery skipped by DRY_RUN=1."
}
else {
    $requiredChecks = @(
        @{ Name = "phase_summary_rules_get"; Value = $hasSummaryRulesGet },
        @{ Name = "phase_summary_rules_patch"; Value = $hasSummaryRulesPatch },
        @{ Name = "openapi_rules_route"; Value = $hasOpenApiRules },
        @{ Name = "openapi_rule_state_route"; Value = $hasOpenApiRuleState },
        @{ Name = "openapi_policy_actions_view"; Value = $hasOpenApiPolicyView },
        @{ Name = "openapi_policy_actions_update"; Value = $hasOpenApiPolicyUpdate },
        @{ Name = "endpoint_get_rules_route"; Value = $hasGetRoute },
        @{ Name = "endpoint_get_rules_policy"; Value = $hasGetPolicy },
        @{ Name = "endpoint_update_rule_state_route"; Value = $hasUpdateRoute },
        @{ Name = "endpoint_update_rule_state_policy"; Value = $hasUpdatePolicy },
        @{ Name = "query_device_id_filter"; Value = $hasQueryDeviceId },
        @{ Name = "query_status_filter"; Value = $hasQueryStatus },
        @{ Name = "query_tenant_scope_client_id"; Value = $hasQueryTenantScope },
        @{ Name = "query_action_attempts_source"; Value = $hasQueryActionAttempts },
        @{ Name = "query_as_no_tracking"; Value = $hasQueryAsNoTracking },
        @{ Name = "query_last_attempt_projection"; Value = $hasQueryLastAttempt },
        @{ Name = "query_status_fail_signal"; Value = $hasQueryStatusFail },
        @{ Name = "command_validate_rule_instance_id"; Value = $hasUpdateValidateId },
        @{ Name = "command_tenant_scope_client_id"; Value = $hasUpdateTenantScope },
        @{ Name = "command_save_changes"; Value = $hasUpdateSaveChanges },
        @{ Name = "command_updates_updated_at"; Value = $hasUpdateUpdatedAt },
        @{ Name = "command_updates_updated_by"; Value = $hasUpdateUpdatedBy },
        @{ Name = "dbcontext_rule_instances_dbset"; Value = $hasDbRuleInstances },
        @{ Name = "dbcontext_action_attempts_dbset"; Value = $hasDbActionAttempts }
    )

    $failed = @($requiredChecks | Where-Object { -not $_.Value })
    if ($failed.Count -gt 0) {
        $failedNames = ($failed | ForEach-Object { $_.Name }) -join ", "
        Write-OutputLog "Observed: required_checks=FAIL ($failedNames)"
        throw "Missing required checks: $failedNames"
    }

    if (-not $hasOpenApiDeviceRules) {
        Write-OutputLog "Observed: WARN openapi_device_rules_route_missing=true"
    }

    Write-OutputLog "Observed: required_checks=PASS"

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

Write-OutputLog "Observed: run finished."
