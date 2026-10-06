#!/bin/bash
# ==============================================================================
# scripts/deploy/firebase.sh
# Deploy delle risorse Firebase (rules / hosting / config / ...).
#
# Uso: scripts/deploy/firebase.sh [target ...]
#   es. scripts/deploy/firebase.sh database storage
#   senza argomenti esegue un deploy completo (`firebase deploy`).
# ==============================================================================
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# --- Rileva la directory con firebase.json (root o ./backend) ---
FIREBASE_DIR=""
for d in "$ROOT_DIR" "$ROOT_DIR/backend"; do
    [ -f "$d/firebase.json" ] && { FIREBASE_DIR="$d"; break; }
done

if [ -z "$FIREBASE_DIR" ]; then
    echo "⏭️  Nessun firebase.json trovato — skip."
    exit 0
fi

cd "$FIREBASE_DIR"
echo "=== Deploy Firebase ==="
echo "📂 Firebase dir: $FIREBASE_DIR"

if [ "$#" -gt 0 ]; then
    ONLY="$(IFS=,; echo "$*")"
    echo "▶ firebase deploy --only $ONLY"
    firebase deploy --only "$ONLY"
else
    echo "▶ firebase deploy"
    firebase deploy
fi

echo "=== FIREBASE DEPLOY OK ==="
