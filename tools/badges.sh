#!/bin/sh
# [impl->req~badges-autonomes~1]
# Badges SVG AUTONOMES — aucun appel réseau, aucun service tiers.
#
# Pourquoi ne pas utiliser shields.io. Un dépôt privé, hébergé sur une forge
# sans exécution de CI, ou simplement consulté hors ligne, ne peut pas
# dépendre d'un service externe pour afficher son état : les badges y restent
# gris à jamais, et chaque lecteur du README émet une requête vers un tiers.
# Les badges sont donc générés et VERSIONNÉS ; la porte anti-dérive garantit
# qu'ils disent la vérité (R8).
#
# Sources de vérité — lues, jamais recopiées :
#   version   : fichier VERSION ;
#   exigences : items req~…~n définis dans spec/02-exigences/ ;
#   licence   : type de licence déclaré en tête de LICENSE.
#
#   sh tools/badges.sh             # vérifie la fraîcheur des badges
#   sh tools/badges.sh --ecrire    # (re)génère docs/badges/*.svg
#
# POSIX sh + awk. Sortie déterministe : aucune date, aucun aléa — sans quoi
# l'anti-dérive signalerait une dérive à chaque exécution.
set -eu

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "${ROOT}"

ECRIRE=0
case "${1:-}" in
    --ecrire) ECRIRE=1 ;;
    "") ;;
    *) echo "Usage : sh tools/badges.sh [--ecrire]" >&2 ; exit 2 ;;
esac

REP="docs/badges"
mkdir -p "${REP}"

# Largeur : approximation métrique de DejaVu Sans 11px, suffisante pour un
# rendu correct sans embarquer de table de fontes. Les caractères non-ASCII
# (UTF-8 multi-octets) sont comptés une fois, pas par octet.
largeur() {
    printf '%s' "$1" | awk '{ n = 0 }
        { for (i = 1; i <= length($0); i++) n++ }
        END { printf "%d", n * 7 + 10 }'
}

badge() {
    _nom="$1"; _label="$2"; _valeur="$3"; _couleur="$4"
    _lw="$(largeur "${_label}")"
    _vw="$(largeur "${_valeur}")"
    _total=$((_lw + _vw))
    cat > "${REP}/${_nom}.svg" <<EOF
<svg xmlns="http://www.w3.org/2000/svg" width="${_total}" height="20" role="img" aria-label="${_label}: ${_valeur}">
  <title>${_label}: ${_valeur}</title>
  <linearGradient id="s" x2="0" y2="100%">
    <stop offset="0" stop-color="#bbb" stop-opacity=".1"/>
    <stop offset="1" stop-opacity=".1"/>
  </linearGradient>
  <clipPath id="r"><rect width="${_total}" height="20" rx="3" fill="#fff"/></clipPath>
  <g clip-path="url(#r)">
    <rect width="${_lw}" height="20" fill="#555"/>
    <rect x="${_lw}" width="${_vw}" height="20" fill="${_couleur}"/>
    <rect width="${_total}" height="20" fill="url(#s)"/>
  </g>
  <g fill="#fff" text-anchor="middle" font-family="DejaVu Sans,Verdana,Geneva,sans-serif" font-size="11">
    <text x="$((_lw / 2))" y="14">${_label}</text>
    <text x="$((_lw + _vw / 2))" y="14">${_valeur}</text>
  </g>
</svg>
EOF
}

version="$(cat VERSION)"

# Items req~…~n définis seuls sur leur ligne entre accents graves (méthode,
# ch. 4) : c'est la forme canonique d'une DÉFINITION, une citation en milieu
# de phrase n'en est pas une.
exigences="$(git ls-files 'spec/02-exigences/*.md' 2>/dev/null | tr '\n' ' ')"
if [ -n "${exigences}" ]; then
    # shellcheck disable=SC2086 — découpe en mots voulue.
    nb="$(awk '/^`req~[a-z0-9-]+~[0-9]+`[ \t]*$/ { n++ } END { print n + 0 }' ${exigences})"
else
    nb=0
fi

licence="$(awk 'NR <= 3 && /Licen[cs]e/ { print; exit }' LICENSE 2>/dev/null | \
           awk '{ for (i = 1; i <= NF; i++) if ($i ~ /^(MIT|Apache|BSD|GPL|MPL|EUPL)/) { print $i; exit } }')"
[ -n "${licence}" ] || licence="—"

ecrire_tous() {
    badge version   "version"   "${version}" "#007ec6"
    badge exigences "exigences" "${nb}"      "#4c1"
    badge licence   "licence"   "${licence}" "#97ca00"
}

if [ "${ECRIRE}" -eq 1 ]; then
    ecrire_tous
    echo "Badges régénérés : ${REP}/{version,exigences,licence}.svg"
    exit 0
fi

# Contrôle de fraîcheur : régénération dans un répertoire témoin puis
# comparaison. On ne touche pas aux fichiers versionnés.
TMP="$(mktemp -d)"
trap 'rm -rf "${TMP}"' EXIT INT TERM
REP_REEL="${REP}"
REP="${TMP}"
ecrire_tous
REP="${REP_REEL}"
FAILURES=0
for b in version exigences licence; do
    if ! cmp -s "${TMP}/${b}.svg" "${REP}/${b}.svg" 2>/dev/null; then
        echo "ÉCHEC : ${REP}/${b}.svg périmé — exécuter « sh tools/badges.sh --ecrire »." >&2
        FAILURES=$((FAILURES + 1))
    fi
done
if [ "${FAILURES}" -gt 0 ]; then exit 1; fi
echo "Badges : OK."
