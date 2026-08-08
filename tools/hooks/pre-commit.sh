#!/usr/bin/env bash
# [impl->req~garde-fous-locaux~1]
# Corps du hook pre-commit : rejoue les portes de la CI avant que le commit
# n'atteigne le dépôt. Le wrapper .githooks/pre-commit (sans extension, non
# scanné par OpenFastTrace) délègue ici — voir méthode, ch. 4.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

if [ "${ALM_SKIP_HOOKS:-0}" = "1" ]; then
    echo "AVERTISSEMENT : portes locales contournées (ALM_SKIP_HOOKS=1)." >&2
    echo "La CI les rejouera : un échec là-bas est un échec ici différé." >&2
    exit 0
fi

echo "Porte locale 1/2 — traçabilité (OpenFastTrace)"
"${ROOT}/tools/oft.sh" trace

echo "Porte locale 2/2 — contrôles de cohérence"
"${ROOT}/tools/checks.sh"
