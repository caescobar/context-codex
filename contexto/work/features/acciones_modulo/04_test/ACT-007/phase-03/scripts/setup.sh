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
    log_output "Observed (pending): DRY_RUN=1 skipped command."
    return
  fi

  echo "[EXEC] $cmd"
  bash -lc "$cmd" >> "$OUTPUTS_LOG" 2>&1
}

log_output "Expected: setup validates prerequisites and discovery for ACT-007 phase-03."
log_output "Observed: setup start (DRY_RUN=$DRY_RUN, FRONTEND_DIR=$FRONTEND_DIR)."

for tool in rg node npm; do
  log_command "command -v $tool"
  if command -v "$tool" >/dev/null 2>&1; then
    log_output "Observed: tool OK -> $tool"
  else
    log_output "Observed: missing tool -> $tool"
  fi
done

declare -a rel_paths=(
  "telemetric-hub/kiss/scripts/docker-compose.yml"
  "telemetric-api/old/docker-compose.yml"
  "telemetric-api/src/Telemetric.Api/Properties/launchSettings.json"
  "contexto/work/features/acciones_modulo/02_plans/ACT-007.plan.md"
  "contexto/work/features/acciones_modulo/03_execution/ACT-007/phase-03.md"
  "telemetric-front/src/features/actions/views/ActionsTemplatesView.vue"
  "telemetric-front/src/features/actions/actions.service.ts"
  "telemetric-front/src/features/actions/types.ts"
  "telemetric-front/src/features/actions/actions.routes.ts"
  "telemetric-front/src/layouts/menuItems.ts"
  "telemetric-api/src/Telemetric.Api/Features/Actions/Rules/GetRules/GetRulesEndpoint.cs"
  "telemetric-api/src/Telemetric.Api/Features/Actions/Rules/UpdateRuleState/UpdateRuleStateEndpoint.cs"
)

for rel in "${rel_paths[@]}"; do
  log_command "test -f $rel"
  if [[ -f "$REPO_ROOT/$rel" ]]; then
    log_output "Observed: path_exists[$rel]=true"
  else
    log_output "Observed: path_exists[$rel]=false"
  fi
done

if [[ -f "$REPO_ROOT/telemetric-hub/kiss/scripts/docker-compose.yml" ]]; then
  run_step "docker compose -f '$REPO_ROOT/telemetric-hub/kiss/scripts/docker-compose.yml' config --services"
fi

cd "$REPO_ROOT"
run_step "rg --line-number -F -e \"activeTab = ref<'runs' | 'rules' | 'templates'>('runs')\" -e '<v-tab value=\"rules\">Rules</v-tab>' telemetric-front/src/features/actions/views/ActionsTemplatesView.vue"
run_step "rg --line-number -F -e 'UiDynamicFilter' -e 'UiServerTable' -e 'rulesErrorMessage' -e 'No se pudieron cargar las reglas.' telemetric-front/src/features/actions/views/ActionsTemplatesView.vue"
run_step "rg --line-number -F -e 'hasLastAttemptFail' -e 'Ultimo fail' -e 'Fail sin detalle de error.' telemetric-front/src/features/actions/views/ActionsTemplatesView.vue"
run_step "rg --line-number -F -e 'updateRuleState(item, !item.isPaused)' -e 'Actions.Update' telemetric-front/src/features/actions/views/ActionsTemplatesView.vue"
run_step "rg --line-number -F -e 'getRules:' -e 'updateRuleState:' -e '/actions/rules' telemetric-front/src/features/actions/actions.service.ts"
run_step "rg --line-number -F -e 'ActionRuleListItem' -e 'ActionRulesQueryParams' -e 'UpdateRuleStateRequest' -e 'UpdateRuleStateResponse' -e 'RuleOperationalStatus' telemetric-front/src/features/actions/types.ts"
run_step "rg --line-number -F -e \"path: '/actions'\" -e \"requiresPermission: 'Actions.View'\" telemetric-front/src/features/actions/actions.routes.ts telemetric-front/src/layouts/menuItems.ts"

log_output "Observed: setup finished."
