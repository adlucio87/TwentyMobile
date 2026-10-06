#!/bin/bash
# ==============================================================================
# scripts/verify.sh — Quality gate
# Rileva le aree modificate dal diff Git ed esegue le verifiche pertinenti.
#
# Uso:
#   scripts/verify.sh                  # aree modificate (uncommitted, altrimenti ultimo commit)
#   scripts/verify.sh --all            # tutte le verifiche MANDATORY (+ Maestro se device)
#   scripts/verify.sh --area <area>    # forza un'area: flutter|functions|firebase|maestro
#   scripts/verify.sh --no-maestro     # salta Maestro anche se c'è un device
#
# MANDATORY: flutter, functions, firebase   |   OPTIONAL: maestro (richiede device)
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$ROOT_DIR"

AREA_ARG=""
FORCE_ALL=0
NO_MAESTRO=0
while [ $# -gt 0 ]; do
    case "$1" in
        --all) FORCE_ALL=1 ;;
        --area) AREA_ARG="$2"; shift ;;
        --no-maestro) NO_MAESTRO=1 ;;
        -h|--help) echo "Uso: scripts/verify.sh [--all] [--area flutter|functions|firebase|maestro] [--no-maestro]"; exit 0 ;;
        *) echo "❌ Parametro sconosciuto: $1"; exit 2 ;;
    esac
    shift
done

# ---- File cambiati: uncommitted (staged+unstaged+untracked), altrimenti ultimo commit ----
CHANGED=""
if [ "$(git rev-parse --is-inside-work-tree 2>/dev/null)" = "true" ]; then
    CHANGED="$({ git diff --name-only HEAD -- 2>/dev/null || true; git ls-files --others --exclude-standard 2>/dev/null || true; } | sort -u)"
    if [ -z "$CHANGED" ]; then
        CHANGED="$(git diff --name-only HEAD~1 HEAD -- 2>/dev/null || true)"
    fi
fi

in_area() { printf '%s\n' "$CHANGED" | grep -Eq "$1" 2>/dev/null; }

detect_flutter=0; detect_functions=0; detect_firebase=0; detect_maestro=0

if in_area '(^|/)(lib|test|integration_test)/|(^|/)(pubspec\.yaml|analysis_options\.yaml)$|\.dart$'; then detect_flutter=1; fi
if in_area '(^|/)functions/'; then detect_functions=1; fi
if in_area '(^|/)(firebase\.json|\.firebaserc|firestore\.rules|storage\.rules|database\.rules\.json|remoteconfig.*\.json|realtimedb.*\.json|cors\.json)$'; then detect_firebase=1; fi
if in_area '(^|/)\.maestro/'; then detect_maestro=1; fi

RUN_FLUTTER=0; RUN_FUNCTIONS=0; RUN_FIREBASE=0; RUN_MAESTRO=0
if [ -n "$AREA_ARG" ]; then
    case "$AREA_ARG" in
        flutter)   RUN_FLUTTER=1 ;;
        functions) RUN_FUNCTIONS=1 ;;
        firebase)  RUN_FIREBASE=1 ;;
        maestro)   RUN_MAESTRO=1 ;;
        *) echo "❌ Area sconosciuta: $AREA_ARG (flutter|functions|firebase|maestro)"; exit 2 ;;
    esac
elif [ "$FORCE_ALL" = "1" ]; then
    RUN_FLUTTER=1; RUN_FUNCTIONS=1; RUN_FIREBASE=1; RUN_MAESTRO=1
else
    RUN_FLUTTER=$detect_flutter
    RUN_FUNCTIONS=$detect_functions
    RUN_FIREBASE=$detect_firebase
    RUN_MAESTRO=$detect_maestro
    if [ "$RUN_FLUTTER" = "0" ] && [ "$RUN_FUNCTIONS" = "0" ] && [ "$RUN_FIREBASE" = "0" ]; then
        RUN_FLUTTER=1; RUN_FUNCTIONS=1; RUN_FIREBASE=1
    fi
fi
[ "$NO_MAESTRO" = "1" ] && RUN_MAESTRO=0

echo "=============================================="
echo "  VERIFY — quality gate"
echo "=============================================="
printf "Changed: Flutter=%s  Functions=%s  Firebase=%s  Maestro=%s\n" \
    "$([ "$RUN_FLUTTER" = "1" ] && echo yes || echo no)" \
    "$([ "$RUN_FUNCTIONS" = "1" ] && echo yes || echo no)" \
    "$([ "$RUN_FIREBASE" = "1" ] && echo yes || echo no)" \
    "$([ "$RUN_MAESTRO" = "1" ] && echo yes || echo no)"

FAILED=""
run_check() {
    local label="$1" script="$2" mandatory="$3"
    echo ""
    echo "▶ $label"
    if [ ! -x "$SCRIPT_DIR/verify/$script" ]; then
        echo "⏭️  $script non presente — skip."
        return 0
    fi
    if "$SCRIPT_DIR/verify/$script"; then
        echo "✅ $label: PASS"
    else
        echo "❌ $label: FAIL"
        [ "$mandatory" = "1" ] && FAILED="$FAILED $label"
    fi
}

[ "$RUN_FLUTTER"   = "1" ] && run_check "Flutter"            "flutter.sh"   1
[ "$RUN_FUNCTIONS" = "1" ] && run_check "Functions"          "functions.sh" 1
[ "$RUN_FIREBASE"  = "1" ] && run_check "Firebase"           "firebase.sh"  1
[ "$RUN_MAESTRO"   = "1" ] && run_check "Maestro (opzionale)" "maestro.sh"  0

echo ""
echo "=============================================="
if [ -n "$FAILED" ]; then
    echo "❌ VERIFY FAILED:$FAILED"
    echo "=============================================="
    exit 1
else
    echo "✅ VERIFY PASSED"
    echo "=============================================="
    exit 0
fi
