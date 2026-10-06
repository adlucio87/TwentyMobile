#!/bin/bash
# ==============================================================================
# scripts/deploy/functions.sh
# Build e deploy delle Firebase / Cloud Functions.
# Salta se non esistono le functions; richiede firebase.json per il deploy.
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

# --- Rileva la directory con firebase.json (root o ./backend) ---
FIREBASE_DIR=""
for d in "$ROOT_DIR" "$ROOT_DIR/backend"; do
    [ -f "$d/firebase.json" ] && { FIREBASE_DIR="$d"; break; }
done

echo "=== Deploy Functions ==="
if [ -z "$FUNCTIONS_DIR" ]; then
    echo "⏭️  Nessuna cartella functions con package.json — skip."
    exit 0
fi
if [ -z "$FIREBASE_DIR" ]; then
    echo "❌ Nessun firebase.json trovato per il deploy delle functions."
    exit 1
fi

echo "📂 Functions dir: $FUNCTIONS_DIR"
echo "📂 Firebase dir:  $FIREBASE_DIR"

cd "$FUNCTIONS_DIR"
if grep -q '"build"' package.json; then
    echo "🔨 npm run build"
    npm run build
fi

cd "$FIREBASE_DIR"
echo "▶ firebase deploy --only functions"
firebase deploy --only functions

echo "=== FUNCTIONS DEPLOY OK ==="
