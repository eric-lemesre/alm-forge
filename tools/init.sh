#!/bin/sh
# [impl->req~instanciation-outillee~1]
# Script d'instanciation du gabarit : personnalise l'identité du projet,
# applique les arbitrages de l'instanciateur (attribution des agents,
# ADR-0011 ; langue, ADR-0009 ; cycle de vie des issues, ADR-0013) et retire
# tout ce qui n'appartient qu'à alm-forge, en laissant la traçabilité verte.
# À lancer UNE FOIS, juste après la création du dépôt (« Use this template »
# sur GitHub, ou simple clone + nouveau remote sur GitLab et toute autre
# forge, ADR-0010).
#   sh tools/init.sh --nom mon-projet --porteur "Prénom Nom" \
#       [--attribution-agents autorisee|interdite] [--langue fr|en|fr-en] \
#       [--cycle-issues complet|reduit] [--force]
# POSIX sh strict. GitHub ne substituant aucune variable à la création depuis
# un template, ce script est le mécanisme de personnalisation.
set -eu

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "${ROOT}"

NOM=""
PORTEUR=""
ATTRIBUTION=""
LANGUE=""
CYCLE=""
FORCE=0

usage() {
    echo "Usage : sh tools/init.sh --nom mon-projet --porteur \"Prénom Nom\" [--attribution-agents autorisee|interdite] [--langue fr|en|fr-en] [--cycle-issues complet|reduit] [--force]" >&2
    exit 2
}

while [ $# -gt 0 ]; do
    case "$1" in
        --nom) NOM="${2:-}"; shift 2 ;;
        --porteur) PORTEUR="${2:-}"; shift 2 ;;
        --attribution-agents)
            case "${2:-}" in
                obligatoire|autorisee|interdite) ATTRIBUTION="$2" ;;
                *) echo "ERREUR : --attribution-agents attend « obligatoire », « autorisee » ou « interdite »." >&2 ; exit 2 ;;
            esac
            shift 2 ;;
        --langue)
            case "${2:-}" in
                fr|en|fr-en) LANGUE="$2" ;;
                *) echo "ERREUR : --langue attend « fr », « en » ou « fr-en »." >&2 ; exit 2 ;;
            esac
            shift 2 ;;
        --cycle-issues)
            case "${2:-}" in
                complet|reduit) CYCLE="$2" ;;
                *) echo "ERREUR : --cycle-issues attend « complet » ou « reduit »." >&2 ; exit 2 ;;
            esac
            shift 2 ;;
        --force) FORCE=1; shift ;;
        *) echo "Option inconnue : $1" >&2 ; usage ;;
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
if [ -z "${ATTRIBUTION}" ] && [ -t 0 ]; then
    printf 'Mention de l'"'"'IA dans les commits — obligatoire, autorisee ou interdite ? [obligatoire] '
    read -r reponse_attr
    case "${reponse_attr}" in
        obligatoire|autorisee|interdite) ATTRIBUTION="${reponse_attr}" ;;
        *) ATTRIBUTION="obligatoire" ;;
    esac
fi
if [ -z "${LANGUE}" ] && [ -t 0 ]; then
    printf 'Langue du dépôt — fr, en ou fr-en ? [fr-en] '
    read -r reponse_langue
    case "${reponse_langue}" in
        fr|en|fr-en) LANGUE="${reponse_langue}" ;;
        *) LANGUE="fr-en" ;;
    esac
fi
if [ -z "${CYCLE}" ] && [ -t 0 ]; then
    printf 'Cycle de vie des issues — complet ([Spec]/[Orga] par consultation) ou reduit (questions ouvertes + ADR) ? [complet] '
    read -r reponse_cycle
    case "${reponse_cycle}" in
        complet|reduit) CYCLE="${reponse_cycle}" ;;
        *) CYCLE="complet" ;;
    esac
fi
# Défauts en l'absence de choix : déclaration obligatoire — diligence
# (ADR-0011) —, bilingue (ADR-0009) et cycle de vie complet (ADR-0013).
[ -n "${ATTRIBUTION}" ] || ATTRIBUTION="obligatoire"
[ -n "${LANGUE}" ] || LANGUE="fr-en"
[ -n "${CYCLE}" ] || CYCLE="complet"
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

echo "1/12 — Retrait des tags de couverture du gabarit dans les documents conservés"
for f in AGENTS.md docs/methode/*.md docs/adr/README.md \
         examples/demo-multi-langages/README.md \
         docs/verification-manuelle/*.md \
         tools/oft.sh tools/checks.sh tools/hooks/pre-commit.sh \
         tools/lexique.sh tools/liens.sh tools/liens-test.sh \
         tools/perimetre.sh tools/perimetre-test.sh tools/ci.sh \
         tools/derive.sh tools/derive-test.sh tools/checks-test.sh \
         tools/todo.sh tools/revues.sh tools/audit.sh tools/badges.sh \
         tools/statuts.sh tools/releves.sh tools/journaux.sh \
         tools/classification.sh tools/issues.sh \
         tools/gouvernance-test.sh tools/socle-test.sh \
         tools/hooks/commit-msg.sh tools/init.sh tools/init-test.sh \
         tools/bootstrap.sh tools/bootstrap.d/*.sh tools/bootstrap-test.sh \
         tools/install-git.sh tools/install-git.ps1 \
         tools/setup.sh tools/setup-test.sh \
         tools/clean.sh tools/clean-test.sh \
         tools/secrets.sh tools/secrets-test.sh \
         .github/workflows/*.yml .gitlab-ci.yml \
         .github/ISSUE_TEMPLATE/*.yml .gitlab/issue_templates/*.md; do
    [ -f "${f}" ] || continue
    sed -e '/^<!-- \[impl->/d' -e '/^<!-- \[utest->/d' \
        -e '/^# \[impl->/d' -e '/^# \[utest->/d' \
        "${f}" > "${f}.tmp"
    mv "${f}.tmp" "${f}"
done

echo "2/12 — Politique de mention de l'IA dans les commits : ${ATTRIBUTION}"
# [impl->req~politique-attribution-agents~2]
if [ "${ATTRIBUTION}" != "obligatoire" ]; then
    # Le bloc livré par défaut (déclaration obligatoire) est retiré…
    sed '/politique-attribution:debut/,/politique-attribution:fin/d' \
        tools/hooks/commit-msg.sh > tools/hooks/commit-msg.sh.tmp
    mv tools/hooks/commit-msg.sh.tmp tools/hooks/commit-msg.sh
    chmod +x tools/hooks/commit-msg.sh
fi
case "${ATTRIBUTION}" in
    autorisee)
        sed_inplace "s/^| R0 |.*/| R0 | Mentions d'agents dans les commits : autorisées, sans obligation (choix d'instanciation, cf. ADR-0011 du gabarit) — les autres règles restent entières | — |/" AGENTS.md
        ;;
    interdite)
        # … et remplacé par le contrôle d'interdiction.
        cat >> tools/hooks/commit-msg.sh <<'FINHOOK'

# R0 — attribution d'agents interdite (choix d'instanciation, cf. ADR-0011
# du gabarit).
if grep -Eiq 'co-authored-by|generated with|generated by|🤖|^IA: ' "${MSG_FILE}"; then
    echo "ERREUR : mention d'agent ou de co-auteur généré interdite dans les commits (R0)." >&2
    exit 1
fi
FINHOOK
        sed_inplace "s/^| R0 |.*/| R0 | Aucune mention d'agent, de co-auteur généré ou d'outil d'IA dans les commits (choix d'instanciation, cf. ADR-0011 du gabarit) | hook commit-msg, revue |/" AGENTS.md
        ;;
esac

echo "3/12 — Langue du dépôt : ${LANGUE}"
# [impl->req~politique-langue~1]
if [ "${LANGUE}" != "fr-en" ]; then
    # Une seule langue : un seul jeu de modèles, plus de porte de parité.
    sed '/parite-templates:debut/,/parite-templates:fin/d' \
        tools/checks.sh > tools/checks.sh.tmp
    mv tools/checks.sh.tmp tools/checks.sh
    chmod +x tools/checks.sh
fi
case "${LANGUE}" in
    fr) rm -rf templates/en ; rm -f README.en.md ;;
    en) rm -rf templates/fr ; rm -f README.en.md ;;
esac

# Le vocabulaire OUTILLÉ suit le même arbitrage que les artefacts générés
# (ADR-0015) : figer la langue ici, c'est décider ce que les portes
# reconnaîtront — « ACTIVE » et « conforme », ou « ACTIVE » et « compliant ».
# En « fr-en », les deux formes restent acceptées.
sed_inplace "s/^LEXIQUE_LANGUE=.*/LEXIQUE_LANGUE=\"\${LEXIQUE_LANGUE:-${LANGUE}}\"/" tools/lexique.sh

if [ "${LANGUE}" = "fr" ]; then
    modeles="templates/fr/"
else
    modeles="templates/fr/ (et templates/en/)"
fi

echo "4/12 — Spécification du gabarit retirée, squelette prêt pour vos besoins"
rm -f spec/01-besoins/besoins.md
rm -f spec/02-exigences/*.md
if [ "${LANGUE}" = "en" ]; then
    cat > spec/README.md <<EOF
# ${NOM} specification

This directory follows the alm-forge template method (docs/methode/, in
French): needs (feat items) in 01-besoins/, EARS requirements (req items) in
02-exigences/, blockers in open-questions.md. Templates: templates/en/.
EOF
    cat > spec/02-exigences/README.md <<EOF
# ${NOM} requirements

One Markdown file per functional domain, requirements following
templates/en/requirement.md (EARS, SHALL/SHOULD/MAY, acceptance criteria,
Covers towards the need, Needs towards the expected coverage).
EOF
    cat > spec/open-questions.md <<'EOF'
# Open questions

Register of blockers awaiting human arbitration. Protocol:
docs/methode/06-questions-ouvertes.md — template: templates/en/open-question.md.

---

No open question to date.
EOF
else
    cat > spec/README.md <<EOF
# Spécification de ${NOM}

Ce répertoire suit la méthode du gabarit alm-forge (voir docs/methode/) :
besoins (items feat) dans 01-besoins/, exigences EARS (items req) dans
02-exigences/, blocages dans open-questions.md. Modèles : ${modeles}.
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
fi

echo "5/12 — ADR du gabarit retirés, registre prêt pour votre ADR-0001"
rm -f docs/adr/0*.md
sed -n '1,/^## Index/p' docs/adr/README.md > docs/adr/README.md.tmp
cat >> docs/adr/README.md.tmp <<EOF

| ADR | Titre | Statut |
| --- | --- | --- |

Aucun ADR à ce jour. Les décisions fondatrices du gabarit alm-forge restent
consultables dans son dépôt d'origine.
EOF
mv docs/adr/README.md.tmp docs/adr/README.md

echo "6/12 — Registre des décisions réinitialisé"
if [ "${LANGUE}" = "en" ]; then
    cat > docs/decisions/registre.md <<'EOF'
# Decision register

Chronological register of durable decisions enacted outside pull requests.
Identifier: D-YYYY-MM-NN; each entry links to the ADR or meeting record that
elaborates it (template: templates/en/decision-record.md, records archived
here).

| ID | Date | Decision | Elaborated in |
| --- | --- | --- | --- |

No decision recorded to date.
EOF
else
    cat > docs/decisions/registre.md <<'EOF'
# Registre des décisions

Registre chronologique des décisions durables actées hors pull request.
Identifiant : D-AAAA-MM-NN ; chaque entrée renvoie vers l'ADR ou le relevé qui
la développe (modèle : templates/fr/decision-record.md, relevés archivés ici).

| ID | Date | Décision | Développée dans |
| --- | --- | --- | --- |

Aucune décision enregistrée à ce jour.
EOF
fi

echo "7/12 — Arbitrage du cycle de vie des issues : ${CYCLE}"
# [impl->req~issues-flux-avancement~2]
# L'arbitrage s'applique (formulaires) puis se consigne au registre du projet
# (ADR-0013) — y compris quand c'est le défaut : un arbitrage non consigné
# n'existe pas. Étiquettes et automatismes de forge restent documentaires
# (méthode, ch. 11).
if [ "${CYCLE}" = "reduit" ]; then
    # Porteur solo : les flux de consultation [Spec]/[Orga] sont remplacés
    # par les questions ouvertes (méthode, ch. 6) et les ADR.
    rm -f .github/ISSUE_TEMPLATE/proposition-exigence.yml \
          .github/ISSUE_TEMPLATE/proposition-organisation.yml
fi
if [ "${LANGUE}" = "en" ]; then
    if [ "${CYCLE}" = "reduit" ]; then
        decision_cycle="Issue lifecycle: reduced circuit — [Spec]/[Orga] consultation flows replaced by open questions and ADRs"
    else
        decision_cycle="Issue lifecycle: template default adopted (full [Spec]/[Orga] consultation circuit)"
    fi
    ref_cycle="alm-forge template ADR-0013"
else
    if [ "${CYCLE}" = "reduit" ]; then
        decision_cycle="Cycle de vie des issues : circuit réduit — flux de consultation [Spec]/[Orga] remplacés par questions ouvertes et ADR"
    else
        decision_cycle="Cycle de vie des issues : défaut du gabarit adopté (circuit de consultation [Spec]/[Orga] complet)"
    fi
    ref_cycle="ADR-0013 du gabarit alm-forge"
fi
awk -v row="| D-$(date +%Y-%m)-01 | $(date +%Y-%m-%d) | ${decision_cycle} | ${ref_cycle} |" '
    /Aucune décision enregistrée à ce jour\./ { next }
    /No decision recorded to date\./ { next }
    { print }
    $0 == "| --- | --- | --- | --- |" { print row }
' docs/decisions/registre.md > docs/decisions/registre.md.tmp
mv docs/decisions/registre.md.tmp docs/decisions/registre.md

echo "8/12 — CHANGELOG et VERSION réinitialisés"
if [ "${LANGUE}" = "en" ]; then
    cat > CHANGELOG.md <<EOF
# Changelog

Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) —
versioning: [SemVer](https://semver.org/).

## [Unreleased]

## [0.1.0] - $(date +%Y-%m-%d)

### Added

- Instantiation of ${NOM} from the alm-forge template.
EOF
else
    cat > CHANGELOG.md <<EOF
# Journal des changements

Format : [Keep a Changelog](https://keepachangelog.com/fr/1.1.0/) —
versionnement : [SemVer](https://semver.org/lang/fr/).

## [Non publié]

## [0.1.0] - $(date +%Y-%m-%d)

### Ajouté

- Instanciation de ${NOM} depuis le gabarit alm-forge.
EOF
fi
printf '0.1.0\n' > VERSION

echo "9/12 — LICENSE au nom du porteur"
sed_inplace "s/^Copyright (c) .*/Copyright (c) ${annee} ${PORTEUR}/" LICENSE

echo "10/12 — README réécrits pour ${NOM}"
if [ "${LANGUE}" = "en" ]; then
    cat > README.md <<EOF
# ${NOM}

Project instantiated from the [alm-forge](https://github.com/eric-lemesre/alm-forge)
ALM template: traced requirements from need to mechanized tests, decisions as
ADRs, quality gates enforced locally and in CI. Note: the template's
normative method documentation (docs/methode/) is currently in French.

- Method: docs/methode/ — working contract: AGENTS.md
- Commands: \`task ci\` (or \`sh tools/oft.sh trace && sh tools/checks.sh\`)
- Getting started: \`task setup\`, then write the first need
  (spec/01-besoins/, template templates/en/need.md) and your ADR-0001

Owner: ${PORTEUR}. Licence: [MIT](LICENSE).
EOF
else
    cat > README.md <<EOF
# ${NOM}

Projet instancié depuis le gabarit [alm-forge](https://github.com/eric-lemesre/alm-forge) :
exigences tracées du besoin aux tests, décisions en ADR, portes vérifiées en
local et en CI.

- Méthode : docs/methode/ — contrat de travail : AGENTS.md
- Commandes : \`task ci\` (ou \`sh tools/oft.sh trace && sh tools/checks.sh\`)
- Démarrage : \`task setup\` puis écrire le premier besoin (spec/01-besoins/)
  et l'ADR-0001 (templates/fr/adr.md)

Porteur : ${PORTEUR}. Licence : [MIT](LICENSE).
EOF
    if [ "${LANGUE}" = "fr-en" ]; then
        cat > README.en.md <<EOF
# ${NOM}

Project instantiated from the [alm-forge](https://github.com/eric-lemesre/alm-forge)
ALM template: traced requirements from need to mechanized tests, ADRs,
quality gates enforced locally and in CI. See README.md (French) and
docs/methode/.
EOF
    fi
fi

echo "11/12 — Artefacts documentaires réinitialisés"
# Fiches du gabarit retirées, artefacts DÉRIVÉS régénérés puis indexés. Les
# indexer est nécessaire : la porte anti-dérive compare le résultat de la
# régénération à l'index, et un artefact hérité du gabarit y ferait échouer
# la première vérification du projet.
# Fiches du gabarit : feuille de route, audit ET revues de code. Une revue
# porte sur un diff qui n'existe pas dans le projet instancié ; la garder lui
# ferait hériter de constats qui ne le concernent pas.
rm -f docs/todo/todo-*.md docs/audit/*.md docs/revues/SUIVI.md
find docs/revues -name '*.md' ! -name 'README.md' ! -name 'SUIVI.md' -exec rm -f {} +
# Les procédures de vérification manuelle du gabarit couvrent des exigences
# qui viennent d'être retirées : les garder laisserait des items orphelins.
# Le README du répertoire, lui, explique le dispositif et reste.
find docs/verification-manuelle -name '*.md' ! -name 'README.md' -exec rm -f {} +
# templates/forge/ est CONSERVÉ : c'est du matériel post-instanciation, au
# même titre que templates/orchestrators/ et templates/bootstrap.d/. Le
# supprimer priverait le projet instancié de ce que req~automatismes-forge~1
# promet de lui fournir — il devrait aller le rechercher dans le gabarit
# (constat de revue n° 5).
sh tools/todo.sh --ecrire   >/dev/null
sh tools/revues.sh --ecrire >/dev/null
sh tools/audit.sh --ecrire  >/dev/null
sh tools/badges.sh --ecrire >/dev/null
git add docs/todo docs/audit docs/revues docs/badges >/dev/null 2>&1 || true

echo "12/12 — Vérification finale (traçabilité + cohérence)"
# Environnement assaini (défense en profondeur, en plus de la primauté de
# l'argument dans ci.sh) : un CI_COMPLET hérité de la CI appelante ne doit
# jamais transformer cette vérification documentaire en voie complète.
CI_COMPLET=0 sh tools/ci.sh --rapide

cat <<EOF

Instanciation de ${NOM} terminée (langue : ${LANGUE}, attribution d'agents :
${ATTRIBUTION}, cycle de vie des issues : ${CYCLE}). Prochaines étapes :
  1. task setup               — accueil du poste (bootstrap, hooks, portes)
  2. Écrire le premier besoin — spec/01-besoins/ (modèle need.md)
  3. Écrire votre ADR-0001    — task adr-new -- votre-premiere-decision
  4. Choisir la façade        — garder Taskfile.yml, ou templates/orchestrators/
  5. Choisir la ou les forges — supprimer .github/ ou .gitlab*/ selon l'hébergeur
  6. Premier commit           — les hooks vérifient tout
Optionnel : supprimer tools/init.sh, tools/init-test.sh et l'étape
« instanciation » des façades CI, devenus inutiles.
EOF
