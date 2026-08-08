#!/bin/sh
# Contrôles de cohérence du dépôt, exécutés par le hook pre-commit, la CI et
# les façades d'orchestration. POSIX sh strict, uniquement des commandes
# intégrées et utilitaires universels (cat, ls) : aucun grep/sed/diff requis.
# Chaque contrôle est tagué vers l'exigence qu'il réalise (R2) et a été testé
# sur son cas d'échec à sa mise en place (R3).
set -eu

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "${ROOT}"
FAILURES=0

# --- parite-templates:debut ---
# [impl->req~bilinguisme-templates~1]
# Parité des templates fr/en : mêmes noms de fichiers des deux côtés.
# Bloc retiré par tools/init.sh quand une seule langue est conservée
# (ADR-0009) ; ne pas déplacer les marqueurs.
parity_fail=0
for f in templates/fr/*.md; do
    if [ ! -f "templates/en/${f##*/}" ]; then
        echo "ÉCHEC : templates/en/${f##*/} manquant" >&2
        parity_fail=1
    fi
done
for f in templates/en/*.md; do
    if [ ! -f "templates/fr/${f##*/}" ]; then
        echo "ÉCHEC : templates/fr/${f##*/} manquant" >&2
        parity_fail=1
    fi
done
if [ "${parity_fail}" -eq 0 ]; then
    echo "ok — parité des templates fr/en"
else
    FAILURES=$((FAILURES + 1))
fi
# --- parite-templates:fin ---

# [impl->req~adr-verification~1]
# Tout ADR au statut Accepté comporte une section « ## Vérification » (R6).
adr_fail=0
for f in docs/adr/[0-9]*.md; do
    # Glob sans correspondance (projet fraîchement instancié, aucun ADR) :
    # la chaîne littérale reste — l'ignorer au lieu d'échouer sur la lecture.
    [ -e "${f}" ] || continue
    accepte=0
    verif=0
    while IFS= read -r line; do
        case "${line}" in
            "**Statut** : Accepté"*) accepte=1 ;;
            "## Vérification"*) verif=1 ;;
        esac
    done < "${f}"
    if [ "${accepte}" -eq 1 ] && [ "${verif}" -eq 0 ]; then
        echo "ÉCHEC : ADR accepté sans section Vérification : ${f}" >&2
        adr_fail=1
    fi
done
if [ "${adr_fail}" -eq 0 ]; then
    echo "ok — section Vérification présente dans les ADR acceptés"
else
    FAILURES=$((FAILURES + 1))
fi

# [impl->req~versionnement-release~1]
# La version du fichier VERSION a sa section dans le CHANGELOG (Keep a Changelog).
version="$(cat VERSION)"
found=0
while IFS= read -r line; do
    case "${line}" in
        "## [${version}]"*) found=1 ;;
    esac
done < CHANGELOG.md
if [ "${found}" -eq 1 ]; then
    echo "ok — VERSION ${version} présente dans le CHANGELOG"
else
    echo "ÉCHEC : la version ${version} (fichier VERSION) n'a pas de section dans CHANGELOG.md" >&2
    FAILURES=$((FAILURES + 1))
fi

if [ "${FAILURES}" -gt 0 ]; then
    echo "${FAILURES} contrôle(s) en échec." >&2
    exit 1
fi
echo "Contrôles de cohérence : OK."
