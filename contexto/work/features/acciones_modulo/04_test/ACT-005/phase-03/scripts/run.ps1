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

$CommandsLog = Join-Path $EvidenceDir "commands.log"
$OutputsLog = Join-Path $EvidenceDir "outputs.log"
$BaselineFile = Join-Path $PackDir "baseline.json"

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
                Write-OutputLog "Observed: auto_login_token=FAIL (token vacio)"
            }
        }
        catch {
            Write-OutputLog "Observed: auto_login_token=FAIL ($($_.Exception.Message))"
        }
    }

    $sqlcmd = Get-Command sqlcmd -ErrorAction SilentlyContinue
    if ($null -eq $sqlcmd) {
        Write-OutputLog "Observed: sqlcmd no disponible para autodiscovery de IDs."
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

Write-OutputLog "Expected: run valida criterios ACT-005 phase-03 (builder UI + rutas/permisos + no-regresion)."
Write-OutputLog "Observed: inicio run (DRY_RUN=$DryRun, API_BASE_URL=$ApiBaseUrl)."

$candidateFiles = @(
    "telemetric-front/src/features/actions/views/ActionsTemplatesView.vue",
    "telemetric-front/src/features/actions/types.ts",
    "telemetric-front/src/features/actions/actions.service.ts",
    "telemetric-front/src/features/actions/actions.routes.ts",
    "telemetric-front/src/layouts/menuItems.ts",
    "contexto/work/features/acciones_modulo/03_execution/ACT-005/phase-03.md"
)

foreach ($rel in $candidateFiles) {
    $exists = Test-Path (Join-Path $RepoRoot $rel)
    Write-CommandLog "Test-Path $rel"
    Write-OutputLog "Observed: file_exists[$rel]=$exists"
}

$viewFile = Join-Path $RepoRoot "telemetric-front/src/features/actions/views/ActionsTemplatesView.vue"
$typesFile = Join-Path $RepoRoot "telemetric-front/src/features/actions/types.ts"
$routeFile = Join-Path $RepoRoot "telemetric-front/src/features/actions/actions.routes.ts"
$menuFile = Join-Path $RepoRoot "telemetric-front/src/layouts/menuItems.ts"
$summaryFile = Join-Path $RepoRoot "contexto/work/features/acciones_modulo/03_execution/ACT-005/phase-03.md"

$hasSummary = Test-Contains $summaryFile "builder guiado"
$hasValidateAndBuild = Test-Contains $viewFile "const validateAndBuild"
$hasNoTextarea = -not (Test-Contains $viewFile "<v-textarea")
$hasRuleType1 = Test-Contains $viewFile "INSTANT_THRESHOLD"
$hasRuleType2 = Test-Contains $viewFile "CONTINUOUS_DURATION"
$hasRuleType3 = Test-Contains $viewFile "ACCUMULATED_DURATION_WINDOW"
$hasRuleType4 = Test-Contains $viewFile "AGGREGATION_WINDOW"
$hasRuleType5 = Test-Contains $viewFile "COUNT_OCCURRENCES_WINDOW"
$hasDurationRule = Test-Contains $viewFile "durationSeconds no puede ser mayor que windowSeconds."
$hasHoldLastRule = Test-Contains $viewFile "ttlSeconds invalido para HOLD_LAST_VALUE."
$hasRecipientsRequired = Test-Contains $viewFile "Debe ingresar al menos un destinatario."
$hasRecipientsFormat = Test-Contains $viewFile "Email invalido:"
$hasFilter = Test-Contains $viewFile "UiDynamicFilter"
$hasTable = Test-Contains $viewFile "UiServerTable"
$hasRouteActions = Test-Contains $routeFile "path: '/actions'"
$hasRoutePermission = Test-Contains $routeFile "requiresPermission: 'Actions.View'"
$hasMenuTitle = Test-Contains $menuFile "title: 'Acciones'"
$hasMenuPath = Test-Contains $menuFile "to: '/actions'"
$hasMenuPermission = Test-Contains $menuFile "requiresPermission: 'Actions.View'"
$typesHasRuleDefinition = Test-Contains $typesFile "export type RuleDefinitionV1"
$typesNoAny = -not (Test-Contains $typesFile "any")
$typesNoUnknown = -not (Test-Contains $typesFile "unknown")

Write-OutputLog "Observed: phase_summary_builder=$hasSummary"
Write-OutputLog "Observed: view_validate_and_build=$hasValidateAndBuild"
Write-OutputLog "Observed: view_without_v_textarea=$hasNoTextarea"
Write-OutputLog "Observed: rule_type_1_instant_threshold=$hasRuleType1"
Write-OutputLog "Observed: rule_type_2_continuous_duration=$hasRuleType2"
Write-OutputLog "Observed: rule_type_3_accumulated_duration_window=$hasRuleType3"
Write-OutputLog "Observed: rule_type_4_aggregation_window=$hasRuleType4"
Write-OutputLog "Observed: rule_type_5_count_occurrences_window=$hasRuleType5"
Write-OutputLog "Observed: duration_rule_t_le_w=$hasDurationRule"
Write-OutputLog "Observed: hold_last_value_ttl_validation=$hasHoldLastRule"
Write-OutputLog "Observed: recipients_required_validation=$hasRecipientsRequired"
Write-OutputLog "Observed: recipients_format_validation=$hasRecipientsFormat"
Write-OutputLog "Observed: ux_filter_present=$hasFilter"
Write-OutputLog "Observed: ux_table_present=$hasTable"
Write-OutputLog "Observed: route_actions_exists=$hasRouteActions"
Write-OutputLog "Observed: route_actions_permission=$hasRoutePermission"
Write-OutputLog "Observed: menu_actions_title=$hasMenuTitle"
Write-OutputLog "Observed: menu_actions_path=$hasMenuPath"
Write-OutputLog "Observed: menu_actions_permission=$hasMenuPermission"
Write-OutputLog "Observed: types_rule_definition_v1=$typesHasRuleDefinition"
Write-OutputLog "Observed: types_no_any=$typesNoAny"
Write-OutputLog "Observed: types_no_unknown=$typesNoUnknown"

if ($DryRun -eq "1") {
    Write-CommandLog "npm --prefix $FrontendDir run typecheck"
    Write-CommandLog "Read baseline from baseline.json"
    Write-OutputLog "Observed (pendiente): typecheck no ejecutado por DRY_RUN=1."
    Write-OutputLog "Observed (pendiente): gate no-regresion no evaluado por DRY_RUN=1."
    Write-OutputLog "Observed (pendiente): auto-login y autodiscovery SQL no ejecutados por DRY_RUN=1."
}
else {
    if (!(Test-Path $BaselineFile)) {
        throw "Baseline file missing: $BaselineFile"
    }
    $baseline = Get-Content -Path $BaselineFile -Raw | ConvertFrom-Json
    $baselineErrors = [int]$baseline.ts_errors
    Write-OutputLog "Observed: baseline_scope=$($baseline.scope), baseline_ts_errors=$baselineErrors"

    Push-Location $RepoRoot
    try {
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
        Write-OutputLog "Expected: no-regresion no-demo => observed <= baseline ($baselineErrors)"
        Write-OutputLog "Observed: no_demo_ts_errors=$observedErrors"
        if ($observedErrors -gt $baselineErrors) {
            Write-OutputLog "Observed: gate_no_regresion=FAIL (observed=$observedErrors > baseline=$baselineErrors)"
            throw "No-regression gate failed: observed=$observedErrors baseline=$baselineErrors"
        }
        Write-OutputLog "Observed: gate_no_regresion=PASS (observed=$observedErrors <= baseline=$baselineErrors)"
    }
    finally {
        Pop-Location
    }

    Try-AutoResolveIntegrationInputs
}

Write-OutputLog "Observed: run finalizado."
