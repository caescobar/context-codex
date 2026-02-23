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

log_output "Expected: setup valida prerequisitos y discovery ACT-004 phase-04."
log_output "Observed: inicio setup (DRY_RUN=$DRY_RUN, FRONTEND_DIR=$FRONTEND_DIR)."

compose_primary_rel="telemetric-hub/kiss/scripts/docker-compose.yml"
compose_legacy_rel="telemetric-api/old/docker-compose.yml"
launch_settings_rel="telemetric-api/src/Telemetric.Api/Properties/launchSettings.json"
phase_summary_rel="contexto/work/features/acciones_modulo/03_execution/ACT-004/phase-04.md"

for tool in node npm rg; do
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

for rel in "$launch_settings_rel" "$phase_summary_rel" "$FRONTEND_DIR/package.json"; do
  log_command "test -f $rel"
  if [[ -f "$REPO_ROOT/$rel" ]]; then
    log_output "Observed: path_exists[$rel]=true"
  else
    log_output "Observed: path_exists[$rel]=false"
  fi
done

pushd "$REPO_ROOT" >/dev/null
run_step "rg --line-number -F '/my-devices/:id/edit' telemetric-front/src/router/MainRoutes.ts"
run_step "rg --line-number -F \"ruleMode = ref<'local' | 'reusable'>('local')\" telemetric-front/src/features/customer/devices/views/DeviceCustomerEditView.vue"
run_step "rg --line-number -F 'Actions.Assign' telemetric-front/src/features/customer/devices/views/DeviceCustomerEditView.vue"
run_step "rg --line-number -F 'actionsService.createRuleFromDevice' telemetric-front/src/features/customer/devices/views/DeviceCustomerEditView.vue"
run_step "rg --line-number -F 'Overrides JSON no es valido.' telemetric-front/src/features/customer/devices/views/DeviceCustomerEditView.vue"
run_step "rg --line-number -F '/actions/assignments/create-from-device' telemetric-front/src/features/actions/actions.service.ts"
run_step "npm --prefix '$FRONTEND_DIR' run typecheck"
popd >/dev/null

log_output "Expected: setup deja evidencia en commands.log y outputs.log."
log_output "Observed: setup finalizado."
