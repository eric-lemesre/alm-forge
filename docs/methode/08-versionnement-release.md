# 8. Versionnement et release

<!-- [impl->req~versionnement-release~1] -->

## Versionnement

- **SemVer** (MAJEUR.MINEUR.CORRECTIF), un numéro unique pour tout le dépôt
  (lockstep), porté par le fichier `VERSION` et le tag git `vX.Y.Z`.
- Le journal `CHANGELOG.md` suit **Keep a Changelog** : une section
  « Non publié » alimentée au fil des pull requests, transformée en section
  versionnée datée au moment de la release. C'est la lecture du journal qui
  décide du niveau d'incrément (correctif, mineur, majeur).
- La cohérence VERSION ↔ CHANGELOG est une porte mécanique (`task check`) : on
  ne peut pas publier une version absente du journal.
- Dans un projet instancié multi-composants, tous les manifestes (Cargo.toml,
  package.json…) suivent le même numéro ; `tools/bump.sh` est le point unique
  de mise à jour — l'étendre aux manifestes du projet fait partie de
  l'instanciation.

## Commits et branches

- **Conventional Commits en français** : `type(scope): sujet` avec les types
  feat, fix, docs, test, chore, refactor, perf, ci, build, style, revert. Le
  scope reprend le domaine d'exigences quand il existe.
- Un commit de réalisation référence son exigence dans le sujet :
  `feat(notif): req~notification-terminale~1 accusé sonore`. Un commit = une
  exigence ou une intention cohérente — pas de commits fourre-tout.
- Le format est vérifié par le hook commit-msg (garde absente d'ergonomia,
  ajoutée ici) ; la mention de l'IA suit la politique arbitrée à
  l'instanciation — par défaut, déclaration obligatoire avec responsable
  humain et relecture recommandée (R0, ADR-0011).
- Branches : `type/sujet-court` (`feat/notification-sonore`,
  `fix/echeance-fin-de-mois`).

## Release

1. Vérifier que `task ci` passe.
2. `task bump -- X.Y.Z` — met à jour VERSION ; transformer la section
   « Non publié » du journal en section `[X.Y.Z] - AAAA-MM-JJ`.
3. Commit `chore: version X.Y.Z`, tag `vX.Y.Z`, push du tag.
4. La publication d'artefacts (paquets, images, SBOM) est propre à chaque
   projet instancié ; le gabarit fournit l'emplacement
   (`.github/workflows/`) et la règle : toute chaîne de publication est
   déclenchée par le tag, jamais à la main.
