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

auto_login_if_needed() {
  if [[ -n "$API_AUTH_TOKEN" ]]; then
    return
  fi

  if ! command -v jq >/dev/null 2>&1; then
    log_output "Observed: auto_login_token=SKIP (jq no disponible para parsear token)"
    return
  fi

  local login_uri="$API_BASE_URL/api/v1/auth/login"
  log_command "curl -sS -X POST $login_uri (auto token)"
  set +e
  local login_response
  login_response="$(curl -sS -X POST "$login_uri" -H 'Content-Type: application/json' -d "{\"username\":\"$API_USER\",\"password\":\"$API_PASSWORD\"}")"
  local curl_exit=$?
  set -e

  if [[ $curl_exit -ne 0 ]]; then
    log_output "Observed: auto_login_token=FAIL (curl_exit=$curl_exit)"
    return
  fi

  local token
  token="$(echo "$login_response" | jq -r '.token // empty' 2>/dev/null || true)"
  if [[ -n "$token" ]]; then
    API_AUTH_TOKEN="$token"
    log_output "Observed: auto_login_token=OK (API_USER=$API_USER)"
  else
    log_output "Observed: auto_login_token=FAIL (token vacio)"
  fi
}

auto_discovery_ids_if_needed() {
  if ! command -v sqlcmd >/dev/null 2>&1; then
    log_output "Observed: sqlcmd no disponible para autodiscovery de IDs."
    return
  fi

  if [[ -z "$TEST_RULE_TEMPLATE_VERSION_ID" ]]; then
    log_command "sqlcmd $SQLCMD_ARGS (autodiscovery TEST_RULE_TEMPLATE_VERSION_ID)"
    set +e
    local raw_version
    raw_version="$(sqlcmd $SQLCMD_ARGS -h -1 -W -Q "SET NOCOUNT ON; SELECT TOP 1 RuleTemplateVersionId FROM dbo.RuleTemplateVersion WHERE IsDeleted=0 ORDER BY RuleTemplateVersionId DESC;" 2>/dev/null)"
    set -e
    TEST_RULE_TEMPLATE_VERSION_ID="$(echo "$raw_version" | tr -d '\r' | grep -E '^[0-9]+$' | head -n1 || true)"
    if [[ -n "$TEST_RULE_TEMPLATE_VERSION_ID" ]]; then
      log_output "Observed: auto_rule_template_version_id=$TEST_RULE_TEMPLATE_VERSION_ID"
    fi
  fi

  if [[ -z "$TEST_DEVICE_ID" ]]; then
    log_command "sqlcmd $SQLCMD_ARGS (autodiscovery TEST_DEVICE_ID)"
    set +e
    local raw_device
    raw_device="$(sqlcmd $SQLCMD_ARGS -h -1 -W -Q "SET NOCOUNT ON; SELECT TOP 1 DeviceId FROM dbo.Device WHERE IsDeleted=0 ORDER BY DeviceId DESC;" 2>/dev/null)"
    set -e
    TEST_DEVICE_ID="$(echo "$raw_device" | tr -d '\r' | grep -E '^[0-9]+$' | head -n1 || true)"
    if [[ -n "$TEST_DEVICE_ID" ]]; then
      log_output "Observed: auto_test_device_id=$TEST_DEVICE_ID"
    fi
  fi
}

log_output "Expected: run valida criterios ACT-004 phase-04 (ruta customer, flujo local/reusable, permisos, no-regresion)."
log_output "Observed: inicio run (DRY_RUN=$DRY_RUN)."

candidate_files=(
  "telemetric-front/src/router/MainRoutes.ts"
  "telemetric-front/src/features/customer/devices/views/DeviceCustomerEditView.vue"
  "telemetric-front/src/features/actions/actions.service.ts"
  "telemetric-front/src/features/actions/types.ts"
  "contexto/work/features/acciones_modulo/03_execution/ACT-004/phase-04.md"
)

for rel in "${candidate_files[@]}"; do
  log_command "test -f $rel"
  if [[ -f "$REPO_ROOT/$rel" ]]; then
    log_output "Observed: file_exists[$rel]=true"
  else
    log_output "Observed: file_exists[$rel]=false"
  fi
done

routes_file="$REPO_ROOT/telemetric-front/src/router/MainRoutes.ts"
view_file="$REPO_ROOT/telemetric-front/src/features/customer/devices/views/DeviceCustomerEditView.vue"
service_file="$REPO_ROOT/telemetric-front/src/features/actions/actions.service.ts"
types_file="$REPO_ROOT/telemetric-front/src/features/actions/types.ts"
phase_summary_file="$REPO_ROOT/contexto/work/features/acciones_modulo/03_execution/ACT-004/phase-04.md"

route_exists="$(contains_text "$routes_file" "path: '/my-devices/:id/edit'")"
route_view="$(contains_text "$routes_file" "DeviceCustomerEditView.vue")"
rule_mode="$(contains_text "$view_file" "ruleMode = ref<'local' | 'reusable'>('local')")"
create_rule_call="$(contains_text "$view_file" "actionsService.createRuleFromDevice")"
permission_gate="$(contains_text "$view_file" "permissions?.includes('Actions.Assign')")"
permission_message="$(contains_text "$view_file" "No tienes permiso")"
invalid_overrides="$(contains_text "$view_file" "Overrides JSON no es valido.")"
local_label="$(contains_text "$view_file" "Regla local (template existente)")"
reusable_label="$(contains_text "$view_file" "Crear template reusable")"
create_local_btn="$(contains_text "$view_file" "Crear regla local")"
create_reusable_btn="$(contains_text "$view_file" "Crear reusable y asignar")"
save_flow="$(contains_text "$view_file" "deviceCustomerService.update")"
save_button="$(contains_text "$view_file" "Guardar Cambios")"
service_wiring="$(contains_text "$service_file" "/actions/assignments/create-from-device")"
service_method="$(contains_text "$service_file" "createRuleFromDevice")"
request_type="$(contains_text "$types_file" "CreateRuleFromDeviceRequest")"
response_type="$(contains_text "$types_file" "CreateRuleFromDeviceResponse")"
trace_flow="$(contains_text "$phase_summary_file" "flujo")"
trace_labels="$(contains_text "$phase_summary_file" "labels UI en espanol")"

if [[ "$route_exists" == "true" && "$route_view" == "true" ]]; then
  log_output "Observed: route_my_devices_edit_exists=true"
else
  log_output "Observed: route_my_devices_edit_exists=false"
fi
log_output "Observed: ui_rule_mode_local_reusable=$rule_mode"
log_output "Observed: ui_calls_create_rule_from_device=$create_rule_call"
log_output "Observed: ui_permission_gate_assign=$permission_gate"
log_output "Observed: ui_permission_block_message=$permission_message"
log_output "Observed: ui_invalid_overrides_message=$invalid_overrides"
if [[ "$local_label" == "true" && "$reusable_label" == "true" ]]; then
  log_output "Observed: ui_local_reusable_labels=true"
else
  log_output "Observed: ui_local_reusable_labels=false"
fi
if [[ "$create_local_btn" == "true" && "$create_reusable_btn" == "true" ]]; then
  log_output "Observed: ui_action_buttons=true"
else
  log_output "Observed: ui_action_buttons=false"
fi
if [[ "$save_flow" == "true" && "$save_button" == "true" ]]; then
  log_output "Observed: customer_edit_save_flow_preserved=true"
else
  log_output "Observed: customer_edit_save_flow_preserved=false"
fi
if [[ "$service_wiring" == "true" && "$service_method" == "true" ]]; then
  log_output "Observed: service_create_from_device_wiring=true"
else
  log_output "Observed: service_create_from_device_wiring=false"
fi
if [[ "$request_type" == "true" && "$response_type" == "true" ]]; then
  log_output "Observed: typed_contracts_create_from_device=true"
else
  log_output "Observed: typed_contracts_create_from_device=false"
fi
if [[ "$trace_flow" == "true" && "$trace_labels" == "true" ]]; then
  log_output "Observed: execution_summary_trace_present=true"
else
  log_output "Observed: execution_summary_trace_present=false"
fi

if [[ "$DRY_RUN" == "1" ]]; then
  log_command "npm --prefix $FRONTEND_DIR run typecheck"
  log_command "read baseline from baseline.json"
  log_output "Observed (pendiente): typecheck no ejecutado por DRY_RUN=1."
  log_output "Observed (pendiente): gate no-regresion no evaluado por DRY_RUN=1."
  log_output "Observed (pendiente): autodiscovery login/sql no ejecutado por DRY_RUN=1."
else
  if [[ ! -f "$BASELINE_FILE" ]]; then
    log_output "Observed: baseline no encontrado en $BASELINE_FILE"
    echo "Baseline file missing: $BASELINE_FILE" >&2
    exit 1
  fi

  baseline_errors="$(grep -oE '"ts_errors"[[:space:]]*:[[:space:]]*[0-9]+' "$BASELINE_FILE" | grep -oE '[0-9]+' | head -n1)"
  baseline_scope="$(grep -oE '"scope"[[:space:]]*:[[:space:]]*"[^"]+"' "$BASELINE_FILE" | sed -E 's/.*"scope"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/' | head -n1)"
  if [[ -z "$baseline_errors" ]]; then
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

  auto_login_if_needed
  auto_discovery_ids_if_needed
  log_output "Observed: API smoke opcional no ejecutado por defecto en fase frontend (set RUN_API_SMOKE=1 para extender)."
fi

log_output "Observed: run finalizado."
