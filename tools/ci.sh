#!/bin/sh
# [impl->req~perimetre-constate~1]
# [impl->req~porte-ci~2]
# Point d'entrée UNIQUE des portes : ce que la CI exécute est exactement ce
# que le poste exécute. Les façades (Taskfile, justfile) et les deux CI
# délèguent ici — aucune ne redéfinit sa propre liste d'étapes, faute de quoi
# « vert en local, rouge en CI » redevient possible.
#
# La voie est CONSTATÉE par tools/perimetre.sh, jamais déclarée :
#   docs    — le changement ne touche que de la documentation : portes
#             documentaires seules (quelques secondes) ;
#   complet — tout le reste, tests d'outillage compris.
#
# TOUTES LES PORTES SONT JOUÉES, puis un bilan est rendu (ADR-0019). Un
# lanceur qui s'arrête à la première porte rouge ne dit rien des suivantes :
# la première porte de la liste masque alors l'état de tout ce qui la suit, et
# elle le masque d'autant plus longtemps qu'elle est légitimement rouge — une
# traçabilité qui attend sa réalisation, par exemple. Le code de retour reste
# non nul dès qu'une porte échoue : le bilan informe, il n'absout pas.
#
#   sh tools/ci.sh              # voie constatée
#   sh tools/ci.sh --complet    # force la voie complète
#   sh tools/ci.sh --rapide     # force la voie documentaire (hook pre-commit)
#   CI_COMPLET=1 sh tools/ci.sh # complète, par l'environnement (CI planifiée)
#
# POSIX sh strict.
set -eu

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "${ROOT}"

FORCE=""
case "${1:-}" in
    --complet) FORCE="complet" ;;
    # Le hook pre-commit force la voie documentaire : ces portes coûtent
    # quelques secondes, là où les tests d'outillage créent une dizaine de
    # dépôts git jetables. Un hook trop lent finit contourné, et une porte
    # contournée ne protège personne — la porte complète reste due avant de
    # proposer le travail.
    --rapide)  FORCE="docs" ;;
    "") ;;
    *) echo "Usage : sh tools/ci.sh [--complet | --rapide]" >&2 ; exit 2 ;;
esac
# L'ARGUMENT EXPLICITE PRIME sur l'environnement. Sans cette garde, un
# CI_COMPLET=1 hérité re-force en voie complète le « ci.sh --rapide » que
# lance la vérification finale de l'instanciation — dont la voie complète
# relance le test d'instanciation, qui relance ci.sh : récursion infinie
# constatée à la remontée (un niveau toutes les ~9 s, plus de 700 processus
# avant l'arrêt manuel). L'outillage d'instanciation se retire du projet
# produit ; la garde reste, un argument explicite devant primer sur un
# environnement hérité quel que soit l'appelant.
[ -n "${FORCE}" ] || [ "${CI_COMPLET:-0}" != "1" ] || FORCE="complet"

if [ -n "${FORCE}" ]; then
    voie="${FORCE}"
    echo "• voie ${voie} (forcée)"
else
    voie="$(sh tools/perimetre.sh)"
    echo "• voie ${voie} (périmètre constaté)"
fi

# Chaque porte est jouée, son verdict retenu, et la suivante est jouée quoi
# qu'il arrive. Le bilan final les rend toutes d'un coup — c'est là qu'on voit
# si une porte rouge en cache deux autres, ce qu'un arrêt à la première ne
# permet jamais de savoir.
BILAN=""
ECHECS=0
etape() {
    _titre="$1"
    shift
    echo "— ${_titre}"
    if "$@"; then
        BILAN="${BILAN}
ok       ${_titre}"
    else
        BILAN="${BILAN}
ÉCHEC    ${_titre}"
        ECHECS=$((ECHECS + 1))
    fi
}

bilan() {
    echo
    echo "— bilan (voie ${voie})"
    printf '%s\n' "${BILAN}" | sed -e '/^$/d' -e 's/^/  /'
    if [ "${ECHECS}" -gt 0 ]; then
        echo "CI locale (voie ${voie}) : ${ECHECS} porte(s) en échec." >&2
        exit 1
    fi
    echo "CI locale (voie ${voie}) : OK."
    exit 0
}

# --- Portes documentaires (les deux voies) ----------------------------------
etape "traçabilité"        sh tools/oft.sh trace
etape "rattachement"       sh tools/rattachement.sh
etape "cohérence"          sh tools/checks.sh
etape "liens"              sh tools/liens.sh
etape "statuts"            sh tools/statuts.sh
etape "classification"     sh tools/classification.sh
etape "relevés"            sh tools/releves.sh
etape "journaux"           sh tools/journaux.sh
etape "feuille de route"   sh tools/todo.sh
etape "avancement"         sh tools/avancement.sh
etape "constats de revue"  sh tools/revues.sh
etape "audit"              sh tools/audit.sh
etape "badges"             sh tools/badges.sh
etape "anti-dérive"        sh tools/derive.sh
etape "secrets"            sh tools/secrets.sh scan
etape "données"            sh tools/donnees.sh
etape "hygiène de compilation" sh tools/hygiene-compilation.sh

# Forme explicite plutôt que « [ … ] && bilan » : sous « set -e », un test
# faux en tête d'une liste ET est exempté, mais la règle est assez subtile
# pour qu'on ne la fasse pas porter par une porte.
if [ "${voie}" = "docs" ]; then
    bilan
fi

# --- Tests d'outillage (voie complète) --------------------------------------
# Chaque porte se teste sur son cas d'échec (R3). Ces tests créent des dépôts
# git jetables : c'est la partie coûteuse, et la raison d'être de l'aiguillage.
etape "test — lanceur"           sh tools/ci-test.sh
etape "test — anti-secrets"      sh tools/secrets-test.sh
etape "test — données"           sh tools/donnees-test.sh
etape "test — liens"             sh tools/liens-test.sh
etape "test — périmètre"         sh tools/perimetre-test.sh
etape "test — anti-dérive"       sh tools/derive-test.sh
etape "test — cohérence"         sh tools/checks-test.sh
etape "test — socle"             sh tools/socle-test.sh
etape "test — gouvernance"       sh tools/gouvernance-test.sh
etape "test — instanciation"     sh tools/init-test.sh
etape "test — accueil"           sh tools/setup-test.sh
etape "test — bootstrap"         sh tools/bootstrap-test.sh
etape "test — nettoyage"         sh tools/clean-test.sh
etape "test — hygiène de compilation" sh tools/hygiene-compilation-test.sh
etape "test — kit Rust"          sh tools/rust-kit-test.sh
etape "test — rattachement"      sh tools/rattachement-test.sh
etape "test — automatismes de forge" sh tools/automatismes-test.sh

bilan
