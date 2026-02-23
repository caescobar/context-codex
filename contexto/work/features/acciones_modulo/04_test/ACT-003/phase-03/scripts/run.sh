#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACK_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
EVIDENCE_DIR="$PACK_DIR/evidence"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../../../../../../.." && pwd)"

DRY_RUN="${DRY_RUN:-1}"
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

log_output "Expected: run valida criterios de fase-03 (rutas/actions, labels ES, tipos EN, servicio con axios core)."
log_output "Observed: inicio run (DRY_RUN=$DRY_RUN)."

candidate_files=(
  "telemetric-front/src/features/actions/actions.routes.ts"
  "telemetric-front/src/features/actions/actions.service.ts"
  "telemetric-front/src/features/actions/types.ts"
  "telemetric-front/src/features/actions/views/ActionsTemplatesView.vue"
  "telemetric-front/src/features/actions/views/ActionTemplateDetailView.vue"
)

for rel in "${candidate_files[@]}"; do
  log_command "test -f $rel"
  if [[ -f "$REPO_ROOT/$rel" ]]; then
    log_output "Observed: file_exists[$rel]=true"
  else
    log_output "Observed: file_exists[$rel]=false"
  fi
done

router_index="$REPO_ROOT/telemetric-front/src/router/index.ts"
main_routes="$REPO_ROOT/telemetric-front/src/router/MainRoutes.ts"
admin_routes="$REPO_ROOT/telemetric-front/src/router/AdminRoutes.ts"
actions_routes="$REPO_ROOT/telemetric-front/src/features/actions/actions.routes.ts"
actions_service="$REPO_ROOT/telemetric-front/src/features/actions/actions.service.ts"
actions_types="$REPO_ROOT/telemetric-front/src/features/actions/types.ts"
actions_list_view="$REPO_ROOT/telemetric-front/src/features/actions/views/ActionsTemplatesView.vue"
actions_detail_view="$REPO_ROOT/telemetric-front/src/features/actions/views/ActionTemplateDetailView.vue"

route_actions="false"
route_detail="false"
for f in "$actions_routes" "$router_index" "$main_routes" "$admin_routes"; do
  [[ "$(contains_text "$f" "/actions")" == "true" ]] && route_actions="true"
  [[ "$(contains_text "$f" "/actions/templates/:id")" == "true" ]] && route_detail="true"
done
log_output "Observed: route_exists[/actions]=$route_actions"
log_output "Observed: route_exists[/actions/templates/:id]=$route_detail"

service_core_axios="false"
service_templates_endpoint="false"
[[ "$(contains_text "$actions_service" "@/core/utils/axios")" == "true" ]] && service_core_axios="true"
[[ "$(contains_text "$actions_service" "httpClient")" == "true" ]] && service_core_axios="true"
[[ "$(contains_text "$actions_service" "/api/v1/actions/templates")" == "true" ]] && service_templates_endpoint="true"
[[ "$(contains_text "$actions_service" "actions/templates")" == "true" ]] && service_templates_endpoint="true"
log_output "Observed: service_uses_core_axios=$service_core_axios"
log_output "Observed: service_uses_templates_endpoint=$service_templates_endpoint"

types_english_hints="false"
views_spanish_hints="false"
[[ "$(contains_text "$actions_types" "interface ")" == "true" ]] && types_english_hints="true"
[[ "$(contains_text "$actions_types" "type ")" == "true" ]] && types_english_hints="true"
[[ "$(contains_text "$actions_list_view" "Plantillas")" == "true" ]] && views_spanish_hints="true"
[[ "$(contains_text "$actions_list_view" "Acciones")" == "true" ]] && views_spanish_hints="true"
[[ "$(contains_text "$actions_detail_view" "Plantillas")" == "true" ]] && views_spanish_hints="true"
[[ "$(contains_text "$actions_detail_view" "Acciones")" == "true" ]] && views_spanish_hints="true"
log_output "Observed: types_file_has_english_contract_hints=$types_english_hints"
log_output "Observed: views_have_spanish_label_hints=$views_spanish_hints"

if [[ "$DRY_RUN" == "1" ]]; then
  log_command "npm --prefix telemetric-front run typecheck"
  log_command "read baseline from baseline.json"
  log_output "Observed (pendiente): typecheck no ejecutado por DRY_RUN=1."
  log_output "Observed (pendiente): gate no-regresion no evaluado por DRY_RUN=1."
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
  log_command "npm --prefix telemetric-front run typecheck"
  tmp_out="$(mktemp)"
  set +e
  npm --prefix telemetric-front run typecheck >"$tmp_out" 2>&1
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
fi

log_output "Observed: run finalizado."
