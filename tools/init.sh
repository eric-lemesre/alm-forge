#!/bin/sh
# [impl->req~instanciation-outillee~1]
# Script d'instanciation du gabarit : personnalise l'identité du projet et
# retire tout ce qui n'appartient qu'à alm-forge, en laissant la traçabilité
# verte. À lancer UNE FOIS, juste après « Use this template ».
#   sh tools/init.sh --nom mon-projet --porteur "Prénom Nom" [--force]
# POSIX sh strict. GitHub ne substituant aucune variable à la création depuis
# un template, ce script est le mécanisme de personnalisation (ADR du projet
# à écrire ensuite : voir les étapes finales affichées).
set -eu

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "${ROOT}"

NOM=""
PORTEUR=""
FORCE=0

while [ $# -gt 0 ]; do
    case "$1" in
        --nom) NOM="${2:-}"; shift 2 ;;
        --porteur) PORTEUR="${2:-}"; shift 2 ;;
        --force) FORCE=1; shift ;;
        *) echo "Option inconnue : $1" >&2
           echo "Usage : sh tools/init.sh --nom mon-projet --porteur \"Prénom Nom\" [--force]" >&2
           exit 2 ;;
    esac
done

# Invites interactives si les valeurs manquent et qu'un terminal est là.
if [ -z "${NOM}" ] && [ -t 0 ]; then
    printf 'Nom du projet (kebab-case) : '
    read -r NOM
fi
if [ -z "${PORTEUR}" ] && [ -t 0 ]; then
    printf 'Porteur du projet (Prénom Nom) : '
    read -r PORTEUR
fi
if [ -z "${NOM}" ] || [ -z "${PORTEUR}" ]; then
    echo "ERREUR : --nom et --porteur sont requis." >&2
    exit 2
fi

# Garde 1 — ne pas ravager le dépôt de développement du gabarit lui-même.
origin="$(git remote get-url origin 2>/dev/null || true)"
case "${origin}" in
    *alm-forge*)
        if [ "${FORCE}" -ne 1 ]; then
            echo "ERREUR : l'origine git pointe vers alm-forge (le gabarit)." >&2
            echo "Ce script s'exécute dans un projet instancié. --force pour outrepasser." >&2
            exit 1
        fi ;;
esac

# Garde 2 — refuser de tourner deux fois : la présence de l'ADR fondateur du
# gabarit sert de marqueur « non encore initialisé ».
if [ ! -f docs/adr/0001-structurer-alm-forge-en-depot-gabarit.md ] && [ "${FORCE}" -ne 1 ]; then
    echo "ERREUR : dépôt déjà initialisé (ADR du gabarit absents). --force pour outrepasser." >&2
    exit 1
fi

if [ "${FORCE}" -ne 1 ]; then
    echo "Ce script va retirer la spécification et les ADR du gabarit, et"
    echo "réinitialiser README, CHANGELOG, VERSION, LICENSE et registres."
    printf 'Continuer ? [o/N] '
    read -r reponse
    case "${reponse}" in
        o|O|oui) ;;
        *) echo "Abandon." ; exit 1 ;;
    esac
fi

sed_inplace() {
    # sed -i n'est pas portable (BSD/macOS) : réécriture via fichier temporaire.
    _expr="$1"
    _file="$2"
    sed "${_expr}" "${_file}" > "${_file}.tmp"
    mv "${_file}.tmp" "${_file}"
}

annee="$(date +%Y)"

echo "1/8 — Retrait des tags de couverture du gabarit dans les documents conservés"
for f in AGENTS.md docs/methode/*.md docs/adr/README.md \
         examples/demo-multi-langages/README.md \
         tools/oft.sh tools/checks.sh tools/hooks/pre-commit.sh \
         tools/hooks/commit-msg.sh tools/init.sh tools/init-test.sh \
         .github/workflows/ci.yml; do
    [ -f "${f}" ] || continue
    sed -e '/^<!-- \[impl->/d' -e '/^<!-- \[utest->/d' \
        -e '/^# \[impl->/d' -e '/^# \[utest->/d' \
        "${f}" > "${f}.tmp"
    mv "${f}.tmp" "${f}"
done

echo "2/8 — Spécification du gabarit retirée, squelette prêt pour vos besoins"
rm -f spec/01-besoins/besoins.md
rm -f spec/02-exigences/*.md
cat > spec/README.md <<EOF
# Spécification de ${NOM}

Ce répertoire suit la méthode du gabarit alm-forge (voir docs/methode/) :
besoins (items feat) dans 01-besoins/, exigences EARS (items req) dans
02-exigences/, blocages dans open-questions.md. Modèles : templates/fr/ et
templates/en/.
EOF
cat > spec/02-exigences/README.md <<EOF
# Exigences de ${NOM}

Un fichier Markdown par domaine fonctionnel, exigences au format du modèle
templates/fr/requirement.md (EARS, DOIT/DEVRAIT/PEUT, critères d'acceptation,
Covers vers le besoin, Needs vers la couverture attendue).
EOF
cat > spec/open-questions.md <<'EOF'
# Questions ouvertes

Registre des blocages en attente d'arbitrage humain. Protocole :
docs/methode/06-questions-ouvertes.md — modèle : templates/fr/open-question.md.

---

Aucune question ouverte à ce jour.
EOF

echo "3/8 — ADR du gabarit retirés, registre prêt pour votre ADR-0001"
rm -f docs/adr/0*.md
sed -n '1,/^## Index/p' docs/adr/README.md > docs/adr/README.md.tmp
cat >> docs/adr/README.md.tmp <<EOF

| ADR | Titre | Statut |
| --- | --- | --- |

Aucun ADR à ce jour. Les décisions fondatrices du gabarit alm-forge restent
consultables dans son dépôt d'origine.
EOF
mv docs/adr/README.md.tmp docs/adr/README.md

echo "4/8 — Registre des décisions réinitialisé"
cat > docs/decisions/registre.md <<'EOF'
# Registre des décisions

Registre chronologique des décisions durables actées hors pull request.
Identifiant : D-AAAA-MM-NN ; chaque entrée renvoie vers l'ADR ou le relevé qui
la développe (modèle : templates/fr/decision-record.md, relevés archivés ici).

| ID | Date | Décision | Développée dans |
| --- | --- | --- | --- |

Aucune décision enregistrée à ce jour.
EOF

echo "5/8 — CHANGELOG et VERSION réinitialisés"
cat > CHANGELOG.md <<EOF
# Journal des changements

Format : [Keep a Changelog](https://keepachangelog.com/fr/1.1.0/) —
versionnement : [SemVer](https://semver.org/lang/fr/).

## [Non publié]

## [0.1.0] - $(date +%Y-%m-%d)

### Ajouté

- Instanciation de ${NOM} depuis le gabarit alm-forge.
EOF
printf '0.1.0\n' > VERSION

echo "6/8 — LICENSE au nom du porteur"
sed_inplace "s/^Copyright (c) .*/Copyright (c) ${annee} ${PORTEUR}/" LICENSE

echo "7/8 — README réécrits pour ${NOM}"
cat > README.md <<EOF
# ${NOM}

Projet instancié depuis le gabarit [alm-forge](https://github.com/eric-lemesre/alm-forge) :
exigences tracées du besoin aux tests, décisions en ADR, portes vérifiées en
local et en CI.

- Méthode : docs/methode/ — contrat de travail : AGENTS.md
- Commandes : \`task ci\` (ou \`sh tools/oft.sh trace && sh tools/checks.sh\`)
- Démarrage : \`task hooks\` puis écrire le premier besoin (spec/01-besoins/)
  et l'ADR-0001 (templates/fr/adr.md)

Porteur : ${PORTEUR}. Licence : [MIT](LICENSE).
EOF
cat > README.en.md <<EOF
# ${NOM}

Project instantiated from the [alm-forge](https://github.com/eric-lemesre/alm-forge)
ALM template: traced requirements from need to mechanized tests, ADRs,
quality gates enforced locally and in CI. See README.md (French) and
docs/methode/.
EOF

echo "8/8 — Vérification finale (traçabilité + cohérence)"
sh tools/oft.sh trace
sh tools/checks.sh

cat <<EOF

Instanciation de ${NOM} terminée. Prochaines étapes :
  1. task hooks               — installer les garde-fous locaux
  2. Écrire le premier besoin — spec/01-besoins/ (modèle templates/fr/need.md)
  3. Écrire votre ADR-0001    — task adr-new -- votre-premiere-decision
  4. Choisir la façade        — garder Taskfile.yml, ou templates/orchestrators/
  5. Premier commit           — les hooks vérifient tout
Optionnel : supprimer tools/init.sh, tools/init-test.sh et l'étape
« instanciation » de .github/workflows/ci.yml, devenus inutiles.
EOF
