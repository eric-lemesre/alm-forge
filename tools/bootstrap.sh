#!/bin/sh
# [impl->req~onboarding-outille~1]
# « Scripts to Rule Them All » — bootstrap : amener les dépendances du projet.
# Le gabarit est agnostique du langage : ce script ne vérifie que le SOCLE
# commun (git, curl, java pour OpenFastTrace) et sert de POINT D'EXTENSION.
# Chaque projet instancié ajoute ci-dessous l'installation de son outillage
# (langage, base de données…) — chaque ajout est la section Vérification
# concrète d'un ADR technologique du projet. Idempotent : relançable sans
# dégât. POSIX sh strict.
set -eu

manque=0
for outil in git curl java; do
    if ! command -v "${outil}" >/dev/null 2>&1; then
        echo "ÉCHEC : prérequis manquant — ${outil}" >&2
        manque=1
    fi
done
if [ "${manque}" -ne 0 ]; then
    echo "Installer les prérequis du socle (git, curl, Java 17+) puis relancer." >&2
    exit 1
fi

if ! command -v task >/dev/null 2>&1; then
    echo "note : la façade « task » n'est pas installée — optionnelle," >&2
    echo "les portes restent utilisables via sh tools/*.sh (ADR-0007)." >&2
fi

# --- Point d'extension du projet instancié -------------------------------
# Ajouter ici l'outillage technologique du projet, idempotent, avec un
# commentaire renvoyant vers l'ADR qui le justifie. Exemples :
#   command -v cargo >/dev/null 2>&1 || { echo "installer rustup (ADR-00NN)"; exit 1; }
#   docker compose -f dev/compose.yml up -d db   # base de dev (ADR-00NN)
# -------------------------------------------------------------------------

echo "Bootstrap : socle commun présent."
