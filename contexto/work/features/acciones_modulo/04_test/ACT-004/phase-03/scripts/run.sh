#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACK_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
EVIDENCE_DIR="$PACK_DIR/evidence"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../../../../../../.." && pwd)"

DRY_RUN="${DRY_RUN:-1}"
FRONTEND_DIR="${FRONTEND_DIR:-telemetric-front}"
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

log_output "Expected: run valida criterios ACT-004 phase-03 (asignacion masiva FE, feedback, no-regresion)."
log_output "Observed: inicio run (DRY_RUN=$DRY_RUN)."

candidate_files=(
  "telemetric-front/src/features/actions/actions.service.ts"
  "telemetric-front/src/features/actions/types.ts"
  "telemetric-front/src/features/actions/views/ActionsTemplatesView.vue"
  "telemetric-front/src/features/actions/views/ActionTemplateDetailView.vue"
  "contexto/work/features/acciones_modulo/03_execution/ACT-004/phase-03.md"
)

for rel in "${candidate_files[@]}"; do
  log_command "test -f $rel"
  if [[ -f "$REPO_ROOT/$rel" ]]; then
    log_output "Observed: file_exists[$rel]=true"
  else
    log_output "Observed: file_exists[$rel]=false"
  fi
done

service_file="$REPO_ROOT/telemetric-front/src/features/actions/actions.service.ts"
types_file="$REPO_ROOT/telemetric-front/src/features/actions/types.ts"
list_view_file="$REPO_ROOT/telemetric-front/src/features/actions/views/ActionsTemplatesView.vue"
detail_view_file="$REPO_ROOT/telemetric-front/src/features/actions/views/ActionTemplateDetailView.vue"
phase_summary_file="$REPO_ROOT/contexto/work/features/acciones_modulo/03_execution/ACT-004/phase-03.md"

log_output "Observed: reuse_first_trace_in_phase_summary=$(contains_text "$phase_summary_file" "Reuse-first")"
log_output "Observed: type_assign_request=$(contains_text "$types_file" "AssignTemplateToDevicesRequest")"
log_output "Observed: type_assign_response=$(contains_text "$types_file" "AssignTemplateToDevicesResponse")"
log_output "Observed: type_status_rejected_duplicate=$(contains_text "$types_file" "RejectedDuplicate")"
log_output "Observed: type_status_rejected_out_of_scope=$(contains_text "$types_file" "RejectedNotFoundOrOutOfScope")"
log_output "Observed: service_assign_method=$(contains_text "$service_file" "assignTemplateToDevices")"
log_output "Observed: service_assign_endpoint=$(contains_text "$service_file" "/actions/assignments/template-version")"
log_output "Observed: service_assignable_devices_method=$(contains_text "$service_file" "getAssignableDevices")"
log_output "Observed: service_devices_endpoint=$(contains_text "$service_file" "/devices")"
log_output "Observed: ui_assign_button_list_view=$(contains_text "$list_view_file" "Asignar seleccionados")"
log_output "Observed: ui_assign_button_detail_view=$(contains_text "$detail_view_file" "Asignar seleccionados")"
log_output "Observed: ui_duplicate_label_list=$(contains_text "$list_view_file" "Duplicado")"
log_output "Observed: ui_out_of_scope_label_list=$(contains_text "$list_view_file" "Fuera de alcance")"
log_output "Observed: ui_duplicate_label_detail=$(contains_text "$detail_view_file" "Duplicado")"
log_output "Observed: ui_out_of_scope_label_detail=$(contains_text "$detail_view_file" "Fuera de alcance")"
log_output "Observed: ui_created_count_visible=$(contains_text "$list_view_file" "assignResult.createdCount")"
log_output "Observed: ui_rejected_count_visible=$(contains_text "$list_view_file" "assignResult.rejectedCount")"
log_output "Observed: ui_result_items_list=$(contains_text "$list_view_file" "assignResult.items")"
log_output "Observed: ui_result_items_detail=$(contains_text "$detail_view_file" "assignResult.items")"

if [[ "$DRY_RUN" == "1" ]]; then
  log_command "npm --prefix $FRONTEND_DIR run typecheck"
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
fi

log_output "Observed: run finalizado."
