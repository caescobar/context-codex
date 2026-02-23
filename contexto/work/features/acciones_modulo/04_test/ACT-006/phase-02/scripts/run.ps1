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

Write-OutputLog "Expected: run validates ACT-006 phase-02 backend runs endpoints/queries + no-regression."
Write-OutputLog "Observed: run start (DRY_RUN=$DryRun, API_BASE_URL=$ApiBaseUrl)."

$globalEndpointFile = Join-Path $RepoRoot "telemetric-api/src/Telemetric.Api/Features/Actions/Runs/GetRuns/GetRunsEndpoint.cs"
$globalQueryFile = Join-Path $RepoRoot "telemetric-api/src/Telemetric.Api/Features/Actions/Runs/GetRuns/GetRunsQueryHandler.cs"
$templateEndpointFile = Join-Path $RepoRoot "telemetric-api/src/Telemetric.Api/Features/Actions/Templates/GetTemplateRuns/GetTemplateRunsEndpoint.cs"
$templateQueryFile = Join-Path $RepoRoot "telemetric-api/src/Telemetric.Api/Features/Actions/Templates/GetTemplateRuns/GetTemplateRunsQueryHandler.cs"
$openapiFile = Join-Path $RepoRoot "contexto/openapi/actions.yaml"
$phaseSummaryFile = Join-Path $RepoRoot "contexto/work/features/acciones_modulo/03_execution/ACT-006/phase-02.md"
$dbContextFile = Join-Path $RepoRoot "telemetric-api/src/Telemetric.Api/Common/Interfaces/IApplicationDbContext.cs"

$paths = @(
    $globalEndpointFile,
    $globalQueryFile,
    $templateEndpointFile,
    $templateQueryFile,
    $openapiFile,
    $phaseSummaryFile,
    $dbContextFile
)

foreach ($path in $paths) {
    $exists = Test-Path $path
    Write-CommandLog "Test-Path $path"
    Write-OutputLog "Observed: file_exists[$path]=$exists"
}

$hasSummary = Test-Contains $phaseSummaryFile "runs"
$hasOpenApiGlobal = Test-Contains $openapiFile "/api/v1/actions/runs:"
$hasOpenApiTemplate = Test-Contains $openapiFile "/api/v1/actions/templates/{ruleTemplateId}/runs:"
$hasOpenApiPolicy = Test-Contains $openapiFile "x-required-policy: Actions.View"
$hasGlobalRoute = Test-Contains $globalEndpointFile "Get(""/api/v1/actions/runs"")"
$hasTemplateRoute = Test-Contains $templateEndpointFile "Get(""/api/v1/actions/templates/{RuleTemplateId}/runs"")"
$hasGlobalPolicy = Test-Contains $globalEndpointFile "Policies(PermissionClaims.Actions.View)"
$hasTemplatePolicy = Test-Contains $templateEndpointFile "Policies(PermissionClaims.Actions.View)"
$hasGlobalActionAttempts = Test-Contains $globalQueryFile "_context.ActionAttempts"
$hasTemplateActionAttempts = Test-Contains $templateQueryFile "_context.ActionAttempts"
$hasGlobalAsNoTracking = Test-Contains $globalQueryFile ".AsNoTracking()"
$hasTemplateAsNoTracking = Test-Contains $templateQueryFile ".AsNoTracking()"
$hasGlobalOrderDesc = Test-Contains $globalQueryFile "OrderByDescending"
$hasTemplateOrderDesc = Test-Contains $templateQueryFile "OrderByDescending"
$hasTemplateRuleFilter = (Test-Contains $templateQueryFile "RuleTemplateId") -or (Test-Contains $templateQueryFile "request.RuleTemplateId")
$hasTenantScope = (Test-Contains $globalQueryFile "ClientId") -or (Test-Contains $templateQueryFile "ClientId")
$hasDbContextActionAttempts = Test-Contains $dbContextFile "DbSet<ActionAttempt> ActionAttempts"

Write-OutputLog "Observed: phase_summary_has_runs_context=$hasSummary"
Write-OutputLog "Observed: openapi_global_runs_route=$hasOpenApiGlobal"
Write-OutputLog "Observed: openapi_template_runs_route=$hasOpenApiTemplate"
Write-OutputLog "Observed: openapi_actions_view_policy=$hasOpenApiPolicy"
Write-OutputLog "Observed: endpoint_global_route=$hasGlobalRoute"
Write-OutputLog "Observed: endpoint_template_route=$hasTemplateRoute"
Write-OutputLog "Observed: endpoint_global_policy=$hasGlobalPolicy"
Write-OutputLog "Observed: endpoint_template_policy=$hasTemplatePolicy"
Write-OutputLog "Observed: query_global_action_attempts_source=$hasGlobalActionAttempts"
Write-OutputLog "Observed: query_template_action_attempts_source=$hasTemplateActionAttempts"
Write-OutputLog "Observed: query_global_as_no_tracking=$hasGlobalAsNoTracking"
Write-OutputLog "Observed: query_template_as_no_tracking=$hasTemplateAsNoTracking"
Write-OutputLog "Observed: query_global_order_desc=$hasGlobalOrderDesc"
Write-OutputLog "Observed: query_template_order_desc=$hasTemplateOrderDesc"
Write-OutputLog "Observed: query_template_rule_template_filter=$hasTemplateRuleFilter"
Write-OutputLog "Observed: query_tenant_scope_client_id=$hasTenantScope"
Write-OutputLog "Observed: dbcontext_action_attempts_dbset=$hasDbContextActionAttempts"

if ($DryRun -eq "1") {
    Write-CommandLog "npm --prefix $FrontendDir run typecheck"
    Write-OutputLog "Observed (pending): typecheck and auto-login/sql autodiscovery skipped by DRY_RUN=1."
}
else {
    $requiredChecks = @(
        @{ Name = "openapi_global_runs_route"; Value = $hasOpenApiGlobal },
        @{ Name = "openapi_template_runs_route"; Value = $hasOpenApiTemplate },
        @{ Name = "openapi_actions_view_policy"; Value = $hasOpenApiPolicy },
        @{ Name = "endpoint_global_route"; Value = $hasGlobalRoute },
        @{ Name = "endpoint_template_route"; Value = $hasTemplateRoute },
        @{ Name = "endpoint_global_policy"; Value = $hasGlobalPolicy },
        @{ Name = "endpoint_template_policy"; Value = $hasTemplatePolicy },
        @{ Name = "query_global_action_attempts_source"; Value = $hasGlobalActionAttempts },
        @{ Name = "query_template_action_attempts_source"; Value = $hasTemplateActionAttempts },
        @{ Name = "query_global_as_no_tracking"; Value = $hasGlobalAsNoTracking },
        @{ Name = "query_template_as_no_tracking"; Value = $hasTemplateAsNoTracking },
        @{ Name = "query_global_order_desc"; Value = $hasGlobalOrderDesc },
        @{ Name = "query_template_order_desc"; Value = $hasTemplateOrderDesc },
        @{ Name = "query_template_rule_template_filter"; Value = $hasTemplateRuleFilter },
        @{ Name = "query_tenant_scope_client_id"; Value = $hasTenantScope },
        @{ Name = "dbcontext_action_attempts_dbset"; Value = $hasDbContextActionAttempts }
    )

    $failed = @($requiredChecks | Where-Object { -not $_.Value })
    if ($failed.Count -gt 0) {
        $failedNames = ($failed | ForEach-Object { $_.Name }) -join ", "
        Write-OutputLog "Observed: required_checks=FAIL ($failedNames)"
        throw "Missing required checks: $failedNames"
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
