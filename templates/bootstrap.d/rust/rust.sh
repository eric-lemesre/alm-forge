#!/bin/sh
# Kit Rust — recettes de compilation hygiéniques, prêtes à copier dans tools/
# d'un projet instancié (puis à taguer vers l'exigence du projet, R2 ; la
# porte du gabarit est tools/hygiene-compilation.sh, exigence
# `req~hygiene-artefacts-compilation~1`).
#
#   sh tools/rust.sh garde      # worktree lié : artefacts confinés ou nommés d'après lui
#   sh tools/rust.sh test       # nextest (ou cargo test) + doctests, incrémental coupé
#   sh tools/rust.sh couverture # cargo llvm-cov, incrémental coupé
#   sh tools/rust.sh clean [N]  # artefacts inutilisés depuis N jours (défaut 2), par l'âge seulement
#   sh tools/rust.sh etat       # où vont les artefacts, et leur poids
#
# Pourquoi (constats, pas théorie) :
# - CARGO_INCREMENTAL=0 sur tests, couverture et CI : l'incrémental n'accélère
#   qu'une boucle d'édition et écrit dans target/*/incremental que rien ne
#   purge — la moitié des 503 Go d'ergonomia (2026-08-08).
# - Les chemins d'artefacts se RÉSOLVENT par `cargo metadata`, jamais en dur :
#   un poste qui déplace le cache (target-dir partagé, CARGO_TARGET_DIR) rend
#   muet tout `./target` écrit dans un script (méthode, ch. 4).
# - Un worktree lié qui compile dans le cache du tree principal sert les
#   artefacts de l'autre copie (symbole « introuvable » pourtant présent,
#   fichier généré vidé — ergonomia, 2026-08-14) : la garde l'interdit, sauf
#   si le cache porte le nom du worktree — un cache nommé d'après son worktree
#   peut vivre hors du dépôt (disque plus grand), un balayage du poste le
#   reconnaît et le retire quand le worktree disparaît.
# - Le nettoyage périodique se fait PAR L'ÂGE (`cargo sweep --time`), jamais
#   par un plafond de taille pendant une compilation : `--maxsize` efface les
#   plus anciens jusqu'à repasser sous la limite, artefacts de quelques minutes
#   compris — build cassé en plein vol (2026-10-25, poste multi-worktree).
# POSIX sh strict.
set -eu

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "${ROOT}"

cible() {  # répertoire d'artefacts effectif, résolu par cargo
    cargo metadata --format-version 1 --no-deps 2>/dev/null \
        | tr ',' '\n' | sed -n 's/.*"target_directory":"\([^"]*\)".*/\1/p' | head -1
}

garde() {
    # Tree principal : .git est un dossier ; worktree lié : .git est un fichier.
    [ -f .git ] || { echo "tree principal : garde sans objet." ; return 0 ; }
    dir="$(cible)"
    nom="$(basename "${ROOT}")"
    case "${dir}" in
        "${ROOT}"/*)
            echo "worktree isolé : artefacts dans le worktree." ;;
        */"${nom}"|*/cargo-target-"${nom}"|*/"${nom}"/*|*/cargo-target-"${nom}"/*)
            echo "worktree isolé : artefacts hors du dépôt, nommés d'après le worktree (${dir})." ;;
        *)
            echo "ERREUR : worktree lié « ${nom} » dont les artefacts iraient dans « ${dir:-?} »," >&2
            echo "cache PARTAGÉ avec le tree principal : artefacts croisés garantis." >&2
            echo "Remède : export CARGO_TARGET_DIR=\"\$PWD/target\" (ou un dossier nommé" >&2
            echo "cargo-target-${nom} sur un disque de votre choix) avant tout cargo." >&2
            exit 1 ;;
    esac
}

test_() {
    garde
    export CARGO_INCREMENTAL=0
    if command -v cargo-nextest >/dev/null 2>&1; then
        cargo nextest run --workspace
    else
        echo "note : cargo-nextest absent (cargo install --locked cargo-nextest) — cargo test, binaires un à un." >&2
        cargo test --workspace --no-fail-fast
    fi
    cargo test --workspace --doc
}

couverture() {
    garde
    export CARGO_INCREMENTAL=0
    command -v cargo-llvm-cov >/dev/null 2>&1 \
        || { echo "ERREUR : cargo-llvm-cov requis (cargo install --locked cargo-llvm-cov)." >&2 ; exit 1 ; }
    cargo llvm-cov --workspace "$@"
}

clean() {
    jours="${1:-2}"
    dir="$(cible)"
    [ -n "${dir}" ] || { echo "cargo metadata muet : rien à nettoyer." ; return 0 ; }
    echo "artefacts : ${dir} ($(du -sh "${dir}" 2>/dev/null | cut -f1 || echo 0))"
    if command -v cargo-sweep >/dev/null 2>&1; then
        # Par l'âge, jamais par la taille : un plafond efface des artefacts
        # tout frais dès que le cache frôle la limite.
        cargo sweep --time "${jours}"
    else
        echo "note : cargo-sweep absent (cargo install --locked cargo-sweep) — balayage ignoré." >&2
    fi
    echo "état final : $(du -sh "${dir}" 2>/dev/null | cut -f1 || echo 0)"
}

etat() {
    dir="$(cible)"
    echo "artefacts   : ${dir:-?}"
    echo "poids       : $(du -sh "${dir}" 2>/dev/null | cut -f1 || echo 0)"
    echo "incrémental : $(du -sh "${dir}"/*/incremental 2>/dev/null | awk '{s+=$1} END{print (s?s:0)}')"
    echo "chaîne      : $( [ -f rust-toolchain.toml ] && echo épinglée || echo 'NON épinglée (rust-toolchain.toml absent)')"
}

case "${1:-}" in
    garde)      garde ;;
    test)       test_ ;;
    couverture) shift ; couverture "$@" ;;
    clean)      clean "${2:-}" ;;
    etat)       etat ;;
    *) echo "Usage : sh tools/rust.sh garde | test | couverture [args] | clean [jours] | etat" >&2 ; exit 2 ;;
esac
