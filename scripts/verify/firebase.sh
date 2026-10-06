#!/bin/bash
# ==============================================================================
# scripts/verify/firebase.sh
# Verifica la configurazione Firebase: presenza e validità di firebase.json e
# del progetto di default (.firebaserc). Salta se non applicabile.
# ==============================================================================
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo "=== Firebase ==="

if ! command -v firebase >/dev/null 2>&1; then
    echo "⚠️  firebase CLI non installata (npm i -g firebase-tools) — skip."
    exit 0
fi

# --- Rileva la directory con firebase.json (root o ./backend) ---
FIREBASE_DIR=""
for d in "$ROOT_DIR" "$ROOT_DIR/backend"; do
    if [ -f "$d/firebase.json" ]; then
        FIREBASE_DIR="$d"
        break
    fi
done

if [ -z "$FIREBASE_DIR" ]; then
    echo "⏭️  Nessun firebase.json trovato — skip."
    exit 0
fi

echo "📂 Firebase dir: $FIREBASE_DIR"
cd "$FIREBASE_DIR"

# Validità JSON della configurazione
node -e "JSON.parse(require('fs').readFileSync('firebase.json','utf8')); console.log('✓ firebase.json valido');"

# Progetto di default (se presente .firebaserc)
if [ -f .firebaserc ]; then
    node -e "const c=JSON.parse(require('fs').readFileSync('.firebaserc','utf8')); const p=c.projects && c.projects.default; console.log(p ? ('✓ progetto default: ' + p) : '⚠️  nessun progetto default in .firebaserc');"
fi

echo "=== FIREBASE VERIFY OK ==="
