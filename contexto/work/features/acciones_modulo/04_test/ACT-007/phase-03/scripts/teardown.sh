#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACK_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
EVIDENCE_DIR="$PACK_DIR/evidence"
DRY_RUN="${DRY_RUN:-1}"

COMMANDS_LOG="$EVIDENCE_DIR/commands.log"
OUTPUTS_LOG="$EVIDENCE_DIR/outputs.log"
NOTES_FILE="$EVIDENCE_DIR/notes.md"

mkdir -p "$EVIDENCE_DIR"
touch "$COMMANDS_LOG" "$OUTPUTS_LOG" "$NOTES_FILE"

{
  echo "$(date -Iseconds) | teardown phase-03 (safe no-op), DRY_RUN=$DRY_RUN"
} >> "$COMMANDS_LOG"

{
  echo "$(date -Iseconds) | Expected: teardown without destructive actions."
  echo "$(date -Iseconds) | Observed: no-op executed."
  echo "$(date -Iseconds) | Runtime closure rule: any instance started during QA must be stopped and verified as not running."
} >> "$OUTPUTS_LOG"

{
  echo "- Teardown phase-03: no destructive actions were performed."
  echo "- If services were started during DRY_RUN=0, stop them and verify they are not running."
} >> "$NOTES_FILE"

echo "Teardown completed (safe no-op)."
