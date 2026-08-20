#!/bin/sh
# [impl->req~classification-exigences~1]
# [impl->req~format-exigence-ears~1]
# Classification des exigences : niveau normatif × niveau de vérification.
#
# Ce que cette porte ajoute à la traçabilité. OpenFastTrace vérifie qu'un
# `Needs: utest` déclaré est SATISFAIT. Il ne vérifie jamais que le `Needs`
# lui-même est à la hauteur de l'exigence : une exigence qui dit DOIT et ne
# déclare aucun niveau de test passe la traçabilité en silence. C'est une
# dette invisible — l'exigence la plus contraignante du dépôt peut n'être
# prouvée par rien, sans qu'aucun voyant ne s'allume.
#
# Deux contrôles :
#   1. toute exigence porte UN niveau normatif explicite (EARS, ch. 2) ;
#   2. toute exigence de niveau DOIT déclare une vérification — mécanisée
#      (utest/itest/stest) ou manuelle assumée (mtest).
#
# PIÈGE VÉRIFIÉ, à l'origine du découpage du corps (constaté sur ergonomia) :
# le niveau normatif se lit dans l'ÉNONCÉ seul. Un « DOIT » cité dans un
# Rationale (« la porte DOIT rester hors ligne ») ou dans un critère
# d'acceptation est un niveau EMPRUNTÉ : le classement le prendrait pour
# l'énoncé et rangerait en DOIT une exigence rédigée en DEVRAIT.
#
#   sh tools/classification.sh            # contrôle + bilan chiffré
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

[ "${1:-}" = "" ] || { echo "Usage : sh tools/classification.sh" >&2 ; exit 2 ; }

FICHIERS="$(git ls-files 'spec/02-exigences/*.md' 2>/dev/null | \
            grep -v 'spec/02-exigences/README.md' || true)"
[ -n "${FICHIERS}" ] || { echo "Classification : aucune exigence."; exit 0; }

# shellcheck disable=SC2086 — découpe en mots voulue.
awk -v doit="$(lex NORM_DOIT)" \
    -v devrait="$(lex NORM_DEVRAIT)" \
    -v peut="$(lex NORM_PEUT)" '
function solder(   niveau, teste) {
    if (id == "") return
    niveau = ""
    # L’ordre compte : une exigence qui dit DOIT et DEVRAIT dans le même
    # énoncé est de niveau DOIT — le plus contraignant l’emporte.
    if (enonce ~ ("(^|[^A-Za-zÀ-ÿ])(" doit ")([^A-Za-zÀ-ÿ]|$)"))         niveau = "DOIT"
    else if (enonce ~ ("(^|[^A-Za-zÀ-ÿ])(" devrait ")([^A-Za-zÀ-ÿ]|$)")) niveau = "DEVRAIT"
    else if (enonce ~ ("(^|[^A-Za-zÀ-ÿ])(" peut ")([^A-Za-zÀ-ÿ]|$)"))    niveau = "PEUT"

    if (niveau == "") {
        printf "ÉCHEC : %s — %s : énoncé sans niveau normatif explicite.\n", fichier, id > "/dev/stderr"
        printf "        Attendu dans l’énoncé : %s | %s | %s\n", doit, devrait, peut > "/dev/stderr"
        defauts++
    } else {
        total[niveau]++
    }

    teste = (needs ~ /(utest|itest|stest|mtest)/)
    if (niveau == "DOIT") {
        if (teste) verifiees++
        else {
            printf "ÉCHEC : %s — %s : niveau DOIT sans vérification déclarée.\n", fichier, id > "/dev/stderr"
            printf "        Ajouter un niveau à « Needs: » — utest/itest/stest, ou mtest si la\n" > "/dev/stderr"
            printf "        vérification est manuelle et assumée (méthode, ch. 5).\n" > "/dev/stderr"
            defauts++
        }
    }
    if (teste) mecanisees[niveau]++
    id = ""; enonce = ""; needs = ""
}

FNR == 1 { solder(); fichier = FILENAME }

# Définition d’item : ferme la précédente, ouvre la suivante.
/^`req~[a-z0-9-]+~[0-9]+`[ \t]*$/ {
    solder()
    id = $0; gsub(/`/, "", id); gsub(/[ \t]/, "", id)
    dans_enonce = 1
    next
}

id == "" { next }

# Fin de l’énoncé : tout ce qui suit (rationale, critères, relations) porte
# un vocabulaire qui n’est PAS celui de l’exigence.
/^(Rationale:|Covers:|Needs:|Critères d.acceptation|Acceptance criteria|## )/ {
    dans_enonce = 0
}
/^Needs:/ { needs = $0 }
dans_enonce { enonce = enonce " " $0 }

END {
    solder()
    d = total["DOIT"] + 0; v = total["DEVRAIT"] + 0; p = total["PEUT"] + 0
    n = d + v + p
    printf "Classification : %d exigence(s) — %s %d, %s %d, %s %d.\n", n, "DOIT", d, "DEVRAIT", v, "PEUT", p
    if (d > 0) printf "  DOIT avec vérification déclarée : %d/%d (%.1f %%)\n", verifiees + 0, d, (verifiees + 0) * 100 / d
    if (defauts > 0) {
        printf "%d défaut(s) de classification.\n", defauts > "/dev/stderr"
        exit 1
    }
}
' ${FICHIERS}
