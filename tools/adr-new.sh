#!/bin/sh
# Crée l'ADR suivant depuis le modèle : tools/adr-new.sh titre-en-kebab
# POSIX sh strict, sans sed : le numéro est rappelé à l'utilisateur.
set -eu

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "${ROOT}"

titre="${1:-}"
if [ -z "${titre}" ]; then
    echo "Usage : tools/adr-new.sh titre-en-kebab" >&2
    exit 2
fi

last=0
for f in docs/adr/[0-9]*.md; do
    n="${f##*/}"
    n="${n%%-*}"
    # Retire les zéros de tête pour éviter l'interprétation octale.
    while [ "${n#0}" != "${n}" ]; do n="${n#0}"; done
    if [ -z "${n}" ]; then n=0; fi
    if [ "${n}" -gt "${last}" ]; then last="${n}"; fi
done
next="$(printf '%04d' $((last + 1)))"
dest="docs/adr/${next}-${titre}.md"

cp templates/fr/adr.md "${dest}"
echo "Créé : ${dest}"
echo "Remplacer ADR-NNNN par ADR-${next} et ajouter l'entrée à l'index docs/adr/README.md."
