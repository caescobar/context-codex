#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACK_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
EVIDENCE_DIR="$PACK_DIR/evidence"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../../../../../../.." && pwd)"

DRY_RUN="${DRY_RUN:-1}"
API_BASE_URL="${API_BASE_URL:-http://localhost:5220}"
API_USER="${API_USER:-admin}"
API_PASSWORD="${API_PASSWORD:-admin123}"
RULE_TEMPLATE_ID="${RULE_TEMPLATE_ID:-1}"
SQLCMD_ARGS="${SQLCMD_ARGS:-}"

COMMANDS_LOG="$EVIDENCE_DIR/commands.log"
OUTPUTS_LOG="$EVIDENCE_DIR/outputs.log"
NOTES_FILE="$EVIDENCE_DIR/notes.md"

mkdir -p "$EVIDENCE_DIR"
touch "$COMMANDS_LOG" "$OUTPUTS_LOG" "$NOTES_FILE"

log_command() {
  echo "$(date -Iseconds) | $1" >> "$COMMANDS_LOG"
}

log_output() {
  echo "$(date -Iseconds) | $1" >> "$OUTPUTS_LOG"
}

run_step() {
  local cmd="$1"
  log_command "$cmd"
  if [[ "$DRY_RUN" == "1" ]]; then
    echo "[DRY_RUN] $cmd"
    log_output "Observed (pendiente): DRY_RUN=1 no ejecuto comando."
    return 0
  fi

  echo "[EXEC] $cmd"
  bash -lc "$cmd"
}

log_output "Expected: run valida GET/PUT templates con versionado inmutable."
log_output "Observed: inicio run (DRY_RUN=$DRY_RUN, RULE_TEMPLATE_ID=$RULE_TEMPLATE_ID)."

pushd "$REPO_ROOT" >/dev/null

run_step "rg --line-number --glob '*.cs' 'api/v1/actions/templates/{RuleTemplateId}|PermissionClaims.Actions.View|PermissionClaims.Actions.Update|Tags(\"Actions\")' telemetric-api/src/Telemetric.Api/Features/Actions/Templates" | tee -a "$OUTPUTS_LOG" || true
run_step "rg --line-number --glob '*.yaml' '/api/v1/actions/templates/{ruleTemplateId}|updateActionTemplate|getActionTemplateById' contexto/openapi/actions.yaml" | tee -a "$OUTPUTS_LOG" || true

if [[ "$DRY_RUN" == "1" ]]; then
  run_step "curl -s -X POST '$API_BASE_URL/api/v1/auth/login' -H 'Content-Type: application/json' -d '{\"username\":\"$API_USER\",\"password\":\"$API_PASSWORD\"}'"
  run_step "curl -s -X GET '$API_BASE_URL/api/v1/actions/templates/$RULE_TEMPLATE_ID' -H 'Authorization: Bearer <TOKEN>'"
  run_step "curl -s -X PUT '$API_BASE_URL/api/v1/actions/templates/$RULE_TEMPLATE_ID' -H 'Authorization: Bearer <TOKEN>' -H 'Content-Type: application/json' -d '{\"ruleTemplateId\":$RULE_TEMPLATE_ID,\"name\":\"Template QA\",\"description\":\"QA phase-02\",\"definitionJson\":\"{\\\"trigger\\\":{\\\"metricCode\\\":\\\"temperature\\\"},\\\"condition\\\":{\\\"operator\\\":\\\">\\\",\\\"value\\\":70}}\",\"isActive\":true}'"
  run_step "curl -s -X GET '$API_BASE_URL/api/v1/actions/templates/$RULE_TEMPLATE_ID' -H 'Authorization: Bearer <TOKEN>'"
else
  if ! command -v jq >/dev/null 2>&1; then
    log_output "Observed: jq no disponible; en DRY_RUN=0 se requiere jq para parsear JSON."
    exit 1
  fi

  login_cmd="curl -s -X POST '$API_BASE_URL/api/v1/auth/login' -H 'Content-Type: application/json' -d '{\"username\":\"$API_USER\",\"password\":\"$API_PASSWORD\"}'"
  log_command "$login_cmd"
  login_raw="$(bash -lc "$login_cmd")"
  echo "$login_raw" | tee -a "$OUTPUTS_LOG" >/dev/null

  token="$(echo "$login_raw" | jq -r '.token // empty')"

  if [[ -z "$token" ]]; then
    log_output "Observed: login sin token, abortando flujo HTTP."
    exit 1
  fi

  get_before_cmd="curl -s -X GET '$API_BASE_URL/api/v1/actions/templates/$RULE_TEMPLATE_ID' -H 'Authorization: Bearer $token'"
  log_command "$get_before_cmd"
  before_raw="$(bash -lc "$get_before_cmd")"
  echo "$before_raw" | tee -a "$OUTPUTS_LOG" >/dev/null

  prev_version="$(echo "$before_raw" | jq -r '.currentVersion.versionNumber // 0')"
  name_before="$(echo "$before_raw" | jq -r '.name // "Template QA"')"
  description_before="$(echo "$before_raw" | jq -r '.description // empty')"
  is_active="$(echo "$before_raw" | jq -r '.isActive // true')"
  definition_json="$(echo "$before_raw" | jq -r '.currentVersion.definitionJson // "{\"trigger\":{\"metricCode\":\"temperature\"},\"condition\":{\"operator\":\">\",\"value\":70}}"')"

  name_after="$name_before [qa-phase-02]"
  payload="$(printf '{"ruleTemplateId":%s,"name":"%s","description":"%s","definitionJson":%s,"isActive":%s}' "$RULE_TEMPLATE_ID" "$name_after" "$description_before" "$(printf '%s' "$definition_json" | jq -Rs '.')" "$is_active")"

  put_cmd="curl -s -X PUT '$API_BASE_URL/api/v1/actions/templates/$RULE_TEMPLATE_ID' -H 'Authorization: Bearer $token' -H 'Content-Type: application/json' -d '$payload'"
  log_command "$put_cmd"
  put_raw="$(bash -lc "$put_cmd")"
  echo "$put_raw" | tee -a "$OUTPUTS_LOG" >/dev/null

  get_after_cmd="curl -s -X GET '$API_BASE_URL/api/v1/actions/templates/$RULE_TEMPLATE_ID' -H 'Authorization: Bearer $token'"
  log_command "$get_after_cmd"
  after_raw="$(bash -lc "$get_after_cmd")"
  echo "$after_raw" | tee -a "$OUTPUTS_LOG" >/dev/null

  post_version="$(echo "$after_raw" | jq -r '.currentVersion.versionNumber // 0')"
  expected=$((prev_version + 1))
  prev_exists="$(echo "$after_raw" | jq -r --argjson v "$prev_version" '(.versions // []) | any(.versionNumber == $v)')"
  log_output "Expected: versionNumber post = pre + 1 ($expected)."
  log_output "Observed: pre=$prev_version, post=$post_version."
  log_output "Expected: version previa sigue en historial."
  log_output "Observed: previousVersionPresent=$prev_exists"
fi

if [[ -n "$SQLCMD_ARGS" ]]; then
  run_step "sqlcmd $SQLCMD_ARGS -i '$PACK_DIR/queries.sql' -v RuleTemplateId=$RULE_TEMPLATE_ID" | tee -a "$OUTPUTS_LOG" || true
else
  log_output "Observed: SQL opcional no ejecutado (SQLCMD_ARGS no definido)."
fi

popd >/dev/null

log_output "Observed: run finalizado."
