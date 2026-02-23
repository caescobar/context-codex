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

run_step() {
  local cmd="$1"
  log_command "$cmd"
  if [[ "$DRY_RUN" == "1" ]]; then
    echo "[DRY_RUN] $cmd"
    log_output "Observed (pending): DRY_RUN=1 skipped command."
    return
  fi
  echo "[EXEC] $cmd"
  bash -lc "$cmd" | tee -a "$OUTPUTS_LOG"
}

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

log_output "Expected: run validates ACT-006 phase-01 discovery/equivalence and OpenAPI contract."
log_output "Observed: run start (DRY_RUN=$DRY_RUN, API_BASE_URL=$API_BASE_URL)."

OPENAPI_FILE="$REPO_ROOT/contexto/openapi/actions.yaml"
ENDPOINT_FILE_1="$REPO_ROOT/telemetric-api/src/Telemetric.Api/Features/Actions/Templates/GetTemplates/GetTemplatesEndpoint.cs"
ENDPOINT_FILE_2="$REPO_ROOT/telemetric-api/src/Telemetric.Api/Features/Actions/Templates/GetTemplateById/GetTemplateByIdEndpoint.cs"
PHASE_SUMMARY_FILE="$REPO_ROOT/contexto/work/features/acciones_modulo/03_execution/ACT-006/phase-01.md"

contains_text "$PHASE_SUMMARY_FILE" "no existe endpoint equivalente de runs" && log_output "Observed: phase_summary_equivalence_note=true" || log_output "Observed: phase_summary_equivalence_note=false"
contains_text "$OPENAPI_FILE" "/api/v1/actions/runs:" && log_output "Observed: openapi_runs_global=true" || log_output "Observed: openapi_runs_global=false"
contains_text "$OPENAPI_FILE" "/api/v1/actions/templates/{ruleTemplateId}/runs:" && log_output "Observed: openapi_runs_template=true" || log_output "Observed: openapi_runs_template=false"
contains_text "$OPENAPI_FILE" "x-required-policy: Actions.View" && log_output "Observed: openapi_policy_actions_view=true" || log_output "Observed: openapi_policy_actions_view=false"
contains_text "$OPENAPI_FILE" "ActionRunListItem" && log_output "Observed: openapi_schema_action_run_list_item=true" || log_output "Observed: openapi_schema_action_run_list_item=false"
contains_text "$OPENAPI_FILE" "ActionRunStatus" && log_output "Observed: openapi_schema_action_run_status=true" || log_output "Observed: openapi_schema_action_run_status=false"
contains_text "$OPENAPI_FILE" "ActionRunContext" && log_output "Observed: openapi_schema_action_run_context=true" || log_output "Observed: openapi_schema_action_run_context=false"
contains_text "$OPENAPI_FILE" "status:" && log_output "Observed: payload_field_status=true" || log_output "Observed: payload_field_status=false"
contains_text "$OPENAPI_FILE" "error:" && log_output "Observed: payload_field_error=true" || log_output "Observed: payload_field_error=false"
contains_text "$OPENAPI_FILE" "attemptedAt:" && log_output "Observed: payload_field_attemptedAt=true" || log_output "Observed: payload_field_attemptedAt=false"
contains_text "$OPENAPI_FILE" "ruleInstanceId:" && log_output "Observed: payload_field_ruleInstanceId=true" || log_output "Observed: payload_field_ruleInstanceId=false"
contains_text "$OPENAPI_FILE" "context:" && log_output "Observed: payload_field_context=true" || log_output "Observed: payload_field_context=false"
contains_text "$OPENAPI_FILE" "/api/v1/actions/" && log_output "Observed: openapi_v1_prefix=true" || log_output "Observed: openapi_v1_prefix=false"
contains_text "$ENDPOINT_FILE_1" "Policies(PermissionClaims.Actions.View)" && log_output "Observed: backend_policy_templates_get=true" || log_output "Observed: backend_policy_templates_get=false"
contains_text "$ENDPOINT_FILE_2" "Policies(PermissionClaims.Actions.View)" && log_output "Observed: backend_policy_template_by_id=true" || log_output "Observed: backend_policy_template_by_id=false"

pushd "$REPO_ROOT" >/dev/null
if [[ "$DRY_RUN" == "0" ]]; then
  log_command "rg --line-number -g '*.cs' -e '/api/v1/actions/runs' -e '/api/v1/actions/templates/{ruleTemplateId}/runs' telemetric-api/src/Telemetric.Api/Features/Actions"
  RUN_MATCHES="$(rg --line-number -g '*.cs' -e '/api/v1/actions/runs' -e '/api/v1/actions/templates/{ruleTemplateId}/runs' telemetric-api/src/Telemetric.Api/Features/Actions || true)"
  if [[ -z "$RUN_MATCHES" ]]; then
    log_output "Observed: backend_runs_equivalence=PASS (no equivalent endpoint found)."
  else
    log_output "Observed: backend_runs_equivalence=FAIL (unexpected matches found)."
    printf "%s\n" "$RUN_MATCHES" >> "$OUTPUTS_LOG"
    popd >/dev/null
    exit 1
  fi

  run_step "rg --line-number -F -e 'x-required-policy: Actions.View' contexto/openapi/actions.yaml"

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
      popd >/dev/null
      exit 1
    fi
    log_output "Observed: gate_no_regression=PASS (observed=$OBSERVED_ERRORS <= baseline=$BASELINE_TS_ERRORS)"
  else
    log_output "Observed: baseline missing (BASELINE_TS_ERRORS). Numeric gate skipped."
  fi

  auto_resolve_inputs
else
  log_output "Observed (pending): backend equivalence execution, typecheck and auto-login/sql autodiscovery skipped by DRY_RUN=1."
fi
popd >/dev/null

log_output "Observed: run finished."
