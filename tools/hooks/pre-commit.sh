#!/bin/sh
# [impl->req~garde-fous-locaux~1]
# Corps du hook pre-commit : rejoue les portes de la CI avant que le commit
# n'atteigne le dépôt, sans dépendre d'aucun orchestrateur (ADR-0007). Le
# wrapper .githooks/pre-commit (sans extension, non scanné par OpenFastTrace)
# délègue ici — voir méthode, ch. 4. POSIX sh strict.
set -eu

ROOT="$(git rev-parse --show-toplevel)"

if [ "${ALM_SKIP_HOOKS:-0}" = "1" ]; then
    echo "AVERTISSEMENT : portes locales contournées (ALM_SKIP_HOOKS=1)." >&2
    echo "La CI les rejouera : un échec là-bas est un échec ici différé." >&2
    exit 0
fi

echo "Porte locale 1/2 — traçabilité (OpenFastTrace)"
sh "${ROOT}/tools/oft.sh" trace

echo "Porte locale 2/2 — contrôles de cohérence"
sh "${ROOT}/tools/checks.sh"
