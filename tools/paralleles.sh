#!/bin/sh
# [impl->req~porte-ci~2]
# Lanceur parallèle des étapes indépendantes de tools/ci.sh : les tests
# d'outillage, qui travaillent chacun dans leur propre dossier jetable
# (mktemp). Joués l'un après l'autre, ils faisaient la plus longue part de
# la voie complète.
#
#   sh tools/paralleles.sh <bilan> < liste
#
# <liste> : une ligne « titre<TAB>commande » par étape ; la commande est
# passée à « sh -c », depuis la racine du dépôt.
#
# Toutes les étapes sont jouées, quel que soit le verdict des autres, au plus
# CI_PARALLELE à la fois (défaut : le nombre de processeurs). Puis, DANS
# L'ORDRE DE LA LISTE, chaque étape imprime « — titre » suivi de sa sortie
# complète : le journal se lit comme celui d'un lanceur séquentiel, sans
# lignes entremêlées. <bilan> reçoit une ligne par étape, dans le même
# ordre : « ok|ÉCHEC<TAB>secondes<TAB>titre ».
#
# Code de retour : 0 si toutes les étapes passent, 1 sinon, 2 sur un usage
# fautif. xargs -P n'est pas POSIX, mais GNU, BSD, busybox et Git pour
# Windows le fournissent.
#
# POSIX sh strict.
set -eu

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "${ROOT}"

if [ $# -ne 1 ] || [ -z "$1" ]; then
    echo "Usage : sh tools/paralleles.sh <bilan> < liste" >&2
    exit 2
fi
BILAN_FICHIER="$1"

REP="$(mktemp -d)"
trap 'rm -rf "${REP}"' EXIT INT TERM
sed '/^$/d' > "${REP}/liste"
NB="$(wc -l < "${REP}/liste" | tr -d ' ')"
if [ "${NB}" -eq 0 ]; then
    echo "ÉCHEC : liste d'étapes vide — un lanceur sans étape passerait toujours." >&2
    exit 1
fi
if ! grep -q '	' "${REP}/liste" || grep -qv '^[^	][^	]*	.' "${REP}/liste"; then
    echo "ÉCHEC : ligne sans « titre<TAB>commande » dans la liste." >&2
    exit 2
fi

PARALLELE="${CI_PARALLELE:-$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 2)}"

# Chaque travailleur reçoit le numéro de sa ligne ; il range sortie, code et
# durée sous ce numéro.
# shellcheck disable=SC2016 — développé par le sh du travailleur.
awk '{ print NR }' "${REP}/liste" | xargs -P "${PARALLELE}" -n 1 sh -c '
    ligne="$(sed -n "$1p" "$0/liste")"
    debut="$(date +%s)"
    code=0
    sh -c "${ligne#*	}" > "$0/$1.sortie" 2>&1 < /dev/null || code=$?
    echo "${code}" > "$0/$1.code"
    echo "$(( $(date +%s) - debut ))" > "$0/$1.duree"
' "${REP}" || true

echecs=0
n=0
while IFS= read -r ligne; do
    n=$((n + 1))
    titre="${ligne%%	*}"
    echo "— ${titre}"
    cat "${REP}/${n}.sortie" 2>/dev/null || true
    # Un travailleur qui n'a pas rendu de code n'a pas joué : c'est un échec.
    code="$(cat "${REP}/${n}.code" 2>/dev/null || echo 1)"
    duree="$(cat "${REP}/${n}.duree" 2>/dev/null || echo 0)"
    if [ "${code}" -eq 0 ]; then verdict="ok"; else verdict="ÉCHEC"; echecs=$((echecs + 1)); fi
    printf '%s\t%s\t%s\n' "${verdict}" "${duree}" "${titre}" >> "${BILAN_FICHIER}"
done < "${REP}/liste"

[ "${echecs}" -eq 0 ]
