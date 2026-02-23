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

Write-OutputLog "Expected: run valida criterios ACT-005 phase-02 (validacion semantica DSL + no-regresion)."
Write-OutputLog "Observed: inicio run (DRY_RUN=$DryRun, API_BASE_URL=$ApiBaseUrl)."

$candidateFiles = @(
    "telemetric-api/src/Telemetric.Api/Features/Actions/Templates/CreateTemplate/CreateTemplateCommandHandler.cs",
    "telemetric-api/src/Telemetric.Api/Features/Actions/Templates/UpdateTemplate/UpdateTemplateCommandHandler.cs",
    "telemetric-api/src/Telemetric.Api/Features/Actions/Assignments/CreateRuleFromDevice/CreateRuleFromDeviceCommandHandler.cs",
    "telemetric-api/src/Telemetric.Api/Features/Actions/Templates/CreateTemplate/CreateTemplateEndpoint.cs",
    "telemetric-api/src/Telemetric.Api/Features/Actions/Templates/UpdateTemplate/UpdateTemplateEndpoint.cs",
    "contexto/work/features/acciones_modulo/03_execution/ACT-005/phase-02.md"
)

foreach ($rel in $candidateFiles) {
    $full = Join-Path $RepoRoot $rel
    $exists = Test-Path $full
    Write-CommandLog "Test-Path $rel"
    Write-OutputLog "Observed: file_exists[$rel]=$exists"
}

$createHandlerFile = Join-Path $RepoRoot "telemetric-api/src/Telemetric.Api/Features/Actions/Templates/CreateTemplate/CreateTemplateCommandHandler.cs"
$updateHandlerFile = Join-Path $RepoRoot "telemetric-api/src/Telemetric.Api/Features/Actions/Templates/UpdateTemplate/UpdateTemplateCommandHandler.cs"
$createFromDeviceHandlerFile = Join-Path $RepoRoot "telemetric-api/src/Telemetric.Api/Features/Actions/Assignments/CreateRuleFromDevice/CreateRuleFromDeviceCommandHandler.cs"
$createEndpointFile = Join-Path $RepoRoot "telemetric-api/src/Telemetric.Api/Features/Actions/Templates/CreateTemplate/CreateTemplateEndpoint.cs"
$updateEndpointFile = Join-Path $RepoRoot "telemetric-api/src/Telemetric.Api/Features/Actions/Templates/UpdateTemplate/UpdateTemplateEndpoint.cs"
$createFromDeviceEndpointFile = Join-Path $RepoRoot "telemetric-api/src/Telemetric.Api/Features/Actions/Assignments/CreateRuleFromDevice/CreateRuleFromDeviceEndpoint.cs"
$phaseSummaryFile = Join-Path $RepoRoot "contexto/work/features/acciones_modulo/03_execution/ACT-005/phase-02.md"

$hasSummary = Test-Contains $phaseSummaryFile "validacion semantica DSL"
$hasCreateValidateMethod = Test-Contains $createHandlerFile "ValidateAndNormalizeDefinitionJson("
$hasUpdateValidateMethod = Test-Contains $updateHandlerFile "ValidateAndNormalizeDefinitionJson("
$hasCreateFromDeviceValidateMethod = Test-Contains $createFromDeviceHandlerFile "ValidateAndNormalizeDefinitionJson("
$hasCreateFromDeviceReusableGuard = Test-Contains $createFromDeviceHandlerFile "if (request.CreateReusableTemplate)"
$hasCreateFromDeviceReusableValidationCall = Test-Contains $createFromDeviceHandlerFile "ValidateAndNormalizeDefinitionJson(request.DefinitionJson)"
$hasTemporalRule = (Test-Contains $createHandlerFile "evaluation.durationSeconds must be less than or equal to evaluation.windowSeconds.") -and
    (Test-Contains $updateHandlerFile "evaluation.durationSeconds must be less than or equal to evaluation.windowSeconds.") -and
    (Test-Contains $createFromDeviceHandlerFile "evaluation.durationSeconds must be less than or equal to evaluation.windowSeconds.")
$hasHoldLastRule = (Test-Contains $createHandlerFile "missingDataPolicy.ttlSeconds is required when mode is HOLD_LAST_VALUE.") -and
    (Test-Contains $updateHandlerFile "missingDataPolicy.ttlSeconds is required when mode is HOLD_LAST_VALUE.") -and
    (Test-Contains $createFromDeviceHandlerFile "missingDataPolicy.ttlSeconds is required when mode is HOLD_LAST_VALUE.")
$hasInsufficientDataRule = (Test-Contains $createHandlerFile "missingDataPolicy.ttlSeconds must be null or omitted when mode is INSUFFICIENT_DATA.") -and
    (Test-Contains $updateHandlerFile "missingDataPolicy.ttlSeconds must be null or omitted when mode is INSUFFICIENT_DATA.") -and
    (Test-Contains $createFromDeviceHandlerFile "missingDataPolicy.ttlSeconds must be null or omitted when mode is INSUFFICIENT_DATA.")
$hasRecipientsIndexed = (Test-Contains $createHandlerFile "action.recipients[") -and
    (Test-Contains $updateHandlerFile "action.recipients[") -and
    (Test-Contains $createFromDeviceHandlerFile "action.recipients[")
$hasCreateEndpointError400 = Test-Contains $createEndpointFile "Send.ErrorsAsync(400"
$hasUpdateEndpointError400 = Test-Contains $updateEndpointFile "Send.ErrorsAsync(400"
$hasCreateFromDeviceEndpointError400 = Test-Contains $createFromDeviceEndpointFile "Send.ErrorsAsync(400"

Write-OutputLog "Observed: phase_summary_semantic_validation=$hasSummary"
Write-OutputLog "Observed: create_handler_validate_method=$hasCreateValidateMethod"
Write-OutputLog "Observed: update_handler_validate_method=$hasUpdateValidateMethod"
Write-OutputLog "Observed: create_from_device_validate_method=$hasCreateFromDeviceValidateMethod"
Write-OutputLog "Observed: create_from_device_reusable_guard=$hasCreateFromDeviceReusableGuard"
Write-OutputLog "Observed: create_from_device_reusable_validation_call=$hasCreateFromDeviceReusableValidationCall"
Write-OutputLog "Observed: temporal_rule_t_le_w=$hasTemporalRule"
Write-OutputLog "Observed: hold_last_value_requires_ttl=$hasHoldLastRule"
Write-OutputLog "Observed: insufficient_data_rejects_ttl=$hasInsufficientDataRule"
Write-OutputLog "Observed: recipients_indexed_error_path=$hasRecipientsIndexed"
Write-OutputLog "Observed: create_endpoint_errors_400=$hasCreateEndpointError400"
Write-OutputLog "Observed: update_endpoint_errors_400=$hasUpdateEndpointError400"
Write-OutputLog "Observed: create_from_device_endpoint_errors_400=$hasCreateFromDeviceEndpointError400"

if ($DryRun -eq "1") {
    Write-CommandLog "npm --prefix $FrontendDir run typecheck"
    Write-CommandLog "Read baseline from baseline.json"
    Write-OutputLog "Observed (pendiente): typecheck no ejecutado por DRY_RUN=1."
    Write-OutputLog "Observed (pendiente): gate no-regresion no evaluado por DRY_RUN=1."
    Write-OutputLog "Observed (pendiente): auto-login y autodiscovery SQL no ejecutados por DRY_RUN=1."
}
else {
    if (!(Test-Path $BaselineFile)) {
        Write-OutputLog "Observed: baseline no encontrado en $BaselineFile"
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
