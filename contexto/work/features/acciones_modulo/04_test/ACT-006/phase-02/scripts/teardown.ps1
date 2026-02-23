# Requires -Version 5.1
$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$PackDir = Resolve-Path (Join-Path $ScriptDir "..")
$EvidenceDir = Join-Path $PackDir "evidence"
$DryRun = if ($env:DRY_RUN) { $env:DRY_RUN } else { "1" }

$CommandsLog = Join-Path $EvidenceDir "commands.log"
$OutputsLog = Join-Path $EvidenceDir "outputs.log"
$NotesFile = Join-Path $EvidenceDir "notes.md"

New-Item -ItemType Directory -Force -Path $EvidenceDir | Out-Null
if (!(Test-Path $CommandsLog)) { New-Item -ItemType File -Path $CommandsLog | Out-Null }
if (!(Test-Path $OutputsLog)) { New-Item -ItemType File -Path $OutputsLog | Out-Null }
if (!(Test-Path $NotesFile)) { New-Item -ItemType File -Path $NotesFile | Out-Null }

Add-Content -Path $CommandsLog -Value ("{0} | teardown phase-02 (safe no-op), DRY_RUN={1}" -f (Get-Date -Format s), $DryRun)
Add-Content -Path $OutputsLog -Value ("{0} | Expected: teardown without destructive actions." -f (Get-Date -Format s))
Add-Content -Path $OutputsLog -Value ("{0} | Observed: no-op executed." -f (Get-Date -Format s))
Add-Content -Path $OutputsLog -Value ("{0} | Runtime closure rule: any instance started during QA must be stopped and verified as not running." -f (Get-Date -Format s))
Add-Content -Path $NotesFile -Value "- Teardown phase-02: no destructive actions were performed."
Add-Content -Path $NotesFile -Value "- If services were started during DRY_RUN=0, stop them and verify they are not running."

Write-Host "Teardown completed (safe no-op)."
