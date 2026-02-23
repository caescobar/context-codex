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
  else
    echo "[EXEC] $cmd"
    bash -lc "$cmd" | tee -a "$OUTPUTS_LOG"
  fi
}

log_output "Expected: setup validates prerequisites and discovery for ACT-007 phase-02."
log_output "Observed: setup start (DRY_RUN=$DRY_RUN, FRONTEND_DIR=$FRONTEND_DIR)."

for tool in rg dotnet node npm; do
  log_command "command -v $tool"
  if command -v "$tool" >/dev/null 2>&1; then
    log_output "Observed: tool OK -> $tool"
  else
    log_output "Observed: missing tool -> $tool"
  fi
done

for rel in \
  "telemetric-hub/kiss/scripts/docker-compose.yml" \
  "telemetric-api/old/docker-compose.yml" \
  "telemetric-api/src/Telemetric.Api/Properties/launchSettings.json" \
  "contexto/work/features/acciones_modulo/02_plans/ACT-007.plan.md" \
  "contexto/work/features/acciones_modulo/03_execution/ACT-007/phase-02.md" \
  "contexto/openapi/actions.yaml" \
  "telemetric-api/src/Telemetric.Api/Features/Actions/Rules/GetRules/GetRulesEndpoint.cs" \
  "telemetric-api/src/Telemetric.Api/Features/Actions/Rules/GetRules/GetRulesQueryHandler.cs" \
  "telemetric-api/src/Telemetric.Api/Features/Actions/Rules/UpdateRuleState/UpdateRuleStateEndpoint.cs" \
  "telemetric-api/src/Telemetric.Api/Features/Actions/Rules/UpdateRuleState/UpdateRuleStateCommandHandler.cs" \
  "telemetric-api/src/Telemetric.Api/Common/Interfaces/IApplicationDbContext.cs"; do
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

pushd "$REPO_ROOT" >/dev/null
run_step "rg --line-number -F -e '/api/v1/actions/rules:' -e '/api/v1/actions/devices/{deviceId}/rules:' -e '/api/v1/actions/rules/{ruleInstanceId}/state:' contexto/openapi/actions.yaml"
run_step "rg --line-number -F -e 'Get(\"/api/v1/actions/rules\")' telemetric-api/src/Telemetric.Api/Features/Actions/Rules/GetRules/GetRulesEndpoint.cs"
run_step "rg --line-number -F -e 'Patch(\"/api/v1/actions/rules/{RuleInstanceId}/state\")' telemetric-api/src/Telemetric.Api/Features/Actions/Rules/UpdateRuleState/UpdateRuleStateEndpoint.cs"
run_step "rg --line-number -F -e 'Policies(PermissionClaims.Actions.View)' -e 'Policies(PermissionClaims.Actions.Update)' telemetric-api/src/Telemetric.Api/Features/Actions/Rules/GetRules/GetRulesEndpoint.cs telemetric-api/src/Telemetric.Api/Features/Actions/Rules/UpdateRuleState/UpdateRuleStateEndpoint.cs"
run_step "rg --line-number -F -e 'DeviceId' -e 'Status' -e 'ClientId' -e 'ActionAttempts' -e 'StatusFail' telemetric-api/src/Telemetric.Api/Features/Actions/Rules/GetRules/GetRulesQueryHandler.cs"
run_step "rg --line-number -F -e 'SaveChangesAsync' -e 'UpdatedAt' -e 'UpdatedBy' -e 'ClientId' telemetric-api/src/Telemetric.Api/Features/Actions/Rules/UpdateRuleState/UpdateRuleStateCommandHandler.cs"
popd >/dev/null

log_output "Observed: setup finished."
