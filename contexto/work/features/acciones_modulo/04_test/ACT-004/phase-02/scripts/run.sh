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
TEST_DEVICE_ID="${TEST_DEVICE_ID:-}"
TEST_RULE_TEMPLATE_VERSION_ID="${TEST_RULE_TEMPLATE_VERSION_ID:-}"

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

log_output "Expected: run valida criterios ACT-004 phase-02 (endpoint, policy, overrides whitelist, local/reusable, no-regresion)."
log_output "Observed: inicio run (DRY_RUN=$DRY_RUN, API_BASE_URL=$API_BASE_URL)."

candidate_files=(
  "telemetric-api/src/Telemetric.Api/Features/Actions/Assignments/CreateRuleFromDevice/CreateRuleFromDeviceEndpoint.cs"
  "telemetric-api/src/Telemetric.Api/Features/Actions/Assignments/CreateRuleFromDevice/CreateRuleFromDeviceCommandHandler.cs"
  "telemetric-api/src/Telemetric.Api/Domain/Constants/PermissionClaims.cs"
  "contexto/openapi/actions.yaml"
  "contexto/work/features/acciones_modulo/03_execution/ACT-004/phase-02.md"
)

for rel in "${candidate_files[@]}"; do
  log_command "test -f $rel"
  if [[ -f "$REPO_ROOT/$rel" ]]; then
    log_output "Observed: file_exists[$rel]=true"
  else
    log_output "Observed: file_exists[$rel]=false"
  fi
done

endpoint_file="$REPO_ROOT/telemetric-api/src/Telemetric.Api/Features/Actions/Assignments/CreateRuleFromDevice/CreateRuleFromDeviceEndpoint.cs"
handler_file="$REPO_ROOT/telemetric-api/src/Telemetric.Api/Features/Actions/Assignments/CreateRuleFromDevice/CreateRuleFromDeviceCommandHandler.cs"
claims_file="$REPO_ROOT/telemetric-api/src/Telemetric.Api/Domain/Constants/PermissionClaims.cs"
openapi_file="$REPO_ROOT/contexto/openapi/actions.yaml"
sql_file="$REPO_ROOT/telemetric-api/scripts/012_create_actions_schema.sql"
phase_summary_file="$REPO_ROOT/contexto/work/features/acciones_modulo/03_execution/ACT-004/phase-02.md"

has_endpoint="$(contains_text "$endpoint_file" 'Post("/api/v1/actions/assignments/create-from-device")')"
has_policy_endpoint="$(contains_text "$endpoint_file" 'PermissionClaims.Actions.Assign')"
has_policy_constant="$(contains_text "$claims_file" 'public const string Assign = "Actions.Assign";')"
has_openapi_path="$(contains_text "$openapi_file" '/api/v1/actions/assignments/create-from-device')"
has_reuse_trace="$(contains_text "$phase_summary_file" 'Reuse-first')"
has_threshold_rule="$(contains_text "$handler_file" "Override 'threshold' must be a numeric value.")"
has_recipients_rule="$(contains_text "$handler_file" "Override 'email.recipients' must be an array.")"
has_not_allowed_rule="$(contains_text "$handler_file" 'is not allowed in v1')"
has_local_path="$(contains_text "$handler_file" 'if (request.CreateReusableTemplate)')"
has_reusable_response="$(contains_text "$handler_file" 'CreatedReusableTemplate')"
has_duplicate_guard="$(contains_text "$handler_file" 'RuleInstance already exists for the provided device and template version.')"
has_unique_index="$(contains_text "$sql_file" 'UQ_RuleInstance_Device_TemplateVersion')"

log_output "Observed: endpoint_exists=$has_endpoint"
log_output "Observed: endpoint_policy_assign=$has_policy_endpoint"
log_output "Observed: permission_claim_assign_constant=$has_policy_constant"
log_output "Observed: openapi_contains_create_from_device_path=$has_openapi_path"
log_output "Observed: reuse_first_trace_in_phase_summary=$has_reuse_trace"
log_output "Observed: overrides_threshold_rule=$has_threshold_rule"
log_output "Observed: overrides_email_recipients_rule=$has_recipients_rule"
log_output "Observed: overrides_reject_non_whitelisted_rule=$has_not_allowed_rule"
log_output "Observed: local_or_reusable_paths_present=$has_local_path"
log_output "Observed: response_marks_created_reusable=$has_reusable_response"
log_output "Observed: duplicate_guard_in_handler=$has_duplicate_guard"
log_output "Observed: sql_unique_index_guard=$has_unique_index"

if [[ "$DRY_RUN" == "1" ]]; then
  log_command "npm --prefix $FRONTEND_DIR run typecheck"
  log_command "read baseline from baseline.json"
  log_output "Observed (pendiente): typecheck no ejecutado por DRY_RUN=1."
  log_output "Observed (pendiente): gate no-regresion no evaluado por DRY_RUN=1."
  log_output "Observed (pendiente): pruebas API integradas no ejecutadas por DRY_RUN=1."
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

  observed_errors="$(grep -E '^src[\/].*error TS[0-9]+:' "$tmp_out" | grep -Ev '^src[\/]_demo[\/]' | wc -l | tr -d ' ')"
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

  if [[ -z "$TEST_DEVICE_ID" ]] && command -v sqlcmd >/dev/null 2>&1; then
    log_command "sqlcmd $SQLCMD_ARGS (autodiscovery TEST_DEVICE_ID)"
    device_id="$(sqlcmd $SQLCMD_ARGS -h -1 -W -Q "SET NOCOUNT ON; SELECT TOP 1 DeviceId FROM dbo.Device WHERE IsDeleted=0 ORDER BY DeviceId DESC;" | tr -d '\r' | awk '/^[0-9]+$/{print; exit}')"
    if [[ -n "$device_id" ]]; then
      TEST_DEVICE_ID="$device_id"
      log_output "Observed: auto_test_device_id=$TEST_DEVICE_ID"
    fi
  fi

  if [[ -z "$API_AUTH_TOKEN" || -z "$TEST_RULE_TEMPLATE_VERSION_ID" || -z "$TEST_DEVICE_ID" ]]; then
    log_output "Observed: pruebas API integradas omitidas (faltan API_AUTH_TOKEN / TEST_RULE_TEMPLATE_VERSION_ID / TEST_DEVICE_ID)."
  else
    endpoint_url="${API_BASE_URL%/}/api/v1/actions/assignments/create-from-device"

    allowed_overrides='{"threshold":15,"email":{"recipients":["qa@telemetric.local"]}}'
    local_payload="$(jq -n --argjson deviceId "$TEST_DEVICE_ID" --argjson ruleTemplateVersionId "$TEST_RULE_TEMPLATE_VERSION_ID" --arg overridesJson "$allowed_overrides" '{deviceId:$deviceId, ruleTemplateVersionId:$ruleTemplateVersionId, createReusableTemplate:false, reusableTemplateName:null, reusableTemplateDescription:null, definitionJson:null, overridesJson:$overridesJson, isPaused:false, isLatchMode:false, cooldownSeconds:0}')"

    log_command "curl -sS -X POST $endpoint_url (local + allowed overrides)"
    local_tmp="$(mktemp)"
    set +e
    local_code="$(curl -sS -o "$local_tmp" -w "%{http_code}" -X POST "$endpoint_url" -H "Authorization: Bearer $API_AUTH_TOKEN" -H "Content-Type: application/json" --data "$local_payload")"
    set -e
    local_body="$(cat "$local_tmp")"
    rm -f "$local_tmp"

    if [[ "$local_code" != "200" ]]; then
      log_output "Observed: local_allowed_request=FAIL (http=$local_code, body=$local_body)"
      exit 1
    fi

    local_created_reusable="$(echo "$local_body" | jq -r '.createdReusableTemplate // false' 2>/dev/null || echo false)"
    local_template_id="$(echo "$local_body" | jq -r '.ruleTemplateId // empty' 2>/dev/null || true)"
    if [[ "$local_created_reusable" == "false" && -z "$local_template_id" ]]; then
      log_output "Observed: local_rule_not_reusable=true"
    else
      log_output "Observed: local_rule_not_reusable=false"
    fi

    invalid_overrides='{"foo":"bar"}'
    invalid_payload="$(jq -n --argjson deviceId "$TEST_DEVICE_ID" --argjson ruleTemplateVersionId "$TEST_RULE_TEMPLATE_VERSION_ID" --arg overridesJson "$invalid_overrides" '{deviceId:$deviceId, ruleTemplateVersionId:$ruleTemplateVersionId, createReusableTemplate:false, overridesJson:$overridesJson, isPaused:false, isLatchMode:false, cooldownSeconds:0}')"

    log_command "curl -sS -X POST $endpoint_url (invalid overrides expected fail)"
    invalid_tmp="$(mktemp)"
    set +e
    invalid_code="$(curl -sS -o "$invalid_tmp" -w "%{http_code}" -X POST "$endpoint_url" -H "Authorization: Bearer $API_AUTH_TOKEN" -H "Content-Type: application/json" --data "$invalid_payload")"
    set -e
    invalid_body="$(cat "$invalid_tmp")"
    rm -f "$invalid_tmp"

    if [[ "$invalid_code" == "400" ]]; then
      log_output "Observed: invalid_override_rejected=TRUE"
      log_output "Observed: invalid_override_error=$invalid_body"
    else
      log_output "Observed: invalid_override_rejected=FALSE (http=$invalid_code, body=$invalid_body)"
      exit 1
    fi

    reusable_name="qa-phase02-reusable-$(date +%Y%m%d%H%M%S)"
    definition_json='{"trigger":{"metricCode":"temperature"},"condition":{"operator":">","value":80}}'
    reusable_payload="$(jq -n --argjson deviceId "$TEST_DEVICE_ID" --arg reusableName "$reusable_name" --arg definitionJson "$definition_json" --arg overridesJson "$allowed_overrides" '{deviceId:$deviceId, ruleTemplateVersionId:null, createReusableTemplate:true, reusableTemplateName:$reusableName, reusableTemplateDescription:"QA ACT-004 phase-02 reusable", definitionJson:$definitionJson, overridesJson:$overridesJson, isPaused:false, isLatchMode:false, cooldownSeconds:5}')"

    log_command "curl -sS -X POST $endpoint_url (reusable + allowed overrides)"
    reusable_tmp="$(mktemp)"
    set +e
    reusable_code="$(curl -sS -o "$reusable_tmp" -w "%{http_code}" -X POST "$endpoint_url" -H "Authorization: Bearer $API_AUTH_TOKEN" -H "Content-Type: application/json" --data "$reusable_payload")"
    set -e
    reusable_body="$(cat "$reusable_tmp")"
    rm -f "$reusable_tmp"

    if [[ "$reusable_code" != "200" ]]; then
      log_output "Observed: reusable_request=FAIL (http=$reusable_code, body=$reusable_body)"
      exit 1
    fi

    reusable_created="$(echo "$reusable_body" | jq -r '.createdReusableTemplate // false' 2>/dev/null || echo false)"
    reusable_version_id="$(echo "$reusable_body" | jq -r '.ruleTemplateVersionId // 0' 2>/dev/null || echo 0)"
    if [[ "$reusable_created" == "true" && "$reusable_version_id" -gt 0 ]]; then
      log_output "Observed: reusable_rule_available_for_future_assignments=true"
    else
      log_output "Observed: reusable_rule_available_for_future_assignments=false"
      exit 1
    fi
  fi
fi

log_output "Observed: run finalizado."
