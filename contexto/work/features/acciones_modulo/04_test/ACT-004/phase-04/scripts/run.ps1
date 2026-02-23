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

Write-OutputLog "Expected: run valida criterios ACT-004 phase-04 (ruta customer, flujo local/reusable, permisos, no-regresion)."
Write-OutputLog "Observed: inicio run (DRY_RUN=$DryRun)."

$candidateFiles = @(
    "telemetric-front/src/router/MainRoutes.ts",
    "telemetric-front/src/features/customer/devices/views/DeviceCustomerEditView.vue",
    "telemetric-front/src/features/actions/actions.service.ts",
    "telemetric-front/src/features/actions/types.ts",
    "contexto/work/features/acciones_modulo/03_execution/ACT-004/phase-04.md"
)

foreach ($rel in $candidateFiles) {
    $full = Join-Path $RepoRoot $rel
    $exists = Test-Path $full
    Write-CommandLog "Test-Path $rel"
    Write-OutputLog "Observed: file_exists[$rel]=$exists"
}

$routesFile = Join-Path $RepoRoot "telemetric-front/src/router/MainRoutes.ts"
$viewFile = Join-Path $RepoRoot "telemetric-front/src/features/customer/devices/views/DeviceCustomerEditView.vue"
$serviceFile = Join-Path $RepoRoot "telemetric-front/src/features/actions/actions.service.ts"
$typesFile = Join-Path $RepoRoot "telemetric-front/src/features/actions/types.ts"
$phaseSummaryFile = Join-Path $RepoRoot "contexto/work/features/acciones_modulo/03_execution/ACT-004/phase-04.md"

$hasRoute = Test-Contains $routesFile "path: '/my-devices/:id/edit'"
$hasRouteView = Test-Contains $routesFile "DeviceCustomerEditView.vue"
$hasRuleMode = Test-Contains $viewFile "ruleMode = ref<'local' | 'reusable'>('local')"
$hasCreateRuleCall = Test-Contains $viewFile "actionsService.createRuleFromDevice"
$hasPermissionGate = Test-Contains $viewFile "permissions?.includes('Actions.Assign')"
$hasPermissionMessage = Test-Contains $viewFile "No tienes permiso"
$hasInvalidOverridesMessage = Test-Contains $viewFile "Overrides JSON no es valido."
$hasLocalLabel = Test-Contains $viewFile "Regla local (template existente)"
$hasReusableLabel = Test-Contains $viewFile "Crear template reusable"
$hasCreateButtonLocal = Test-Contains $viewFile "Crear regla local"
$hasCreateButtonReusable = Test-Contains $viewFile "Crear reusable y asignar"
$hasSaveFlow = Test-Contains $viewFile "deviceCustomerService.update"
$hasSaveButton = Test-Contains $viewFile "Guardar Cambios"
$hasCreateFromDeviceService = Test-Contains $serviceFile "createRuleFromDevice"
$hasCreateFromDeviceEndpoint = Test-Contains $serviceFile "/actions/assignments/create-from-device"
$hasCreateFromDeviceRequestType = Test-Contains $typesFile "CreateRuleFromDeviceRequest"
$hasCreateFromDeviceResponseType = Test-Contains $typesFile "CreateRuleFromDeviceResponse"
$hasExecutionTrace = Test-Contains $phaseSummaryFile "flujo"
$hasSpanishLabelsTrace = Test-Contains $phaseSummaryFile "labels UI en espanol"

Write-OutputLog "Observed: route_my_devices_edit_exists=$($hasRoute -and $hasRouteView)"
Write-OutputLog "Observed: ui_rule_mode_local_reusable=$hasRuleMode"
Write-OutputLog "Observed: ui_calls_create_rule_from_device=$hasCreateRuleCall"
Write-OutputLog "Observed: ui_permission_gate_assign=$hasPermissionGate"
Write-OutputLog "Observed: ui_permission_block_message=$hasPermissionMessage"
Write-OutputLog "Observed: ui_invalid_overrides_message=$hasInvalidOverridesMessage"
Write-OutputLog "Observed: ui_local_reusable_labels=$($hasLocalLabel -and $hasReusableLabel)"
Write-OutputLog "Observed: ui_action_buttons=$($hasCreateButtonLocal -and $hasCreateButtonReusable)"
Write-OutputLog "Observed: customer_edit_save_flow_preserved=$($hasSaveFlow -and $hasSaveButton)"
Write-OutputLog "Observed: service_create_from_device_wiring=$($hasCreateFromDeviceService -and $hasCreateFromDeviceEndpoint)"
Write-OutputLog "Observed: typed_contracts_create_from_device=$($hasCreateFromDeviceRequestType -and $hasCreateFromDeviceResponseType)"
Write-OutputLog "Observed: execution_summary_trace_present=$($hasExecutionTrace -and $hasSpanishLabelsTrace)"

if ($DryRun -eq "1") {
    Write-CommandLog "npm --prefix $FrontendDir run typecheck"
    Write-CommandLog "Read baseline from baseline.json"
    Write-OutputLog "Observed (pendiente): typecheck no ejecutado por DRY_RUN=1."
    Write-OutputLog "Observed (pendiente): gate no-regresion no evaluado por DRY_RUN=1."
    Write-OutputLog "Observed (pendiente): autodiscovery login/sql no ejecutado por DRY_RUN=1."
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
    Write-OutputLog "Observed: API smoke opcional no ejecutado por defecto en fase frontend (set RUN_API_SMOKE=1 para extender)."
}

Write-OutputLog "Observed: run finalizado."
