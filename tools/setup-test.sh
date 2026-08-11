#!/bin/sh
# [utest->req~onboarding-outille~2]
# Test mécanisé du parcours d'accueil : exécute setup.sh sur une copie
# temporaire et vérifie ses critères d'acceptation (hooks installés, portes
# vertes, idempotence, échec du bootstrap sur prérequis manquant).
# POSIX sh strict.
set -eu

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "${TMP}"' EXIT INT TERM

echo "setup-test — copie de travail dans ${TMP}"
cp -R "${ROOT}/." "${TMP}/"
rm -rf "${TMP}/.git" "${TMP}/build"
(cd "${TMP}" && git init -q)

fail=0

echo "setup-test — premier accueil"
if ! (cd "${TMP}" && sh tools/setup.sh); then
    echo "ÉCHEC : setup.sh a échoué sur un clone frais" >&2
    fail=1
fi
hooks_path="$(cd "${TMP}" && git config core.hooksPath || true)"
if [ "${hooks_path}" != ".githooks" ]; then
    echo "ÉCHEC : hooks non installés (core.hooksPath = '${hooks_path}')" >&2
    fail=1
fi

echo "setup-test — idempotence (second accueil)"
if ! (cd "${TMP}" && sh tools/setup.sh >/dev/null); then
    echo "ÉCHEC : setup.sh n'est pas relançable" >&2
    fail=1
fi

echo "setup-test — bootstrap doit échouer si un prérequis du socle manque"
if (cd "${TMP}" && PATH="" sh tools/bootstrap.sh) >/dev/null 2>&1; then
    echo "ÉCHEC : bootstrap.sh a réussi sans aucun outil dans le PATH" >&2
    fail=1
fi

if [ "${fail}" -ne 0 ]; then
    echo "setup-test : ÉCHEC." >&2
    exit 1
fi
echo "setup-test : OK."
