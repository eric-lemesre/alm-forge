#!/bin/sh
# [utest->req~confinement-artefacts-worktree~1]
# [utest->req~epinglage-chaine-stable~1]
# Test du kit Rust (templates/bootstrap.d/rust/rust.sh) sur ses cas d'échec
# (R3) : la garde d'un worktree lié refuse le cache du tree principal et un
# cache partagé dont un composant porte le nom du worktree ; elle admet le
# cache dans le worktree et le dossier cargo-target-<nom> ; le nettoyage
# balaie PAR L'ÂGE (jamais --maxsize) et refuse un cache partagé sans
# --partage ; l'épinglage écrit la version exacte que donne le manifeste du
# canal stable, ne touche que la ligne channel d'un fichier existant, et
# laisse le fichier intact sur un manifeste injoignable ou sans version.
# cargo et cargo-sweep sont remplacés par des talons, le manifeste par un
# fichier local (file://) : aucune compilation, aucun téléchargement.
# POSIX sh strict.
set -eu

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "${TMP}"' EXIT INT TERM
fail=0

KIT="${ROOT}/templates/bootstrap.d/rust/rust.sh"

# --- Talons : cargo rend le target_directory voulu, cargo-sweep note ses args -
mkdir -p "${TMP}/bin"
cat > "${TMP}/bin/cargo" <<'EOF'
#!/bin/sh
# Talon : « cargo metadata » rend le répertoire désigné par TALON_TARGET ;
# « cargo sweep » délègue au talon cargo-sweep ; le reste est refusé.
case "${1:-}" in
    metadata) printf '{"packages":[{"name":"x","targets":[{"kind":["bin"],"name":"x"}]}],"target_directory":"%s","workspace_root":"/w"}\n' "${TALON_TARGET}" ;;
    sweep) shift ; exec cargo-sweep "$@" ;;
    *) echo "talon cargo : commande inattendue $*" >&2 ; exit 9 ;;
esac
EOF
cat > "${TMP}/bin/cargo-sweep" <<'EOF'
#!/bin/sh
printf '%s\n' "$*" >> "${TALON_JOURNAL}"
EOF
chmod +x "${TMP}/bin/cargo" "${TMP}/bin/cargo-sweep"
export PATH="${TMP}/bin:${PATH}"
export TALON_JOURNAL="${TMP}/sweep.log"

# --- Dépôt principal + worktree lié « feature » ------------------------------
PRINCIPAL="${TMP}/main/proj"
mkdir -p "${PRINCIPAL}/tools"
( cd "${PRINCIPAL}" && git init -q && git -c user.name=t -c user.email=t@t commit -q --allow-empty -m init )
cp "${KIT}" "${PRINCIPAL}/tools/rust.sh"
( cd "${PRINCIPAL}" && git add tools/rust.sh && git -c user.name=t -c user.email=t@t commit -q -m kit )
mkdir -p "${TMP}/wt"
( cd "${PRINCIPAL}" && git worktree add -q "${TMP}/wt/feature" -b feature )
WT="${TMP}/wt/feature"

garde() { ( cd "${WT}" && TALON_TARGET="$1" sh tools/rust.sh garde >/dev/null 2>&1 ); }
sortie_garde() { ( cd "${WT}" && TALON_TARGET="$1" sh tools/rust.sh garde 2>&1 || true ); }

echo "rust-kit-test — [A] tree principal : garde sans objet"
if ! ( cd "${PRINCIPAL}" && TALON_TARGET="${PRINCIPAL}/target" sh tools/rust.sh garde 2>&1 | grep -q "sans objet" ); then
    echo "ÉCHEC [A] : le tree principal devrait passer sans contrôle" >&2 ; fail=1
fi

echo "rust-kit-test — [B] worktree lié, artefacts dans le worktree : admis"
if ! garde "${WT}/target"; then
    echo "ÉCHEC [B] : artefacts confinés refusés" >&2 ; fail=1
fi

echo "rust-kit-test — [C] worktree lié, dossier cargo-target-feature hors dépôt : admis"
if ! garde "${TMP}/cache/cargo-target-feature"; then
    echo "ÉCHEC [C] : cargo-target-<nom> refusé" >&2 ; fail=1
fi

echo "rust-kit-test — [D] worktree lié, cache du tree principal : refusé avec le remède"
if garde "${PRINCIPAL}/target"; then
    echo "ÉCHEC [D] : le cache du tree principal est accepté" >&2 ; fail=1
fi
if ! sortie_garde "${PRINCIPAL}/target" | grep -q "cargo-target-feature"; then
    echo "ÉCHEC [D] : le remède ne nomme pas cargo-target-feature" >&2 ; fail=1
fi

echo "rust-kit-test — [E] cache partagé dont un composant porte le nom du worktree : refusé"
# Constat de revue n° 1 (2026-10-25) : …/main/feature/target et
# /var/cache/feature/shared étaient acceptés par un motif trop large.
mkdir -p "${TMP}/main2/feature"
if garde "${TMP}/main2/feature/target" || garde "${TMP}/cache/feature/shared"; then
    echo "ÉCHEC [E] : un composant de chemin homonyme suffit à passer la garde" >&2 ; fail=1
fi

echo "rust-kit-test — [F] cache partagé du poste : refusé"
if garde "${TMP}/cache/cargo-target"; then
    echo "ÉCHEC [F] : le cache partagé du poste est accepté" >&2 ; fail=1
fi

echo "rust-kit-test — [G] cargo muet : erreur dédiée, pas « cache partagé »"
s="$(sortie_garde "")"
if ! printf '%s' "${s}" | grep -q "aucun répertoire" || printf '%s' "${s}" | grep -q "PARTAGÉ"; then
    echo "ÉCHEC [G] : message inadapté quand cargo metadata ne rend rien" >&2 ; fail=1
fi

echo "rust-kit-test — [H] clean : par l'âge (--time), jamais --maxsize"
: > "${TALON_JOURNAL}"
mkdir -p "${WT}/target"
if ! ( cd "${WT}" && TALON_TARGET="${WT}/target" sh tools/rust.sh clean 3 >/dev/null 2>&1 ); then
    echo "ÉCHEC [H] : clean échoue sur des artefacts confinés" >&2 ; fail=1
fi
if ! grep -q -- '--time 3' "${TALON_JOURNAL}" || grep -q -- '--maxsize' "${TALON_JOURNAL}"; then
    echo "ÉCHEC [H] : cargo sweep n'a pas été appelé par l'âge seulement ($(cat "${TALON_JOURNAL}"))" >&2 ; fail=1
fi

echo "rust-kit-test — [I] clean sur un cache partagé : refusé sans --partage, admis avec"
: > "${TALON_JOURNAL}"
mkdir -p "${TMP}/cache/cargo-target"
if ( cd "${WT}" && TALON_TARGET="${TMP}/cache/cargo-target" sh tools/rust.sh clean >/dev/null 2>&1 ); then
    echo "ÉCHEC [I] : clean balaie un cache partagé sans le dire" >&2 ; fail=1
fi
if [ -s "${TALON_JOURNAL}" ]; then
    echo "ÉCHEC [I] : cargo sweep a été appelé malgré le refus" >&2 ; fail=1
fi
if ! ( cd "${WT}" && TALON_TARGET="${TMP}/cache/cargo-target" sh tools/rust.sh clean --partage 5 >/dev/null 2>&1 ) \
   || ! grep -q -- '--time 5' "${TALON_JOURNAL}"; then
    echo "ÉCHEC [I] : clean --partage n'a pas balayé par l'âge" >&2 ; fail=1
fi

echo "rust-kit-test — [J] etat : poids et incrémental lisibles, dossier absent dit « absent »"
s="$( cd "${WT}" && TALON_TARGET="${TMP}/nulle-part" sh tools/rust.sh etat 2>&1 )"
if ! printf '%s' "${s}" | grep -q "poids       : absent"; then
    echo "ÉCHEC [J] : un dossier absent n'est pas annoncé comme tel" >&2 ; fail=1
fi
mkdir -p "${WT}/target/debug/incremental" && dd if=/dev/zero of="${WT}/target/debug/incremental/a" bs=1024 count=2048 2>/dev/null
s="$( cd "${WT}" && TALON_TARGET="${WT}/target" sh tools/rust.sh etat 2>&1 )"
if ! printf '%s' "${s}" | grep -qE "incrémental : 0\.0 Gio"; then
    echo "ÉCHEC [J] : la somme de l'incrémental n'est pas en Gio (${s})" >&2 ; fail=1
fi

# --- Épinglage sur la stable courante (manifeste local, aucun réseau) -------
# Extrait du manifeste réel : la version de rustc est sous [pkg.rust], suivie
# du hash et de la date de compilation ; d'autres paquets ont la leur.
cat > "${TMP}/manifeste.toml" <<'FIN'
manifest-version = "2"
date = "2031-03-06"
[pkg.cargo]
version = "0.200.0 (aaaaaaaaa 2031-02-20)"
[pkg.rust]
version = "1.140.2 (bbbbbbbbb 2031-03-01)"
[pkg.rustfmt-preview]
version = "1.9.0-stable (bbbbbbbbb 2031-03-01)"
FIN
printf 'date = "2031-03-06"\n[pkg.rust]\nversion = "stable"\n' > "${TMP}/sans-version.toml"
EPI="${TMP}/epingle"
mkdir -p "${EPI}/tools" && cp "${KIT}" "${EPI}/tools/rust.sh"
epingler() { ( cd "${EPI}" && RUST_MANIFESTE="file://$1" sh tools/rust.sh epingler 2>&1 ); }

echo "rust-kit-test — [K] sans fichier de chaîne : créé sur la version exacte du manifeste"
rm -f "${EPI}/rust-toolchain.toml"
epingler "${TMP}/manifeste.toml" >/dev/null || { echo "ÉCHEC [K] : épinglage en échec" >&2 ; fail=1 ; }
if ! grep -q '^channel = "1.140.2"$' "${EPI}/rust-toolchain.toml" 2>/dev/null \
   || grep -q '"stable"' "${EPI}/rust-toolchain.toml" \
   || ! grep -q '2031-03-06' "${EPI}/rust-toolchain.toml"; then
    echo "ÉCHEC [K] : la chaîne créée n'est pas 1.140.2 datée du 2031-03-06 ($(cat "${EPI}/rust-toolchain.toml" 2>/dev/null))" >&2 ; fail=1
fi

echo "rust-kit-test — [L] chaîne ancienne : seule la ligne channel change, le reste est gardé"
printf '# garde\n[toolchain]\nchannel = "1.95.0"\ncomponents = ["rustfmt", "clippy", "llvm-tools"]\nprofile = "minimal"\n' > "${EPI}/rust-toolchain.toml"
s="$(epingler "${TMP}/manifeste.toml" || true)"
attendu="$(printf '# garde\n[toolchain]\nchannel = "1.140.2"\ncomponents = ["rustfmt", "clippy", "llvm-tools"]\nprofile = "minimal"')"
if [ "$(cat "${EPI}/rust-toolchain.toml")" != "${attendu}" ] || ! printf '%s' "${s}" | grep -q '1.95.0 → 1.140.2'; then
    echo "ÉCHEC [L] : montée de version inexacte (${s})" >&2 ; fail=1
fi

echo "rust-kit-test — [M] chaîne à jour : rien ne change, et c'est dit"
avant="$(cat "${EPI}/rust-toolchain.toml")"
if ! epingler "${TMP}/manifeste.toml" | grep -q "déjà à jour" || [ "$(cat "${EPI}/rust-toolchain.toml")" != "${avant}" ]; then
    echo "ÉCHEC [M] : une chaîne à jour est réécrite ou non signalée" >&2 ; fail=1
fi

echo "rust-kit-test — [N] manifeste sans version exacte, ou injoignable : échec, fichier intact"
printf '[toolchain]\nchannel = "1.95.0"\n' > "${EPI}/rust-toolchain.toml"
avant="$(cat "${EPI}/rust-toolchain.toml")"
if ( cd "${EPI}" && RUST_MANIFESTE="file://${TMP}/sans-version.toml" sh tools/rust.sh epingler >/dev/null 2>&1 ); then
    echo "ÉCHEC [N] : un manifeste sans version exacte est accepté" >&2 ; fail=1
fi
if ( cd "${EPI}" && RUST_MANIFESTE="file://${TMP}/absent.toml" sh tools/rust.sh epingler >/dev/null 2>&1 ); then
    echo "ÉCHEC [N] : un manifeste injoignable est accepté" >&2 ; fail=1
fi
if [ "$(cat "${EPI}/rust-toolchain.toml")" != "${avant}" ]; then
    echo "ÉCHEC [N] : le fichier de chaîne a été modifié malgré l'échec" >&2 ; fail=1
fi
rm -f "${EPI}/rust-toolchain.toml"
( cd "${EPI}" && RUST_MANIFESTE="file://${TMP}/absent.toml" sh tools/rust.sh epingler >/dev/null 2>&1 ) || true
if [ -e "${EPI}/rust-toolchain.toml" ]; then
    echo "ÉCHEC [N] : un fichier de chaîne est créé sans manifeste" >&2 ; fail=1
fi

if [ "${fail}" -ne 0 ]; then
    echo "rust-kit-test : ÉCHEC." >&2
    exit 1
fi
echo "rust-kit-test : OK."
