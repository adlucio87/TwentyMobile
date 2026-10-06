#!/bin/bash
# ==============================================================================
# scripts/smoke/production.sh
# Smoke test post-deploy contro l'ambiente di produzione.
#
# Personalizza l'array CHECKS con gli URL/endpoint da verificare (HTTP 200 atteso).
# ==============================================================================
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- Elenco degli endpoint da verificare (HTTP 200 atteso) ---
CHECKS=(
    # "https://sendtokindle.luciosoft.it/"
)

echo "=== SMOKE (production) ==="

if [ "${#CHECKS[@]}" -eq 0 ]; then
    echo "⏭️  Nessun check configurato — personalizza l'array CHECKS in $0."
    exit 0
fi

fail=0
for url in "${CHECKS[@]}"; do
    code="$(curl -s -o /dev/null -w '%{http_code}' "$url" || echo 000)"
    if [ "$code" = "200" ]; then
        echo "✓ $url ($code)"
    else
        echo "✗ $url ($code)"
        fail=1
    fi
done

if [ "$fail" -ne 0 ]; then
    echo "=== ❌ SMOKE FAILED ==="
    exit 1
fi

echo "=== ✅ SMOKE OK ==="
