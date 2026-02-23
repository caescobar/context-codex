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
$TestRuleTemplateId = if ($env:TEST_RULE_TEMPLATE_ID) { $env:TEST_RULE_TEMPLATE_ID } else { "" }
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

    if ([string]::IsNullOrWhiteSpace($TestRuleTemplateId)) {
        try {
            Write-CommandLog "sqlcmd $SqlcmdArgs (autodiscovery TEST_RULE_TEMPLATE_ID)"
            $raw = Invoke-Expression ("sqlcmd {0} -h -1 -W -Q `"SET NOCOUNT ON; SELECT TOP 1 RuleTemplateId FROM dbo.RuleTemplate WHERE IsDeleted=0 ORDER BY RuleTemplateId DESC;`"" -f $SqlcmdArgs) | Out-String
            $id = ($raw -split "`r?`n" | ForEach-Object { $_.Trim() } | Where-Object { $_ -match '^\d+$' } | Select-Object -First 1)
            if ($id) {
                $script:TestRuleTemplateId = $id
                Write-OutputLog "Observed: auto_rule_template_id=$id"
            }
        }
        catch {
            Write-OutputLog "Observed: auto_rule_template_id=FAIL ($($_.Exception.Message))"
        }
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
}

Write-OutputLog "Expected: run valida criterios ACT-005 phase-01 (contrato DSL + no-regresion)."
Write-OutputLog "Observed: inicio run (DRY_RUN=$DryRun, API_BASE_URL=$ApiBaseUrl)."

$candidateFiles = @(
    "contexto/openapi/actions.yaml",
    "telemetric-front/src/features/actions/types.ts",
    "telemetric-api/src/Telemetric.Api/Features/Actions/Templates/CreateTemplate/CreateTemplateEndpoint.cs",
    "telemetric-api/src/Telemetric.Api/Features/Actions/Templates/UpdateTemplate/UpdateTemplateEndpoint.cs",
    "contexto/work/features/acciones_modulo/03_execution/ACT-005/phase-01.md"
)

foreach ($rel in $candidateFiles) {
    $full = Join-Path $RepoRoot $rel
    $exists = Test-Path $full
    Write-CommandLog "Test-Path $rel"
    Write-OutputLog "Observed: file_exists[$rel]=$exists"
}

$openApiFile = Join-Path $RepoRoot "contexto/openapi/actions.yaml"
$typesFile = Join-Path $RepoRoot "telemetric-front/src/features/actions/types.ts"
$createEndpointFile = Join-Path $RepoRoot "telemetric-api/src/Telemetric.Api/Features/Actions/Templates/CreateTemplate/CreateTemplateEndpoint.cs"
$updateEndpointFile = Join-Path $RepoRoot "telemetric-api/src/Telemetric.Api/Features/Actions/Templates/UpdateTemplate/UpdateTemplateEndpoint.cs"
$phaseSummaryFile = Join-Path $RepoRoot "contexto/work/features/acciones_modulo/03_execution/ACT-005/phase-01.md"

$hasPlanTrace = Test-Contains $phaseSummaryFile "DefinitionJsonV1"
$hasOpenApiDefinition = Test-Contains $openApiFile "DefinitionJsonV1"
$hasDiscriminator = Test-Contains $openApiFile "discriminator:"
$hasRuleTypeProperty = Test-Contains $openApiFile "propertyName: ruleType"
$hasRuleType1 = Test-Contains $openApiFile "INSTANT_THRESHOLD"
$hasRuleType2 = Test-Contains $openApiFile "CONTINUOUS_DURATION"
$hasRuleType3 = Test-Contains $openApiFile "ACCUMULATED_DURATION_WINDOW"
$hasRuleType4 = Test-Contains $openApiFile "AGGREGATION_WINDOW"
$hasRuleType5 = Test-Contains $openApiFile "COUNT_OCCURRENCES_WINDOW"
$hasCreateObjectValidation = Test-Contains $createEndpointFile "JsonValueKind.Object"
$hasUpdateObjectValidation = Test-Contains $updateEndpointFile "JsonValueKind.Object"
$hasCreateRawText = Test-Contains $createEndpointFile "GetRawText()"
$hasUpdateRawText = Test-Contains $updateEndpointFile "GetRawText()"
$hasUpdateRouteToken = Test-Contains $updateEndpointFile 'Put("/api/v1/actions/templates/{ruleTemplateId}")'
$hasOpenApiUpdateRouteToken = Test-Contains $openApiFile "/api/v1/actions/templates/{ruleTemplateId}"
$hasRuleTypeFront = Test-Contains $typesFile "export type RuleType"
$hasDurationSecondsFront = Test-Contains $typesFile "durationSeconds"

Write-OutputLog "Observed: phase_summary_contains_definitionjsonv1=$hasPlanTrace"
Write-OutputLog "Observed: openapi_has_definitionjsonv1=$hasOpenApiDefinition"
Write-OutputLog "Observed: openapi_has_discriminator_ruletype=$($hasDiscriminator -and $hasRuleTypeProperty)"
Write-OutputLog "Observed: openapi_has_all_rule_types=$($hasRuleType1 -and $hasRuleType2 -and $hasRuleType3 -and $hasRuleType4 -and $hasRuleType5)"
Write-OutputLog "Observed: create_endpoint_object_validation=$hasCreateObjectValidation"
Write-OutputLog "Observed: update_endpoint_object_validation=$hasUpdateObjectValidation"
Write-OutputLog "Observed: create_endpoint_getrawtext=$hasCreateRawText"
Write-OutputLog "Observed: update_endpoint_getrawtext=$hasUpdateRawText"
Write-OutputLog "Observed: update_route_ruleTemplateId_aligned=$($hasUpdateRouteToken -and $hasOpenApiUpdateRouteToken)"
Write-OutputLog "Observed: frontend_rule_type_declared=$hasRuleTypeFront"
Write-OutputLog "Observed: frontend_duration_seconds_declared=$hasDurationSecondsFront"

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
