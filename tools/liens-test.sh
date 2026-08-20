#!/bin/sh
# [utest->req~integrite-liens~1]
# Test mécanisé de la porte des liens de documentation. Les cas NÉGATIFS sont
# les plus importants : une porte qui ne signale jamais rien passe toujours.
# POSIX sh strict.
set -eu

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "${TMP}"' EXIT INT TERM
fail=0

prepare() {
    rm -rf "${TMP}/depot"
    mkdir -p "${TMP}/depot/tools" "${TMP}/depot/docs"
    cp "${ROOT}/tools/liens.sh" "${TMP}/depot/tools/"
    (cd "${TMP}/depot" && git init -q)
}
commit() {
    (cd "${TMP}/depot" && git add -A && \
        git -c user.name=t -c user.email=t@t commit -q -m "docs: cas de test")
}
porte() { (cd "${TMP}/depot" && sh tools/liens.sh >/dev/null 2>&1); }

echo "liens-test — dépôt sain : liens, ancres, répertoire et bloc de code"
prepare
cat > "${TMP}/depot/docs/cible.md" <<'EOF'
# Titre principal

## Vérification de la chose

Contenu.
EOF
cat > "${TMP}/depot/README.md" <<'EOF'
# Accueil

- [Fichier voisin](docs/cible.md)
- [Ancre accentuée](docs/cible.md#vérification-de-la-chose)
- [Répertoire](docs/)
- [Externe](https://example.org/inexistant.md)
- [Renvoi interne](#accueil)

```markdown
- [Exemple mort dans un bloc de code](docs/jamais-versé.md)
```
EOF
commit
if ! porte; then
    echo "ÉCHEC : la porte refuse un dépôt sain" >&2
    fail=1
fi

echo "liens-test — cible absente : la porte doit échouer"
prepare
cat > "${TMP}/depot/README.md" <<'EOF'
# Accueil

[Spécification jamais versée](docs/29-materiel.md)
EOF
commit
if porte; then
    echo "ÉCHEC : lien vers un fichier inexistant non signalé" >&2
    fail=1
fi

echo "liens-test — fichier présent mais NON versionné : la porte doit échouer"
# Cas subtil et vécu : le fichier existe sur le poste de celui qui écrit le
# lien, mais n'a jamais été ajouté — le lien est mort pour tous les autres.
prepare
printf '# Brouillon\n' > "${TMP}/depot/docs/brouillon.md"
cat > "${TMP}/depot/README.md" <<'EOF'
# Accueil

[Brouillon local](docs/brouillon.md)
EOF
(cd "${TMP}/depot" && git add README.md tools && \
    git -c user.name=t -c user.email=t@t commit -q -m "docs: sans le brouillon")
if porte; then
    echo "ÉCHEC : lien vers un fichier non versionné non signalé" >&2
    fail=1
fi

echo "liens-test — ancre absente : la porte doit échouer"
prepare
printf '# Titre principal\n\n## Section existante\n' > "${TMP}/depot/docs/cible.md"
cat > "${TMP}/depot/README.md" <<'EOF'
# Accueil

[Section disparue](docs/cible.md#section-renommée)
EOF
commit
if porte; then
    echo "ÉCHEC : ancre inexistante non signalée" >&2
    fail=1
fi

if [ "${fail}" -ne 0 ]; then
    echo "liens-test : ÉCHEC." >&2
    exit 1
fi
echo "liens-test : OK."
