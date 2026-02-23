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

log_output "Expected: run valida criterios ACT-005 phase-03 (builder UI + rutas/permisos + no-regresion)."
log_output "Observed: inicio run (DRY_RUN=$DRY_RUN, API_BASE_URL=$API_BASE_URL)."

view_file="$REPO_ROOT/telemetric-front/src/features/actions/views/ActionsTemplatesView.vue"
types_file="$REPO_ROOT/telemetric-front/src/features/actions/types.ts"
route_file="$REPO_ROOT/telemetric-front/src/features/actions/actions.routes.ts"
menu_file="$REPO_ROOT/telemetric-front/src/layouts/menuItems.ts"
summary_file="$REPO_ROOT/contexto/work/features/acciones_modulo/03_execution/ACT-005/phase-03.md"

log_output "Observed: phase_summary_builder=$(contains_text "$summary_file" "builder guiado")"
log_output "Observed: view_validate_and_build=$(contains_text "$view_file" "const validateAndBuild")"
if contains_text "$view_file" "<v-textarea" | grep -q true; then
  log_output "Observed: view_without_v_textarea=false"
else
  log_output "Observed: view_without_v_textarea=true"
fi
log_output "Observed: rule_type_1_instant_threshold=$(contains_text "$view_file" "INSTANT_THRESHOLD")"
log_output "Observed: rule_type_2_continuous_duration=$(contains_text "$view_file" "CONTINUOUS_DURATION")"
log_output "Observed: rule_type_3_accumulated_duration_window=$(contains_text "$view_file" "ACCUMULATED_DURATION_WINDOW")"
log_output "Observed: rule_type_4_aggregation_window=$(contains_text "$view_file" "AGGREGATION_WINDOW")"
log_output "Observed: rule_type_5_count_occurrences_window=$(contains_text "$view_file" "COUNT_OCCURRENCES_WINDOW")"
log_output "Observed: duration_rule_t_le_w=$(contains_text "$view_file" "durationSeconds no puede ser mayor que windowSeconds.")"
log_output "Observed: hold_last_value_ttl_validation=$(contains_text "$view_file" "ttlSeconds invalido para HOLD_LAST_VALUE.")"
log_output "Observed: recipients_required_validation=$(contains_text "$view_file" "Debe ingresar al menos un destinatario.")"
log_output "Observed: recipients_format_validation=$(contains_text "$view_file" "Email invalido:")"
log_output "Observed: route_actions_exists=$(contains_text "$route_file" "path: '/actions'")"
log_output "Observed: route_actions_permission=$(contains_text "$route_file" "requiresPermission: 'Actions.View'")"
log_output "Observed: menu_actions_title=$(contains_text "$menu_file" "title: 'Acciones'")"
log_output "Observed: menu_actions_path=$(contains_text "$menu_file" "to: '/actions'")"
log_output "Observed: menu_actions_permission=$(contains_text "$menu_file" "requiresPermission: 'Actions.View'")"
log_output "Observed: types_rule_definition_v1=$(contains_text "$types_file" "export type RuleDefinitionV1")"
if grep -Eq '\bany\b|\bunknown\b' "$types_file"; then
  log_output "Observed: types_no_any_unknown=false"
else
  log_output "Observed: types_no_any_unknown=true"
fi

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
