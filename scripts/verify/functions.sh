#!/bin/bash
# ==============================================================================
# scripts/verify/functions.sh
# Esegue i test delle Firebase / Cloud Functions (npm test).
# Salta automaticamente se non esiste una cartella functions con package.json.
# ==============================================================================
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# --- Rileva la directory delle functions (preferendo quella con script "test") ---
FUNCTIONS_DIR=""
FALLBACK=""
for d in \
    "$ROOT_DIR/functions/functions" \
    "$ROOT_DIR/backend/functions/functions-ts" \
    "$ROOT_DIR/functions" \
    "$ROOT_DIR/backend/functions"; do
    if [ -f "$d/package.json" ]; then
        [ -z "$FALLBACK" ] && FALLBACK="$d"
        if grep -q '"test"' "$d/package.json"; then
            FUNCTIONS_DIR="$d"
            break
        fi
    fi
done
[ -z "$FUNCTIONS_DIR" ] && FUNCTIONS_DIR="$FALLBACK"

echo "=== Firebase Functions ==="
if [ -z "$FUNCTIONS_DIR" ]; then
    echo "⏭️  Nessuna cartella functions con package.json trovata — skip."
    exit 0
fi

echo "📂 Functions dir: $FUNCTIONS_DIR"
cd "$FUNCTIONS_DIR"

if ! grep -q '"test"' package.json; then
    echo "⏭️  Nessuno script 'test' in package.json — skip."
    exit 0
fi

[ -d node_modules ] || npm install
npm test

echo "=== FUNCTIONS VERIFY OK ==="
