# Orchestrateur du dépôt — `just` liste les recettes.
# La logique vit dans tools/*.sh (fichiers à extension, donc scannés et tagués
# par OpenFastTrace) ; le justfile ne fait qu'orchestrer.

# Liste des recettes disponibles
default:
    @just --list

# Traçabilité complète (échoue si un maillon manque)
trace:
    tools/oft.sh trace

# Rapport HTML de traçabilité dans build/tracabilite.html
report:
    tools/oft.sh report

# Contrôles de cohérence (ADR, templates, version)
check:
    tools/checks.sh

# Tout ce que la CI exécute
ci: trace check
    @echo "CI locale : OK."

# Installe les hooks git du dépôt
hooks:
    git config core.hooksPath .githooks
    @echo "Hooks installés (core.hooksPath = .githooks)."

# Crée l'ADR suivant depuis le modèle : just adr-new titre-en-kebab
adr-new titre:
    #!/usr/bin/env bash
    set -euo pipefail
    last=$(ls docs/adr/[0-9]*.md 2>/dev/null | sed 's/.*\/\([0-9]*\)-.*/\1/' | sort -n | tail -1)
    next=$(printf '%04d' $((10#${last:-0} + 1)))
    dest="docs/adr/${next}-{{titre}}.md"
    cp templates/fr/adr.md "${dest}"
    sed -i "s/ADR-NNNN/ADR-${next}/" "${dest}"
    echo "Créé : ${dest} — penser à l'ajouter à l'index docs/adr/README.md"

# Met à jour VERSION (compléter le CHANGELOG à la main) : just bump X.Y.Z
bump version:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "{{version}}" > VERSION
    echo "VERSION → {{version}}."
    echo "Compléter CHANGELOG.md (section [{{version}}]) : just check le vérifie."
