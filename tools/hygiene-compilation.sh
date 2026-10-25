#!/bin/sh
# [impl->req~hygiene-artefacts-compilation~1]
# Hygiène des artefacts de compilation. Dans un projet instancié qui compile
# du Rust, la porte vérifie les deux réglages sans lesquels le cache de
# compilation grossit sans limite — constats : 500 Go de target/ sur
# ergonomia (2026-08-08), puis 70 à 80 Go PAR BRANCHE de travail sur un
# poste multi-worktree et un disque plein trois fois en un mois (2026-10-25).
#
#   1. La chaîne de compilation est épinglée (rust-toolchain.toml, ou
#      rust-toolchain, à la racine) : sans elle, chaque changement de rustc
#      recompile et CONSERVE une copie complète des artefacts.
#   2. Toute commande de test, de couverture ou de CI coupe la compilation
#      incrémentale (CARGO_INCREMENTAL=0) : l'incrémental n'accélère qu'une
#      boucle d'édition, jamais une exécution complète, et il écrit dans
#      target/*/incremental que rien ne purge — la moitié des 503 Go.
#
# Le contrôle 2 est PAR FICHIER : le fichier (façade, script, CI) qui invoque
# `cargo test`, `cargo nextest`, `cargo llvm-cov` ou `cargo tarpaulin` doit
# porter CARGO_INCREMENTAL=0, sur la ligne ou par un `export` en amont — la
# forme recommandée est l'export en tête du script. Les lignes de commentaire
# ne comptent pas.
#
# Sans manifeste Cargo à la racine, la porte n'a rien à juger et le dit.
# Un autre langage se traite par un bloc de plus, sur le même patron : cache
# de compilation épinglé (chaîne fixée) et borné (pas d'artefact que rien ne
# purge).
#
#   sh tools/hygiene-compilation.sh
#
# POSIX sh strict ; grep -E et sed seulement.
set -eu

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "${ROOT}"

if [ ! -f Cargo.toml ]; then
    echo "hygiène de compilation : aucun manifeste Cargo à la racine, rien à vérifier."
    exit 0
fi

fail=0

# --- 1. Chaîne de compilation épinglée ----------------------------------------
if [ -f rust-toolchain.toml ]; then
    echo "ok — chaîne de compilation épinglée (rust-toolchain.toml)"
elif [ -f rust-toolchain ]; then
    echo "ok — chaîne de compilation épinglée (rust-toolchain)"
else
    echo "ÉCHEC : aucune chaîne épinglée (rust-toolchain.toml absent) — chaque changement de rustc duplique les artefacts." >&2
    fail=1
fi

# --- 2. Incrémental coupé sur test, couverture et CI ---------------------------
MOTIF='cargo (nextest|test|llvm-cov|tarpaulin)([[:space:]]|$)'
trouve=0
for f in justfile Justfile Taskfile.yml Makefile .gitlab-ci.yml \
         tools/*.sh .github/workflows/*.yml .github/workflows/*.yaml; do
    [ -f "$f" ] || continue
    # Lignes d'appel hors commentaires.
    appels="$(grep -nE "${MOTIF}" "$f" 2>/dev/null | grep -vE '^[0-9]+:[[:space:]]*#' || true)"
    [ -n "${appels}" ] || continue
    trouve=1
    if grep -q 'CARGO_INCREMENTAL=0' "$f"; then
        echo "ok — ${f} : commandes de test Cargo avec CARGO_INCREMENTAL=0"
    else
        echo "ÉCHEC : ${f} lance des tests Cargo sans CARGO_INCREMENTAL=0 :" >&2
        printf '%s\n' "${appels}" | sed 's/^/    /' >&2
        fail=1
    fi
done
if [ "${trouve}" -eq 0 ]; then
    echo "note — aucune commande de test Cargo trouvée dans les façades, scripts et CI."
fi

if [ "${fail}" -ne 0 ]; then
    echo "hygiène de compilation : ÉCHEC." >&2
    exit 1
fi
echo "hygiène de compilation : OK."
