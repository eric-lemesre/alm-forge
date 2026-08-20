#!/bin/sh
# [impl->req~statut-specification~1]
# Statuts des domaines de spécification — le COMMUTATEUR de couverture.
#
# Un statut n'est pas une décoration : il commande le dénominateur. ACTIVE
# fait entrer les exigences d'un domaine dans les taux d'audit et de
# classification ; PROPOSITION les en tient dehors, le temps de l'arbitrage.
# Un statut qui ment fausse donc un chiffre sans qu'aucune porte ne proteste
# — en-tête et index qui divergent, domaine déclaré ACTIVE sans décision qui
# l'acte, exigences comptées d'un domaine jamais validé.
#
# Trois invariants, transposés d'ergonomia (doc 03 §6) :
#   1. chaque domaine porte UN statut, pris au lexique ;
#   2. un domaine ACTIVE est adossé à une décision du registre ;
#   3. l'index des domaines et les en-têtes disent la même chose.
#
#   sh tools/statuts.sh
#
# POSIX sh + awk.
set -eu

# Chemins portant espaces ou métacaractères (constat de revue n° 2) : le
# découpage par défaut d'un « $(git ls-files) » non quoté coupe « mon
# document.md » en deux et laisse un glob s'expanser. Une porte qui rate un
# fichier ne signale rien — elle se contente de ne pas le voir. On découpe
# donc sur les seules fins de ligne, globbing désactivé.
IFS='
'
set -f

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "${ROOT}"
. "${ROOT}/tools/lexique.sh"

[ "${1:-}" = "" ] || { echo "Usage : sh tools/statuts.sh" >&2 ; exit 2 ; }

INDEX="spec/02-exigences/README.md"
FICHIERS="$(git ls-files 'spec/02-exigences/*.md' 2>/dev/null | grep -v "${INDEX}" || true)"
[ -n "${FICHIERS}" ] || { echo "Statuts : aucun domaine de spécification."; exit 0; }

MOTIF_STATUT="$(lex SPEC_PROPOSITION)|$(lex SPEC_ACTIVE)|$(lex SPEC_OBSOLETE)"
# Motif PARENTHÉSÉ — même piège que dans todo.sh (constat de revue n° 1).
LIB_STATUT="$(lex_motif SECTION_STATUT)"
FAILURES=0

# Statut déclaré en tête d'un domaine : « **Statut : ACTIVE** ».
statut_de() {
    awk -v lib="${LIB_STATUT}" -v motif="${MOTIF_STATUT}" '
        $0 ~ ("^\\*\\*" lib "[ \t]*:") {
            ligne = $0
            if (match(ligne, "(" motif ")")) { print substr(ligne, RSTART, RLENGTH); exit }
        }' "$1"
}

for f in ${FICHIERS}; do
    dom="${f##*/}"; dom="${dom%.md}"
    statut="$(statut_de "${f}")"

    # 1. Statut présent et au vocabulaire.
    if [ -z "${statut}" ]; then
        echo "ÉCHEC : ${f} — pas de ligne « **$(lex SECTION_STATUT) : …** » au vocabulaire (${MOTIF_STATUT})." >&2
        FAILURES=$((FAILURES + 1))
        continue
    fi

    # 2. Un domaine ACTIVE s'appuie sur une décision actée. Sans cela, un
    #    domaine peut passer ACTIVE d'un simple trait de plume et gonfler la
    #    couverture sans que personne n'ait rien validé.
    if lex_est SPEC_ACTIVE "${statut}"; then
        if ! grep -q "${dom}" docs/decisions/registre.md 2>/dev/null; then
            echo "ÉCHEC : ${f} — domaine ACTIVE sans entrée au registre des décisions." >&2
            echo "        Acter le domaine (relevé + ligne D-AAAA-MM-NN citant « ${dom} »)," >&2
            echo "        ou le repasser en $(lex SECTION_STATUT) : $(lex SPEC_PROPOSITION)." >&2
            FAILURES=$((FAILURES + 1))
        fi
    fi

    # 3. L'index dit la même chose que l'en-tête.
    if [ -f "${INDEX}" ]; then
        ligne_index="$(grep -F "${dom}.md" "${INDEX}" 2>/dev/null || true)"
        if [ -z "${ligne_index}" ]; then
            echo "ÉCHEC : ${INDEX} — domaine absent de l'index : ${dom}" >&2
            FAILURES=$((FAILURES + 1))
        elif ! printf '%s' "${ligne_index}" | grep -Eq "${MOTIF_STATUT}"; then
            echo "ÉCHEC : ${INDEX} — la ligne de ${dom} ne porte aucun statut." >&2
            FAILURES=$((FAILURES + 1))
        elif ! printf '%s' "${ligne_index}" | grep -Fq "${statut}"; then
            echo "ÉCHEC : ${dom} — l'index et l'en-tête divergent (en-tête : ${statut})." >&2
            FAILURES=$((FAILURES + 1))
        fi
    fi
done

# Dérive inverse : une ligne d'index sans domaine réel. Seules les cibles du
# MÊME répertoire sont des domaines — un renvoi vers la méthode
# (`../../docs/methode/…`) n'en est pas un, et le confondre produisait un
# faux positif à la première rédaction de cette porte.
if [ -f "${INDEX}" ]; then
    for cite in $(grep -oE '\]\([a-z0-9-]+\.md\)' "${INDEX}" | \
                  sed -e 's/^](//' -e 's/)$//' | sort -u); do
        [ -f "spec/02-exigences/${cite}" ] || {
            echo "ÉCHEC : ${INDEX} — cite un domaine inexistant : ${cite}" >&2
            FAILURES=$((FAILURES + 1))
        }
    done
fi

if [ "${FAILURES}" -gt 0 ]; then
    echo "${FAILURES} défaut(s) de statut." >&2
    exit 1
fi
echo "Statuts des domaines : OK."
