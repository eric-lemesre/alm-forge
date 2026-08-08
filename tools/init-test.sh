#!/bin/sh
# [utest->req~instanciation-outillee~1]
# [utest->req~politique-attribution-agents~1]
# [utest->req~politique-langue~1]
# Test mécanisé du script d'instanciation : exécute tools/init.sh sur des
# copies temporaires et vérifie les critères d'acceptation des trois
# arbitrages (identité, attribution des agents, langue), le refus de tourner
# deux fois, et des portes vertes dans chaque variante. POSIX sh strict.
set -eu

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TA="$(mktemp -d)"
TB="$(mktemp -d)"
TC="$(mktemp -d)"
TD="$(mktemp -d)"
trap 'rm -rf "${TA}" "${TB}" "${TC}" "${TD}"' EXIT INT TERM
fail=0

instancier() {
    _dest="$1"
    shift
    cp -R "${ROOT}/." "${_dest}/"
    rm -rf "${_dest}/.git" "${_dest}/build"
    (cd "${_dest}" && git init -q &&
        sh tools/init.sh --nom projet-test --porteur "Porteuse Test" --force "$@")
}

echo "init-test [A] — instanciation par défaut"
instancier "${TA}"
if [ -f "${TA}/docs/adr/0001-structurer-alm-forge-en-depot-gabarit.md" ]; then
    echo "ÉCHEC [A] : les ADR du gabarit n'ont pas été retirés" >&2 ; fail=1
fi
if [ -f "${TA}/spec/01-besoins/besoins.md" ]; then
    echo "ÉCHEC [A] : la spécification du gabarit n'a pas été retirée" >&2 ; fail=1
fi
case "$(cat "${TA}/LICENSE")" in
    *"Porteuse Test"*) ;;
    *) echo "ÉCHEC [A] : la LICENSE ne porte pas le porteur" >&2 ; fail=1 ;;
esac
case "$(cat "${TA}/README.md")" in
    *projet-test*) ;;
    *) echo "ÉCHEC [A] : le README ne porte pas le nom du projet" >&2 ; fail=1 ;;
esac
if [ ! -d "${TA}/templates/en" ] || [ ! -f "${TA}/README.en.md" ]; then
    echo "ÉCHEC [A] : le défaut fr-en doit conserver le bilinguisme" >&2 ; fail=1
fi
printf 'feat: sujet valide\n\nCo-Authored-By: Robot <r@x>\n' > "${TA}/msg-attr"
if (cd "${TA}" && sh tools/hooks/commit-msg.sh msg-attr) 2>/dev/null; then
    echo "ÉCHEC [A] : le hook accepte un co-auteur alors que l'attribution est interdite par défaut" >&2
    fail=1
fi
(cd "${TA}" && sh tools/oft.sh trace >/dev/null && sh tools/checks.sh >/dev/null) || {
    echo "ÉCHEC [A] : portes non vertes après instanciation" >&2 ; fail=1
}
if (cd "${TA}" && sh tools/init.sh --nom x --porteur y </dev/null) 2>/dev/null; then
    echo "ÉCHEC [A] : init.sh a accepté de tourner deux fois sans --force" >&2 ; fail=1
fi

echo "init-test [B] — attribution des agents autorisée"
instancier "${TB}" --attribution-agents autorisee
printf 'feat: sujet valide\n\nCo-Authored-By: Robot <r@x>\n' > "${TB}/msg-attr"
if ! (cd "${TB}" && sh tools/hooks/commit-msg.sh msg-attr) 2>/dev/null; then
    echo "ÉCHEC [B] : le hook refuse un co-auteur alors que l'attribution est autorisée" >&2
    fail=1
fi
case "$(cat "${TB}/AGENTS.md")" in
    *"autorisées (choix d'instanciation"*) ;;
    *) echo "ÉCHEC [B] : la règle R0 d'AGENTS.md ne reflète pas le choix" >&2 ; fail=1 ;;
esac

echo "init-test [C] — langue fr uniquement"
instancier "${TC}" --langue fr
if [ -d "${TC}/templates/en" ] || [ -f "${TC}/README.en.md" ]; then
    echo "ÉCHEC [C] : le jeu anglais aurait dû être retiré" >&2 ; fail=1
fi
if grep -q "parite-templates:debut" "${TC}/tools/checks.sh"; then
    echo "ÉCHEC [C] : la porte de parité aurait dû être retirée" >&2 ; fail=1
fi
(cd "${TC}" && sh tools/oft.sh trace >/dev/null && sh tools/checks.sh >/dev/null) || {
    echo "ÉCHEC [C] : portes non vertes en langue fr" >&2 ; fail=1
}

echo "init-test [D] — langue en uniquement"
instancier "${TD}" --langue en
if [ -d "${TD}/templates/fr" ]; then
    echo "ÉCHEC [D] : le jeu français aurait dû être retiré" >&2 ; fail=1
fi
case "$(cat "${TD}/README.md")" in
    *"instantiated from"*) ;;
    *) echo "ÉCHEC [D] : le README principal devrait être en anglais" >&2 ; fail=1 ;;
esac
(cd "${TD}" && sh tools/oft.sh trace >/dev/null && sh tools/checks.sh >/dev/null) || {
    echo "ÉCHEC [D] : portes non vertes en langue en" >&2 ; fail=1
}
(cd "${TD}" && sh tools/adr-new.sh premiere-decision >/dev/null && \
    [ -f docs/adr/0001-premiere-decision.md ]) || {
    echo "ÉCHEC [D] : adr-new doit fonctionner sans templates/fr" >&2 ; fail=1
}

if [ "${fail}" -ne 0 ]; then
    echo "init-test : ÉCHEC." >&2
    exit 1
fi
echo "init-test : OK."
