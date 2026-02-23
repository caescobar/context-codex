# Requires -Version 5.1
$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$PackDir = Resolve-Path (Join-Path $ScriptDir "..")
$EvidenceDir = Join-Path $PackDir "evidence"
$RepoRoot = Resolve-Path (Join-Path $ScriptDir "..\..\..\..\..\..\..\..")

$DryRun = if ($env:DRY_RUN) { $env:DRY_RUN } else { "1" }
$FrontendDir = if ($env:FRONTEND_DIR) { $env:FRONTEND_DIR } else { "telemetric-front" }
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

Write-OutputLog "Expected: run valida criterios ACT-004 phase-03 (asignacion masiva FE, feedback, no-regresion)."
Write-OutputLog "Observed: inicio run (DRY_RUN=$DryRun)."

$candidateFiles = @(
    "telemetric-front/src/features/actions/actions.service.ts",
    "telemetric-front/src/features/actions/types.ts",
    "telemetric-front/src/features/actions/views/ActionsTemplatesView.vue",
    "telemetric-front/src/features/actions/views/ActionTemplateDetailView.vue",
    "contexto/work/features/acciones_modulo/03_execution/ACT-004/phase-03.md"
)

foreach ($rel in $candidateFiles) {
    $full = Join-Path $RepoRoot $rel
    $exists = Test-Path $full
    Write-CommandLog "Test-Path $rel"
    Write-OutputLog "Observed: file_exists[$rel]=$exists"
}

$serviceFile = Join-Path $RepoRoot "telemetric-front/src/features/actions/actions.service.ts"
$typesFile = Join-Path $RepoRoot "telemetric-front/src/features/actions/types.ts"
$listViewFile = Join-Path $RepoRoot "telemetric-front/src/features/actions/views/ActionsTemplatesView.vue"
$detailViewFile = Join-Path $RepoRoot "telemetric-front/src/features/actions/views/ActionTemplateDetailView.vue"
$phaseSummaryFile = Join-Path $RepoRoot "contexto/work/features/acciones_modulo/03_execution/ACT-004/phase-03.md"

$hasReuseFirst = Test-Contains $phaseSummaryFile "Reuse-first"
$hasAssignRequestType = Test-Contains $typesFile "AssignTemplateToDevicesRequest"
$hasAssignResponseType = Test-Contains $typesFile "AssignTemplateToDevicesResponse"
$hasRejectedDuplicateType = Test-Contains $typesFile "RejectedDuplicate"
$hasRejectedOutOfScopeType = Test-Contains $typesFile "RejectedNotFoundOrOutOfScope"
$hasAssignService = Test-Contains $serviceFile "assignTemplateToDevices"
$hasAssignmentsEndpoint = Test-Contains $serviceFile "/actions/assignments/template-version"
$hasAssignableDevicesService = Test-Contains $serviceFile "getAssignableDevices"
$hasDevicesEndpoint = Test-Contains $serviceFile "/devices"
$hasAssignButtonList = Test-Contains $listViewFile "Asignar seleccionados"
$hasAssignButtonDetail = Test-Contains $detailViewFile "Asignar seleccionados"
$hasDuplicateLabelList = Test-Contains $listViewFile "Duplicado"
$hasOutOfScopeLabelList = Test-Contains $listViewFile "Fuera de alcance"
$hasDuplicateLabelDetail = Test-Contains $detailViewFile "Duplicado"
$hasOutOfScopeLabelDetail = Test-Contains $detailViewFile "Fuera de alcance"
$hasCreatedCountList = Test-Contains $listViewFile "assignResult.createdCount"
$hasRejectedCountList = Test-Contains $listViewFile "assignResult.rejectedCount"
$hasResultItemsList = Test-Contains $listViewFile "assignResult.items"
$hasResultItemsDetail = Test-Contains $detailViewFile "assignResult.items"

Write-OutputLog "Observed: reuse_first_trace_in_phase_summary=$hasReuseFirst"
Write-OutputLog "Observed: type_assign_request=$hasAssignRequestType"
Write-OutputLog "Observed: type_assign_response=$hasAssignResponseType"
Write-OutputLog "Observed: type_status_rejected_duplicate=$hasRejectedDuplicateType"
Write-OutputLog "Observed: type_status_rejected_out_of_scope=$hasRejectedOutOfScopeType"
Write-OutputLog "Observed: service_assign_method=$hasAssignService"
Write-OutputLog "Observed: service_assign_endpoint=$hasAssignmentsEndpoint"
Write-OutputLog "Observed: service_assignable_devices_method=$hasAssignableDevicesService"
Write-OutputLog "Observed: service_devices_endpoint=$hasDevicesEndpoint"
Write-OutputLog "Observed: ui_assign_button_list_view=$hasAssignButtonList"
Write-OutputLog "Observed: ui_assign_button_detail_view=$hasAssignButtonDetail"
Write-OutputLog "Observed: ui_duplicate_label_list=$hasDuplicateLabelList"
Write-OutputLog "Observed: ui_out_of_scope_label_list=$hasOutOfScopeLabelList"
Write-OutputLog "Observed: ui_duplicate_label_detail=$hasDuplicateLabelDetail"
Write-OutputLog "Observed: ui_out_of_scope_label_detail=$hasOutOfScopeLabelDetail"
Write-OutputLog "Observed: ui_created_count_visible=$hasCreatedCountList"
Write-OutputLog "Observed: ui_rejected_count_visible=$hasRejectedCountList"
Write-OutputLog "Observed: ui_result_items_list=$hasResultItemsList"
Write-OutputLog "Observed: ui_result_items_detail=$hasResultItemsDetail"

if ($DryRun -eq "1") {
    Write-CommandLog "npm --prefix $FrontendDir run typecheck"
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
}

Write-OutputLog "Observed: run finalizado."
