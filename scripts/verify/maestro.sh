#!/bin/bash
# ==============================================================================
# scripts/verify/maestro.sh — E2E Maestro (OPZIONALE)
# Esegue i flussi .maestro/ SOLO se è presente un device/emulatore connesso.
# Se non c'è device, salta SENZA errore (exit 0).
#
# Variabili d'ambiente:
#   MAESTRO_ARGS   argomenti extra per `maestro test`
# ==============================================================================
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
MAESTRO_DIR="$ROOT_DIR/.maestro"

export PATH="$PATH:$HOME/.maestro/bin"

echo "=== Maestro ==="

if ! command -v maestro >/dev/null 2>&1; then
    echo "⚠️  maestro non installato (curl -Ls \"https://get.maestro.mobile.dev\" | bash) — skip."
    exit 0
fi

if [ ! -d "$MAESTRO_DIR" ] || [ -z "$(ls -A "$MAESTRO_DIR"/*.yaml 2>/dev/null)" ]; then
    echo "⏭️  Nessun flusso .yaml in $MAESTRO_DIR — skip."
    exit 0
fi

# --- Rilevamento device (Android via adb, iOS simulator via simctl) ---
has_device() {
    if command -v adb >/dev/null 2>&1; then
        if adb devices 2>/dev/null | awk 'NR>1 && $2=="device" {found=1} END {exit !found}'; then
            return 0
        fi
    fi
    if command -v xcrun >/dev/null 2>&1; then
        if xcrun simctl list devices booted 2>/dev/null | grep -q "Booted"; then
            return 0
        fi
    fi
    return 1
}

if ! has_device; then
    echo "⚠️  Nessun device/emulatore connesso — Maestro skipped (opzionale)."
    exit 0
fi

cd "$ROOT_DIR"
# shellcheck disable=SC2086
maestro test "$MAESTRO_DIR" ${MAESTRO_ARGS:-}

echo "=== MAESTRO OK ==="
