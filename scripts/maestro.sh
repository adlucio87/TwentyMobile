#!/bin/bash
# ==============================================================================
# scripts/maestro.sh — Esegui i test E2E Maestro
#
# Uso:
#   scripts/maestro.sh                  # tutti i flussi in .maestro/
#   scripts/maestro.sh <file.yaml>      # singolo flusso
#   scripts/maestro.sh onboarding_auth_methods
# ==============================================================================
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

export PATH="$PATH:$HOME/.maestro/bin"

if ! command -v maestro >/dev/null 2>&1; then
    echo "❌ Maestro CLI non installata. Installa con: curl -Ls 'https://get.maestro.mobile.dev' | bash"
    exit 1
fi

cd "$ROOT_DIR"

if [ -n "$1" ]; then
    FLOW="$1"
    if [ -f "$FLOW" ]; then
        echo "▶ maestro test $FLOW"
        maestro test "$FLOW"
    elif [ -f ".maestro/$FLOW" ]; then
        echo "▶ maestro test .maestro/$FLOW"
        maestro test ".maestro/$FLOW"
    elif [ -f ".maestro/$FLOW.yaml" ]; then
        echo "▶ maestro test .maestro/$FLOW.yaml"
        maestro test ".maestro/$FLOW.yaml"
    else
        echo "❌ Flusso non trovato: $FLOW"
        exit 1
    fi
else
    echo "▶ maestro test .maestro/"
    maestro test .maestro/
fi
