#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACK_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
EVIDENCE_DIR="$PACK_DIR/evidence"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../../../../../../.." && pwd)"

DRY_RUN="${DRY_RUN:-1}"
FRONTEND_DIR="${FRONTEND_DIR:-telemetric-front}"
COMMANDS_LOG="$EVIDENCE_DIR/commands.log"
OUTPUTS_LOG="$EVIDENCE_DIR/outputs.log"

mkdir -p "$EVIDENCE_DIR"
touch "$COMMANDS_LOG" "$OUTPUTS_LOG"

log_command() {
  echo "$(date -Iseconds) | $1" >> "$COMMANDS_LOG"
}

log_output() {
  echo "$(date -Iseconds) | $1" >> "$OUTPUTS_LOG"
}

run_step() {
  local cmd="$1"
  log_command "$cmd"
  if [[ "$DRY_RUN" == "1" ]]; then
    echo "[DRY_RUN] $cmd"
    log_output "Observed (pendiente): DRY_RUN=1 no ejecuto comando."
  else
    echo "[EXEC] $cmd"
    bash -lc "$cmd" | tee -a "$OUTPUTS_LOG"
  fi
}

log_output "Expected: setup valida prerequisitos y discovery ACT-004 phase-02."
log_output "Observed: inicio setup (DRY_RUN=$DRY_RUN, FRONTEND_DIR=$FRONTEND_DIR)."

compose_primary_rel="telemetric-hub/kiss/scripts/docker-compose.yml"
compose_legacy_rel="telemetric-api/old/docker-compose.yml"
launch_settings_rel="telemetric-api/src/Telemetric.Api/Properties/launchSettings.json"
phase_summary_rel="contexto/work/features/acciones_modulo/03_execution/ACT-004/phase-02.md"
frontend_package_rel="$FRONTEND_DIR/package.json"

for tool in rg dotnet node npm; do
  log_command "command -v $tool"
  if command -v "$tool" >/dev/null 2>&1; then
    log_output "Observed: herramienta OK -> $tool"
  else
    log_output "Observed: herramienta faltante -> $tool"
  fi
done

if [[ -f "$REPO_ROOT/$compose_primary_rel" ]]; then
  run_step "docker compose -f '$REPO_ROOT/$compose_primary_rel' config --services"
else
  log_output "Observed: compose primario no encontrado ($compose_primary_rel)."
fi

if [[ -f "$REPO_ROOT/$compose_legacy_rel" ]]; then
  log_output "Observed: compose legado detectado (no usado): $compose_legacy_rel"
fi

for rel in "$launch_settings_rel" "$phase_summary_rel" "$frontend_package_rel"; do
  log_command "test -f $rel"
  if [[ -f "$REPO_ROOT/$rel" ]]; then
    log_output "Observed: path_exists[$rel]=true"
  else
    log_output "Observed: path_exists[$rel]=false"
  fi
done

pushd "$REPO_ROOT" >/dev/null
run_step "rg --line-number -F 'CreateRuleFromDevice' telemetric-api/src/Telemetric.Api/Features/Actions"
run_step "rg --line-number -F '/api/v1/actions/assignments/create-from-device' telemetric-api/src/Telemetric.Api/Features/Actions/Assignments/CreateRuleFromDevice/CreateRuleFromDeviceEndpoint.cs contexto/openapi/actions.yaml"
run_step "rg --line-number -F 'PermissionClaims.Actions.Assign' telemetric-api/src/Telemetric.Api/Features/Actions/Assignments/CreateRuleFromDevice/CreateRuleFromDeviceEndpoint.cs telemetric-api/src/Telemetric.Api/Domain/Constants/PermissionClaims.cs"
run_step "rg --line-number -F 'threshold' telemetric-api/src/Telemetric.Api/Features/Actions/Assignments/CreateRuleFromDevice/CreateRuleFromDeviceCommandHandler.cs"
run_step "rg --line-number -F 'email.recipients' telemetric-api/src/Telemetric.Api/Features/Actions/Assignments/CreateRuleFromDevice/CreateRuleFromDeviceCommandHandler.cs"
run_step "rg --line-number -F 'is not allowed in v1' telemetric-api/src/Telemetric.Api/Features/Actions/Assignments/CreateRuleFromDevice/CreateRuleFromDeviceCommandHandler.cs"
run_step "npm --prefix telemetric-front run typecheck"
popd >/dev/null

log_output "Expected: setup deja evidencia en commands.log y outputs.log."
log_output "Observed: setup finalizado."
