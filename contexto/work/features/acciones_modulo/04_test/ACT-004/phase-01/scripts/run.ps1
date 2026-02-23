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
$TestDeviceIdsRaw = if ($env:TEST_DEVICE_IDS) { $env:TEST_DEVICE_IDS } else { "" }

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

    if ([string]::IsNullOrWhiteSpace($TestDeviceIdsRaw)) {
        try {
            Write-CommandLog "sqlcmd $SqlcmdArgs (autodiscovery TEST_DEVICE_IDS)"
            $raw = Invoke-Expression ("sqlcmd {0} -h -1 -W -Q `"SET NOCOUNT ON; SELECT TOP 3 DeviceId FROM dbo.Device WHERE IsDeleted=0 ORDER BY DeviceId DESC;`"" -f $SqlcmdArgs) | Out-String
            $ids = @($raw -split "`r?`n" | ForEach-Object { $_.Trim() } | Where-Object { $_ -match '^\d+$' } | Select-Object -First 3)
            if ($ids.Count -gt 0) {
                $script:TestDeviceIdsRaw = ($ids -join ",")
                Write-OutputLog "Observed: auto_test_device_ids=$($script:TestDeviceIdsRaw)"
            }
        }
        catch {
            Write-OutputLog "Observed: auto_test_device_ids=FAIL ($($_.Exception.Message))"
        }
    }
}

Write-OutputLog "Expected: run valida criterios ACT-004 phase-01 (endpoint, policy, duplicados, scope, no-regresion)."
Write-OutputLog "Observed: inicio run (DRY_RUN=$DryRun, API_BASE_URL=$ApiBaseUrl)."

$candidateFiles = @(
    "telemetric-api/src/Telemetric.Api/Features/Actions/Assignments/AssignTemplateToDevices/AssignTemplateToDevicesEndpoint.cs",
    "telemetric-api/src/Telemetric.Api/Features/Actions/Assignments/AssignTemplateToDevices/AssignTemplateToDevicesCommandHandler.cs",
    "telemetric-api/src/Telemetric.Api/Domain/Constants/PermissionClaims.cs",
    "contexto/openapi/actions.yaml",
    "contexto/work/features/acciones_modulo/03_execution/ACT-004/phase-01.md"
)

foreach ($rel in $candidateFiles) {
    $full = Join-Path $RepoRoot $rel
    $exists = Test-Path $full
    Write-CommandLog "Test-Path $rel"
    Write-OutputLog "Observed: file_exists[$rel]=$exists"
}

$endpointFile = Join-Path $RepoRoot "telemetric-api/src/Telemetric.Api/Features/Actions/Assignments/AssignTemplateToDevices/AssignTemplateToDevicesEndpoint.cs"
$handlerFile = Join-Path $RepoRoot "telemetric-api/src/Telemetric.Api/Features/Actions/Assignments/AssignTemplateToDevices/AssignTemplateToDevicesCommandHandler.cs"
$claimsFile = Join-Path $RepoRoot "telemetric-api/src/Telemetric.Api/Domain/Constants/PermissionClaims.cs"
$openApiFile = Join-Path $RepoRoot "contexto/openapi/actions.yaml"
$sqlFile = Join-Path $RepoRoot "telemetric-api/scripts/012_create_actions_schema.sql"
$phaseSummaryFile = Join-Path $RepoRoot "contexto/work/features/acciones_modulo/03_execution/ACT-004/phase-01.md"

$hasEndpoint = Test-Contains $endpointFile 'Post("/api/v1/actions/assignments/template-version")'
$hasPolicyInEndpoint = Test-Contains $endpointFile "PermissionClaims.Actions.Assign"
$hasPolicyConstant = Test-Contains $claimsFile 'public const string Assign = "Actions.Assign";'
$hasOpenApiPath = Test-Contains $openApiFile "/api/v1/actions/assignments/template-version"
$hasReuseFirstTrace = Test-Contains $phaseSummaryFile "Reuse-first"

$hasStatusCreated = Test-Contains $handlerFile 'public const string Created = "Created";'
$hasStatusDuplicate = Test-Contains $handlerFile 'public const string RejectedDuplicate = "RejectedDuplicate";'
$hasStatusOutOfScope = Test-Contains $handlerFile 'public const string RejectedNotFoundOrOutOfScope = "RejectedNotFoundOrOutOfScope";'
$hasDistinctInput = Test-Contains $handlerFile ".Distinct()"
$hasScopeGuard = Test-Contains $handlerFile "_currentUserService.ClientId"
$hasUniqueIndex = Test-Contains $sqlFile "UQ_RuleInstance_Device_TemplateVersion"

Write-OutputLog "Observed: endpoint_exists=$hasEndpoint"
Write-OutputLog "Observed: endpoint_policy_assign=$hasPolicyInEndpoint"
Write-OutputLog "Observed: permission_claim_assign_constant=$hasPolicyConstant"
Write-OutputLog "Observed: openapi_contains_assignment_path=$hasOpenApiPath"
Write-OutputLog "Observed: reuse_first_trace_in_phase_summary=$hasReuseFirstTrace"
Write-OutputLog "Observed: statuses_created_duplicate_outofscope=$($hasStatusCreated -and $hasStatusDuplicate -and $hasStatusOutOfScope)"
Write-OutputLog "Observed: handler_deduplicates_input=$hasDistinctInput"
Write-OutputLog "Observed: handler_scope_guard=$hasScopeGuard"
Write-OutputLog "Observed: sql_unique_index_guard=$hasUniqueIndex"

if ($DryRun -eq "1") {
    Write-CommandLog "npm --prefix $FrontendDir run typecheck"
    Write-CommandLog "Read baseline from baseline.json"
    Write-OutputLog "Observed (pendiente): typecheck no ejecutado por DRY_RUN=1."
    Write-OutputLog "Observed (pendiente): gate no-regresion no evaluado por DRY_RUN=1."
    Write-OutputLog "Observed (pendiente): prueba API integrada no ejecutada por DRY_RUN=1."
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

    if ([string]::IsNullOrWhiteSpace($ApiAuthToken) -or [string]::IsNullOrWhiteSpace($TestRuleTemplateVersionId) -or [string]::IsNullOrWhiteSpace($TestDeviceIdsRaw)) {
        Write-OutputLog "Observed: prueba API integrada omitida (faltan API_AUTH_TOKEN / TEST_RULE_TEMPLATE_VERSION_ID / TEST_DEVICE_IDS)."
    }
    else {
        $deviceIds = @()
        foreach ($raw in $TestDeviceIdsRaw.Split(",")) {
            $trimmed = $raw.Trim()
            if ($trimmed -match '^\d+$') {
                $deviceIds += [int]$trimmed
            }
        }

        if ($deviceIds.Count -eq 0) {
            Write-OutputLog "Observed: prueba API integrada omitida (TEST_DEVICE_IDS sin enteros validos)."
        }
        else {
            $uri = "$ApiBaseUrl/api/v1/actions/assignments/template-version"
            Write-CommandLog "Invoke-RestMethod POST $uri (payload tipado JSON)"

            $headers = @{
                Authorization = "Bearer $ApiAuthToken"
                "Content-Type" = "application/json"
            }
            $payload = @{
                ruleTemplateVersionId = [int]$TestRuleTemplateVersionId
                deviceIds = $deviceIds
            }
            $body = $payload | ConvertTo-Json -Depth 5

            try {
                $response = Invoke-RestMethod -Method Post -Uri $uri -Headers $headers -Body $body
                $responseJson = $response | ConvertTo-Json -Depth 10
                Add-Content -Path $OutputsLog -Value ("{0} | Observed: api_response={1}" -f (Get-Date -Format s), $responseJson)
            }
            catch {
                Write-OutputLog "Observed: prueba API integrada fallo -> $($_.Exception.Message)"
                throw
            }
        }
    }
}

Write-OutputLog "Observed: run finalizado."
