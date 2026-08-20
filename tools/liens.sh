#!/bin/sh
# [impl->req~integrite-liens~1]
# Intégrité des liens internes de la documentation : chaque lien Markdown
# relatif DOIT atteindre un fichier suivi par git, et son ancre — quand il en
# porte une — un titre qui existe réellement dans le fichier visé.
#
# Pourquoi cette porte existe. Un lien mort ne casse aucun test : il envoie un
# lecteur dans le vide et lui laisse croire qu'un document existe. Cas fondateur
# (ergonomia, 2026-08-19) : trois documents de la branche principale ont renvoyé
# NEUF JOURS durant vers une spécification jamais versée — la pull request qui
# la portait avait été fermée, celle qui la citait fusionnée. Aucune porte n'a
# protesté. Sur un dépôt dont la documentation EST le produit, c'est un défaut
# de premier ordre.
#
#   sh tools/liens.sh            # verdict, code retour non nul si défaut
#
# POSIX sh + awk. Aucune dépendance hors du socle.
set -eu

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "${ROOT}"

# L'index de référence est `git ls-files` : un lien ne vaut que s'il vise un
# fichier RÉELLEMENT versionné. Un fichier présent sur le poste mais jamais
# ajouté satisferait un test d'existence tout en étant invisible pour les
# autres — c'est le même angle mort que celui de la porte anti-dérive.
INDEX="$(mktemp)"
trap 'rm -f "${INDEX}"' EXIT INT TERM
git ls-files > "${INDEX}"

# Les modèles sont scannés comme le reste : ils contiennent de vrais renvois
# vers la méthode, et un modèle qui pointe dans le vide accueille chaque
# nouveau projet par un lien mort.
MD="$(git ls-files '*.md')"
[ -n "${MD}" ] || { echo "Liens de documentation : aucun fichier Markdown."; exit 0; }

# shellcheck disable=SC2086 — la découpe en mots de MD est voulue.
awk -v index_file="${INDEX}" '
# --- Slug des ancres, règle GitHub ------------------------------------------
# Minuscules, ponctuation ASCII retirée, espaces en tirets. La ponctuation est
# retirée par ÉNUMÉRATION et non par classe négative : une classe [^a-z0-9-]
# mangerait aussi les octets UTF-8 des lettres accentuées, et « Vérification »
# ne trouverait plus son ancre.
function slug(s,    t) {
    t = s
    gsub(/`/, "", t)                       # code inline
    gsub(/\*\*|\*|__|_/, "", t)            # emphase
    gsub(/\[|\]/, "", t)                   # liens dans les titres
    gsub(/\([^)]*\)/, "", t)               #   … et leur cible
    t = tolower(t)
    gsub(/[!"#$%&'"'"'()*+,.\/:;<=>?@\\^{|}~]/, "", t)
    gsub(/^[ \t]+|[ \t]+$/, "", t)
    gsub(/[ \t]+/, "-", t)
    return t
}

function normalise(p,    parts, n, out, i, j) {
    # Résolution des « . » et « .. » sans toucher au disque.
    n = split(p, parts, "/")
    j = 0
    for (i = 1; i <= n; i++) {
        if (parts[i] == "" || parts[i] == ".") continue
        if (parts[i] == "..") { if (j > 0) j--; continue }
        out[++j] = parts[i]
    }
    p = ""
    for (i = 1; i <= j; i++) p = (p == "" ? out[i] : p "/" out[i])
    return p
}

# --- Passe 0 : index des chemins versionnés ---------------------------------
FILENAME == index_file {
    FICHIERS[$0] = 1
    # Tout préfixe de répertoire est une cible de lien légitime.
    chemin = $0
    while (match(chemin, /\/[^\/]*$/)) {
        chemin = substr(chemin, 1, RSTART - 1)
        REPS[chemin] = 1
    }
    next
}

# --- Passe 1 : titres (pour les ancres) et liens ----------------------------
FNR == 1 { dans_bloc = 0 }

/^[ \t]*(```|~~~)/ { dans_bloc = !dans_bloc; next }
dans_bloc { next }

/^#{1,6}[ \t]+/ {
    titre = $0
    sub(/^#{1,6}[ \t]+/, "", titre)
    a = slug(titre)
    ANCRES[FILENAME SUBSEP a] = 1
    # Titres homonymes : GitHub suffixe -1, -2… On enregistre les variantes
    # pour ne pas signaler un renvoi légitime vers le second homonyme.
    n = ++VUS[FILENAME SUBSEP a]
    if (n > 1) ANCRES[FILENAME SUBSEP a "-" (n - 1)] = 1
}

{
    ligne = $0
    # Chaque lien Markdown de la ligne : [texte](cible) et ![alt](cible).
    while (match(ligne, /\]\([^)( \t]+(\)|[ \t])/)) {
        cible = substr(ligne, RSTART + 2, RLENGTH - 3)
        ligne = substr(ligne, RSTART + RLENGTH)
        gsub(/[ \t)]+$/, "", cible)
        if (cible == "") continue
        # Liens externes et protocoles : hors périmètre de cette porte.
        if (cible ~ /^(https?|mailto|ftp|tel):/) continue
        LIENS[++nl] = FILENAME "\t" FNR "\t" cible
    }
}

# --- Verdict ----------------------------------------------------------------
END {
    defauts = 0
    for (i = 1; i <= nl; i++) {
        split(LIENS[i], c, "\t")
        source = c[1]; num = c[2]; cible = c[3]

        ancre = ""
        p = index(cible, "#")
        if (p > 0) { ancre = substr(cible, p + 1); cible = substr(cible, 1, p - 1) }

        if (cible == "") {          # renvoi interne au document
            fichier = source
        } else {
            base = source
            sub(/\/[^\/]*$/, "", base)
            if (base == source) base = ""            # fichier à la racine
            fichier = normalise(cible ~ /^\// ? cible : (base == "" ? cible : base "/" cible))
            if (!(fichier in FICHIERS)) {
                if (fichier in REPS) continue        # renvoi vers un répertoire
                printf "ÉCHEC : %s:%d — cible absente : %s\n", source, num, c[3] > "/dev/stderr"
                defauts++
                continue
            }
        }
        if (ancre == "") continue
        # Les ancres explicites (<a name="…">) et les cibles non-Markdown ne
        # se vérifient pas par les titres : on ne signale que ce qui est sûr.
        if (fichier !~ /\.md$/) continue
        if (!((fichier SUBSEP tolower(ancre)) in ANCRES)) {
            printf "ÉCHEC : %s:%d — ancre absente de %s : #%s\n", source, num, fichier, ancre > "/dev/stderr"
            defauts++
        }
    }
    if (defauts > 0) {
        printf "%d lien(s) mort(s).\n", defauts > "/dev/stderr"
        exit 1
    }
    printf "ok — %d lien(s) interne(s) vérifié(s)\n", nl
}
' "${INDEX}" ${MD}

echo "Liens de documentation : OK."
