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
# Trois contrôles :
#   1. toute exigence porte UN niveau normatif explicite (EARS, ch. 2) ;
#   2. toute exigence de niveau DOIT déclare une vérification — mécanisée
#      (utest/itest/stest) ou manuelle assumée (mtest) ;
#   3. COMPLÉTUDE : une vérification manuelle (mtest) sur une exigence DOIT ou
#      DEVRAIT n'est pas un défaut — R10 l'autorise explicitement — mais reste
#      une promesse plus faible qu'un niveau mécanisé. Le contrôle la NOMME
#      « à élever » sans faire échouer la porte : la méthode (ch. 5) dit
#      qu'« une exigence bascule de mtest vers un niveau automatisé dès que
#      c'est techniquement possible », chaque cas appelle donc un arbitrage
#      (rester en mtest si l'automatisation n'est pas possible, ou écrire le
#      test mécanisé) — jamais un tag de complaisance.
#
# PIÈGE VÉRIFIÉ, à l'origine du découpage du corps (constaté sur ergonomia) :
# le niveau normatif se lit dans l'ÉNONCÉ seul. Un « DOIT » cité dans un
# Rationale (« la porte DOIT rester hors ligne ») ou dans un critère
# d'acceptation est un niveau EMPRUNTÉ : le classement le prendrait pour
# l'énoncé et rangerait en DOIT une exigence rédigée en DEVRAIT.
#
# ADAPTATION DÉLIBÉRÉE (constatée sur un projet instancié, qui distingue par
# un `Tags: niveau-…` le niveau de vérification CIBLE — unitaire/intégration/
# système/manuel/… — de la couverture réellement déclarée, et nomme « à
# élever » toute exigence couverte sous sa cible). Le gabarit ne porte PAS ce
# `Tags:` : son format d'item (`docs/methode/02-exigences.md`) n'a que
# Rationale/Critères/Covers/Needs, et son seul axe de rigueur exigible est le
# niveau normatif EARS lui-même (R10 : seul le DOIT engage une vérification).
# La complétude porte donc ici sur le seul écart qui existe réellement dans ce
# format — mtest déclaré seul là où un niveau mécanisé reste possible — plutôt
# que sur un axe « niveau cible » qui n'existe pas dans ce gabarit. Un projet
# instancié qui adopte un `Tags: niveau-…` retrouve le contrôle complet en
# reprenant la table niveau → type de la source (méthode, ch. 5).
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
    -v peut="$(lex NORM_PEUT)" \
    -v approuvee="$(lex_motif EXIGENCE_APPROUVEE)" \
    -v etiq_a_elever="$(lex_fr CLASSIFICATION_A_ELEVER)" '
function solder(   niveau, teste, mecanisee, manuelle_seule) {
    if (id == "") return
    # Dénominateur : les exigences approuvées (ADR-0018). Un brouillon n’a pas
    # à porter un niveau de vérification : ce n’est pas encore un engagement.
    if (statut !~ ("^" approuvee "$")) { id = ""; enonce = ""; needs = ""; statut = ""; return }
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

    # Frontières de mot : « itest » ne doit se lire ni dans un mot qui le
    # contient, ni ailleurs que comme un type entier de la liste Needs.
    teste = (needs ~ /(^|[ ,:])(utest|itest|stest|mtest)([ ,]|$)/)
    if (niveau == "DOIT") {
        if (teste) verifiees++
        else {
            printf "ÉCHEC : %s — %s : niveau DOIT sans vérification déclarée.\n", fichier, id > "/dev/stderr"
            printf "        Ajouter un niveau à « Needs: » — utest/itest/stest, ou mtest si la\n" > "/dev/stderr"
            printf "        vérification est manuelle et assumée (méthode, ch. 5).\n" > "/dev/stderr"
            defauts++
        }
    }

    # Contrôle 3 — complétude : un DOIT/DEVRAIT couvert par mtest SEUL (aucun
    # niveau mécanisé) tient sa promesse — R10 l’autorise — mais reste la
    # preuve la plus faible. Ne fait jamais échouer : chaque cas appelle un
    # arbitrage humain (méthode, ch. 5), pas un contrôle automatique.
    mecanisee = (needs ~ /(^|[ ,:])(utest|itest|stest)([ ,]|$)/)
    manuelle_seule = (teste && !mecanisee && needs ~ /(^|[ ,:])mtest([ ,]|$)/)
    if (manuelle_seule && (niveau == "DOIT" || niveau == "DEVRAIT")) {
        printf "  %s   %s — %s (niveau %s couvert par mtest seul — bascule vers un niveau mécanisé dès que possible)\n", \
               etiq_a_elever, fichier, id, niveau
        a_elever++
    }
    id = ""; enonce = ""; needs = ""; statut = ""
}

FNR == 1 { solder(); fichier = FILENAME }

# Définition d’item : ferme la précédente, ouvre la suivante.
/^`req~[a-z0-9-]+~[0-9]+`[ \t]*$/ {
    solder()
    id = $0; gsub(/`/, "", id); gsub(/[ \t]/, "", id)
    dans_enonce = 1
    attente_statut = 1
    next
}

# Ligne de statut, juste sous l’identifiant.
attente_statut && /^\*\*/ {
    statut = $0
    sub(/^[^:]*:[ \t]*/, "", statut); sub(/\*\*[ \t]*$/, "", statut)
    gsub(/[ \t]+$/, "", statut)
    attente_statut = 0
    next
}
attente_statut && NF > 0 { attente_statut = 0 }

id == "" { next }

# Fin de l’énoncé : tout ce qui suit (rationale, critères, relations) porte
# un vocabulaire qui n’est PAS celui de l’exigence. Les noms de champ
# tolèrent l’espace avant le deux-points (« Needs : » à la française) : une
# typographie ne doit jamais désarmer une porte en silence.
/^(Rationale[ ]?:|Covers[ ]?:|Needs[ ]?:|Critères d.acceptation|Acceptance criteria|## )/ {
    dans_enonce = 0
}
# Les lignes Needs: se CUMULENT : la dernière n’écrase pas la première —
# deux déclarations valent deux couvertures, pas une perte silencieuse.
/^Needs[ ]?:/ { needs = (needs == "" ? $0 : needs " " $0) }
dans_enonce { enonce = enonce " " $0 }

END {
    solder()
    d = total["DOIT"] + 0; v = total["DEVRAIT"] + 0; p = total["PEUT"] + 0
    n = d + v + p
    printf "Classification : %d exigence(s) — %s %d, %s %d, %s %d.\n", n, "DOIT", d, "DEVRAIT", v, "PEUT", p
    # Dénominateur/taux (méthode, ch. 5) : M = exigences « testables » — dans
    # ce gabarit, celles de niveau DOIT, seul niveau que R10 engage à une
    # vérification (DEVRAIT/PEUT en sont l’équivalent du « non applicable » :
    # aucune règle ne leur impose de Needs). N = celles qui en déclarent un
    # réel (utest/itest/stest/mtest).
    if (d > 0) {
        printf "Couverture déclarée : %d/%d exigence(s) testable(s) (%.1f %%).\n", \
               verifiees + 0, d, (verifiees + 0) * 100 / d
        if (a_elever > 0)
            printf "Complétude : %d exigence(s) couverte(s) par mtest seul (à élever).\n", a_elever + 0
    }
    if (defauts > 0) {
        printf "%d défaut(s) de classification.\n", defauts > "/dev/stderr"
        exit 1
    }
}
' ${FICHIERS}
