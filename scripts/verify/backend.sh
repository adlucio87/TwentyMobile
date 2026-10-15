#!/bin/bash
# ==============================================================================
# scripts/verify/backend.sh — Cloud Functions (OAuth client registry)
# Controllo di sintassi (node --check) + unit test della logica pura (`npm test`).
# Salta senza errore se backend/ non esiste o se node non è installato.
# ==============================================================================
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
BACKEND_DIR="$ROOT_DIR/backend"

echo "=== Backend (Cloud Functions) ==="
echo "📂 Backend dir: $BACKEND_DIR"

if [ ! -f "$BACKEND_DIR/index.js" ]; then
    echo "⏭️  Nessun backend/index.js — skip."
    exit 0
fi

if ! command -v node >/dev/null 2>&1; then
    echo "⚠️  node non installato — backend skipped (opzionale)."
    exit 0
fi

cd "$BACKEND_DIR"

node --check index.js
node --check lib/registry.js

# I test usano solo il runner nativo di Node: nessun `npm install` richiesto.
node --test test/*.test.js

echo "=== BACKEND VERIFY OK ==="
