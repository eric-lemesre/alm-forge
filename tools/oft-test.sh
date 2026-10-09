#!/bin/sh
# [utest->req~statut-trace-concordant~1]
# Test mécanisé du filtre de statut de la porte de traçabilité (ADR-0020) :
# un item non approuvé sort de la porte, un item approuvé non couvert la fait
# échouer. Le cas NÉGATIF est le plus important : un filtre trop large
# rendrait la porte muette.
# POSIX sh strict. Requiert Java (comme tools/oft.sh).
set -eu

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "${TMP}"' EXIT INT TERM
fail=0

prepare() {
    rm -rf "${TMP}/depot"
    mkdir -p "${TMP}/depot/tools" "${TMP}/depot/spec"
    # Les tags de couverture de la porte elle-même pointeraient vers des
    # exigences absentes du dépôt de test : on les retire de la copie.
    grep -v '^# \[[a-z]*->' "${ROOT}/tools/oft.sh" > "${TMP}/depot/tools/oft.sh"
    # Réutilise le jar déjà vérifié du dépôt : pas de téléchargement par cas.
    if [ -d "${ROOT}/.cache" ]; then cp -R "${ROOT}/.cache" "${TMP}/depot/"; fi
}
porte() { (cd "${TMP}/depot" && sh tools/oft.sh trace >/dev/null 2>&1); }
attendu() {
    if porte; then r=ok; else r=echec; fi
    if [ "${r}" != "$1" ]; then
        echo "ÉCHEC : $2 — attendu ${1}, obtenu ${r}" >&2
        fail=1
    fi
}

echo "oft-test — besoin et exigence en brouillon, non réalisés : acceptés"
prepare
cat > "${TMP}/depot/spec/s.md" <<'SPEC'
`feat~besoin~1`
Status: draft

Texte.

Needs: req

`req~exigence~1`
Status: draft

Texte.

Covers:

- feat~besoin~1

Needs: impl
SPEC
attendu ok "items en brouillon"

echo "oft-test — exigence approuvée non réalisée : la porte doit échouer"
sed -i '/^Status: draft$/d' "${TMP}/depot/spec/s.md"
attendu echec "exigence approuvée sans implémentation"

echo "oft-test — besoin approuvé couvert seulement par un brouillon : la porte doit échouer"
prepare
cat > "${TMP}/depot/spec/s.md" <<'SPEC'
`feat~besoin~1`

Texte.

Needs: req

`req~exigence~1`
Status: draft

Texte.

Covers:

- feat~besoin~1

Needs: impl
SPEC
attendu echec "besoin approuvé sans exigence approuvée"

[ "${fail}" -eq 0 ] && echo "oft-test : OK" || { echo "oft-test : ÉCHEC" >&2; exit 1; }
