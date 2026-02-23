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

log_command() { echo "$(date -Iseconds) | $1" >> "$COMMANDS_LOG"; }
log_output() { echo "$(date -Iseconds) | $1" >> "$OUTPUTS_LOG"; }

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

log_output "Expected: setup valida prerequisitos y discovery ACT-005 phase-03."
log_output "Observed: inicio setup (DRY_RUN=$DRY_RUN, FRONTEND_DIR=$FRONTEND_DIR)."

for tool in rg node npm; do
  log_command "command -v $tool"
  if command -v "$tool" >/dev/null 2>&1; then
    log_output "Observed: herramienta OK -> $tool"
  else
    log_output "Observed: herramienta faltante -> $tool"
  fi
done

if [[ -f "$REPO_ROOT/telemetric-hub/kiss/scripts/docker-compose.yml" ]]; then
  run_step "docker compose -f '$REPO_ROOT/telemetric-hub/kiss/scripts/docker-compose.yml' config --services"
fi

pushd "$REPO_ROOT" >/dev/null
run_step "rg --line-number -F 'validateAndBuild' telemetric-front/src/features/actions/views/ActionsTemplatesView.vue"
run_step "rg --line-number -F 'durationSeconds no puede ser mayor que windowSeconds.' telemetric-front/src/features/actions/views/ActionsTemplatesView.vue"
run_step "rg --line-number -F 'ttlSeconds invalido para HOLD_LAST_VALUE.' telemetric-front/src/features/actions/views/ActionsTemplatesView.vue"
run_step "rg --line-number -F 'Debe ingresar al menos un destinatario.' telemetric-front/src/features/actions/views/ActionsTemplatesView.vue"
run_step "rg --line-number -F \"path: '/actions'\" telemetric-front/src/features/actions/actions.routes.ts"
run_step "rg --line-number -F \"requiresPermission: 'Actions.View'\" telemetric-front/src/features/actions/actions.routes.ts telemetric-front/src/layouts/menuItems.ts"
run_step "npm --prefix $FRONTEND_DIR run typecheck"
popd >/dev/null

log_output "Observed: setup finalizado."
