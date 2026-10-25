# Module bootstrap — Rust : cargo (rustup), cargo-nextest, cargo-sweep, et la
# chaîne épinglée du dépôt (rust-toolchain.toml).
# MODÈLE à copier dans tools/bootstrap.d/ d'un projet instancié, puis à
# taguer vers l'ADR technologique du projet qui le justifie (R2) ; l'hygiène
# des artefacts relève de l'exigence `req~hygiene-artefacts-compilation~1`
# du gabarit, à reprendre dans la spécification du projet.
# Contrat : sourcé par tools/bootstrap.sh, PHASE=annonce puis PHASE=verifie
# (voir l'en-tête de bootstrap.sh pour les variables et aides disponibles).
case "${PHASE}" in
    annonce)
        echo "    - Rust (cargo)      — compilation ; cargo-nextest (tests), cargo-sweep (hygiène du cache)"
        ;;
    verifie)
        # rustup n'est dans aucun dépôt apt/dnf utile : https://rustup.rs
        verifier "Rust (cargo)" cargo "" "" "rustup" "Rustlang.Rustup" \
            "installer rustup (https://rustup.rs), puis relancer --verifie ; la chaîne vient de rust-toolchain.toml"

        if command -v cargo >/dev/null 2>&1; then
            # Outils cargo : installables par cargo lui-même, quelle que soit
            # la plateforme — on n'attend pas le gestionnaire de paquets.
            for outil in cargo-nextest cargo-sweep; do
                if command -v "${outil}" >/dev/null 2>&1; then
                    echo "ok — ${outil}"
                elif [ "${INSTALLE}" -eq 1 ]; then
                    echo "MANQUANT — ${outil} : installation via cargo install"
                    cargo install --locked "${outil}" \
                        || { echo "  → échec de cargo install ${outil}" ; AVERTISSEMENTS=$((AVERTISSEMENTS + 1)) ; }
                else
                    echo "MANQUANT — ${outil} (cargo install --locked ${outil})"
                    MANQUANTS=$((MANQUANTS + 1))
                    ABSENTS="${ABSENTS} ${outil}"
                fi
            done

            # Chaîne épinglée : sans elle chaque changement de rustc duplique
            # les artefacts (porte tools/hygiene-compilation.sh du gabarit).
            if [ -f "${RACINE}/rust-toolchain.toml" ] || [ -f "${RACINE}/rust-toolchain" ]; then
                echo "ok — chaîne de compilation épinglée"
            else
                echo "AVERTISSEMENT — rust-toolchain.toml absent : la chaîne n'est pas épinglée"
                AVERTISSEMENTS=$((AVERTISSEMENTS + 1))
            fi

            # Cache de compilation hors du dépôt (target-dir partagé ou
            # déplacé par le poste) : le signaler, car les chemins ./target
            # en dur deviennent muets (méthode, ch. 4). La vérification
            # effective est faite par tools/rust.sh garde avant chaque build.
            cible="$(cargo metadata --format-version 1 --no-deps 2>/dev/null \
                | tr ',' '\n' | sed -n 's/.*"target_directory":"\([^"]*\)".*/\1/p' | head -1)"
            case "${cible}" in
                "")             ;;
                "${RACINE}"/*)  echo "ok — artefacts dans le dépôt (${cible#"${RACINE}"/})" ;;
                *)              echo "note — artefacts hors du dépôt : ${cible} (cache déplacé par le poste ; voir tools/rust.sh garde)" ;;
            esac
        fi
        ;;
esac
