#!/usr/bin/env bash
# Contrôles de cohérence du dépôt, exécutés par le hook pre-commit et la CI.
# Chaque contrôle est tagué vers l'exigence qu'il réalise (R2) et a été testé
# sur son cas d'échec à sa mise en place (R3).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FAILURES=0

fail() {
    echo "ÉCHEC : $1" >&2
    FAILURES=$((FAILURES + 1))
}

# [impl->req~bilinguisme-templates~1]
# Parité des templates fr/en : mêmes noms de fichiers des deux côtés.
check_templates_parity() {
    local diff_out
    diff_out="$(diff <(ls "${ROOT}/templates/fr") <(ls "${ROOT}/templates/en") || true)"
    if [ -n "${diff_out}" ]; then
        fail "parité templates/fr ↔ templates/en rompue :
${diff_out}"
    else
        echo "ok — parité des templates fr/en"
    fi
}

# [impl->req~adr-verification~1]
# Tout ADR au statut Accepté comporte une section « ## Vérification » (R6).
check_adr_verification() {
    local f status_line missing=0
    for f in "${ROOT}"/docs/adr/[0-9]*.md; do
        status_line="$(grep -m1 '^\*\*Statut\*\*' "${f}" || true)"
        if printf '%s' "${status_line}" | grep -q 'Accepté'; then
            if ! grep -q '^## Vérification' "${f}"; then
                fail "ADR accepté sans section Vérification : ${f#"${ROOT}"/}"
                missing=1
            fi
        fi
    done
    [ "${missing}" -eq 0 ] && echo "ok — section Vérification présente dans les ADR acceptés"
}

# [impl->req~versionnement-release~1]
# La version du fichier VERSION existe dans le CHANGELOG (Keep a Changelog).
check_version_changelog() {
    local version
    version="$(tr -d '[:space:]' < "${ROOT}/VERSION")"
    if ! grep -q "^## \[${version}\]" "${ROOT}/CHANGELOG.md"; then
        fail "la version ${version} (fichier VERSION) n'a pas de section dans CHANGELOG.md"
    else
        echo "ok — VERSION ${version} présente dans le CHANGELOG"
    fi
}

check_templates_parity
check_adr_verification
check_version_changelog

if [ "${FAILURES}" -gt 0 ]; then
    echo "${FAILURES} contrôle(s) en échec." >&2
    exit 1
fi
echo "Contrôles de cohérence : OK."
