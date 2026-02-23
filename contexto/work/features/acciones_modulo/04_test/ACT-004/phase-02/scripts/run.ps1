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
$TestDeviceId = if ($env:TEST_DEVICE_ID) { $env:TEST_DEVICE_ID } else { "" }
$TestRuleTemplateVersionId = if ($env:TEST_RULE_TEMPLATE_VERSION_ID) { $env:TEST_RULE_TEMPLATE_VERSION_ID } else { "" }

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
        try {
            Write-CommandLog "sqlcmd $SqlcmdArgs (autodiscovery TEST_RULE_TEMPLATE_VERSION_ID)"
            $raw = Invoke-Expression ("sqlcmd {0} -h -1 -W -Q `"SET NOCOUNT ON; SELECT TOP 1 RuleTemplateVersionId FROM dbo.RuleTemplateVersion WHERE IsDeleted=0 ORDER BY RuleTemplateVersionId DESC;`"" -f $SqlcmdArgs) | Out-String
            $id = ($raw -split "`r?`n" | ForEach-Object { $_.Trim() } | Where-Object { $_ -match '^\d+$' } | Select-Object -First 1)
            if ($id) {
                $script:TestRuleTemplateVersionId = $id
                Write-OutputLog "Observed: auto_rule_template_version_id=$id"
            }
        }
        catch {
            Write-OutputLog "Observed: auto_rule_template_version_id=FAIL ($($_.Exception.Message))"
        }
    }

    if ([string]::IsNullOrWhiteSpace($TestDeviceId)) {
        try {
            Write-CommandLog "sqlcmd $SqlcmdArgs (autodiscovery TEST_DEVICE_ID)"
            $raw = Invoke-Expression ("sqlcmd {0} -h -1 -W -Q `"SET NOCOUNT ON; SELECT TOP 1 DeviceId FROM dbo.Device WHERE IsDeleted=0 ORDER BY DeviceId DESC;`"" -f $SqlcmdArgs) | Out-String
            $id = ($raw -split "`r?`n" | ForEach-Object { $_.Trim() } | Where-Object { $_ -match '^\d+$' } | Select-Object -First 1)
            if ($id) {
                $script:TestDeviceId = $id
                Write-OutputLog "Observed: auto_test_device_id=$id"
            }
        }
        catch {
            Write-OutputLog "Observed: auto_test_device_id=FAIL ($($_.Exception.Message))"
        }
    }
}

Write-OutputLog "Expected: run valida criterios ACT-004 phase-02 (endpoint, policy, overrides whitelist, local/reusable, no-regresion)."
Write-OutputLog "Observed: inicio run (DRY_RUN=$DryRun, API_BASE_URL=$ApiBaseUrl)."

$candidateFiles = @(
    "telemetric-api/src/Telemetric.Api/Features/Actions/Assignments/CreateRuleFromDevice/CreateRuleFromDeviceEndpoint.cs",
    "telemetric-api/src/Telemetric.Api/Features/Actions/Assignments/CreateRuleFromDevice/CreateRuleFromDeviceCommandHandler.cs",
    "telemetric-api/src/Telemetric.Api/Domain/Constants/PermissionClaims.cs",
    "contexto/openapi/actions.yaml",
    "contexto/work/features/acciones_modulo/03_execution/ACT-004/phase-02.md"
)

foreach ($rel in $candidateFiles) {
    $full = Join-Path $RepoRoot $rel
    $exists = Test-Path $full
    Write-CommandLog "Test-Path $rel"
    Write-OutputLog "Observed: file_exists[$rel]=$exists"
}

$endpointFile = Join-Path $RepoRoot "telemetric-api/src/Telemetric.Api/Features/Actions/Assignments/CreateRuleFromDevice/CreateRuleFromDeviceEndpoint.cs"
$handlerFile = Join-Path $RepoRoot "telemetric-api/src/Telemetric.Api/Features/Actions/Assignments/CreateRuleFromDevice/CreateRuleFromDeviceCommandHandler.cs"
$claimsFile = Join-Path $RepoRoot "telemetric-api/src/Telemetric.Api/Domain/Constants/PermissionClaims.cs"
$openApiFile = Join-Path $RepoRoot "contexto/openapi/actions.yaml"
$sqlFile = Join-Path $RepoRoot "telemetric-api/scripts/012_create_actions_schema.sql"
$phaseSummaryFile = Join-Path $RepoRoot "contexto/work/features/acciones_modulo/03_execution/ACT-004/phase-02.md"

$hasEndpoint = Test-Contains $endpointFile 'Post("/api/v1/actions/assignments/create-from-device")'
$hasPolicyInEndpoint = Test-Contains $endpointFile "PermissionClaims.Actions.Assign"
$hasPolicyConstant = Test-Contains $claimsFile 'public const string Assign = "Actions.Assign";'
$hasOpenApiPath = Test-Contains $openApiFile "/api/v1/actions/assignments/create-from-device"
$hasReuseFirstTrace = Test-Contains $phaseSummaryFile "Reuse-first"

$hasThresholdRule = Test-Contains $handlerFile "Override 'threshold' must be a numeric value."
$hasRecipientsRule = Test-Contains $handlerFile "Override 'email.recipients' must be an array."
$hasNotAllowedRule = Test-Contains $handlerFile "is not allowed in v1"
$hasLocalPath = Test-Contains $handlerFile "if (request.CreateReusableTemplate)"
$hasReusableResponse = Test-Contains $handlerFile "CreatedReusableTemplate"
$hasDuplicateGuard = Test-Contains $handlerFile "RuleInstance already exists for the provided device and template version."
$hasUniqueIndex = Test-Contains $sqlFile "UQ_RuleInstance_Device_TemplateVersion"

Write-OutputLog "Observed: endpoint_exists=$hasEndpoint"
Write-OutputLog "Observed: endpoint_policy_assign=$hasPolicyInEndpoint"
Write-OutputLog "Observed: permission_claim_assign_constant=$hasPolicyConstant"
Write-OutputLog "Observed: openapi_contains_create_from_device_path=$hasOpenApiPath"
Write-OutputLog "Observed: reuse_first_trace_in_phase_summary=$hasReuseFirstTrace"
Write-OutputLog "Observed: overrides_threshold_rule=$hasThresholdRule"
Write-OutputLog "Observed: overrides_email_recipients_rule=$hasRecipientsRule"
Write-OutputLog "Observed: overrides_reject_non_whitelisted_rule=$hasNotAllowedRule"
Write-OutputLog "Observed: local_or_reusable_paths_present=$hasLocalPath"
Write-OutputLog "Observed: response_marks_created_reusable=$hasReusableResponse"
Write-OutputLog "Observed: duplicate_guard_in_handler=$hasDuplicateGuard"
Write-OutputLog "Observed: sql_unique_index_guard=$hasUniqueIndex"

if ($DryRun -eq "1") {
    Write-CommandLog "npm --prefix $FrontendDir run typecheck"
    Write-CommandLog "Read baseline from baseline.json"
    Write-OutputLog "Observed (pendiente): typecheck no ejecutado por DRY_RUN=1."
    Write-OutputLog "Observed (pendiente): gate no-regresion no evaluado por DRY_RUN=1."
    Write-OutputLog "Observed (pendiente): pruebas API integradas no ejecutadas por DRY_RUN=1."
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
                ($_ -match '^(src[\/]).*error TS[0-9]+:') -and
                ($_ -notmatch '^(src[\/]_demo[\/])')
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

    if ([string]::IsNullOrWhiteSpace($ApiAuthToken) -or [string]::IsNullOrWhiteSpace($TestRuleTemplateVersionId) -or [string]::IsNullOrWhiteSpace($TestDeviceId)) {
        Write-OutputLog "Observed: pruebas API integradas omitidas (faltan API_AUTH_TOKEN / TEST_RULE_TEMPLATE_VERSION_ID / TEST_DEVICE_ID)."
    }
    else {
        $uri = "$ApiBaseUrl/api/v1/actions/assignments/create-from-device"
        $headers = @{ Authorization = "Bearer $ApiAuthToken"; "Content-Type" = "application/json" }

        $allowedOverrides = '{"threshold": 15, "email": {"recipients": ["qa@telemetric.local"]}}'
        $localPayload = @{
            deviceId = [int]$TestDeviceId
            ruleTemplateVersionId = [int]$TestRuleTemplateVersionId
            createReusableTemplate = $false
            reusableTemplateName = $null
            reusableTemplateDescription = $null
            definitionJson = $null
            overridesJson = $allowedOverrides
            isPaused = $false
            isLatchMode = $false
            cooldownSeconds = 0
        } | ConvertTo-Json -Depth 6

        Write-CommandLog "Invoke-RestMethod POST $uri (local + allowed overrides)"
        try {
            $localResponse = Invoke-RestMethod -Method Post -Uri $uri -Headers $headers -Body $localPayload
            $localJson = $localResponse | ConvertTo-Json -Depth 10
            Add-Content -Path $OutputsLog -Value ("{0} | Observed: local_allowed_response={1}" -f (Get-Date -Format s), $localJson)

            $isLocal = ($localResponse.createdReusableTemplate -eq $false)
            $hasNullTemplate = ($null -eq $localResponse.ruleTemplateId)
            Write-OutputLog "Observed: local_rule_not_reusable=$($isLocal -and $hasNullTemplate)"
        }
        catch {
            Write-OutputLog "Observed: local_allowed_request=FAIL ($($_.Exception.Message))"
            throw
        }

        $invalidOverrides = '{"foo": "bar"}'
        $invalidPayload = @{
            deviceId = [int]$TestDeviceId
            ruleTemplateVersionId = [int]$TestRuleTemplateVersionId
            createReusableTemplate = $false
            overridesJson = $invalidOverrides
            isPaused = $false
            isLatchMode = $false
            cooldownSeconds = 0
        } | ConvertTo-Json -Depth 6

        Write-CommandLog "Invoke-RestMethod POST $uri (invalid overrides expected fail)"
        try {
            $null = Invoke-RestMethod -Method Post -Uri $uri -Headers $headers -Body $invalidPayload
            Write-OutputLog "Observed: invalid_override_rejected=FALSE (unexpected success)"
            throw "Invalid override request unexpectedly succeeded."
        }
        catch {
            Write-OutputLog "Observed: invalid_override_rejected=TRUE"
            Write-OutputLog "Observed: invalid_override_error=$($_.Exception.Message)"
        }

        $reusableName = "qa-phase02-reusable-$(Get-Date -Format 'yyyyMMddHHmmss')"
        $definitionJson = '{"trigger":{"metricCode":"temperature"},"condition":{"operator":">","value":80}}'
        $reusablePayload = @{
            deviceId = [int]$TestDeviceId
            ruleTemplateVersionId = $null
            createReusableTemplate = $true
            reusableTemplateName = $reusableName
            reusableTemplateDescription = "QA ACT-004 phase-02 reusable"
            definitionJson = $definitionJson
            overridesJson = $allowedOverrides
            isPaused = $false
            isLatchMode = $false
            cooldownSeconds = 5
        } | ConvertTo-Json -Depth 6

        Write-CommandLog "Invoke-RestMethod POST $uri (reusable + allowed overrides)"
        try {
            $reusableResponse = Invoke-RestMethod -Method Post -Uri $uri -Headers $headers -Body $reusablePayload
            $reusableJson = $reusableResponse | ConvertTo-Json -Depth 10
            Add-Content -Path $OutputsLog -Value ("{0} | Observed: reusable_response={1}" -f (Get-Date -Format s), $reusableJson)

            $isReusable = ($reusableResponse.createdReusableTemplate -eq $true)
            $hasVersion = ([int]$reusableResponse.ruleTemplateVersionId -gt 0)
            Write-OutputLog "Observed: reusable_rule_available_for_future_assignments=$($isReusable -and $hasVersion)"
        }
        catch {
            Write-OutputLog "Observed: reusable_request=FAIL ($($_.Exception.Message))"
            throw
        }
    }
}

Write-OutputLog "Observed: run finalizado."
