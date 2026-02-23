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

echo "$(date -Iseconds) | teardown phase-04 (safe no-op), DRY_RUN=$DRY_RUN" >> "$COMMANDS_LOG"
echo "$(date -Iseconds) | Expected: teardown sin borrar datos criticos." >> "$OUTPUTS_LOG"
echo "$(date -Iseconds) | Observed: no-op ejecutado." >> "$OUTPUTS_LOG"
echo "$(date -Iseconds) | Observed: cierre operativo -> si se levantaron instancias para QA, deben apagarse y verificarse detenidas." >> "$OUTPUTS_LOG"
echo "- Teardown phase-04: no se realizaron cambios destructivos." >> "$NOTES_FILE"
echo "- Regla de cierre: toda instancia levantada durante QA debe apagarse y verificarse como detenida." >> "$NOTES_FILE"

echo "Teardown completado (safe no-op)."
