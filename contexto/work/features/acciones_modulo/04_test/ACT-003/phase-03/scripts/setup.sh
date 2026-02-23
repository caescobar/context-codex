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

log_output "Expected: setup valida herramientas y discovery de frontend para ACT-003 phase-03."
log_output "Observed: inicio setup (DRY_RUN=$DRY_RUN, FRONTEND_DIR=$FRONTEND_DIR)."

compose_primary_rel="telemetric-hub/kiss/scripts/docker-compose.yml"
compose_legacy_rel="telemetric-api/old/docker-compose.yml"
launch_settings_rel="telemetric-api/src/Telemetric.Api/Properties/launchSettings.json"

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

if [[ -f "$REPO_ROOT/$launch_settings_rel" ]]; then
  log_output "Observed: launchSettings encontrado ($launch_settings_rel)."
else
  log_output "Observed: launchSettings no encontrado ($launch_settings_rel)."
fi

if [[ -f "$REPO_ROOT/$FRONTEND_DIR/package.json" ]]; then
  log_output "Observed: frontend package.json encontrado en $FRONTEND_DIR."
else
  log_output "Observed: frontend package.json no encontrado en $FRONTEND_DIR."
fi

pushd "$REPO_ROOT" >/dev/null
run_step "rg --line-number -F '/actions' telemetric-front/src"
run_step "rg --line-number -F '/actions/templates/:id' telemetric-front/src"
run_step "rg --line-number -F 'features/actions' telemetric-front/src/router telemetric-front/src/features -g '*.ts'"
run_step "rg --line-number -F '@/core/utils/axios' telemetric-front/src/features -g '*.ts'"
run_step "npm --prefix telemetric-front run typecheck"
popd >/dev/null

log_output "Expected: setup deja evidencia en commands.log y outputs.log."
log_output "Observed: setup finalizado."
