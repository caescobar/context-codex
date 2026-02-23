# Requires -Version 5.1
$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$PackDir = Resolve-Path (Join-Path $ScriptDir "..")
$EvidenceDir = Join-Path $PackDir "evidence"
$RepoRoot = Resolve-Path (Join-Path $ScriptDir "..\..\..\..\..\..\..\..")

$DryRun = if ($env:DRY_RUN) { $env:DRY_RUN } else { "1" }
$ApiBaseUrl = if ($env:API_BASE_URL) { $env:API_BASE_URL } else { "http://localhost:5220" }
$ApiUser = if ($env:API_USER) { $env:API_USER } else { "admin" }
$ApiPassword = if ($env:API_PASSWORD) { $env:API_PASSWORD } else { "admin123" }
$RuleTemplateId = if ($env:RULE_TEMPLATE_ID) { [int]$env:RULE_TEMPLATE_ID } else { 1 }
$SqlcmdArgs = if ($env:SQLCMD_ARGS) { $env:SQLCMD_ARGS } else { "" }

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

function Invoke-Step([string]$Command) {
    Write-CommandLog $Command
    if ($DryRun -eq "1") {
        Write-Host "[DRY_RUN] $Command"
        Write-OutputLog "Observed (pendiente): DRY_RUN=1 no ejecuto comando."
        return $null
    }

    Write-Host "[EXEC] $Command"
    $output = Invoke-Expression $Command | Out-String
    if (-not [string]::IsNullOrWhiteSpace($output)) {
        Add-Content -Path $OutputsLog -Value $output.TrimEnd()
    }
    return $output
}

Write-OutputLog "Expected: run valida GET/PUT templates con versionado inmutable."
Write-OutputLog "Observed: inicio run (DRY_RUN=$DryRun, RULE_TEMPLATE_ID=$RuleTemplateId)."

Push-Location $RepoRoot
try {
    Invoke-Step "rg --line-number --glob '*.cs' -F -e '/api/v1/actions/templates/{RuleTemplateId}' -e 'PermissionClaims.Actions.View' -e 'PermissionClaims.Actions.Update' -e 'Tags(""Actions"")' telemetric-api/src/Telemetric.Api/Features/Actions/Templates" | Out-Null
    Invoke-Step "rg --line-number -F -e '/api/v1/actions/templates/{ruleTemplateId}' -e 'updateActionTemplate' -e 'getActionTemplateById' contexto/openapi/actions.yaml" | Out-Null

    if ($DryRun -eq "1") {
        Write-CommandLog "HTTP placeholders: login, GET template, PUT template, GET template"
        Write-OutputLog "Observed (pendiente): flujo HTTP omitido por DRY_RUN=1."
    }
    else {
        Write-CommandLog "Invoke-RestMethod POST $ApiBaseUrl/api/v1/auth/login"
        $loginBody = @{ username = $ApiUser; password = $ApiPassword } | ConvertTo-Json -Compress
        $login = Invoke-RestMethod -Method Post -Uri "$ApiBaseUrl/api/v1/auth/login" -ContentType "application/json" -Body $loginBody

        $token = $login.token
        if ([string]::IsNullOrWhiteSpace($token)) {
            throw "No se pudo obtener token de login."
        }

        $headers = @{ Authorization = "Bearer $token" }

        Write-CommandLog "Invoke-RestMethod GET $ApiBaseUrl/api/v1/actions/templates/$RuleTemplateId (before)"
        $before = Invoke-RestMethod -Method Get -Uri "$ApiBaseUrl/api/v1/actions/templates/$RuleTemplateId" -Headers $headers

        $prevVersion = [int]$before.currentVersion.versionNumber
        $newDefinition = $before.currentVersion.definitionJson
        if ([string]::IsNullOrWhiteSpace($newDefinition)) {
            $newDefinition = '{"trigger":{"metricCode":"temperature"},"condition":{"operator":">","value":70}}'
        }

        $payload = @{
            ruleTemplateId = $RuleTemplateId
            name = (([string]$before.name) + " [qa-phase-02]").Trim()
            description = $before.description
            definitionJson = $newDefinition
            isActive = [bool]$before.isActive
        } | ConvertTo-Json -Compress

        Write-CommandLog "Invoke-RestMethod PUT $ApiBaseUrl/api/v1/actions/templates/$RuleTemplateId"
        $put = Invoke-RestMethod -Method Put -Uri "$ApiBaseUrl/api/v1/actions/templates/$RuleTemplateId" -Headers $headers -ContentType "application/json" -Body $payload

        Write-CommandLog "Invoke-RestMethod GET $ApiBaseUrl/api/v1/actions/templates/$RuleTemplateId (after)"
        $after = Invoke-RestMethod -Method Get -Uri "$ApiBaseUrl/api/v1/actions/templates/$RuleTemplateId" -Headers $headers

        $postVersion = [int]$after.currentVersion.versionNumber
        $expected = $prevVersion + 1
        $prevStillExists = ($after.versions | Where-Object { [int]$_.versionNumber -eq $prevVersion } | Measure-Object).Count -gt 0

        Write-OutputLog "Expected: versionNumber post = pre + 1 ($expected)."
        Write-OutputLog ("Observed: pre={0}, post={1}, putVersion={2}." -f $prevVersion, $postVersion, $put.versionNumber)
        Write-OutputLog "Expected: version previa sigue en historial."
        Write-OutputLog "Observed: previousVersionPresent=$prevStillExists"
    }

    if (![string]::IsNullOrWhiteSpace($SqlcmdArgs)) {
        $queriesPath = Join-Path $PackDir "queries.sql"
        Invoke-Step ("sqlcmd {0} -i `"{1}`" -v RuleTemplateId={2}" -f $SqlcmdArgs, $queriesPath, $RuleTemplateId) | Out-Null
    }
    else {
        Write-OutputLog "Observed: SQL opcional no ejecutado (SQLCMD_ARGS no definido)."
    }
}
finally {
    Pop-Location
}

Write-OutputLog "Observed: run finalizado."
