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

log_command() { echo "$(date -Iseconds) | $1" >> "$COMMANDS_LOG"; }
log_output() { echo "$(date -Iseconds) | $1" >> "$OUTPUTS_LOG"; }

contains_text() {
  local file="$1"
  local text="$2"
  if [[ -f "$file" ]] && grep -Fq "$text" "$file"; then
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
  sqlcmd $SQLCMD_ARGS -h -1 -W -Q "SET NOCOUNT ON; $query" 2>/dev/null | tr -d '\r' | awk '/^[0-9]+$/{print}' | paste -sd "," - || true
}

try_auto_discovery() {
  if [[ -z "$API_AUTH_TOKEN" ]]; then
    local login_url="${API_BASE_URL%/}/api/v1/auth/login"
    log_command "curl -sS -X POST $login_url (auto token)"
    local login_resp api_token
    login_resp="$(curl -sS -X POST "$login_url" -H "Content-Type: application/json" --data "{\"username\":\"$API_USER\",\"password\":\"$API_PASSWORD\"}" || true)"
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
      TEST_RULE_TEMPLATE_VERSION_ID="$(try_query_sql_first_id "SELECT TOP 1 RuleTemplateVersionId FROM dbo.RuleTemplateVersion WHERE IsDeleted=0 ORDER BY RuleTemplateVersionId DESC;")"
      if [[ -n "${TEST_RULE_TEMPLATE_VERSION_ID:-}" ]]; then
        log_output "Observed: auto_rule_template_version_id=$TEST_RULE_TEMPLATE_VERSION_ID"
      else
        log_output "Observed: auto_rule_template_version_id=FAIL"
      fi
    fi
    if [[ -z "$TEST_DEVICE_IDS" ]]; then
      TEST_DEVICE_IDS="$(try_query_sql_id_list "SELECT TOP 3 DeviceId FROM dbo.Device WHERE IsDeleted=0 ORDER BY DeviceId DESC;")"
      if [[ -z "${TEST_DEVICE_IDS:-}" ]]; then
        TEST_DEVICE_IDS="$(try_query_sql_id_list "SELECT TOP 3 DeviceId FROM dbo.Devices WHERE IsDeleted=0 ORDER BY DeviceId DESC;")"
      fi
      if [[ -n "${TEST_DEVICE_IDS:-}" ]]; then
        log_output "Observed: auto_test_device_ids=$TEST_DEVICE_IDS"
      else
        log_output "Observed: auto_test_device_ids=FAIL"
      fi
    fi
  else
    log_output "Observed: sqlcmd no disponible para autodiscovery de IDs."
  fi
}

log_output "Expected: run valida criterios ACT-005 phase-04 (customer DSL, overrides v1, permisos, no-regresion)."
log_output "Observed: inicio run (DRY_RUN=$DRY_RUN, API_BASE_URL=$API_BASE_URL)."

routes_file="$REPO_ROOT/telemetric-front/src/router/MainRoutes.ts"
view_file="$REPO_ROOT/telemetric-front/src/features/customer/devices/views/DeviceCustomerEditView.vue"
service_file="$REPO_ROOT/telemetric-front/src/features/actions/actions.service.ts"
types_file="$REPO_ROOT/telemetric-front/src/features/actions/types.ts"
openapi_file="$REPO_ROOT/contexto/openapi/actions.yaml"
summary_file="$REPO_ROOT/contexto/work/features/acciones_modulo/03_execution/ACT-005/phase-04.md"

log_output "Observed: execution_summary_contract_trace=$(contains_text "$summary_file" "contrato DSL canonico")"
log_output "Observed: route_my_devices_edit_exists=$(contains_text "$routes_file" "path: '/my-devices/:id/edit'")"
log_output "Observed: ui_permission_gate_assign=$(contains_text "$view_file" "permissions?.includes('Actions.Assign')")"
log_output "Observed: ui_permission_block_message=$(contains_text "$view_file" "No tienes permiso \`Actions.Assign\`")"
log_output "Observed: ui_builder_definition=$(contains_text "$view_file" "const validateAndBuildDefinition")"
log_output "Observed: ui_builder_overrides=$(contains_text "$view_file" "const buildOverrides")"
log_output "Observed: duration_rule_t_le_w=$(contains_text "$view_file" "durationSeconds no puede ser mayor que windowSeconds.")"
log_output "Observed: hold_last_value_ttl_validation=$(contains_text "$view_file" "ttlSeconds invalido para HOLD_LAST_VALUE.")"
log_output "Observed: recipients_required_validation=$(contains_text "$view_file" "Debe ingresar al menos un destinatario.")"
log_output "Observed: recipients_email_validation=$(contains_text "$view_file" "Email invalido:")"
log_output "Observed: overrides_threshold_validation=$(contains_text "$view_file" "threshold override invalido.")"
log_output "Observed: overrides_email_validation=$(contains_text "$view_file" "Email override invalido:")"
log_output "Observed: overrides_limited_scope=$([[ $(contains_text "$view_file" "overrides.threshold = threshold") == true && $(contains_text "$view_file" "overrides.email = { recipients }") == true ]] && echo true || echo false)"
log_output "Observed: ui_calls_create_rule_from_device=$(contains_text "$view_file" "actionsService.createRuleFromDevice")"
log_output "Observed: service_create_from_device_wiring=$([[ $(contains_text "$service_file" "createRuleFromDevice") == true && $(contains_text "$service_file" "/create-from-device") == true ]] && echo true || echo false)"
log_output "Observed: service_backend_compat_serialization=$([[ $(contains_text "$service_file" "JSON.stringify(payload.definitionJson)") == true && $(contains_text "$service_file" "JSON.stringify(payload.overridesJson)") == true ]] && echo true || echo false)"
log_output "Observed: typed_contracts_create_from_device=$([[ $(contains_text "$types_file" "definitionJson: RuleDefinitionV1") == true && $(contains_text "$types_file" "overridesJson?: RuleInstanceOverridesV1 | null") == true && $(contains_text "$types_file" "export interface CreateRuleFromDeviceRequest") == true ]] && echo true || echo false)"
log_output "Observed: openapi_dsl_contract=$([[ $(contains_text "$openapi_file" "/api/v1/actions/assignments/create-from-device:") == true && $(contains_text "$openapi_file" "DefinitionJsonV1") == true && $(contains_text "$openapi_file" "RuleInstanceOverridesV1") == true ]] && echo true || echo false)"

if [[ "$DRY_RUN" == "1" ]]; then
  log_command "npm --prefix $FRONTEND_DIR run typecheck"
  log_output "Observed (pendiente): typecheck no ejecutado por DRY_RUN=1."
  log_output "Observed (pendiente): gate no-regresion no evaluado por DRY_RUN=1."
  log_output "Observed (pendiente): auto-login y autodiscovery SQL no ejecutados por DRY_RUN=1."
else
  if ! command -v jq >/dev/null 2>&1; then
    echo "Missing required tool: jq" >&2
    exit 1
  fi
  baseline_errors="$(jq -r '.ts_errors' "$BASELINE_FILE")"
  pushd "$REPO_ROOT" >/dev/null
  log_command "npm --prefix $FRONTEND_DIR run typecheck"
  tmp_out="$(mktemp)"
  set +e
  npm --prefix "$FRONTEND_DIR" run typecheck >"$tmp_out" 2>&1
  set -e
  cat "$tmp_out" >> "$OUTPUTS_LOG"
  observed_errors="$(grep -E '^src[\\/].*error TS[0-9]+:' "$tmp_out" | grep -Ev '^src[\\/]_demo[\\/]' | wc -l | tr -d ' ')"
  rm -f "$tmp_out"
  popd >/dev/null
  log_output "Observed: no_demo_ts_errors=$observed_errors"
  if [[ "$observed_errors" -gt "$baseline_errors" ]]; then
    log_output "Observed: gate_no_regresion=FAIL (observed=$observed_errors > baseline=$baseline_errors)"
    exit 1
  fi
  log_output "Observed: gate_no_regresion=PASS (observed=$observed_errors <= baseline=$baseline_errors)"
  try_auto_discovery
fi

log_output "Observed: run finalizado."
