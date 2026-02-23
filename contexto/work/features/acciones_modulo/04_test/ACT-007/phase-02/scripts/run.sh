#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACK_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
EVIDENCE_DIR="$PACK_DIR/evidence"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../../../../../../.." && pwd)"

DRY_RUN="${DRY_RUN:-1}"
FRONTEND_DIR="${FRONTEND_DIR:-telemetric-front}"
API_BASE_URL="${API_BASE_URL:-http://localhost:5220}"
API_AUTH_TOKEN="${API_AUTH_TOKEN:-}"
API_USER="${API_USER:-vcsoft}"
API_PASSWORD="${API_PASSWORD:-123456}"
SQLCMD_ARGS="${SQLCMD_ARGS:--S . -d TelemetricDb -U sa -P sa -C}"
TEST_RULE_TEMPLATE_VERSION_ID="${TEST_RULE_TEMPLATE_VERSION_ID:-}"
TEST_DEVICE_IDS="${TEST_DEVICE_IDS:-}"
BASELINE_TS_ERRORS="${BASELINE_TS_ERRORS:-}"

COMMANDS_LOG="$EVIDENCE_DIR/commands.log"
OUTPUTS_LOG="$EVIDENCE_DIR/outputs.log"

mkdir -p "$EVIDENCE_DIR"
touch "$COMMANDS_LOG" "$OUTPUTS_LOG"

log_command() { echo "$(date -Iseconds) | $1" >> "$COMMANDS_LOG"; }
log_output() { echo "$(date -Iseconds) | $1" >> "$OUTPUTS_LOG"; }

contains_text() {
  local file="$1"
  local text="$2"
  [[ -f "$file" ]] && grep -Fq "$text" "$file"
}

sql_first_id() {
  local query="$1"
  log_command "sqlcmd $SQLCMD_ARGS ($query)"
  sqlcmd $SQLCMD_ARGS -h -1 -W -Q "SET NOCOUNT ON; $query" 2>/dev/null | tr -d '\r' | awk '/^[0-9]+$/{print; exit}'
}

sql_id_list() {
  local query="$1"
  log_command "sqlcmd $SQLCMD_ARGS ($query)"
  sqlcmd $SQLCMD_ARGS -h -1 -W -Q "SET NOCOUNT ON; $query" 2>/dev/null | tr -d '\r' | awk '/^[0-9]+$/{print}' | paste -sd, -
}

auto_resolve_inputs() {
  if [[ -z "$API_AUTH_TOKEN" ]]; then
    if ! command -v curl >/dev/null 2>&1; then
      log_output "Observed: auto_login_token=SKIP (curl missing)"
    elif ! command -v jq >/dev/null 2>&1; then
      log_output "Observed: auto_login_token=FAIL (jq required when DRY_RUN=0 and API_AUTH_TOKEN is missing)"
      exit 1
    else
      log_command "curl POST $API_BASE_URL/api/v1/auth/login (auto token)"
      local token
      token="$(curl -sS -X POST "$API_BASE_URL/api/v1/auth/login" -H "Content-Type: application/json" -d "{\"username\":\"$API_USER\",\"password\":\"$API_PASSWORD\"}" | jq -r '.token // empty' || true)"
      if [[ -n "$token" ]]; then
        API_AUTH_TOKEN="$token"
        log_output "Observed: auto_login_token=OK (API_USER=$API_USER)"
      else
        log_output "Observed: auto_login_token=FAIL (empty token)"
      fi
    fi
  fi

  if ! command -v sqlcmd >/dev/null 2>&1; then
    log_output "Observed: sqlcmd unavailable for autodiscovery."
    return
  fi

  if [[ -z "$TEST_RULE_TEMPLATE_VERSION_ID" ]]; then
    local id
    id="$(sql_first_id "SELECT TOP 1 RuleTemplateVersionId FROM dbo.RuleTemplateVersion WHERE IsDeleted=0 ORDER BY RuleTemplateVersionId DESC;" || true)"
    if [[ -n "$id" ]]; then
      TEST_RULE_TEMPLATE_VERSION_ID="$id"
      log_output "Observed: auto_rule_template_version_id=$id"
    else
      log_output "Observed: auto_rule_template_version_id=FAIL"
    fi
  fi

  if [[ -z "$TEST_DEVICE_IDS" ]]; then
    local ids
    ids="$(sql_id_list "SELECT TOP 3 DeviceId FROM dbo.Device WHERE IsDeleted=0 ORDER BY DeviceId DESC;" || true)"
    if [[ -z "$ids" ]]; then
      ids="$(sql_id_list "SELECT TOP 3 DeviceId FROM dbo.Devices WHERE IsDeleted=0 ORDER BY DeviceId DESC;" || true)"
    fi
    if [[ -n "$ids" ]]; then
      TEST_DEVICE_IDS="$ids"
      log_output "Observed: auto_test_device_ids=$ids"
    else
      log_output "Observed: auto_test_device_ids=FAIL"
    fi
  fi
}

log_output "Expected: run validates ACT-007 phase-02 backend Rules endpoints/handlers + no-regression."
log_output "Observed: run start (DRY_RUN=$DRY_RUN, API_BASE_URL=$API_BASE_URL)."

get_endpoint_file="$REPO_ROOT/telemetric-api/src/Telemetric.Api/Features/Actions/Rules/GetRules/GetRulesEndpoint.cs"
get_query_file="$REPO_ROOT/telemetric-api/src/Telemetric.Api/Features/Actions/Rules/GetRules/GetRulesQueryHandler.cs"
update_endpoint_file="$REPO_ROOT/telemetric-api/src/Telemetric.Api/Features/Actions/Rules/UpdateRuleState/UpdateRuleStateEndpoint.cs"
update_command_file="$REPO_ROOT/telemetric-api/src/Telemetric.Api/Features/Actions/Rules/UpdateRuleState/UpdateRuleStateCommandHandler.cs"
openapi_file="$REPO_ROOT/contexto/openapi/actions.yaml"
phase_summary_file="$REPO_ROOT/contexto/work/features/acciones_modulo/03_execution/ACT-007/phase-02.md"
dbcontext_file="$REPO_ROOT/telemetric-api/src/Telemetric.Api/Common/Interfaces/IApplicationDbContext.cs"

for file in \
  "$get_endpoint_file" \
  "$get_query_file" \
  "$update_endpoint_file" \
  "$update_command_file" \
  "$openapi_file" \
  "$phase_summary_file" \
  "$dbcontext_file"; do
  log_command "test -f $file"
  if [[ -f "$file" ]]; then
    log_output "Observed: file_exists[$file]=true"
  else
    log_output "Observed: file_exists[$file]=false"
  fi
done

contains_text "$phase_summary_file" "GET /api/v1/actions/rules" && log_output "Observed: phase_summary_rules_get=true" || log_output "Observed: phase_summary_rules_get=false"
contains_text "$phase_summary_file" "PATCH /api/v1/actions/rules/{ruleInstanceId}/state" && log_output "Observed: phase_summary_rules_patch=true" || log_output "Observed: phase_summary_rules_patch=false"
contains_text "$openapi_file" "/api/v1/actions/rules:" && log_output "Observed: openapi_rules_route=true" || log_output "Observed: openapi_rules_route=false"
contains_text "$openapi_file" "/api/v1/actions/devices/{deviceId}/rules:" && log_output "Observed: openapi_device_rules_route=true" || log_output "Observed: openapi_device_rules_route=false"
contains_text "$openapi_file" "/api/v1/actions/rules/{ruleInstanceId}/state:" && log_output "Observed: openapi_rule_state_route=true" || log_output "Observed: openapi_rule_state_route=false"
contains_text "$openapi_file" "x-required-policy: Actions.View" && log_output "Observed: openapi_policy_actions_view=true" || log_output "Observed: openapi_policy_actions_view=false"
contains_text "$openapi_file" "x-required-policy: Actions.Update" && log_output "Observed: openapi_policy_actions_update=true" || log_output "Observed: openapi_policy_actions_update=false"
contains_text "$openapi_file" "GetRulesResponse" && log_output "Observed: openapi_schema_get_rules_response=true" || log_output "Observed: openapi_schema_get_rules_response=false"
contains_text "$openapi_file" "RuleListItem" && log_output "Observed: openapi_schema_rule_list_item=true" || log_output "Observed: openapi_schema_rule_list_item=false"
contains_text "$openapi_file" "UpdateRuleStateRequest" && log_output "Observed: openapi_schema_update_rule_state_request=true" || log_output "Observed: openapi_schema_update_rule_state_request=false"
contains_text "$openapi_file" "UpdateRuleStateResponse" && log_output "Observed: openapi_schema_update_rule_state_response=true" || log_output "Observed: openapi_schema_update_rule_state_response=false"
contains_text "$openapi_file" "- name: status" && log_output "Observed: openapi_rules_status_param=true" || log_output "Observed: openapi_rules_status_param=false"
contains_text "$get_endpoint_file" "Get(\"/api/v1/actions/rules\")" && log_output "Observed: endpoint_get_rules_route=true" || log_output "Observed: endpoint_get_rules_route=false"
contains_text "$get_endpoint_file" "Policies(PermissionClaims.Actions.View)" && log_output "Observed: endpoint_get_rules_policy=true" || log_output "Observed: endpoint_get_rules_policy=false"
contains_text "$update_endpoint_file" "Patch(\"/api/v1/actions/rules/{RuleInstanceId}/state\")" && log_output "Observed: endpoint_update_rule_state_route=true" || log_output "Observed: endpoint_update_rule_state_route=false"
contains_text "$update_endpoint_file" "Policies(PermissionClaims.Actions.Update)" && log_output "Observed: endpoint_update_rule_state_policy=true" || log_output "Observed: endpoint_update_rule_state_policy=false"
contains_text "$get_query_file" "DeviceId" && log_output "Observed: query_device_id_filter=true" || log_output "Observed: query_device_id_filter=false"
contains_text "$get_query_file" "Status" && log_output "Observed: query_status_filter=true" || log_output "Observed: query_status_filter=false"
contains_text "$get_query_file" "ClientId" && log_output "Observed: query_tenant_scope_client_id=true" || log_output "Observed: query_tenant_scope_client_id=false"
contains_text "$get_query_file" "ActionAttempts" && log_output "Observed: query_action_attempts_source=true" || log_output "Observed: query_action_attempts_source=false"
contains_text "$get_query_file" ".AsNoTracking()" && log_output "Observed: query_as_no_tracking=true" || log_output "Observed: query_as_no_tracking=false"
contains_text "$get_query_file" "LastAttempt" && log_output "Observed: query_last_attempt_projection=true" || log_output "Observed: query_last_attempt_projection=false"
contains_text "$get_query_file" "StatusFail" && log_output "Observed: query_status_fail_signal=true" || log_output "Observed: query_status_fail_signal=false"
contains_text "$update_command_file" "RuleInstanceId <= 0" && log_output "Observed: command_validate_rule_instance_id=true" || log_output "Observed: command_validate_rule_instance_id=false"
contains_text "$update_command_file" "ClientId" && log_output "Observed: command_tenant_scope_client_id=true" || log_output "Observed: command_tenant_scope_client_id=false"
contains_text "$update_command_file" "SaveChangesAsync" && log_output "Observed: command_save_changes=true" || log_output "Observed: command_save_changes=false"
contains_text "$update_command_file" "UpdatedAt" && log_output "Observed: command_updates_updated_at=true" || log_output "Observed: command_updates_updated_at=false"
contains_text "$update_command_file" "UpdatedBy" && log_output "Observed: command_updates_updated_by=true" || log_output "Observed: command_updates_updated_by=false"
contains_text "$dbcontext_file" "DbSet<RuleInstance> RuleInstances" && log_output "Observed: dbcontext_rule_instances_dbset=true" || log_output "Observed: dbcontext_rule_instances_dbset=false"
contains_text "$dbcontext_file" "DbSet<ActionAttempt> ActionAttempts" && log_output "Observed: dbcontext_action_attempts_dbset=true" || log_output "Observed: dbcontext_action_attempts_dbset=false"

if [[ "$DRY_RUN" == "1" ]]; then
  log_command "npm --prefix $FRONTEND_DIR run typecheck"
  log_output "Observed (pending): typecheck and auto-login/sql autodiscovery skipped by DRY_RUN=1."
else
  required_checks=(
    "phase_summary_rules_get"
    "phase_summary_rules_patch"
    "openapi_rules_route"
    "openapi_rule_state_route"
    "openapi_policy_actions_view"
    "openapi_policy_actions_update"
    "endpoint_get_rules_route"
    "endpoint_get_rules_policy"
    "endpoint_update_rule_state_route"
    "endpoint_update_rule_state_policy"
    "query_device_id_filter"
    "query_status_filter"
    "query_tenant_scope_client_id"
    "query_action_attempts_source"
    "query_as_no_tracking"
    "query_last_attempt_projection"
    "query_status_fail_signal"
    "command_validate_rule_instance_id"
    "command_tenant_scope_client_id"
    "command_save_changes"
    "command_updates_updated_at"
    "command_updates_updated_by"
    "dbcontext_rule_instances_dbset"
    "dbcontext_action_attempts_dbset"
  )

  failed=()
  for check in "${required_checks[@]}"; do
    if ! grep -Fq "Observed: ${check}=true" "$OUTPUTS_LOG"; then
      failed+=("$check")
    fi
  done

  if [[ "${#failed[@]}" -gt 0 ]]; then
    failed_joined="$(IFS=", "; echo "${failed[*]}")"
    log_output "Observed: required_checks=FAIL ($failed_joined)"
    echo "Missing required checks: $failed_joined" >&2
    exit 1
  fi

  if ! grep -Fq "Observed: openapi_device_rules_route=true" "$OUTPUTS_LOG"; then
    log_output "Observed: WARN openapi_device_rules_route_missing=true"
  fi

  log_output "Observed: required_checks=PASS"

  log_command "npm --prefix $FRONTEND_DIR run typecheck"
  TYPECHECK_OUT="$(npm --prefix "$FRONTEND_DIR" run typecheck 2>&1 || true)"
  printf "%s\n" "$TYPECHECK_OUT" >> "$OUTPUTS_LOG"
  OBSERVED_ERRORS="$(printf "%s\n" "$TYPECHECK_OUT" | awk '
    /^src[\\/]/ && /error TS[0-9]+:/ && $0 !~ /^src[\\/]_demo[\\/]/ { c++ }
    END { print c+0 }')"
  log_output "Observed: no_demo_ts_errors=$OBSERVED_ERRORS"

  if [[ -n "$BASELINE_TS_ERRORS" ]]; then
    log_output "Expected: no regression no-demo -> observed <= baseline ($BASELINE_TS_ERRORS)"
    if (( OBSERVED_ERRORS > BASELINE_TS_ERRORS )); then
      log_output "Observed: gate_no_regression=FAIL (observed=$OBSERVED_ERRORS > baseline=$BASELINE_TS_ERRORS)"
      echo "No-regression gate failed: observed=$OBSERVED_ERRORS baseline=$BASELINE_TS_ERRORS" >&2
      exit 1
    fi
    log_output "Observed: gate_no_regression=PASS (observed=$OBSERVED_ERRORS <= baseline=$BASELINE_TS_ERRORS)"
  else
    log_output "Observed: baseline missing (BASELINE_TS_ERRORS). Numeric gate skipped."
  fi

  auto_resolve_inputs
fi

log_output "Observed: run finished."
