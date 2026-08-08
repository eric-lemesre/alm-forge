#!/bin/sh
# [utest->req~instanciation-outillee~1]
# Test mécanisé du script d'instanciation : exécute tools/init.sh sur une
# copie temporaire du dépôt et vérifie ses critères d'acceptation, y compris
# le refus de tourner deux fois. Lancé par la CI ; supprimable avec init.sh
# dans un projet instancié. POSIX sh strict.
set -eu

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "${TMP}"' EXIT INT TERM

echo "init-test — copie de travail dans ${TMP}"
cp -R "${ROOT}/." "${TMP}/"
rm -rf "${TMP}/.git" "${TMP}/build"
(cd "${TMP}" && git init -q)

echo "init-test — exécution de init.sh"
(cd "${TMP}" && sh tools/init.sh --nom projet-test --porteur "Porteuse Test" --force)

echo "init-test — vérification des critères d'acceptation"
fail=0
if [ -f "${TMP}/docs/adr/0001-structurer-alm-forge-en-depot-gabarit.md" ]; then
    echo "ÉCHEC : les ADR du gabarit n'ont pas été retirés" >&2
    fail=1
fi
if [ -f "${TMP}/spec/01-besoins/besoins.md" ]; then
    echo "ÉCHEC : la spécification du gabarit n'a pas été retirée" >&2
    fail=1
fi
case "$(cat "${TMP}/LICENSE")" in
    *"Porteuse Test"*) ;;
    *) echo "ÉCHEC : la LICENSE ne porte pas le porteur" >&2 ; fail=1 ;;
esac
case "$(cat "${TMP}/README.md")" in
    *projet-test*) ;;
    *) echo "ÉCHEC : le README ne porte pas le nom du projet" >&2 ; fail=1 ;;
esac

echo "init-test — traçabilité et cohérence sur le projet instancié"
(cd "${TMP}" && sh tools/oft.sh trace && sh tools/checks.sh) || {
    echo "ÉCHEC : portes non vertes après instanciation" >&2
    fail=1
}

echo "init-test — un second lancement sans --force doit être refusé"
if (cd "${TMP}" && sh tools/init.sh --nom x --porteur y </dev/null) 2>/dev/null; then
    echo "ÉCHEC : init.sh a accepté de tourner deux fois sans --force" >&2
    fail=1
fi

if [ "${fail}" -ne 0 ]; then
    echo "init-test : ÉCHEC." >&2
    exit 1
fi
echo "init-test : OK."
