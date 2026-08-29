#!/bin/sh
# [utest->req~porte-ci~2]
# Test du LANCEUR de portes : joue-t-il toutes les portes de la voie, quel
# qu'ait été le verdict des précédentes, et le bilan les nomme-t-il toutes ?
#
# Ce que ce test protège. Un lanceur qui s'arrête à la première porte rouge
# laisse ignorer l'état de toutes les suivantes, et il le laisse ignorer
# d'autant plus longtemps que la première est LÉGITIMEMENT rouge — une
# traçabilité qui attend la réalisation d'exigences déjà écrites l'est pendant
# des semaines. Le défaut est silencieux : la sortie ne dit pas « je n'ai pas
# joué la suite », elle s'arrête, et rien ne distingue une porte non jouée
# d'une porte absente. Constaté sur un projet instancié, où deux tests
# d'outillage étaient cassés depuis l'origine derrière une traçabilité rouge.
#
# Ce test n'exige PAS que le dépôt soit sain : il vérifie que la LISTE des
# portes jouées ne dépend pas de leurs verdicts. Un test qui supposerait un
# dépôt vert échouerait dans tout projet dont la spécification précède la
# réalisation — c'est-à-dire au moment précis où ce lanceur sert le plus.
#
#   sh tools/ci-test.sh
#
# POSIX sh strict.
set -eu

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "${TMP}"' EXIT INT TERM
fail=0

D="${TMP}/depot"
prepare() {
    rm -rf "${D}"
    mkdir -p "${D}"
    cp -R "${ROOT}/." "${D}/"
    rm -rf "${D}/.git" "${D}/build"
    # Les générateurs lisent l'INDEX (« git ls-files ») : sans commit initial,
    # ils ne verraient aucun fichier et les portes seraient vertes par vide.
    (cd "${D}" && git init -q && git add -A &&
        git -c user.name="CI Test" -c user.email="ci-test@example.invalid" \
            -c commit.gpgsign=false commit -q -m "gabarit: état initial")
}
# CI_COMPLET neutralisé : le lanceur du dépôt de synthèse ne doit pas repartir
# en voie complète, qui le ferait rejouer CE test — récursion.
#
# La sortie ET le code de retour sont pris d'UNE SEULE exécution. Rejouer le
# lanceur pour relire sa sortie donnerait un autre résultat : l'anti-dérive
# régénère les artefacts en place, de sorte que la porte des badges échoue au
# premier passage et passe au second. Défaut commis dans ce test avant d'être
# corrigé.
# « lancer » n'écrit rien sur sa sortie : appelée dans une substitution de
# commande, elle s'exécuterait dans un sous-shell et CODE ne remonterait pas.
CODE=0
lancer() {
    CODE=0
    (cd "${D}" && CI_COMPLET=0 sh tools/ci.sh --rapide) > "${TMP}/sortie" 2>&1 || CODE=$?
}
# Les noms de portes du bilan, dans l'ordre, verdicts ôtés.
portes_du_bilan() {
    printf '%s\n' "$1" | sed -n '/^— bilan/,$p' | \
        sed -n 's/^  \(ok\|ÉCHEC\) *//p'
}

echo "ci-test — dépôt tel quel : le bilan nomme les portes jouées"
prepare
lancer
sortie_saine="$(cat "${TMP}/sortie")"
portes_saines="$(portes_du_bilan "${sortie_saine}")"
nb_saines="$(printf '%s\n' "${portes_saines}" | sed '/^$/d' | wc -l | tr -d ' ')"
if [ "${nb_saines}" -lt 5 ]; then
    echo "ÉCHEC : bilan absent ou illisible (${nb_saines} porte(s) nommée(s))" >&2
    printf '%s\n' "${sortie_saine}" | tail -20 | sed 's/^/        /' >&2
    fail=1
fi

echo "ci-test — deux portes cassées : la liste jouée ne change pas"
# Le cas capital. « liens » est jouée tôt, « badges » plus tard : un lanceur
# qui s'arrête à la première ne nommerait jamais la seconde, et le dépôt
# passerait pour n'avoir qu'un seul défaut.
prepare
printf '\n[lien mort](fichier-qui-nexiste-pas.md)\n' >> "${D}/docs/methode/README.md"
printf '9.9.9\n' > "${D}/VERSION"
lancer
sortie_cassee="$(cat "${TMP}/sortie")"
if [ "${CODE}" -eq 0 ]; then
    echo "ÉCHEC : le lanceur accepte un dépôt à deux portes cassées" >&2
    fail=1
fi
case "${sortie_cassee}" in
    *"ÉCHEC    liens"*) ;;
    *) echo "ÉCHEC : la porte « liens », pourtant cassée, n'est pas signalée" >&2 ; fail=1 ;;
esac
case "${sortie_cassee}" in
    *"ÉCHEC    badges"*) ;;
    *) echo "ÉCHEC : le lanceur s'est arrêté avant « badges » — bilan incomplet" >&2 ; fail=1 ;;
esac
# L'invariant : la liste des portes JOUÉES est la même, cassées ou non. C'est
# la propriété entière, et elle ne suppose rien de l'état du dépôt.
if [ "$(portes_du_bilan "${sortie_cassee}")" != "${portes_saines}" ]; then
    echo "ÉCHEC : la liste des portes jouées dépend de leurs verdicts" >&2
    echo "        avant :" >&2 ; printf '%s\n' "${portes_saines}"  | sed 's/^/          /' >&2
    echo "        après :" >&2 ; printf '%s\n' "$(portes_du_bilan "${sortie_cassee}")" | sed 's/^/          /' >&2
    fail=1
fi

if [ "${fail}" -ne 0 ]; then
    echo "ci-test : ÉCHEC." >&2
    exit 1
fi
echo "ci-test : OK."
