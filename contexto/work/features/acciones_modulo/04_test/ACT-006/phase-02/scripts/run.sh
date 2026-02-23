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
    if command -v curl >/dev/null 2>&1; then
      log_command "curl POST $API_BASE_URL/api/v1/auth/login (auto token)"
      if command -v jq >/dev/null 2>&1; then
        local token
        token="$(curl -sS -X POST "$API_BASE_URL/api/v1/auth/login" -H "Content-Type: application/json" -d "{\"username\":\"$API_USER\",\"password\":\"$API_PASSWORD\"}" | jq -r '.token // empty' || true)"
        if [[ -n "$token" ]]; then
          API_AUTH_TOKEN="$token"
          log_output "Observed: auto_login_token=OK (API_USER=$API_USER)"
        else
          log_output "Observed: auto_login_token=FAIL (empty token)"
        fi
      else
        log_output "Observed: auto_login_token=SKIP (jq missing)"
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

log_output "Expected: run validates ACT-006 phase-02 backend runs endpoints/queries + no-regression."
log_output "Observed: run start (DRY_RUN=$DRY_RUN, API_BASE_URL=$API_BASE_URL)."

global_endpoint_file="$REPO_ROOT/telemetric-api/src/Telemetric.Api/Features/Actions/Runs/GetRuns/GetRunsEndpoint.cs"
global_query_file="$REPO_ROOT/telemetric-api/src/Telemetric.Api/Features/Actions/Runs/GetRuns/GetRunsQueryHandler.cs"
template_endpoint_file="$REPO_ROOT/telemetric-api/src/Telemetric.Api/Features/Actions/Templates/GetTemplateRuns/GetTemplateRunsEndpoint.cs"
template_query_file="$REPO_ROOT/telemetric-api/src/Telemetric.Api/Features/Actions/Templates/GetTemplateRuns/GetTemplateRunsQueryHandler.cs"
openapi_file="$REPO_ROOT/contexto/openapi/actions.yaml"
phase_summary_file="$REPO_ROOT/contexto/work/features/acciones_modulo/03_execution/ACT-006/phase-02.md"
dbcontext_file="$REPO_ROOT/telemetric-api/src/Telemetric.Api/Common/Interfaces/IApplicationDbContext.cs"

for file in \
  "$global_endpoint_file" \
  "$global_query_file" \
  "$template_endpoint_file" \
  "$template_query_file" \
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

contains_text "$phase_summary_file" "runs" && log_output "Observed: phase_summary_has_runs_context=true" || log_output "Observed: phase_summary_has_runs_context=false"
contains_text "$openapi_file" "/api/v1/actions/runs:" && log_output "Observed: openapi_global_runs_route=true" || log_output "Observed: openapi_global_runs_route=false"
contains_text "$openapi_file" "/api/v1/actions/templates/{ruleTemplateId}/runs:" && log_output "Observed: openapi_template_runs_route=true" || log_output "Observed: openapi_template_runs_route=false"
contains_text "$openapi_file" "x-required-policy: Actions.View" && log_output "Observed: openapi_actions_view_policy=true" || log_output "Observed: openapi_actions_view_policy=false"
contains_text "$global_endpoint_file" "Get(\"/api/v1/actions/runs\")" && log_output "Observed: endpoint_global_route=true" || log_output "Observed: endpoint_global_route=false"
contains_text "$template_endpoint_file" "Get(\"/api/v1/actions/templates/{RuleTemplateId}/runs\")" && log_output "Observed: endpoint_template_route=true" || log_output "Observed: endpoint_template_route=false"
contains_text "$global_endpoint_file" "Policies(PermissionClaims.Actions.View)" && log_output "Observed: endpoint_global_policy=true" || log_output "Observed: endpoint_global_policy=false"
contains_text "$template_endpoint_file" "Policies(PermissionClaims.Actions.View)" && log_output "Observed: endpoint_template_policy=true" || log_output "Observed: endpoint_template_policy=false"
contains_text "$global_query_file" "_context.ActionAttempts" && log_output "Observed: query_global_action_attempts_source=true" || log_output "Observed: query_global_action_attempts_source=false"
contains_text "$template_query_file" "_context.ActionAttempts" && log_output "Observed: query_template_action_attempts_source=true" || log_output "Observed: query_template_action_attempts_source=false"
contains_text "$global_query_file" ".AsNoTracking()" && log_output "Observed: query_global_as_no_tracking=true" || log_output "Observed: query_global_as_no_tracking=false"
contains_text "$template_query_file" ".AsNoTracking()" && log_output "Observed: query_template_as_no_tracking=true" || log_output "Observed: query_template_as_no_tracking=false"
contains_text "$global_query_file" "OrderByDescending" && log_output "Observed: query_global_order_desc=true" || log_output "Observed: query_global_order_desc=false"
contains_text "$template_query_file" "OrderByDescending" && log_output "Observed: query_template_order_desc=true" || log_output "Observed: query_template_order_desc=false"
if contains_text "$template_query_file" "RuleTemplateId" || contains_text "$template_query_file" "request.RuleTemplateId"; then
  log_output "Observed: query_template_rule_template_filter=true"
else
  log_output "Observed: query_template_rule_template_filter=false"
fi
if contains_text "$global_query_file" "ClientId" || contains_text "$template_query_file" "ClientId"; then
  log_output "Observed: query_tenant_scope_client_id=true"
else
  log_output "Observed: query_tenant_scope_client_id=false"
fi
contains_text "$dbcontext_file" "DbSet<ActionAttempt> ActionAttempts" && log_output "Observed: dbcontext_action_attempts_dbset=true" || log_output "Observed: dbcontext_action_attempts_dbset=false"

if [[ "$DRY_RUN" == "1" ]]; then
  log_command "npm --prefix $FRONTEND_DIR run typecheck"
  log_output "Observed (pending): typecheck and auto-login/sql autodiscovery skipped by DRY_RUN=1."
else
  required_checks=(
    "openapi_global_runs_route"
    "openapi_template_runs_route"
    "openapi_actions_view_policy"
    "endpoint_global_route"
    "endpoint_template_route"
    "endpoint_global_policy"
    "endpoint_template_policy"
    "query_global_action_attempts_source"
    "query_template_action_attempts_source"
    "query_global_as_no_tracking"
    "query_template_as_no_tracking"
    "query_global_order_desc"
    "query_template_order_desc"
    "query_template_rule_template_filter"
    "query_tenant_scope_client_id"
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

  auto_resolve_inputs
fi

log_output "Observed: run finished."
