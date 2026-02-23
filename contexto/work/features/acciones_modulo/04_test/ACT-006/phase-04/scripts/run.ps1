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

function Count-MatchesInFile([string]$Path, [string]$Pattern) {
    if (!(Test-Path $Path)) { return 0 }
    $matches = Select-String -Path $Path -Pattern $Pattern -AllMatches -ErrorAction SilentlyContinue
    if ($null -eq $matches) { return 0 }
    return @($matches).Count
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

Write-OutputLog "Expected: run validates ACT-006 phase-04 runs detail by template + typed contracts + counter consistency."
Write-OutputLog "Observed: run start (DRY_RUN=$DryRun, API_BASE_URL=$ApiBaseUrl)."

$viewFile = Join-Path $RepoRoot "telemetric-front/src/features/actions/views/ActionTemplateDetailView.vue"
$serviceFile = Join-Path $RepoRoot "telemetric-front/src/features/actions/actions.service.ts"
$typesFile = Join-Path $RepoRoot "telemetric-front/src/features/actions/types.ts"
$summaryFile = Join-Path $RepoRoot "contexto/work/features/acciones_modulo/03_execution/ACT-006/phase-04.md"
$templateRunsEndpoint = Join-Path $RepoRoot "telemetric-api/src/Telemetric.Api/Features/Actions/Templates/GetTemplateRuns/GetTemplateRunsEndpoint.cs"
$getTemplateByIdHandler = Join-Path $RepoRoot "telemetric-api/src/Telemetric.Api/Features/Actions/Templates/GetTemplateById/GetTemplateByIdQueryHandler.cs"
$openApiFile = Join-Path $RepoRoot "contexto/openapi/actions.yaml"

$paths = @(
    $viewFile,
    $serviceFile,
    $typesFile,
    $summaryFile,
    $templateRunsEndpoint,
    $getTemplateByIdHandler,
    $openApiFile
)

foreach ($path in $paths) {
    $exists = Test-Path $path
    Write-CommandLog "Test-Path $path"
    Write-OutputLog "Observed: file_exists[$path]=$exists"
}

$hasSummaryDone = Test-Contains $summaryFile "DONE"
$hasSummaryRunsDetail = Test-Contains $summaryFile 'tab `Runs`'
$hasRunsTab = Test-Contains $viewFile '<v-tab value="runs">Ejecuciones</v-tab>'
$hasWatchRunsTab = Test-Contains $viewFile "if (tab === 'runs')"
$hasReloadRunsOnTab = Test-Contains $viewFile "reloadRuns()"
$hasServiceTemplateRunsCall = Test-Contains $viewFile "actionsService.getTemplateRuns(ruleTemplateId.value"
$hasRunsErrorState = Test-Contains $viewFile "runsErrorMessage"
$hasRunsErrorCopy = Test-Contains $viewFile "No se pudieron cargar las ejecuciones del template."
$hasRunsEmptyState = Test-Contains $viewFile "hasRunsLoaded && !runsErrorMessage && runsTotalItems === 0"
$hasRunsEmptyCopy = Test-Contains $viewFile "No hay ejecuciones para el template seleccionado."
$hasFailRowError = Test-Contains $viewFile "item.status === 'Fail'"
$hasFailFallback = Test-Contains $viewFile "Fallo sin detalle de error."
$hasFailedRunsCountView = Test-Contains $viewFile "detail.failedRunsCount"
$hasServiceGetTemplateRuns = Test-Contains $serviceFile "getTemplateRuns:"
$hasServiceTemplateRunsRoute = (Test-Contains $serviceFile "getTemplateRuns: (ruleTemplateId: number") -and (Test-Contains $serviceFile '/runs${buildQueryString(')
$hasTypeTemplateParams = Test-Contains $typesFile "export type TemplateActionRunsQueryParams"
$hasTypeRunItem = Test-Contains $typesFile "export type ActionRunListItem"
$hasTypeFailedRunsCount = Test-Contains $typesFile "failedRunsCount: number"
$hasEndpointTemplateRunsRoute = Test-Contains $templateRunsEndpoint 'Get("/api/v1/actions/templates/{RuleTemplateId}/runs")'
$hasEndpointTemplateRunsPolicy = Test-Contains $templateRunsEndpoint "Policies(PermissionClaims.Actions.View)"
$hasOpenApiTemplateRuns = Test-Contains $openApiFile "/api/v1/actions/templates/{ruleTemplateId}/runs:"
$hasFailStatusFilter = Test-Contains $getTemplateByIdHandler "attempt.Status == ActionAttempt.StatusFail"
$hasTemplateFilter = Test-Contains $getTemplateByIdHandler "attempt.RuleInstance.RuleTemplateVersion.RuleTemplateId == template.RuleTemplateId"
$hasTenantFilter = Test-Contains $getTemplateByIdHandler "attempt.RuleInstance.RuleTemplateVersion.RuleTemplate.ClientId == _currentUserService.ClientId.Value"
$hasSoftDeleteAttempt = Test-Contains $getTemplateByIdHandler "!attempt.IsDeleted"
$hasSoftDeleteRuleInstance = Test-Contains $getTemplateByIdHandler "!attempt.RuleInstance.IsDeleted"
$hasSoftDeleteVersion = Test-Contains $getTemplateByIdHandler "!attempt.RuleInstance.RuleTemplateVersion.IsDeleted"
$hasSoftDeleteTemplate = Test-Contains $getTemplateByIdHandler "!attempt.RuleInstance.RuleTemplateVersion.RuleTemplate.IsDeleted"

$serviceAnyCount = Count-MatchesInFile $serviceFile '\bany\b'
$typesAnyCount = Count-MatchesInFile $typesFile '\bany\b'
$viewAnyCount = Count-MatchesInFile $viewFile '\bany\b'
$serviceUnknownCount = Count-MatchesInFile $serviceFile '\bunknown\b'
$typesUnknownCount = Count-MatchesInFile $typesFile '\bunknown\b'
$viewUnknownCount = Count-MatchesInFile $viewFile '\bunknown\b'

Write-OutputLog "Observed: phase_summary_done=$hasSummaryDone"
Write-OutputLog "Observed: phase_summary_runs_detail=$hasSummaryRunsDetail"
Write-OutputLog "Observed: view_runs_tab_present=$hasRunsTab"
Write-OutputLog "Observed: view_watch_runs_tab=$hasWatchRunsTab"
Write-OutputLog "Observed: view_reload_runs_on_tab=$hasReloadRunsOnTab"
Write-OutputLog "Observed: view_service_template_runs_call=$hasServiceTemplateRunsCall"
Write-OutputLog "Observed: view_runs_error_state=$hasRunsErrorState"
Write-OutputLog "Observed: view_runs_error_copy=$hasRunsErrorCopy"
Write-OutputLog "Observed: view_runs_empty_state=$hasRunsEmptyState"
Write-OutputLog "Observed: view_runs_empty_copy=$hasRunsEmptyCopy"
Write-OutputLog "Observed: view_fail_row_error_cell=$hasFailRowError"
Write-OutputLog "Observed: view_fail_row_error_fallback=$hasFailFallback"
Write-OutputLog "Observed: view_failed_runs_count=$hasFailedRunsCountView"
Write-OutputLog "Observed: service_get_template_runs_method=$hasServiceGetTemplateRuns"
Write-OutputLog "Observed: service_get_template_runs_route=$hasServiceTemplateRunsRoute"
Write-OutputLog "Observed: types_template_runs_query_params=$hasTypeTemplateParams"
Write-OutputLog "Observed: types_action_run_list_item=$hasTypeRunItem"
Write-OutputLog "Observed: types_failed_runs_count=$hasTypeFailedRunsCount"
Write-OutputLog "Observed: endpoint_template_runs_route=$hasEndpointTemplateRunsRoute"
Write-OutputLog "Observed: endpoint_template_runs_policy=$hasEndpointTemplateRunsPolicy"
Write-OutputLog "Observed: openapi_template_runs_path=$hasOpenApiTemplateRuns"
Write-OutputLog "Observed: backend_fail_status_filter=$hasFailStatusFilter"
Write-OutputLog "Observed: backend_template_filter=$hasTemplateFilter"
Write-OutputLog "Observed: backend_tenant_filter=$hasTenantFilter"
Write-OutputLog "Observed: backend_soft_delete_attempt=$hasSoftDeleteAttempt"
Write-OutputLog "Observed: backend_soft_delete_rule_instance=$hasSoftDeleteRuleInstance"
Write-OutputLog "Observed: backend_soft_delete_version=$hasSoftDeleteVersion"
Write-OutputLog "Observed: backend_soft_delete_template=$hasSoftDeleteTemplate"
Write-OutputLog "Observed: any_count[service]=$serviceAnyCount"
Write-OutputLog "Observed: any_count[types]=$typesAnyCount"
Write-OutputLog "Observed: any_count[view]=$viewAnyCount"
Write-OutputLog "Observed: unknown_count[service]=$serviceUnknownCount"
Write-OutputLog "Observed: unknown_count[types]=$typesUnknownCount"
Write-OutputLog "Observed: unknown_count[view]=$viewUnknownCount"

if ($DryRun -eq "1") {
    Write-CommandLog "npm --prefix $FrontendDir run typecheck"
    Write-OutputLog "Observed (pending): typecheck and auto-login/sql autodiscovery skipped by DRY_RUN=1."
}
else {
    $requiredChecks = @(
        @{ Name = "phase_summary_done"; Value = $hasSummaryDone },
        @{ Name = "view_runs_tab_present"; Value = $hasRunsTab },
        @{ Name = "view_watch_runs_tab"; Value = $hasWatchRunsTab },
        @{ Name = "view_reload_runs_on_tab"; Value = $hasReloadRunsOnTab },
        @{ Name = "view_service_template_runs_call"; Value = $hasServiceTemplateRunsCall },
        @{ Name = "view_runs_error_state"; Value = $hasRunsErrorState },
        @{ Name = "view_runs_error_copy"; Value = $hasRunsErrorCopy },
        @{ Name = "view_runs_empty_state"; Value = $hasRunsEmptyState },
        @{ Name = "view_runs_empty_copy"; Value = $hasRunsEmptyCopy },
        @{ Name = "view_fail_row_error_cell"; Value = $hasFailRowError },
        @{ Name = "view_fail_row_error_fallback"; Value = $hasFailFallback },
        @{ Name = "view_failed_runs_count"; Value = $hasFailedRunsCountView },
        @{ Name = "service_get_template_runs_method"; Value = $hasServiceGetTemplateRuns },
        @{ Name = "service_get_template_runs_route"; Value = $hasServiceTemplateRunsRoute },
        @{ Name = "types_template_runs_query_params"; Value = $hasTypeTemplateParams },
        @{ Name = "types_action_run_list_item"; Value = $hasTypeRunItem },
        @{ Name = "types_failed_runs_count"; Value = $hasTypeFailedRunsCount },
        @{ Name = "endpoint_template_runs_route"; Value = $hasEndpointTemplateRunsRoute },
        @{ Name = "endpoint_template_runs_policy"; Value = $hasEndpointTemplateRunsPolicy },
        @{ Name = "openapi_template_runs_path"; Value = $hasOpenApiTemplateRuns },
        @{ Name = "backend_fail_status_filter"; Value = $hasFailStatusFilter },
        @{ Name = "backend_template_filter"; Value = $hasTemplateFilter },
        @{ Name = "backend_tenant_filter"; Value = $hasTenantFilter },
        @{ Name = "backend_soft_delete_attempt"; Value = $hasSoftDeleteAttempt },
        @{ Name = "backend_soft_delete_rule_instance"; Value = $hasSoftDeleteRuleInstance },
        @{ Name = "backend_soft_delete_version"; Value = $hasSoftDeleteVersion },
        @{ Name = "backend_soft_delete_template"; Value = $hasSoftDeleteTemplate }
    )

    $failed = @($requiredChecks | Where-Object { -not $_.Value })
    if ($failed.Count -gt 0) {
        $failedNames = ($failed | ForEach-Object { $_.Name }) -join ", "
        Write-OutputLog "Observed: required_checks=FAIL ($failedNames)"
        throw "Missing required checks: $failedNames"
    }

    if (($serviceAnyCount + $typesAnyCount + $viewAnyCount) -gt 0) {
        Write-OutputLog "Observed: any_guard=FAIL (any detected in scope files)"
        throw "Any detected in scope files."
    }
    Write-OutputLog "Observed: any_guard=PASS (no any in scope files)"
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
