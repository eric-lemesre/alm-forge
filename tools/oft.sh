#!/usr/bin/env bash
# [impl->req~tracabilite-outillee~1]
# Point unique d'exécution d'OpenFastTrace : hooks, justfile et CI passent
# tous par ce script, avec le même périmètre de fichiers (R2, ADR-0002).
set -euo pipefail

OFT_VERSION="4.9.0"
OFT_SHA256="d4ed42503ae066f51d55c3aad7c6e4b16acb80365921951ef5a065a4dc3d94f3"
OFT_URL="https://github.com/itsallcode/openfasttrace/releases/download/${OFT_VERSION}/openfasttrace-${OFT_VERSION}.jar"

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CACHE_DIR="${ROOT}/.cache"
JAR="${CACHE_DIR}/openfasttrace-${OFT_VERSION}.jar"

# Périmètre scanné. templates/ est exclu : les modèles contiennent des
# identifiants d'exemple qui ne doivent pas devenir des items (ADR-0002).
INPUTS=(
    "${ROOT}/spec"
    "${ROOT}/docs"
    "${ROOT}/examples"
    "${ROOT}/tools"
    "${ROOT}/.github"
    "${ROOT}/AGENTS.md"
    "${ROOT}/README.md"
    "${ROOT}/README.en.md"
    "${ROOT}/CONTRIBUTING.md"
    "${ROOT}/CHANGELOG.md"
)

fetch_jar() {
    if [ ! -f "${JAR}" ]; then
        mkdir -p "${CACHE_DIR}"
        echo "Téléchargement d'OpenFastTrace ${OFT_VERSION}…" >&2
        curl -fsSL -o "${JAR}.tmp" "${OFT_URL}"
        mv "${JAR}.tmp" "${JAR}"
    fi
    # L'empreinte est vérifiée à chaque exécution : un jar altéré ou corrompu
    # doit échouer bruyamment, jamais tracer en silence.
    echo "${OFT_SHA256}  ${JAR}" | sha256sum --check --quiet -- || {
        echo "ERREUR : empreinte SHA-256 du jar OpenFastTrace invalide (${JAR})." >&2
        echo "Supprimez le fichier et relancez pour retélécharger." >&2
        exit 1
    }
}

require_java() {
    command -v java >/dev/null 2>&1 || {
        echo "ERREUR : java introuvable — OpenFastTrace requiert Java 17+." >&2
        exit 1
    }
}

case "${1:-trace}" in
    trace)
        require_java
        fetch_jar
        java -jar "${JAR}" trace -v failures "${INPUTS[@]}"
        echo "Traçabilité : OK (aucune exigence orpheline)."
        ;;
    report)
        require_java
        fetch_jar
        mkdir -p "${ROOT}/build"
        # Le rapport HTML est informatif : on le génère même en cas de défauts
        # (code retour conservé pour la porte).
        java -jar "${JAR}" trace -o html -f "${ROOT}/build/tracabilite.html" "${INPUTS[@]}" || true
        java -jar "${JAR}" trace -v summary "${INPUTS[@]}"
        echo "Rapport : ${ROOT}/build/tracabilite.html"
        ;;
    *)
        echo "Usage : tools/oft.sh [trace|report]" >&2
        exit 2
        ;;
esac
