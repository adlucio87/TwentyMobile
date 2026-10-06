#!/bin/bash
# ==============================================================================
# scripts/verify/all.sh
# Esegue la pipeline di verifica disponibile: Flutter + Functions + Firebase
# (+ Maestro con WITH_MAESTRO=1). Salta gli step i cui script non esistono.
# ==============================================================================
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

run_step() {
    local step="$1"
    if [ -x "$SCRIPT_DIR/$step" ]; then
        "$SCRIPT_DIR/$step"
    else
        echo "⏭️  $step non presente — skip."
    fi
}

run_step flutter.sh
run_step functions.sh
run_step firebase.sh

if [ "${WITH_MAESTRO:-0}" = "1" ]; then
    run_step maestro.sh
fi

echo ""
echo "=== ✅ VERIFY ALL OK ==="
