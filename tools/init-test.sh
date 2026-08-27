#!/bin/sh
# [utest->req~instanciation-outillee~1]
# [utest->req~politique-attribution-agents~2]
# [utest->req~politique-langue~1]
# Test mécanisé du script d'instanciation : exécute tools/init.sh sur des
# copies temporaires et vérifie les critères d'acceptation des quatre
# arbitrages (identité, attribution des agents, langue, cycle de vie des
# issues), le refus de tourner deux fois, et des portes vertes dans chaque
# variante. POSIX sh strict.
set -eu

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TA="$(mktemp -d)"
TB="$(mktemp -d)"
TC="$(mktemp -d)"
TD="$(mktemp -d)"
TE="$(mktemp -d)"
TF="$(mktemp -d)"
trap 'rm -rf "${TA}" "${TB}" "${TC}" "${TD}" "${TE}" "${TF}"' EXIT INT TERM
fail=0

instancier() {
    _dest="$1"
    shift
    cp -R "${ROOT}/." "${_dest}/"
    rm -rf "${_dest}/.git" "${_dest}/build"
    # Commit initial obligatoire : un vrai clone (ou un dépôt « Use this
    # template ») a un index peuplé, et les générateurs le consultent via
    # « git ls-files ». Sans ce commit l'index est vide et le test resterait
    # aveugle aux fichiers hérités du gabarit supprimés mais non désindexés
    # par init.sh (cas constaté : awk fatal sur todo-0001).
    (cd "${_dest}" && git init -q &&
        git add -A &&
        git -c user.name="Init Test" -c user.email="init-test@example.invalid" \
            -c commit.gpgsign=false commit -q -m "gabarit: état initial" &&
        sh tools/init.sh --nom projet-test --porteur "Porteuse Test" --force "$@")
}

echo "init-test [A] — instanciation par défaut"
instancier "${TA}"
if [ -f "${TA}/docs/adr/0001-structurer-alm-forge-en-depot-gabarit.md" ]; then
    echo "ÉCHEC [A] : les ADR du gabarit n'ont pas été retirés" >&2 ; fail=1
fi
if [ -f "${TA}/spec/01-besoins/besoins.md" ]; then
    echo "ÉCHEC [A] : la spécification du gabarit n'a pas été retirée" >&2 ; fail=1
fi
case "$(cat "${TA}/LICENSE")" in
    *"Porteuse Test"*) ;;
    *) echo "ÉCHEC [A] : la LICENSE ne porte pas le porteur" >&2 ; fail=1 ;;
esac
case "$(cat "${TA}/README.md")" in
    *projet-test*) ;;
    *) echo "ÉCHEC [A] : le README ne porte pas le nom du projet" >&2 ; fail=1 ;;
esac
if [ ! -d "${TA}/templates/en" ] || [ ! -f "${TA}/README.en.md" ]; then
    echo "ÉCHEC [A] : le défaut fr-en doit conserver le bilinguisme" >&2 ; fail=1
fi
# Politique par défaut : déclaration obligatoire (diligence, ADR-0011).
printf 'feat: sujet valide\n' > "${TA}/msg-attr"
if (cd "${TA}" && sh tools/hooks/commit-msg.sh msg-attr) 2>/dev/null; then
    echo "ÉCHEC [A] : le hook accepte un commit sans trailer IA (défaut = obligatoire)" >&2
    fail=1
fi
printf 'feat: sujet valide\n\nIA: aucune\n' > "${TA}/msg-attr"
if ! (cd "${TA}" && sh tools/hooks/commit-msg.sh msg-attr) 2>/dev/null; then
    echo "ÉCHEC [A] : le hook refuse « IA: aucune »" >&2
    fail=1
fi
printf 'feat: sujet valide\n\nIA: Outil X\n' > "${TA}/msg-attr"
if (cd "${TA}" && sh tools/hooks/commit-msg.sh msg-attr) 2>/dev/null; then
    echo "ÉCHEC [A] : le hook accepte un usage d'IA sans responsable humain" >&2
    fail=1
fi
printf 'feat: sujet valide\n\nIA: Outil X\nResponsable: Porteuse Test\n' > "${TA}/msg-attr"
if ! (cd "${TA}" && sh tools/hooks/commit-msg.sh msg-attr) 2>/dev/null; then
    echo "ÉCHEC [A] : le hook refuse une déclaration IA complète (outil + responsable)" >&2
    fail=1
fi
# Cycle de vie des issues par défaut : circuit complet conservé et consigné.
if [ ! -f "${TA}/.github/ISSUE_TEMPLATE/proposition-exigence.yml" ] || \
   [ ! -f "${TA}/.github/ISSUE_TEMPLATE/proposition-organisation.yml" ]; then
    echo "ÉCHEC [A] : le défaut complet doit conserver les formulaires [Spec]/[Orga]" >&2
    fail=1
fi
case "$(cat "${TA}/docs/decisions/registre.md")" in
    *"défaut du gabarit adopté"*) ;;
    *) echo "ÉCHEC [A] : l'arbitrage du cycle de vie n'est pas consigné au registre" >&2 ; fail=1 ;;
esac
if grep -q 'impl->req~issues-' "${TA}/.github/ISSUE_TEMPLATE/anomalie.yml" 2>/dev/null; then
    echo "ÉCHEC [A] : les tags de couverture des formulaires n'ont pas été retirés" >&2
    fail=1
fi
(cd "${TA}" && sh tools/oft.sh trace >/dev/null && sh tools/checks.sh >/dev/null) || {
    echo "ÉCHEC [A] : portes non vertes après instanciation" >&2 ; fail=1
}
if (cd "${TA}" && sh tools/init.sh --nom x --porteur y </dev/null) 2>/dev/null; then
    echo "ÉCHEC [A] : init.sh a accepté de tourner deux fois sans --force" >&2 ; fail=1
fi
if (cd "${TA}" && sh tools/init.sh --nom x --porteur y --cycle-issues nimporte --force </dev/null) 2>/dev/null; then
    echo "ÉCHEC [A] : init.sh a accepté une valeur invalide pour --cycle-issues" >&2 ; fail=1
fi

echo "init-test [B] — mentions autorisées, sans obligation"
instancier "${TB}" --attribution-agents autorisee
printf 'feat: sujet valide\n\nCo-Authored-By: Robot <r@x>\n' > "${TB}/msg-attr"
if ! (cd "${TB}" && sh tools/hooks/commit-msg.sh msg-attr) 2>/dev/null; then
    echo "ÉCHEC [B] : le hook refuse un co-auteur alors que les mentions sont autorisées" >&2
    fail=1
fi
printf 'feat: sujet valide\n' > "${TB}/msg-attr"
if ! (cd "${TB}" && sh tools/hooks/commit-msg.sh msg-attr) 2>/dev/null; then
    echo "ÉCHEC [B] : le hook impose un trailer alors que rien n'est obligatoire" >&2
    fail=1
fi
case "$(cat "${TB}/AGENTS.md")" in
    *"autorisées, sans obligation"*) ;;
    *) echo "ÉCHEC [B] : la règle R0 d'AGENTS.md ne reflète pas le choix" >&2 ; fail=1 ;;
esac

echo "init-test [E] — mentions interdites"
instancier "${TE}" --attribution-agents interdite
printf 'feat: sujet valide\n\nCo-Authored-By: Robot <r@x>\n' > "${TE}/msg-attr"
if (cd "${TE}" && sh tools/hooks/commit-msg.sh msg-attr) 2>/dev/null; then
    echo "ÉCHEC [E] : le hook accepte un co-auteur alors que les mentions sont interdites" >&2
    fail=1
fi
printf 'feat: sujet valide\n' > "${TE}/msg-attr"
if ! (cd "${TE}" && sh tools/hooks/commit-msg.sh msg-attr) 2>/dev/null; then
    echo "ÉCHEC [E] : le hook refuse un commit sain sous interdiction" >&2
    fail=1
fi

echo "init-test [C] — langue fr uniquement"
instancier "${TC}" --langue fr
if [ -d "${TC}/templates/en" ] || [ -f "${TC}/README.en.md" ]; then
    echo "ÉCHEC [C] : le jeu anglais aurait dû être retiré" >&2 ; fail=1
fi
if grep -q "parite-templates:debut" "${TC}/tools/checks.sh"; then
    echo "ÉCHEC [C] : la porte de parité aurait dû être retirée" >&2 ; fail=1
fi
(cd "${TC}" && sh tools/oft.sh trace >/dev/null && sh tools/checks.sh >/dev/null) || {
    echo "ÉCHEC [C] : portes non vertes en langue fr" >&2 ; fail=1
}

echo "init-test [D] — langue en uniquement"
instancier "${TD}" --langue en
if [ -d "${TD}/templates/fr" ]; then
    echo "ÉCHEC [D] : le jeu français aurait dû être retiré" >&2 ; fail=1
fi
case "$(cat "${TD}/README.md")" in
    *"instantiated from"*) ;;
    *) echo "ÉCHEC [D] : le README principal devrait être en anglais" >&2 ; fail=1 ;;
esac
(cd "${TD}" && sh tools/oft.sh trace >/dev/null && sh tools/checks.sh >/dev/null) || {
    echo "ÉCHEC [D] : portes non vertes en langue en" >&2 ; fail=1
}
(cd "${TD}" && sh tools/adr-new.sh premiere-decision >/dev/null && \
    [ -f docs/adr/0001-premiere-decision.md ]) || {
    echo "ÉCHEC [D] : adr-new doit fonctionner sans templates/fr" >&2 ; fail=1
}

echo "init-test [F] — cycle de vie des issues réduit"
instancier "${TF}" --cycle-issues reduit
if [ -f "${TF}/.github/ISSUE_TEMPLATE/proposition-exigence.yml" ] || \
   [ -f "${TF}/.github/ISSUE_TEMPLATE/proposition-organisation.yml" ]; then
    echo "ÉCHEC [F] : les formulaires de consultation [Spec]/[Orga] auraient dû être retirés" >&2
    fail=1
fi
case "$(cat "${TF}/docs/decisions/registre.md")" in
    *"circuit réduit"*) ;;
    *) echo "ÉCHEC [F] : la réduction du cycle de vie n'est pas consignée au registre" >&2 ; fail=1 ;;
esac
(cd "${TF}" && sh tools/oft.sh trace >/dev/null && sh tools/checks.sh >/dev/null) || {
    echo "ÉCHEC [F] : portes non vertes en cycle réduit" >&2 ; fail=1
}

if [ "${fail}" -ne 0 ]; then
    echo "init-test : ÉCHEC." >&2
    exit 1
fi
echo "init-test : OK."
