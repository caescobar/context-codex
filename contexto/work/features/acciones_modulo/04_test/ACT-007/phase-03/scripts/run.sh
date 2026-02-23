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

count_matches() {
  local file="$1"
  local pattern="$2"
  if [[ ! -f "$file" ]]; then
    echo "0"
    return
  fi
  grep -Eo "$pattern" "$file" | wc -l | tr -d ' '
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
    if ! command -v jq >/dev/null 2>&1; then
      log_output "Observed: auto_login_token=SKIP (jq missing)"
    elif command -v curl >/dev/null 2>&1; then
      log_command "curl POST $API_BASE_URL/api/v1/auth/login (auto token)"
      token="$(curl -sS -X POST "$API_BASE_URL/api/v1/auth/login" -H "Content-Type: application/json" -d "{\"username\":\"$API_USER\",\"password\":\"$API_PASSWORD\"}" | jq -r '.token // empty' || true)"
      if [[ -n "$token" ]]; then
        API_AUTH_TOKEN="$token"
        log_output "Observed: auto_login_token=OK (API_USER=$API_USER)"
      else
        log_output "Observed: auto_login_token=FAIL (empty token)"
      fi
    else
      log_output "Observed: auto_login_token=SKIP (curl missing)"
    fi
  fi

  if ! command -v sqlcmd >/dev/null 2>&1; then
    log_output "Observed: sqlcmd unavailable for autodiscovery."
    return
  fi

  if [[ -z "$TEST_RULE_TEMPLATE_VERSION_ID" ]]; then
    id="$(sql_first_id "SELECT TOP 1 RuleTemplateVersionId FROM dbo.RuleTemplateVersion WHERE IsDeleted=0 ORDER BY RuleTemplateVersionId DESC;" || true)"
    if [[ -n "$id" ]]; then
      TEST_RULE_TEMPLATE_VERSION_ID="$id"
      log_output "Observed: auto_rule_template_version_id=$id"
    else
      log_output "Observed: auto_rule_template_version_id=FAIL"
    fi
  fi

  if [[ -z "$TEST_DEVICE_IDS" ]]; then
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

log_output "Expected: run validates ACT-007 phase-03 frontend rules tab + badge fail + toggle + no-regression."
log_output "Observed: run start (DRY_RUN=$DRY_RUN, API_BASE_URL=$API_BASE_URL)."

view_file="$REPO_ROOT/telemetric-front/src/features/actions/views/ActionsTemplatesView.vue"
service_file="$REPO_ROOT/telemetric-front/src/features/actions/actions.service.ts"
types_file="$REPO_ROOT/telemetric-front/src/features/actions/types.ts"
routes_file="$REPO_ROOT/telemetric-front/src/features/actions/actions.routes.ts"
menu_file="$REPO_ROOT/telemetric-front/src/layouts/menuItems.ts"
summary_file="$REPO_ROOT/contexto/work/features/acciones_modulo/03_execution/ACT-007/phase-03.md"
get_rules_endpoint="$REPO_ROOT/telemetric-api/src/Telemetric.Api/Features/Actions/Rules/GetRules/GetRulesEndpoint.cs"
update_state_endpoint="$REPO_ROOT/telemetric-api/src/Telemetric.Api/Features/Actions/Rules/UpdateRuleState/UpdateRuleStateEndpoint.cs"

for file in \
  "$view_file" \
  "$service_file" \
  "$types_file" \
  "$routes_file" \
  "$menu_file" \
  "$summary_file" \
  "$get_rules_endpoint" \
  "$update_state_endpoint"; do
  log_command "test -f $file"
  if [[ -f "$file" ]]; then
    log_output "Observed: file_exists[$file]=true"
  else
    log_output "Observed: file_exists[$file]=false"
  fi
done

contains_text "$summary_file" "DONE" && log_output "Observed: phase_summary_done=true" || log_output "Observed: phase_summary_done=false"
contains_text "$summary_file" "tab \`Rules\`" && log_output "Observed: phase_summary_rules_tab=true" || log_output "Observed: phase_summary_rules_tab=false"
contains_text "$summary_file" "badge rojo" && log_output "Observed: phase_summary_badge=true" || log_output "Observed: phase_summary_badge=false"
contains_text "$summary_file" "updateRuleState" && log_output "Observed: phase_summary_toggle=true" || log_output "Observed: phase_summary_toggle=false"

contains_text "$view_file" "<v-tab value=\"rules\">Rules</v-tab>" && log_output "Observed: view_rules_tab_present=true" || log_output "Observed: view_rules_tab_present=false"
contains_text "$view_file" "activeTab = ref<'runs' | 'rules' | 'templates'>('runs')" && log_output "Observed: view_active_tab_rules=true" || log_output "Observed: view_active_tab_rules=false"
contains_text "$view_file" "const rulesFilterSchema" && log_output "Observed: view_rules_filter_schema=true" || log_output "Observed: view_rules_filter_schema=false"
contains_text "$view_file" "rulesErrorMessage" && log_output "Observed: view_rules_error_state=true" || log_output "Observed: view_rules_error_state=false"
contains_text "$view_file" "No se pudieron cargar las reglas." && log_output "Observed: view_rules_error_copy=true" || log_output "Observed: view_rules_error_copy=false"
contains_text "$view_file" "No hay reglas para los filtros seleccionados." && log_output "Observed: view_rules_empty_state=true" || log_output "Observed: view_rules_empty_state=false"
contains_text "$view_file" "rulesTableProps" && log_output "Observed: view_rules_table=true" || log_output "Observed: view_rules_table=false"
contains_text "$view_file" "UiDynamicFilter" && log_output "Observed: view_ui_dynamic_filter=true" || log_output "Observed: view_ui_dynamic_filter=false"
contains_text "$view_file" "UiServerTable" && log_output "Observed: view_ui_server_table=true" || log_output "Observed: view_ui_server_table=false"
contains_text "$view_file" "Enabled" && contains_text "$view_file" "Paused" && log_output "Observed: view_rules_status_values=true" || log_output "Observed: view_rules_status_values=false"
contains_text "$view_file" "item.hasLastAttemptFail" && log_output "Observed: view_badge_flag=true" || log_output "Observed: view_badge_flag=false"
contains_text "$view_file" "Ultimo fail" && log_output "Observed: view_badge_chip=true" || log_output "Observed: view_badge_chip=false"
contains_text "$view_file" "Fail sin detalle de error." && log_output "Observed: view_last_fail_fallback=true" || log_output "Observed: view_last_fail_fallback=false"
contains_text "$view_file" "updateRuleState(item, !item.isPaused)" && log_output "Observed: view_update_rule_state_action=true" || log_output "Observed: view_update_rule_state_action=false"
contains_text "$view_file" "Actions.Update" && log_output "Observed: view_actions_update_permission=true" || log_output "Observed: view_actions_update_permission=false"
contains_text "$view_file" "await reloadRules()" && log_output "Observed: view_reload_rules_after_toggle=true" || log_output "Observed: view_reload_rules_after_toggle=false"

contains_text "$service_file" "getRules:" && log_output "Observed: service_get_rules_method=true" || log_output "Observed: service_get_rules_method=false"
contains_text "$service_file" "updateRuleState:" && log_output "Observed: service_update_rule_state_method=true" || log_output "Observed: service_update_rule_state_method=false"
contains_text "$service_file" "/actions/rules" && log_output "Observed: service_rules_route=true" || log_output "Observed: service_rules_route=false"
contains_text "$service_file" "/actions/rules/${payload.ruleInstanceId}/state" && log_output "Observed: service_rules_patch_route=true" || log_output "Observed: service_rules_patch_route=false"

contains_text "$types_file" "export type ActionRulesQueryParams" && log_output "Observed: types_rules_query_params=true" || log_output "Observed: types_rules_query_params=false"
contains_text "$types_file" "export type ActionRuleListItem" && log_output "Observed: types_rule_list_item=true" || log_output "Observed: types_rule_list_item=false"
contains_text "$types_file" "export type RuleOperationalStatus" && log_output "Observed: types_rule_operational_status=true" || log_output "Observed: types_rule_operational_status=false"
contains_text "$types_file" "export type UpdateRuleStateRequest" && log_output "Observed: types_update_rule_state_request=true" || log_output "Observed: types_update_rule_state_request=false"
contains_text "$types_file" "export type UpdateRuleStateResponse" && log_output "Observed: types_update_rule_state_response=true" || log_output "Observed: types_update_rule_state_response=false"
contains_text "$types_file" "hasLastAttemptFail" && log_output "Observed: types_last_attempt_fail_flag=true" || log_output "Observed: types_last_attempt_fail_flag=false"

contains_text "$routes_file" "path: '/actions'" && log_output "Observed: route_actions_path=true" || log_output "Observed: route_actions_path=false"
contains_text "$routes_file" "requiresPermission: 'Actions.View'" && log_output "Observed: route_actions_permission=true" || log_output "Observed: route_actions_permission=false"
contains_text "$menu_file" "to: '/actions'" && log_output "Observed: menu_actions_path=true" || log_output "Observed: menu_actions_path=false"
contains_text "$menu_file" "requiresPermission: 'Actions.View'" && log_output "Observed: menu_actions_permission=true" || log_output "Observed: menu_actions_permission=false"

contains_text "$get_rules_endpoint" "Get(\"/api/v1/actions/rules\")" && log_output "Observed: backend_rules_route=true" || log_output "Observed: backend_rules_route=false"
contains_text "$get_rules_endpoint" "Policies(PermissionClaims.Actions.View)" && log_output "Observed: backend_rules_policy=true" || log_output "Observed: backend_rules_policy=false"
contains_text "$update_state_endpoint" "Patch(\"/api/v1/actions/rules/{RuleInstanceId}/state\")" && log_output "Observed: backend_update_route=true" || log_output "Observed: backend_update_route=false"
contains_text "$update_state_endpoint" "Policies(PermissionClaims.Actions.Update)" && log_output "Observed: backend_update_policy=true" || log_output "Observed: backend_update_policy=false"

service_any_count="$(count_matches "$service_file" '\\bany\\b')"
types_any_count="$(count_matches "$types_file" '\\bany\\b')"
view_any_count="$(count_matches "$view_file" '\\bany\\b')"

log_output "Observed: any_count[service]=$service_any_count"
log_output "Observed: any_count[types]=$types_any_count"
log_output "Observed: any_count[view]=$view_any_count"

if [[ "$DRY_RUN" == "1" ]]; then
  log_command "npm --prefix $FRONTEND_DIR run typecheck"
  log_output "Observed (pending): typecheck and auto-login/sql autodiscovery skipped by DRY_RUN=1."
else
  required_checks=(
    "phase_summary_done"
    "phase_summary_rules_tab"
    "phase_summary_badge"
    "phase_summary_toggle"
    "view_rules_tab_present"
    "view_active_tab_rules"
    "view_rules_filter_schema"
    "view_rules_error_state"
    "view_rules_error_copy"
    "view_rules_empty_state"
    "view_rules_table"
    "view_ui_dynamic_filter"
    "view_ui_server_table"
    "view_rules_status_values"
    "view_badge_flag"
    "view_badge_chip"
    "view_last_fail_fallback"
    "view_update_rule_state_action"
    "view_actions_update_permission"
    "view_reload_rules_after_toggle"
    "service_get_rules_method"
    "service_update_rule_state_method"
    "service_rules_route"
    "service_rules_patch_route"
    "types_rules_query_params"
    "types_rule_list_item"
    "types_rule_operational_status"
    "types_update_rule_state_request"
    "types_update_rule_state_response"
    "types_last_attempt_fail_flag"
    "route_actions_path"
    "route_actions_permission"
    "menu_actions_path"
    "menu_actions_permission"
    "backend_rules_route"
    "backend_rules_policy"
    "backend_update_route"
    "backend_update_policy"
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

  any_total=$((service_any_count + types_any_count + view_any_count))
  if [[ "$any_total" -gt 0 ]]; then
    log_output "Observed: any_guard=FAIL (any detected in scope files)"
    echo "Any detected in scope files." >&2
    exit 1
  fi

  log_output "Observed: any_guard=PASS (no any in scope files)"
  log_output "Observed: required_checks=PASS"

  log_command "npm --prefix $FRONTEND_DIR run typecheck"
  TYPECHECK_OUT="$(npm --prefix "$FRONTEND_DIR" run typecheck 2>&1 || true)"
  printf "%s\n" "$TYPECHECK_OUT" >> "$OUTPUTS_LOG"
  OBSERVED_ERRORS="$(printf "%s\n" "$TYPECHECK_OUT" | awk '
    /^src[\\/]/ && /error TS[0-9]+:/ && $0 !~ /^src[\\/]_demo[\\/]/ { c++ }
    END { print c+0 }'
  )"
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

  if [[ -z "$API_AUTH_TOKEN" ]] && ! command -v jq >/dev/null 2>&1; then
    echo "Missing required tool for DRY_RUN=0 auto-login parsing: jq" >&2
    exit 1
  fi
  auto_resolve_inputs
fi

log_output "Observed: run finished."
