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

Write-OutputLog "Expected: run validates ACT-007 phase-03 frontend rules tab + badge fail + toggle + no-regression."
Write-OutputLog "Observed: run start (DRY_RUN=$DryRun, API_BASE_URL=$ApiBaseUrl)."

$viewFile = Join-Path $RepoRoot "telemetric-front/src/features/actions/views/ActionsTemplatesView.vue"
$serviceFile = Join-Path $RepoRoot "telemetric-front/src/features/actions/actions.service.ts"
$typesFile = Join-Path $RepoRoot "telemetric-front/src/features/actions/types.ts"
$routesFile = Join-Path $RepoRoot "telemetric-front/src/features/actions/actions.routes.ts"
$menuFile = Join-Path $RepoRoot "telemetric-front/src/layouts/menuItems.ts"
$summaryFile = Join-Path $RepoRoot "contexto/work/features/acciones_modulo/03_execution/ACT-007/phase-03.md"
$getRulesEndpoint = Join-Path $RepoRoot "telemetric-api/src/Telemetric.Api/Features/Actions/Rules/GetRules/GetRulesEndpoint.cs"
$updateStateEndpoint = Join-Path $RepoRoot "telemetric-api/src/Telemetric.Api/Features/Actions/Rules/UpdateRuleState/UpdateRuleStateEndpoint.cs"

$paths = @(
    $viewFile,
    $serviceFile,
    $typesFile,
    $routesFile,
    $menuFile,
    $summaryFile,
    $getRulesEndpoint,
    $updateStateEndpoint
)

foreach ($path in $paths) {
    $exists = Test-Path $path
    Write-CommandLog "Test-Path $path"
    Write-OutputLog "Observed: file_exists[$path]=$exists"
}

$hasSummaryDone = Test-Contains $summaryFile "DONE"
$hasSummaryRulesTab = Test-Contains $summaryFile 'tab `Rules`'
$hasSummaryBadge = Test-Contains $summaryFile "badge rojo"
$hasSummaryToggle = Test-Contains $summaryFile "updateRuleState"

$hasRulesTab = Test-Contains $viewFile '<v-tab value="rules">Rules</v-tab>'
$hasActiveTabRules = Test-Contains $viewFile "activeTab = ref<'runs' | 'rules' | 'templates'>('runs')"
$hasRulesFilterSchema = Test-Contains $viewFile "const rulesFilterSchema"
$hasRulesErrorState = Test-Contains $viewFile "rulesErrorMessage"
$hasRulesErrorCopy = Test-Contains $viewFile "No se pudieron cargar las reglas."
$hasRulesEmptyState = Test-Contains $viewFile "No hay reglas para los filtros seleccionados."
$hasRulesTable = Test-Contains $viewFile "rulesTableProps"
$hasUiDynamicFilter = Test-Contains $viewFile "UiDynamicFilter"
$hasUiServerTable = Test-Contains $viewFile "UiServerTable"
$hasRulesStatusValues = (Test-Contains $viewFile "Enabled") -and (Test-Contains $viewFile "Paused")
$hasBadgeFlag = Test-Contains $viewFile "item.hasLastAttemptFail"
$hasBadgeChip = Test-Contains $viewFile "Ultimo fail"
$hasLastFailFallback = Test-Contains $viewFile "Fail sin detalle de error."
$hasUpdateRuleStateAction = Test-Contains $viewFile "updateRuleState(item, !item.isPaused)"
$hasCanUpdatePermission = Test-Contains $viewFile "Actions.Update"
$hasReloadRulesAfterToggle = Test-Contains $viewFile "await reloadRules()"

$hasServiceGetRules = Test-Contains $serviceFile "getRules:"
$hasServiceUpdateRuleState = Test-Contains $serviceFile "updateRuleState:"
$hasServiceRulesRoute = Test-Contains $serviceFile "/actions/rules"
$hasServiceRulesPatch = Test-Contains $serviceFile "/actions/rules/${payload.ruleInstanceId}/state"

$hasTypeRulesParams = Test-Contains $typesFile "export type ActionRulesQueryParams"
$hasTypeRulesItem = Test-Contains $typesFile "export type ActionRuleListItem"
$hasTypeRuleOperationalStatus = Test-Contains $typesFile "export type RuleOperationalStatus"
$hasTypeUpdateStateReq = Test-Contains $typesFile "export type UpdateRuleStateRequest"
$hasTypeUpdateStateRes = Test-Contains $typesFile "export type UpdateRuleStateResponse"
$hasTypeLastAttemptFail = Test-Contains $typesFile "hasLastAttemptFail"

$hasRouteActions = Test-Contains $routesFile "path: '/actions'"
$hasRoutePermission = Test-Contains $routesFile "requiresPermission: 'Actions.View'"
$hasMenuActionsPath = Test-Contains $menuFile "to: '/actions'"
$hasMenuPermission = Test-Contains $menuFile "requiresPermission: 'Actions.View'"

$hasBackendRulesRoute = Test-Contains $getRulesEndpoint 'Get("/api/v1/actions/rules")'
$hasBackendRulesPolicy = Test-Contains $getRulesEndpoint "Policies(PermissionClaims.Actions.View)"
$hasBackendUpdateRoute = Test-Contains $updateStateEndpoint 'Patch("/api/v1/actions/rules/{RuleInstanceId}/state")'
$hasBackendUpdatePolicy = Test-Contains $updateStateEndpoint "Policies(PermissionClaims.Actions.Update)"

$serviceAnyCount = Count-MatchesInFile $serviceFile '\bany\b'
$typesAnyCount = Count-MatchesInFile $typesFile '\bany\b'
$viewAnyCount = Count-MatchesInFile $viewFile '\bany\b'

Write-OutputLog "Observed: phase_summary_done=$hasSummaryDone"
Write-OutputLog "Observed: phase_summary_rules_tab=$hasSummaryRulesTab"
Write-OutputLog "Observed: phase_summary_badge=$hasSummaryBadge"
Write-OutputLog "Observed: phase_summary_toggle=$hasSummaryToggle"
Write-OutputLog "Observed: view_rules_tab_present=$hasRulesTab"
Write-OutputLog "Observed: view_active_tab_rules=$hasActiveTabRules"
Write-OutputLog "Observed: view_rules_filter_schema=$hasRulesFilterSchema"
Write-OutputLog "Observed: view_rules_error_state=$hasRulesErrorState"
Write-OutputLog "Observed: view_rules_error_copy=$hasRulesErrorCopy"
Write-OutputLog "Observed: view_rules_empty_state=$hasRulesEmptyState"
Write-OutputLog "Observed: view_rules_table=$hasRulesTable"
Write-OutputLog "Observed: view_ui_dynamic_filter=$hasUiDynamicFilter"
Write-OutputLog "Observed: view_ui_server_table=$hasUiServerTable"
Write-OutputLog "Observed: view_rules_status_values=$hasRulesStatusValues"
Write-OutputLog "Observed: view_badge_flag=$hasBadgeFlag"
Write-OutputLog "Observed: view_badge_chip=$hasBadgeChip"
Write-OutputLog "Observed: view_last_fail_fallback=$hasLastFailFallback"
Write-OutputLog "Observed: view_update_rule_state_action=$hasUpdateRuleStateAction"
Write-OutputLog "Observed: view_actions_update_permission=$hasCanUpdatePermission"
Write-OutputLog "Observed: view_reload_rules_after_toggle=$hasReloadRulesAfterToggle"
Write-OutputLog "Observed: service_get_rules_method=$hasServiceGetRules"
Write-OutputLog "Observed: service_update_rule_state_method=$hasServiceUpdateRuleState"
Write-OutputLog "Observed: service_rules_route=$hasServiceRulesRoute"
Write-OutputLog "Observed: service_rules_patch_route=$hasServiceRulesPatch"
Write-OutputLog "Observed: types_rules_query_params=$hasTypeRulesParams"
Write-OutputLog "Observed: types_rule_list_item=$hasTypeRulesItem"
Write-OutputLog "Observed: types_rule_operational_status=$hasTypeRuleOperationalStatus"
Write-OutputLog "Observed: types_update_rule_state_request=$hasTypeUpdateStateReq"
Write-OutputLog "Observed: types_update_rule_state_response=$hasTypeUpdateStateRes"
Write-OutputLog "Observed: types_last_attempt_fail_flag=$hasTypeLastAttemptFail"
Write-OutputLog "Observed: route_actions_path=$hasRouteActions"
Write-OutputLog "Observed: route_actions_permission=$hasRoutePermission"
Write-OutputLog "Observed: menu_actions_path=$hasMenuActionsPath"
Write-OutputLog "Observed: menu_actions_permission=$hasMenuPermission"
Write-OutputLog "Observed: backend_rules_route=$hasBackendRulesRoute"
Write-OutputLog "Observed: backend_rules_policy=$hasBackendRulesPolicy"
Write-OutputLog "Observed: backend_update_route=$hasBackendUpdateRoute"
Write-OutputLog "Observed: backend_update_policy=$hasBackendUpdatePolicy"
Write-OutputLog "Observed: any_count[service]=$serviceAnyCount"
Write-OutputLog "Observed: any_count[types]=$typesAnyCount"
Write-OutputLog "Observed: any_count[view]=$viewAnyCount"

if ($DryRun -eq "1") {
    Write-CommandLog "npm --prefix $FrontendDir run typecheck"
    Write-OutputLog "Observed (pending): typecheck and auto-login/sql autodiscovery skipped by DRY_RUN=1."
}
else {
    $requiredChecks = @(
        @{ Name = "phase_summary_done"; Value = $hasSummaryDone },
        @{ Name = "phase_summary_rules_tab"; Value = $hasSummaryRulesTab },
        @{ Name = "phase_summary_badge"; Value = $hasSummaryBadge },
        @{ Name = "phase_summary_toggle"; Value = $hasSummaryToggle },
        @{ Name = "view_rules_tab_present"; Value = $hasRulesTab },
        @{ Name = "view_active_tab_rules"; Value = $hasActiveTabRules },
        @{ Name = "view_rules_filter_schema"; Value = $hasRulesFilterSchema },
        @{ Name = "view_rules_error_state"; Value = $hasRulesErrorState },
        @{ Name = "view_rules_error_copy"; Value = $hasRulesErrorCopy },
        @{ Name = "view_rules_empty_state"; Value = $hasRulesEmptyState },
        @{ Name = "view_rules_table"; Value = $hasRulesTable },
        @{ Name = "view_ui_dynamic_filter"; Value = $hasUiDynamicFilter },
        @{ Name = "view_ui_server_table"; Value = $hasUiServerTable },
        @{ Name = "view_rules_status_values"; Value = $hasRulesStatusValues },
        @{ Name = "view_badge_flag"; Value = $hasBadgeFlag },
        @{ Name = "view_badge_chip"; Value = $hasBadgeChip },
        @{ Name = "view_last_fail_fallback"; Value = $hasLastFailFallback },
        @{ Name = "view_update_rule_state_action"; Value = $hasUpdateRuleStateAction },
        @{ Name = "view_actions_update_permission"; Value = $hasCanUpdatePermission },
        @{ Name = "view_reload_rules_after_toggle"; Value = $hasReloadRulesAfterToggle },
        @{ Name = "service_get_rules_method"; Value = $hasServiceGetRules },
        @{ Name = "service_update_rule_state_method"; Value = $hasServiceUpdateRuleState },
        @{ Name = "service_rules_route"; Value = $hasServiceRulesRoute },
        @{ Name = "service_rules_patch_route"; Value = $hasServiceRulesPatch },
        @{ Name = "types_rules_query_params"; Value = $hasTypeRulesParams },
        @{ Name = "types_rule_list_item"; Value = $hasTypeRulesItem },
        @{ Name = "types_rule_operational_status"; Value = $hasTypeRuleOperationalStatus },
        @{ Name = "types_update_rule_state_request"; Value = $hasTypeUpdateStateReq },
        @{ Name = "types_update_rule_state_response"; Value = $hasTypeUpdateStateRes },
        @{ Name = "types_last_attempt_fail_flag"; Value = $hasTypeLastAttemptFail },
        @{ Name = "route_actions_path"; Value = $hasRouteActions },
        @{ Name = "route_actions_permission"; Value = $hasRoutePermission },
        @{ Name = "menu_actions_path"; Value = $hasMenuActionsPath },
        @{ Name = "menu_actions_permission"; Value = $hasMenuPermission },
        @{ Name = "backend_rules_route"; Value = $hasBackendRulesRoute },
        @{ Name = "backend_rules_policy"; Value = $hasBackendRulesPolicy },
        @{ Name = "backend_update_route"; Value = $hasBackendUpdateRoute },
        @{ Name = "backend_update_policy"; Value = $hasBackendUpdatePolicy }
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
