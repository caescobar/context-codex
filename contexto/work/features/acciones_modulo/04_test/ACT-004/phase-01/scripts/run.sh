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

COMMANDS_LOG="$EVIDENCE_DIR/commands.log"
OUTPUTS_LOG="$EVIDENCE_DIR/outputs.log"
BASELINE_FILE="$PACK_DIR/baseline.json"

mkdir -p "$EVIDENCE_DIR"
touch "$COMMANDS_LOG" "$OUTPUTS_LOG"

log_command() {
  echo "$(date -Iseconds) | $1" >> "$COMMANDS_LOG"
}

log_output() {
  echo "$(date -Iseconds) | $1" >> "$OUTPUTS_LOG"
}

contains_text() {
  local file="$1"
  local text="$2"
  if [[ ! -f "$file" ]]; then
    echo "false"
    return
  fi
  if grep -Fq "$text" "$file"; then
    echo "true"
  else
    echo "false"
  fi
}

log_output "Expected: run valida criterios ACT-004 phase-01 (endpoint, policy, duplicados, scope, no-regresion)."
log_output "Observed: inicio run (DRY_RUN=$DRY_RUN, API_BASE_URL=$API_BASE_URL)."

candidate_files=(
  "telemetric-api/src/Telemetric.Api/Features/Actions/Assignments/AssignTemplateToDevices/AssignTemplateToDevicesEndpoint.cs"
  "telemetric-api/src/Telemetric.Api/Features/Actions/Assignments/AssignTemplateToDevices/AssignTemplateToDevicesCommandHandler.cs"
  "telemetric-api/src/Telemetric.Api/Domain/Constants/PermissionClaims.cs"
  "contexto/openapi/actions.yaml"
  "contexto/work/features/acciones_modulo/03_execution/ACT-004/phase-01.md"
)

for rel in "${candidate_files[@]}"; do
  log_command "test -f $rel"
  if [[ -f "$REPO_ROOT/$rel" ]]; then
    log_output "Observed: file_exists[$rel]=true"
  else
    log_output "Observed: file_exists[$rel]=false"
  fi
done

endpoint_file="$REPO_ROOT/telemetric-api/src/Telemetric.Api/Features/Actions/Assignments/AssignTemplateToDevices/AssignTemplateToDevicesEndpoint.cs"
handler_file="$REPO_ROOT/telemetric-api/src/Telemetric.Api/Features/Actions/Assignments/AssignTemplateToDevices/AssignTemplateToDevicesCommandHandler.cs"
claims_file="$REPO_ROOT/telemetric-api/src/Telemetric.Api/Domain/Constants/PermissionClaims.cs"
openapi_file="$REPO_ROOT/contexto/openapi/actions.yaml"
sql_file="$REPO_ROOT/telemetric-api/scripts/012_create_actions_schema.sql"
phase_summary_file="$REPO_ROOT/contexto/work/features/acciones_modulo/03_execution/ACT-004/phase-01.md"

has_endpoint="$(contains_text "$endpoint_file" 'Post("/api/v1/actions/assignments/template-version")')"
has_policy_endpoint="$(contains_text "$endpoint_file" 'PermissionClaims.Actions.Assign')"
has_policy_constant="$(contains_text "$claims_file" 'public const string Assign = "Actions.Assign";')"
has_openapi_path="$(contains_text "$openapi_file" '/api/v1/actions/assignments/template-version')"
has_reuse_trace="$(contains_text "$phase_summary_file" 'Reuse-first')"
has_status_created="$(contains_text "$handler_file" 'public const string Created = "Created";')"
has_status_duplicate="$(contains_text "$handler_file" 'public const string RejectedDuplicate = "RejectedDuplicate";')"
has_status_outofscope="$(contains_text "$handler_file" 'public const string RejectedNotFoundOrOutOfScope = "RejectedNotFoundOrOutOfScope";')"
has_distinct_input="$(contains_text "$handler_file" '.Distinct()')"
has_scope_guard="$(contains_text "$handler_file" '_currentUserService.ClientId')"
has_unique_index="$(contains_text "$sql_file" 'UQ_RuleInstance_Device_TemplateVersion')"

if [[ "$has_status_created" == "true" && "$has_status_duplicate" == "true" && "$has_status_outofscope" == "true" ]]; then
  has_statuses="true"
else
  has_statuses="false"
fi

log_output "Observed: endpoint_exists=$has_endpoint"
log_output "Observed: endpoint_policy_assign=$has_policy_endpoint"
log_output "Observed: permission_claim_assign_constant=$has_policy_constant"
log_output "Observed: openapi_contains_assignment_path=$has_openapi_path"
log_output "Observed: reuse_first_trace_in_phase_summary=$has_reuse_trace"
log_output "Observed: statuses_created_duplicate_outofscope=$has_statuses"
log_output "Observed: handler_deduplicates_input=$has_distinct_input"
log_output "Observed: handler_scope_guard=$has_scope_guard"
log_output "Observed: sql_unique_index_guard=$has_unique_index"

if [[ "$DRY_RUN" == "1" ]]; then
  log_command "npm --prefix $FRONTEND_DIR run typecheck"
  log_command "read baseline from baseline.json"
  log_output "Observed (pendiente): typecheck no ejecutado por DRY_RUN=1."
  log_output "Observed (pendiente): gate no-regresion no evaluado por DRY_RUN=1."
  log_output "Observed (pendiente): prueba API integrada no ejecutada por DRY_RUN=1."
else
  if ! command -v jq >/dev/null 2>&1; then
    log_output "Observed: jq no disponible y DRY_RUN=0 requiere parser JSON."
    echo "Missing required tool: jq" >&2
    exit 1
  fi

  if [[ ! -f "$BASELINE_FILE" ]]; then
    log_output "Observed: baseline no encontrado en $BASELINE_FILE"
    echo "Baseline file missing: $BASELINE_FILE" >&2
    exit 1
  fi

  baseline_errors="$(jq -r '.ts_errors' "$BASELINE_FILE")"
  baseline_scope="$(jq -r '.scope' "$BASELINE_FILE")"
  if [[ -z "$baseline_errors" || "$baseline_errors" == "null" ]]; then
    log_output "Observed: baseline invalido en $BASELINE_FILE"
    echo "Invalid baseline file: $BASELINE_FILE" >&2
    exit 1
  fi

  log_output "Observed: baseline_scope=${baseline_scope:-unknown}, baseline_ts_errors=$baseline_errors"

  pushd "$REPO_ROOT" >/dev/null
  log_command "npm --prefix $FRONTEND_DIR run typecheck"
  tmp_out="$(mktemp)"
  set +e
  npm --prefix "$FRONTEND_DIR" run typecheck >"$tmp_out" 2>&1
  typecheck_exit=$?
  set -e
  cat "$tmp_out" | tee -a "$OUTPUTS_LOG"

  observed_errors="$(grep -E '^src[\\/].*error TS[0-9]+:' "$tmp_out" | grep -Ev '^src[\\/]_demo[\\/]' | wc -l | tr -d ' ')"
  rm -f "$tmp_out"
  popd >/dev/null

  log_output "Observed: typecheck_exit_code=$typecheck_exit"
  log_output "Expected: no-regresion no-demo => observed <= baseline ($baseline_errors)"
  log_output "Observed: no_demo_ts_errors=$observed_errors"

  if [[ "$observed_errors" -gt "$baseline_errors" ]]; then
    log_output "Observed: gate_no_regresion=FAIL (observed=$observed_errors > baseline=$baseline_errors)"
    echo "No-regression gate failed: observed=$observed_errors baseline=$baseline_errors" >&2
    exit 1
  fi

  log_output "Observed: gate_no_regresion=PASS (observed=$observed_errors <= baseline=$baseline_errors)"

  if [[ -z "$API_AUTH_TOKEN" ]]; then
    login_url="${API_BASE_URL%/}/api/v1/auth/login"
    log_command "curl -sS -X POST $login_url (auto token)"
    login_resp="$(curl -sS -X POST "$login_url" -H "Content-Type: application/json" --data "{\"username\":\"$API_USER\",\"password\":\"$API_PASSWORD\"}" || true)"
    api_token="$(echo "$login_resp" | jq -r '.token // empty' 2>/dev/null || true)"
    if [[ -n "$api_token" ]]; then
      API_AUTH_TOKEN="$api_token"
      log_output "Observed: auto_login_token=OK (API_USER=$API_USER)"
    else
      log_output "Observed: auto_login_token=FAIL"
    fi
  fi

  if [[ -z "$TEST_RULE_TEMPLATE_VERSION_ID" ]] && command -v sqlcmd >/dev/null 2>&1; then
    log_command "sqlcmd $SQLCMD_ARGS (autodiscovery TEST_RULE_TEMPLATE_VERSION_ID)"
    rtv_id="$(sqlcmd $SQLCMD_ARGS -h -1 -W -Q "SET NOCOUNT ON; SELECT TOP 1 RuleTemplateVersionId FROM dbo.RuleTemplateVersion WHERE IsDeleted=0 ORDER BY RuleTemplateVersionId DESC;" | tr -d '\r' | awk '/^[0-9]+$/{print; exit}')"
    if [[ -n "$rtv_id" ]]; then
      TEST_RULE_TEMPLATE_VERSION_ID="$rtv_id"
      log_output "Observed: auto_rule_template_version_id=$TEST_RULE_TEMPLATE_VERSION_ID"
    fi
  fi

  if [[ -z "$TEST_DEVICE_IDS" ]] && command -v sqlcmd >/dev/null 2>&1; then
    log_command "sqlcmd $SQLCMD_ARGS (autodiscovery TEST_DEVICE_IDS)"
    device_ids="$(sqlcmd $SQLCMD_ARGS -h -1 -W -Q "SET NOCOUNT ON; SELECT TOP 3 DeviceId FROM dbo.Device WHERE IsDeleted=0 ORDER BY DeviceId DESC;" | tr -d '\r' | awk '/^[0-9]+$/{print}' | paste -sd, -)"
    if [[ -n "$device_ids" ]]; then
      TEST_DEVICE_IDS="$device_ids"
      log_output "Observed: auto_test_device_ids=$TEST_DEVICE_IDS"
    fi
  fi

  if [[ -z "$API_AUTH_TOKEN" || -z "$TEST_RULE_TEMPLATE_VERSION_ID" || -z "$TEST_DEVICE_IDS" ]]; then
    log_output "Observed: prueba API integrada omitida (faltan API_AUTH_TOKEN / TEST_RULE_TEMPLATE_VERSION_ID / TEST_DEVICE_IDS)."
  else
    device_ids_json="$(echo "$TEST_DEVICE_IDS" | awk -F',' '{for(i=1;i<=NF;i++){gsub(/^[ \t]+|[ \t]+$/,"",$i); if($i ~ /^[0-9]+$/){printf "%s%s", (c++?",":""), $i}}}')"
    if [[ -z "$device_ids_json" ]]; then
      log_output "Observed: prueba API integrada omitida (TEST_DEVICE_IDS sin enteros validos)."
    else
      endpoint_url="${API_BASE_URL%/}/api/v1/actions/assignments/template-version"
      payload="$(jq -n --argjson templateVersionId "$TEST_RULE_TEMPLATE_VERSION_ID" --argjson deviceIds "[$device_ids_json]" '{ruleTemplateVersionId:$templateVersionId, deviceIds:$deviceIds}')"
      log_command "curl -sS -X POST $endpoint_url (JSON payload)"

      tmp_api="$(mktemp)"
      set +e
      curl -sS -X POST "$endpoint_url" \
        -H "Authorization: Bearer $API_AUTH_TOKEN" \
        -H "Content-Type: application/json" \
        --data "$payload" >"$tmp_api"
      curl_exit=$?
      set -e

      if [[ "$curl_exit" -ne 0 ]]; then
        log_output "Observed: prueba API integrada fallo (curl_exit=$curl_exit)."
        cat "$tmp_api" >> "$OUTPUTS_LOG"
        rm -f "$tmp_api"
        exit 1
      fi

      api_compact="$(jq -c . "$tmp_api" 2>/dev/null || cat "$tmp_api")"
      log_output "Observed: api_response=$api_compact"
      rm -f "$tmp_api"
    fi
  fi
fi

log_output "Observed: run finalizado."
