#!/bin/sh
# [utest->req~porte-ci~2]
# Test du lanceur parallèle (tools/paralleles.sh) sur ses cas d'échec (R3) :
# une étape en échec n'empêche pas les autres et rend le lanceur rouge ; les
# sorties sortent dans l'ordre de la liste ; les étapes tournent vraiment en
# même temps (rendez-vous qu'un lanceur séquentiel ne peut pas tenir) ; une
# liste vide ou mal formée est refusée.
#
#   sh tools/paralleles-test.sh
#
# POSIX sh strict.
set -eu

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "${TMP}"' EXIT INT TERM
fail=0
T="$(printf '\t')"

# lancer <liste> : rend CODE, la sortie dans ${TMP}/sortie, le bilan dans
# ${TMP}/bilan.
CODE=0
lancer() {
    CODE=0
    rm -f "${TMP}/bilan"
    printf '%s\n' "$1" | sh "${ROOT}/tools/paralleles.sh" "${TMP}/bilan" > "${TMP}/sortie" 2>&1 || CODE=$?
}
attendre() {   # attendre <libellé> <code attendu>
    if [ "${CODE}" -ne "$2" ]; then
        echo "ÉCHEC : $1 — code ${CODE}, attendu $2" >&2
        sed 's/^/  | /' "${TMP}/sortie" >&2 ; fail=1
    fi
}

echo "paralleles-test — trois étapes saines : vert, sorties dans l'ordre de la liste"
lancer "premiere${T}sleep 1; echo sortie-un
deuxieme${T}echo sortie-deux
troisieme${T}echo sortie-trois"
attendre "étapes saines" 0
ordre="$(grep -E '^(— |sortie-)' "${TMP}/sortie" | tr '\n' ' ')"
if [ "${ordre}" != "— premiere sortie-un — deuxieme sortie-deux — troisieme sortie-trois " ]; then
    echo "ÉCHEC : sorties hors de l'ordre de la liste : ${ordre}" >&2 ; fail=1
fi
if [ "$(cut -f1,3 "${TMP}/bilan" | tr '\t\n' ': ')" != "ok:premiere ok:deuxieme ok:troisieme " ]; then
    echo "ÉCHEC : bilan inattendu :" >&2 ; sed 's/^/  | /' "${TMP}/bilan" >&2 ; fail=1
fi

echo "paralleles-test — étape du milieu en échec : rouge, les autres jouées quand même"
lancer "avant${T}echo joue-avant
casse${T}echo casse-dit-pourquoi; exit 3
apres${T}echo joue-apres"
attendre "une étape en échec" 1
for attendu in joue-avant casse-dit-pourquoi joue-apres; do
    grep -q "${attendu}" "${TMP}/sortie" || { echo "ÉCHEC : « ${attendu} » absent de la sortie" >&2 ; fail=1; }
done
if [ "$(cut -f1 "${TMP}/bilan" | tr '\n' ' ')" != "ok ÉCHEC ok " ]; then
    echo "ÉCHEC : le bilan ne marque pas la seule étape cassée :" >&2
    sed 's/^/  | /' "${TMP}/bilan" >&2 ; fail=1
fi

echo "paralleles-test — rendez-vous : les étapes tournent en même temps"
# La première attend un fichier que seule la seconde crée : jouées l'une
# après l'autre, la première échouerait au bout de dix secondes.
R="${TMP}/rendez-vous"
export CI_PARALLELE=2
lancer "attend${T}i=0; while [ ! -f ${R} ] && [ \$i -lt 100 ]; do sleep 0.1; i=\$((i+1)); done; [ -f ${R} ]
cree${T}touch ${R}"
attendre "rendez-vous de deux étapes parallèles" 0
unset CI_PARALLELE

echo "paralleles-test — liste vide : échec, rien n'est vert par vide"
lancer ""
attendre "liste vide" 1

echo "paralleles-test — ligne sans tabulation : usage fautif"
lancer "titre-sans-commande"
attendre "ligne mal formée" 2

echo "paralleles-test — bilan non désigné : usage fautif"
code=0
sh "${ROOT}/tools/paralleles.sh" < /dev/null > /dev/null 2>&1 || code=$?
if [ "${code}" -ne 2 ]; then
    echo "ÉCHEC : sans argument, code ${code}, attendu 2" >&2 ; fail=1
fi

if [ "${fail}" -ne 0 ]; then
    echo "paralleles-test : ÉCHEC." >&2
    exit 1
fi
echo "paralleles-test : OK."
