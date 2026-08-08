#!/bin/sh
# [impl->req~tracabilite-outillee~1]
# Point unique d'exécution d'OpenFastTrace : la CI, les hooks et les façades
# d'orchestration (Taskfile, justfile…) passent tous par ce script, avec le
# même périmètre de fichiers (R2, ADR-0002, ADR-0007).
# POSIX sh strict — aucun bashisme : exécutable par dash, bash, et le sh de
# Git pour Windows.
set -eu

OFT_VERSION="4.9.0"
OFT_SHA256="d4ed42503ae066f51d55c3aad7c6e4b16acb80365921951ef5a065a4dc3d94f3"
OFT_URL="https://github.com/itsallcode/openfasttrace/releases/download/${OFT_VERSION}/openfasttrace-${OFT_VERSION}.jar"

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
JAR="${ROOT}/.cache/openfasttrace-${OFT_VERSION}.jar"

# Périmètre scanné (relatif à la racine). templates/ est exclu : les modèles
# contiennent des identifiants d'exemple qui ne doivent pas devenir des items.
INPUTS="spec docs examples tools .github AGENTS.md README.md README.en.md CONTRIBUTING.md CHANGELOG.md Taskfile.yml"

require_java() {
    command -v java >/dev/null 2>&1 || {
        echo "ERREUR : java introuvable — OpenFastTrace requiert Java 17+." >&2
        exit 1
    }
}

fetch_jar() {
    if [ ! -f "${JAR}" ]; then
        mkdir -p "${ROOT}/.cache"
        echo "Téléchargement d'OpenFastTrace ${OFT_VERSION}…" >&2
        curl -fsSL -o "${JAR}.tmp" "${OFT_URL}"
        mv "${JAR}.tmp" "${JAR}"
    fi
    # L'empreinte est vérifiée à chaque exécution : un jar altéré ou corrompu
    # doit échouer bruyamment, jamais tracer en silence.
    set -- $(shasum -a 256 "${JAR}")
    if [ "$1" != "${OFT_SHA256}" ]; then
        echo "ERREUR : empreinte SHA-256 du jar OpenFastTrace invalide (${JAR})." >&2
        echo "Supprimez le fichier et relancez pour retélécharger." >&2
        exit 1
    fi
}

cd "${ROOT}"
case "${1:-trace}" in
    trace)
        require_java
        fetch_jar
        # shellcheck disable=SC2086 — la découpe en mots de INPUTS est voulue.
        java -jar "${JAR}" trace -v failures ${INPUTS}
        echo "Traçabilité : OK (aucune exigence orpheline)."
        ;;
    report)
        require_java
        fetch_jar
        mkdir -p build
        # Le rapport HTML est informatif : généré même en cas de défauts ; le
        # code retour de la porte est porté par le résumé qui suit.
        java -jar "${JAR}" trace -o html -f build/tracabilite.html ${INPUTS} || true
        java -jar "${JAR}" trace -v summary ${INPUTS}
        echo "Rapport : build/tracabilite.html"
        ;;
    *)
        echo "Usage : tools/oft.sh [trace|report]" >&2
        exit 2
        ;;
esac
