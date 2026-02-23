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
TEST_RULE_TEMPLATE_ID="${TEST_RULE_TEMPLATE_ID:-}"
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
    if [[ -z "$TEST_RULE_TEMPLATE_ID" ]]; then
      log_command "sqlcmd $SQLCMD_ARGS (autodiscovery TEST_RULE_TEMPLATE_ID)"
      local rule_template_id
      rule_template_id="$(sqlcmd $SQLCMD_ARGS -h -1 -W -Q "SET NOCOUNT ON; SELECT TOP 1 RuleTemplateId FROM dbo.RuleTemplate WHERE IsDeleted=0 ORDER BY RuleTemplateId DESC;" | tr -d '\r' | awk '/^[0-9]+$/{print; exit}')"
      if [[ -n "$rule_template_id" ]]; then
        TEST_RULE_TEMPLATE_ID="$rule_template_id"
        log_output "Observed: auto_rule_template_id=$TEST_RULE_TEMPLATE_ID"
      fi
    fi

    if [[ -z "$TEST_RULE_TEMPLATE_VERSION_ID" ]]; then
      log_command "sqlcmd $SQLCMD_ARGS (autodiscovery TEST_RULE_TEMPLATE_VERSION_ID)"
      local rule_template_version_id
      rule_template_version_id="$(sqlcmd $SQLCMD_ARGS -h -1 -W -Q "SET NOCOUNT ON; SELECT TOP 1 RuleTemplateVersionId FROM dbo.RuleTemplateVersion WHERE IsDeleted=0 ORDER BY RuleTemplateVersionId DESC;" | tr -d '\r' | awk '/^[0-9]+$/{print; exit}')"
      if [[ -n "$rule_template_version_id" ]]; then
        TEST_RULE_TEMPLATE_VERSION_ID="$rule_template_version_id"
        log_output "Observed: auto_rule_template_version_id=$TEST_RULE_TEMPLATE_VERSION_ID"
      fi
    fi
  else
    log_output "Observed: sqlcmd no disponible para autodiscovery de IDs."
  fi
}

log_output "Expected: run valida criterios ACT-005 phase-01 (contrato DSL + no-regresion)."
log_output "Observed: inicio run (DRY_RUN=$DRY_RUN, API_BASE_URL=$API_BASE_URL)."

candidate_files=(
  "contexto/openapi/actions.yaml"
  "telemetric-front/src/features/actions/types.ts"
  "telemetric-api/src/Telemetric.Api/Features/Actions/Templates/CreateTemplate/CreateTemplateEndpoint.cs"
  "telemetric-api/src/Telemetric.Api/Features/Actions/Templates/UpdateTemplate/UpdateTemplateEndpoint.cs"
  "contexto/work/features/acciones_modulo/03_execution/ACT-005/phase-01.md"
)

for rel in "${candidate_files[@]}"; do
  log_command "test -f $rel"
  if [[ -f "$REPO_ROOT/$rel" ]]; then
    log_output "Observed: file_exists[$rel]=true"
  else
    log_output "Observed: file_exists[$rel]=false"
  fi
done

openapi_file="$REPO_ROOT/contexto/openapi/actions.yaml"
types_file="$REPO_ROOT/telemetric-front/src/features/actions/types.ts"
create_endpoint_file="$REPO_ROOT/telemetric-api/src/Telemetric.Api/Features/Actions/Templates/CreateTemplate/CreateTemplateEndpoint.cs"
update_endpoint_file="$REPO_ROOT/telemetric-api/src/Telemetric.Api/Features/Actions/Templates/UpdateTemplate/UpdateTemplateEndpoint.cs"
phase_summary_file="$REPO_ROOT/contexto/work/features/acciones_modulo/03_execution/ACT-005/phase-01.md"

has_summary_definitionjsonv1="$(contains_text "$phase_summary_file" 'DefinitionJsonV1')"
has_openapi_definitionjsonv1="$(contains_text "$openapi_file" 'DefinitionJsonV1')"
has_discriminator="$(contains_text "$openapi_file" 'discriminator:')"
has_property_ruletype="$(contains_text "$openapi_file" 'propertyName: ruleType')"
has_rule_type_1="$(contains_text "$openapi_file" 'INSTANT_THRESHOLD')"
has_rule_type_2="$(contains_text "$openapi_file" 'CONTINUOUS_DURATION')"
has_rule_type_3="$(contains_text "$openapi_file" 'ACCUMULATED_DURATION_WINDOW')"
has_rule_type_4="$(contains_text "$openapi_file" 'AGGREGATION_WINDOW')"
has_rule_type_5="$(contains_text "$openapi_file" 'COUNT_OCCURRENCES_WINDOW')"
has_create_object_validation="$(contains_text "$create_endpoint_file" 'JsonValueKind.Object')"
has_update_object_validation="$(contains_text "$update_endpoint_file" 'JsonValueKind.Object')"
has_create_getrawtext="$(contains_text "$create_endpoint_file" 'GetRawText()')"
has_update_getrawtext="$(contains_text "$update_endpoint_file" 'GetRawText()')"
has_update_route_token="$(contains_text "$update_endpoint_file" 'Put("/api/v1/actions/templates/{ruleTemplateId}")')"
has_openapi_update_route_token="$(contains_text "$openapi_file" '/api/v1/actions/templates/{ruleTemplateId}')"
has_rule_type_front="$(contains_text "$types_file" 'export type RuleType')"
has_duration_front="$(contains_text "$types_file" 'durationSeconds')"

if [[ "$has_rule_type_1" == "true" && "$has_rule_type_2" == "true" && "$has_rule_type_3" == "true" && "$has_rule_type_4" == "true" && "$has_rule_type_5" == "true" ]]; then
  has_all_rule_types="true"
else
  has_all_rule_types="false"
fi

if [[ "$has_discriminator" == "true" && "$has_property_ruletype" == "true" ]]; then
  has_discriminator_ruletype="true"
else
  has_discriminator_ruletype="false"
fi

if [[ "$has_update_route_token" == "true" && "$has_openapi_update_route_token" == "true" ]]; then
  has_aligned_route_token="true"
else
  has_aligned_route_token="false"
fi

log_output "Observed: phase_summary_contains_definitionjsonv1=$has_summary_definitionjsonv1"
log_output "Observed: openapi_has_definitionjsonv1=$has_openapi_definitionjsonv1"
log_output "Observed: openapi_has_discriminator_ruletype=$has_discriminator_ruletype"
log_output "Observed: openapi_has_all_rule_types=$has_all_rule_types"
log_output "Observed: create_endpoint_object_validation=$has_create_object_validation"
log_output "Observed: update_endpoint_object_validation=$has_update_object_validation"
log_output "Observed: create_endpoint_getrawtext=$has_create_getrawtext"
log_output "Observed: update_endpoint_getrawtext=$has_update_getrawtext"
log_output "Observed: update_route_ruleTemplateId_aligned=$has_aligned_route_token"
log_output "Observed: frontend_rule_type_declared=$has_rule_type_front"
log_output "Observed: frontend_duration_seconds_declared=$has_duration_front"

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
