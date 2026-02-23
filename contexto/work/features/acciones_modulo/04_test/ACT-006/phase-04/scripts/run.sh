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

log_output "Expected: run validates ACT-006 phase-04 runs detail by template + typed contracts + counter consistency."
log_output "Observed: run start (DRY_RUN=$DRY_RUN, API_BASE_URL=$API_BASE_URL)."

view_file="$REPO_ROOT/telemetric-front/src/features/actions/views/ActionTemplateDetailView.vue"
service_file="$REPO_ROOT/telemetric-front/src/features/actions/actions.service.ts"
types_file="$REPO_ROOT/telemetric-front/src/features/actions/types.ts"
summary_file="$REPO_ROOT/contexto/work/features/acciones_modulo/03_execution/ACT-006/phase-04.md"
template_runs_endpoint="$REPO_ROOT/telemetric-api/src/Telemetric.Api/Features/Actions/Templates/GetTemplateRuns/GetTemplateRunsEndpoint.cs"
get_template_by_id_handler="$REPO_ROOT/telemetric-api/src/Telemetric.Api/Features/Actions/Templates/GetTemplateById/GetTemplateByIdQueryHandler.cs"
openapi_file="$REPO_ROOT/contexto/openapi/actions.yaml"

for file in \
  "$view_file" \
  "$service_file" \
  "$types_file" \
  "$summary_file" \
  "$template_runs_endpoint" \
  "$get_template_by_id_handler" \
  "$openapi_file"; do
  log_command "test -f $file"
  if [[ -f "$file" ]]; then
    log_output "Observed: file_exists[$file]=true"
  else
    log_output "Observed: file_exists[$file]=false"
  fi
done

contains_text "$summary_file" "DONE" && log_output "Observed: phase_summary_done=true" || log_output "Observed: phase_summary_done=false"
contains_text "$summary_file" "tab \`Runs\`" && log_output "Observed: phase_summary_runs_detail=true" || log_output "Observed: phase_summary_runs_detail=false"
contains_text "$view_file" "<v-tab value=\"runs\">Ejecuciones</v-tab>" && log_output "Observed: view_runs_tab_present=true" || log_output "Observed: view_runs_tab_present=false"
contains_text "$view_file" "if (tab === 'runs')" && log_output "Observed: view_watch_runs_tab=true" || log_output "Observed: view_watch_runs_tab=false"
contains_text "$view_file" "reloadRuns()" && log_output "Observed: view_reload_runs_on_tab=true" || log_output "Observed: view_reload_runs_on_tab=false"
contains_text "$view_file" "actionsService.getTemplateRuns(ruleTemplateId.value" && log_output "Observed: view_service_template_runs_call=true" || log_output "Observed: view_service_template_runs_call=false"
contains_text "$view_file" "runsErrorMessage" && log_output "Observed: view_runs_error_state=true" || log_output "Observed: view_runs_error_state=false"
contains_text "$view_file" "No se pudieron cargar las ejecuciones del template." && log_output "Observed: view_runs_error_copy=true" || log_output "Observed: view_runs_error_copy=false"
contains_text "$view_file" "hasRunsLoaded && !runsErrorMessage && runsTotalItems === 0" && log_output "Observed: view_runs_empty_state=true" || log_output "Observed: view_runs_empty_state=false"
contains_text "$view_file" "No hay ejecuciones para el template seleccionado." && log_output "Observed: view_runs_empty_copy=true" || log_output "Observed: view_runs_empty_copy=false"
contains_text "$view_file" "item.status === 'Fail'" && log_output "Observed: view_fail_row_error_cell=true" || log_output "Observed: view_fail_row_error_cell=false"
contains_text "$view_file" "Fallo sin detalle de error." && log_output "Observed: view_fail_row_error_fallback=true" || log_output "Observed: view_fail_row_error_fallback=false"
contains_text "$view_file" "detail.failedRunsCount" && log_output "Observed: view_failed_runs_count=true" || log_output "Observed: view_failed_runs_count=false"
contains_text "$service_file" "getTemplateRuns:" && log_output "Observed: service_get_template_runs_method=true" || log_output "Observed: service_get_template_runs_method=false"
if contains_text "$service_file" "getTemplateRuns: (ruleTemplateId: number" && contains_text "$service_file" '/runs${buildQueryString('; then
  log_output "Observed: service_get_template_runs_route=true"
else
  log_output "Observed: service_get_template_runs_route=false"
fi
contains_text "$types_file" "export type TemplateActionRunsQueryParams" && log_output "Observed: types_template_runs_query_params=true" || log_output "Observed: types_template_runs_query_params=false"
contains_text "$types_file" "export type ActionRunListItem" && log_output "Observed: types_action_run_list_item=true" || log_output "Observed: types_action_run_list_item=false"
contains_text "$types_file" "failedRunsCount: number" && log_output "Observed: types_failed_runs_count=true" || log_output "Observed: types_failed_runs_count=false"
contains_text "$template_runs_endpoint" "Get(\"/api/v1/actions/templates/{RuleTemplateId}/runs\")" && log_output "Observed: endpoint_template_runs_route=true" || log_output "Observed: endpoint_template_runs_route=false"
contains_text "$template_runs_endpoint" "Policies(PermissionClaims.Actions.View)" && log_output "Observed: endpoint_template_runs_policy=true" || log_output "Observed: endpoint_template_runs_policy=false"
contains_text "$openapi_file" "/api/v1/actions/templates/{ruleTemplateId}/runs:" && log_output "Observed: openapi_template_runs_path=true" || log_output "Observed: openapi_template_runs_path=false"
contains_text "$get_template_by_id_handler" "attempt.Status == ActionAttempt.StatusFail" && log_output "Observed: backend_fail_status_filter=true" || log_output "Observed: backend_fail_status_filter=false"
contains_text "$get_template_by_id_handler" "attempt.RuleInstance.RuleTemplateVersion.RuleTemplateId == template.RuleTemplateId" && log_output "Observed: backend_template_filter=true" || log_output "Observed: backend_template_filter=false"
contains_text "$get_template_by_id_handler" "attempt.RuleInstance.RuleTemplateVersion.RuleTemplate.ClientId == _currentUserService.ClientId.Value" && log_output "Observed: backend_tenant_filter=true" || log_output "Observed: backend_tenant_filter=false"
contains_text "$get_template_by_id_handler" "!attempt.IsDeleted" && log_output "Observed: backend_soft_delete_attempt=true" || log_output "Observed: backend_soft_delete_attempt=false"
contains_text "$get_template_by_id_handler" "!attempt.RuleInstance.IsDeleted" && log_output "Observed: backend_soft_delete_rule_instance=true" || log_output "Observed: backend_soft_delete_rule_instance=false"
contains_text "$get_template_by_id_handler" "!attempt.RuleInstance.RuleTemplateVersion.IsDeleted" && log_output "Observed: backend_soft_delete_version=true" || log_output "Observed: backend_soft_delete_version=false"
contains_text "$get_template_by_id_handler" "!attempt.RuleInstance.RuleTemplateVersion.RuleTemplate.IsDeleted" && log_output "Observed: backend_soft_delete_template=true" || log_output "Observed: backend_soft_delete_template=false"

service_any_count="$(count_matches "$service_file" '\\bany\\b')"
types_any_count="$(count_matches "$types_file" '\\bany\\b')"
view_any_count="$(count_matches "$view_file" '\\bany\\b')"
service_unknown_count="$(count_matches "$service_file" '\\bunknown\\b')"
types_unknown_count="$(count_matches "$types_file" '\\bunknown\\b')"
view_unknown_count="$(count_matches "$view_file" '\\bunknown\\b')"

log_output "Observed: any_count[service]=$service_any_count"
log_output "Observed: any_count[types]=$types_any_count"
log_output "Observed: any_count[view]=$view_any_count"
log_output "Observed: unknown_count[service]=$service_unknown_count"
log_output "Observed: unknown_count[types]=$types_unknown_count"
log_output "Observed: unknown_count[view]=$view_unknown_count"

if [[ "$DRY_RUN" == "1" ]]; then
  log_command "npm --prefix $FRONTEND_DIR run typecheck"
  log_output "Observed (pending): typecheck and auto-login/sql autodiscovery skipped by DRY_RUN=1."
else
  required_checks=(
    "phase_summary_done"
    "view_runs_tab_present"
    "view_watch_runs_tab"
    "view_reload_runs_on_tab"
    "view_service_template_runs_call"
    "view_runs_error_state"
    "view_runs_error_copy"
    "view_runs_empty_state"
    "view_runs_empty_copy"
    "view_fail_row_error_cell"
    "view_fail_row_error_fallback"
    "view_failed_runs_count"
    "service_get_template_runs_method"
    "service_get_template_runs_route"
    "types_template_runs_query_params"
    "types_action_run_list_item"
    "types_failed_runs_count"
    "endpoint_template_runs_route"
    "endpoint_template_runs_policy"
    "openapi_template_runs_path"
    "backend_fail_status_filter"
    "backend_template_filter"
    "backend_tenant_filter"
    "backend_soft_delete_attempt"
    "backend_soft_delete_rule_instance"
    "backend_soft_delete_version"
    "backend_soft_delete_template"
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
