#!/bin/bash
# ==============================================================================
# scripts/verify.sh — Quality gate
# Rileva le aree modificate dal diff Git ed esegue le verifiche pertinenti.
#
# Uso:
#   scripts/verify.sh                  # aree modificate (flutter, backend)
#   scripts/verify.sh --all            # tutte le verifiche (flutter + backend)
#   scripts/verify.sh --area <area>    # forza un'area: flutter|backend|maestro
#   scripts/verify.sh --with-maestro   # include anche Maestro (richiede device)
#
# MANDATORY: flutter, backend   |   ON-DEMAND: maestro (richiede device)
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$ROOT_DIR"

AREA_ARG=""
FORCE_ALL=0
WITH_MAESTRO=0
while [ $# -gt 0 ]; do
    case "$1" in
        --all) FORCE_ALL=1 ;;
        --area) AREA_ARG="$2"; shift ;;
        --with-maestro) WITH_MAESTRO=1 ;;
        --no-maestro) WITH_MAESTRO=0 ;;
        -h|--help) echo "Uso: scripts/verify.sh [--all] [--area flutter|backend|maestro] [--with-maestro]"; exit 0 ;;
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

detect_flutter=0; detect_backend=0

if in_area '(^|/)(lib|test|integration_test)/|(^|/)(pubspec\.yaml|analysis_options\.yaml)$|\.dart$'; then detect_flutter=1; fi
if in_area '(^|/)backend/|(^|/)(firebase\.json|\.firebaserc|firestore\.rules)$'; then detect_backend=1; fi

RUN_FLUTTER=0; RUN_BACKEND=0; RUN_MAESTRO=0
if [ -n "$AREA_ARG" ]; then
    case "$AREA_ARG" in
        flutter)   RUN_FLUTTER=1 ;;
        backend)   RUN_BACKEND=1 ;;
        maestro)   RUN_MAESTRO=1 ;;
        *) echo "❌ Area sconosciuta: $AREA_ARG (flutter|backend|maestro)"; exit 2 ;;
    esac
elif [ "$FORCE_ALL" = "1" ]; then
    RUN_FLUTTER=1; RUN_BACKEND=1
else
    RUN_FLUTTER=$detect_flutter
    RUN_BACKEND=$detect_backend
    if [ "$RUN_FLUTTER" = "0" ] && [ "$RUN_BACKEND" = "0" ]; then
        RUN_FLUTTER=1
    fi
fi
[ "$WITH_MAESTRO" = "1" ] && RUN_MAESTRO=1

echo "=============================================="
echo "  VERIFY — quality gate"
echo "=============================================="
printf "Changed: Flutter=%s  Backend=%s%s\n" \
    "$([ "$RUN_FLUTTER" = "1" ] && echo yes || echo no)" \
    "$([ "$RUN_BACKEND" = "1" ] && echo yes || echo no)" \
    "$([ "$RUN_MAESTRO" = "1" ] && echo "  Maestro=yes" || echo "")"

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

[ "$RUN_FLUTTER" = "1" ] && run_check "Flutter"            "flutter.sh"   1
[ "$RUN_BACKEND" = "1" ] && run_check "Backend"            "backend.sh"   1
[ "$RUN_MAESTRO" = "1" ] && run_check "Maestro (on-demand)" "maestro.sh"  0

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
