# Requires -Version 5.1
$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$PackDir = Resolve-Path (Join-Path $ScriptDir "..")
$EvidenceDir = Join-Path $PackDir "evidence"
$RepoRoot = Resolve-Path (Join-Path $ScriptDir "..\..\..\..\..\..\..\..")

$DryRun = if ($env:DRY_RUN) { $env:DRY_RUN } else { "1" }
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

Write-OutputLog "Expected: run valida criterios de fase-03 (rutas/actions, labels ES, tipos EN, servicio con axios core)."
Write-OutputLog "Observed: inicio run (DRY_RUN=$DryRun)."

$candidateFiles = @(
    "telemetric-front/src/features/actions/actions.routes.ts",
    "telemetric-front/src/features/actions/actions.service.ts",
    "telemetric-front/src/features/actions/types.ts",
    "telemetric-front/src/features/actions/views/ActionsTemplatesView.vue",
    "telemetric-front/src/features/actions/views/ActionTemplateDetailView.vue"
)

foreach ($rel in $candidateFiles) {
    $full = Join-Path $RepoRoot $rel
    $exists = Test-Path $full
    Write-CommandLog "Test-Path $rel"
    Write-OutputLog "Observed: file_exists[$rel]=$exists"
}

$routerIndex = Join-Path $RepoRoot "telemetric-front/src/router/index.ts"
$mainRoutes = Join-Path $RepoRoot "telemetric-front/src/router/MainRoutes.ts"
$adminRoutes = Join-Path $RepoRoot "telemetric-front/src/router/AdminRoutes.ts"
$actionsRoutes = Join-Path $RepoRoot "telemetric-front/src/features/actions/actions.routes.ts"
$actionsService = Join-Path $RepoRoot "telemetric-front/src/features/actions/actions.service.ts"
$actionsTypes = Join-Path $RepoRoot "telemetric-front/src/features/actions/types.ts"
$actionsListView = Join-Path $RepoRoot "telemetric-front/src/features/actions/views/ActionsTemplatesView.vue"
$actionsDetailView = Join-Path $RepoRoot "telemetric-front/src/features/actions/views/ActionTemplateDetailView.vue"

$routeActionsInRouter = (Test-Contains $actionsRoutes "/actions") -or (Test-Contains $routerIndex "/actions") -or (Test-Contains $mainRoutes "/actions") -or (Test-Contains $adminRoutes "/actions")
$routeDetailInRouter = (Test-Contains $actionsRoutes "/actions/templates/:id") -or (Test-Contains $routerIndex "/actions/templates/:id") -or (Test-Contains $mainRoutes "/actions/templates/:id") -or (Test-Contains $adminRoutes "/actions/templates/:id")
Write-OutputLog "Observed: route_exists[/actions]=$routeActionsInRouter"
Write-OutputLog "Observed: route_exists[/actions/templates/:id]=$routeDetailInRouter"

$serviceUsesCoreAxios = (Test-Contains $actionsService "@/core/utils/axios") -or (Test-Contains $actionsService "httpClient")
$serviceUsesTemplatesEndpoint = (Test-Contains $actionsService "/api/v1/actions/templates") -or (Test-Contains $actionsService "actions/templates")
Write-OutputLog "Observed: service_uses_core_axios=$serviceUsesCoreAxios"
Write-OutputLog "Observed: service_uses_templates_endpoint=$serviceUsesTemplatesEndpoint"

$typesEnglishHints = (Test-Contains $actionsTypes "interface ") -or (Test-Contains $actionsTypes "type ")
$labelsSpanishHints = (Test-Contains $actionsListView "Plantillas") -or (Test-Contains $actionsListView "Acciones") -or (Test-Contains $actionsDetailView "Plantillas") -or (Test-Contains $actionsDetailView "Acciones")
Write-OutputLog "Observed: types_file_has_english_contract_hints=$typesEnglishHints"
Write-OutputLog "Observed: views_have_spanish_label_hints=$labelsSpanishHints"

if ($DryRun -eq "1") {
    Write-CommandLog "npm --prefix telemetric-front run typecheck"
    Write-CommandLog "Read baseline from baseline.json"
    Write-OutputLog "Observed (pendiente): typecheck no ejecutado por DRY_RUN=1."
    Write-OutputLog "Observed (pendiente): gate no-regresion no evaluado por DRY_RUN=1."
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
        Write-CommandLog "npm --prefix telemetric-front run typecheck"
        $typecheckOut = @(npm --prefix telemetric-front run typecheck 2>&1)
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
}

Write-OutputLog "Observed: run finalizado."
