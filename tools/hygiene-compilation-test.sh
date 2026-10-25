#!/bin/sh
# [utest->req~hygiene-artefacts-compilation~1]
# Test de la porte d'hygiène des artefacts de compilation, sur ses cas
# d'échec (R3) : chaîne non épinglée, tests Cargo sans CARGO_INCREMENTAL=0 ;
# et sur ses cas de passage : dépôt sans Cargo, dépôt réglé, export en amont
# dans le même fichier, appel en commentaire ignoré. POSIX sh strict.
set -eu

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "${TMP}"' EXIT INT TERM
fail=0

D="${TMP}/depot"
prepare() {
    rm -rf "${D}"
    mkdir -p "${D}/tools"
    cp "${ROOT}/tools/hygiene-compilation.sh" "${D}/tools/"
}
porte() { (cd "${D}" && sh tools/hygiene-compilation.sh >/dev/null 2>&1); }

echo "hygiene-test — [A] sans manifeste Cargo : rien à juger, la porte passe"
prepare
if ! porte; then
    echo "ÉCHEC [A] : la porte échoue sur un dépôt sans Cargo.toml" >&2 ; fail=1
fi

echo "hygiene-test — [B] Cargo.toml sans chaîne épinglée : la porte échoue"
prepare
printf '[package]\nname = "x"\nversion = "0.1.0"\n' > "${D}/Cargo.toml"
if porte; then
    echo "ÉCHEC [B] : chaîne non épinglée acceptée" >&2 ; fail=1
fi

echo "hygiene-test — [C] tests Cargo sans CARGO_INCREMENTAL=0 : la porte échoue"
prepare
printf '[package]\nname = "x"\nversion = "0.1.0"\n' > "${D}/Cargo.toml"
printf '[toolchain]\nchannel = "stable"\n' > "${D}/rust-toolchain.toml"
printf 'test:\n    cargo nextest run --workspace\n' > "${D}/justfile"
if porte; then
    echo "ÉCHEC [C] : nextest sans CARGO_INCREMENTAL=0 accepté" >&2 ; fail=1
fi
# Le message nomme le fichier fautif et la ligne.
if ! (cd "${D}" && sh tools/hygiene-compilation.sh 2>&1 || true) | grep -q 'justfile'; then
    echo "ÉCHEC [C] : le fichier fautif n'est pas nommé" >&2 ; fail=1
fi

echo "hygiene-test — [D] CARGO_INCREMENTAL=0 sur la ligne : la porte passe"
printf 'test:\n    CARGO_INCREMENTAL=0 cargo nextest run --workspace\n' > "${D}/justfile"
if ! porte; then
    echo "ÉCHEC [D] : réglage correct refusé" >&2 ; fail=1
fi

echo "hygiene-test — [E] export en amont dans le même script : la porte passe"
rm -f "${D}/justfile"
printf '#!/bin/sh\nexport CARGO_INCREMENTAL=0\ncargo test --workspace\ncargo llvm-cov --workspace\n' > "${D}/tools/ci.sh"
if ! porte; then
    echo "ÉCHEC [E] : export en amont non reconnu" >&2 ; fail=1
fi

echo "hygiene-test — [F] appel seulement en commentaire : ignoré, la porte passe"
printf '#!/bin/sh\n# exemple : cargo test --workspace\necho rien\n' > "${D}/tools/ci.sh"
if ! porte; then
    echo "ÉCHEC [F] : un appel en commentaire a été compté" >&2 ; fail=1
fi

echo "hygiene-test — [G] couverture sans réglage dans la CI GitHub : la porte échoue"
mkdir -p "${D}/.github/workflows"
printf 'jobs:\n  tests:\n    steps:\n      - run: cargo llvm-cov --workspace\n' > "${D}/.github/workflows/ci.yml"
if porte; then
    echo "ÉCHEC [G] : llvm-cov sans CARGO_INCREMENTAL=0 accepté dans la CI" >&2 ; fail=1
fi

if [ "${fail}" -ne 0 ]; then
    echo "hygiene-test : ÉCHEC." >&2
    exit 1
fi
echo "hygiene-test : OK."
