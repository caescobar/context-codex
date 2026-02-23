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

try_query_sql_first_id() {
  local query="$1"
  log_command "sqlcmd $SQLCMD_ARGS ($query)"
  sqlcmd $SQLCMD_ARGS -h -1 -W -Q "SET NOCOUNT ON; $query" 2>/dev/null | tr -d '\r' | awk '/^[0-9]+$/{print; exit}' || true
}

try_query_sql_id_list() {
  local query="$1"
  log_command "sqlcmd $SQLCMD_ARGS ($query)"
  local ids
  ids="$(sqlcmd $SQLCMD_ARGS -h -1 -W -Q "SET NOCOUNT ON; $query" 2>/dev/null | tr -d '\r' | awk '/^[0-9]+$/{print}' | paste -sd "," - || true)"
  if [[ -n "${ids:-}" ]]; then
    echo "$ids"
  fi
}

try_auto_discovery() {
  if [[ -z "$API_AUTH_TOKEN" ]]; then
    local login_url="${API_BASE_URL%/}/api/v1/auth/login"
    log_command "curl -sS -X POST $login_url (auto token)"
    local login_resp
    login_resp="$(curl -sS -X POST "$login_url" -H "Content-Type: application/json" --data "{\"username\":\"$API_USER\",\"password\":\"$API_PASSWORD\"}" || true)"
    local api_token
    api_token="$(echo "$login_resp" | jq -r '.token // empty' 2>/dev/null || true)"
    if [[ -n "$api_token" ]]; then
      API_AUTH_TOKEN="$api_token"
      log_output "Observed: auto_login_token=OK (API_USER=$API_USER)"
    else
      log_output "Observed: auto_login_token=FAIL"
    fi
  fi

  if command -v sqlcmd >/dev/null 2>&1; then
    if [[ -z "$TEST_RULE_TEMPLATE_VERSION_ID" ]]; then
      local version_id
      version_id="$(try_query_sql_first_id "SELECT TOP 1 RuleTemplateVersionId FROM dbo.RuleTemplateVersion WHERE IsDeleted=0 ORDER BY RuleTemplateVersionId DESC;")"
      if [[ -n "${version_id:-}" ]]; then
        TEST_RULE_TEMPLATE_VERSION_ID="$version_id"
        log_output "Observed: auto_rule_template_version_id=$TEST_RULE_TEMPLATE_VERSION_ID"
      else
        log_output "Observed: auto_rule_template_version_id=FAIL"
      fi
    fi

    if [[ -z "$TEST_DEVICE_IDS" ]]; then
      local device_ids
      device_ids="$(try_query_sql_id_list "SELECT TOP 3 DeviceId FROM dbo.Device WHERE IsDeleted=0 ORDER BY DeviceId DESC;")"
      if [[ -z "${device_ids:-}" ]]; then
        device_ids="$(try_query_sql_id_list "SELECT TOP 3 DeviceId FROM dbo.Devices WHERE IsDeleted=0 ORDER BY DeviceId DESC;")"
      fi

      if [[ -n "${device_ids:-}" ]]; then
        TEST_DEVICE_IDS="$device_ids"
        log_output "Observed: auto_test_device_ids=$TEST_DEVICE_IDS"
      else
        log_output "Observed: auto_test_device_ids=FAIL"
      fi
    fi
  else
    log_output "Observed: sqlcmd no disponible para autodiscovery de IDs."
  fi
}

log_output "Expected: run valida criterios ACT-005 phase-02 (validacion semantica DSL + no-regresion)."
log_output "Observed: inicio run (DRY_RUN=$DRY_RUN, API_BASE_URL=$API_BASE_URL)."

candidate_files=(
  "telemetric-api/src/Telemetric.Api/Features/Actions/Templates/CreateTemplate/CreateTemplateCommandHandler.cs"
  "telemetric-api/src/Telemetric.Api/Features/Actions/Templates/UpdateTemplate/UpdateTemplateCommandHandler.cs"
  "telemetric-api/src/Telemetric.Api/Features/Actions/Assignments/CreateRuleFromDevice/CreateRuleFromDeviceCommandHandler.cs"
  "telemetric-api/src/Telemetric.Api/Features/Actions/Templates/CreateTemplate/CreateTemplateEndpoint.cs"
  "telemetric-api/src/Telemetric.Api/Features/Actions/Templates/UpdateTemplate/UpdateTemplateEndpoint.cs"
  "contexto/work/features/acciones_modulo/03_execution/ACT-005/phase-02.md"
)

for rel in "${candidate_files[@]}"; do
  log_command "test -f $rel"
  if [[ -f "$REPO_ROOT/$rel" ]]; then
    log_output "Observed: file_exists[$rel]=true"
  else
    log_output "Observed: file_exists[$rel]=false"
  fi
done

create_handler_file="$REPO_ROOT/telemetric-api/src/Telemetric.Api/Features/Actions/Templates/CreateTemplate/CreateTemplateCommandHandler.cs"
update_handler_file="$REPO_ROOT/telemetric-api/src/Telemetric.Api/Features/Actions/Templates/UpdateTemplate/UpdateTemplateCommandHandler.cs"
create_from_device_handler_file="$REPO_ROOT/telemetric-api/src/Telemetric.Api/Features/Actions/Assignments/CreateRuleFromDevice/CreateRuleFromDeviceCommandHandler.cs"
create_endpoint_file="$REPO_ROOT/telemetric-api/src/Telemetric.Api/Features/Actions/Templates/CreateTemplate/CreateTemplateEndpoint.cs"
update_endpoint_file="$REPO_ROOT/telemetric-api/src/Telemetric.Api/Features/Actions/Templates/UpdateTemplate/UpdateTemplateEndpoint.cs"
create_from_device_endpoint_file="$REPO_ROOT/telemetric-api/src/Telemetric.Api/Features/Actions/Assignments/CreateRuleFromDevice/CreateRuleFromDeviceEndpoint.cs"
phase_summary_file="$REPO_ROOT/contexto/work/features/acciones_modulo/03_execution/ACT-005/phase-02.md"

has_summary="$(contains_text "$phase_summary_file" 'validacion semantica DSL')"
has_create_validate="$(contains_text "$create_handler_file" 'ValidateAndNormalizeDefinitionJson(')"
has_update_validate="$(contains_text "$update_handler_file" 'ValidateAndNormalizeDefinitionJson(')"
has_create_from_device_validate="$(contains_text "$create_from_device_handler_file" 'ValidateAndNormalizeDefinitionJson(')"
has_reusable_guard="$(contains_text "$create_from_device_handler_file" 'if (request.CreateReusableTemplate)')"
has_reusable_call="$(contains_text "$create_from_device_handler_file" 'ValidateAndNormalizeDefinitionJson(request.DefinitionJson)')"

has_temporal_1="$(contains_text "$create_handler_file" 'evaluation.durationSeconds must be less than or equal to evaluation.windowSeconds.')"
has_temporal_2="$(contains_text "$update_handler_file" 'evaluation.durationSeconds must be less than or equal to evaluation.windowSeconds.')"
has_temporal_3="$(contains_text "$create_from_device_handler_file" 'evaluation.durationSeconds must be less than or equal to evaluation.windowSeconds.')"
if [[ "$has_temporal_1" == "true" && "$has_temporal_2" == "true" && "$has_temporal_3" == "true" ]]; then
  has_temporal_rule="true"
else
  has_temporal_rule="false"
fi

has_hold_1="$(contains_text "$create_handler_file" 'missingDataPolicy.ttlSeconds is required when mode is HOLD_LAST_VALUE.')"
has_hold_2="$(contains_text "$update_handler_file" 'missingDataPolicy.ttlSeconds is required when mode is HOLD_LAST_VALUE.')"
has_hold_3="$(contains_text "$create_from_device_handler_file" 'missingDataPolicy.ttlSeconds is required when mode is HOLD_LAST_VALUE.')"
if [[ "$has_hold_1" == "true" && "$has_hold_2" == "true" && "$has_hold_3" == "true" ]]; then
  has_hold_last_rule="true"
else
  has_hold_last_rule="false"
fi

has_ins_1="$(contains_text "$create_handler_file" 'missingDataPolicy.ttlSeconds must be null or omitted when mode is INSUFFICIENT_DATA.')"
has_ins_2="$(contains_text "$update_handler_file" 'missingDataPolicy.ttlSeconds must be null or omitted when mode is INSUFFICIENT_DATA.')"
has_ins_3="$(contains_text "$create_from_device_handler_file" 'missingDataPolicy.ttlSeconds must be null or omitted when mode is INSUFFICIENT_DATA.')"
if [[ "$has_ins_1" == "true" && "$has_ins_2" == "true" && "$has_ins_3" == "true" ]]; then
  has_insufficient_rule="true"
else
  has_insufficient_rule="false"
fi

has_recip_1="$(contains_text "$create_handler_file" 'action.recipients[')"
has_recip_2="$(contains_text "$update_handler_file" 'action.recipients[')"
has_recip_3="$(contains_text "$create_from_device_handler_file" 'action.recipients[')"
if [[ "$has_recip_1" == "true" && "$has_recip_2" == "true" && "$has_recip_3" == "true" ]]; then
  has_recipients_indexed="true"
else
  has_recipients_indexed="false"
fi

has_create_400="$(contains_text "$create_endpoint_file" 'Send.ErrorsAsync(400')"
has_update_400="$(contains_text "$update_endpoint_file" 'Send.ErrorsAsync(400')"
has_create_from_device_400="$(contains_text "$create_from_device_endpoint_file" 'Send.ErrorsAsync(400')"

log_output "Observed: phase_summary_semantic_validation=$has_summary"
log_output "Observed: create_handler_validate_method=$has_create_validate"
log_output "Observed: update_handler_validate_method=$has_update_validate"
log_output "Observed: create_from_device_validate_method=$has_create_from_device_validate"
log_output "Observed: create_from_device_reusable_guard=$has_reusable_guard"
log_output "Observed: create_from_device_reusable_validation_call=$has_reusable_call"
log_output "Observed: temporal_rule_t_le_w=$has_temporal_rule"
log_output "Observed: hold_last_value_requires_ttl=$has_hold_last_rule"
log_output "Observed: insufficient_data_rejects_ttl=$has_insufficient_rule"
log_output "Observed: recipients_indexed_error_path=$has_recipients_indexed"
log_output "Observed: create_endpoint_errors_400=$has_create_400"
log_output "Observed: update_endpoint_errors_400=$has_update_400"
log_output "Observed: create_from_device_endpoint_errors_400=$has_create_from_device_400"

if [[ "$DRY_RUN" == "1" ]]; then
  log_command "npm --prefix $FRONTEND_DIR run typecheck"
  log_command "read baseline from baseline.json"
  log_output "Observed (pendiente): typecheck no ejecutado por DRY_RUN=1."
  log_output "Observed (pendiente): gate no-regresion no evaluado por DRY_RUN=1."
  log_output "Observed (pendiente): auto-login y autodiscovery SQL no ejecutados por DRY_RUN=1."
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

  try_auto_discovery
fi

log_output "Observed: run finalizado."
