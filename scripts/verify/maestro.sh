#!/bin/bash
# ==============================================================================
# scripts/verify/maestro.sh
# Esegue i flussi E2E Maestro presenti nella cartella .maestro/.
# Salta automaticamente se Maestro o i flussi non sono disponibili.
#
# Variabili d'ambiente opzionali:
#   MAESTRO_ARGS   argomenti extra per `maestro test` (es. "-e USER=x -e PASS=y")
# ==============================================================================
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
MAESTRO_DIR="$ROOT_DIR/.maestro"

# Maestro di default è installato in ~/.maestro/bin
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

cd "$ROOT_DIR"
# shellcheck disable=SC2086
maestro test "$MAESTRO_DIR" ${MAESTRO_ARGS:-}

echo "=== MAESTRO VERIFY OK ==="
