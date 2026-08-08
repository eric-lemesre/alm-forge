# Journal des changements

Format : [Keep a Changelog](https://keepachangelog.com/fr/1.1.0/) —
versionnement : [SemVer](https://semver.org/lang/fr/).

## [Non publié]

### Modifié

- Anti-pattern « outillage aveugle à son environnement » ajouté à la méthode
  (ch. 4) et rappelé dans les points d'extension de `tools/clean.sh` et
  `tools/bootstrap.sh` : chemins d'artefacts en dur cassés ou neutralisés
  par les caches partagés du poste (CARGO_TARGET_DIR…), nettoyages d'outil
  devenus globaux — leçon d'un cas vécu le jour même.

- Orchestration découplée (ADR-0007, OQ-001) : portes réécrites en POSIX sh
  strict dans `tools/` (appelées directement par la CI et les hooks),
  orchestrateur réduit à une façade de délégation pure et interchangeable —
  `Taskfile.yml` (Task) par défaut, variante justfile dans
  `templates/orchestrators/`, ou aucun. Le justfile racine est supprimé.

### Ajouté

- Porte anti-secrets (req~detection-secrets~1, ADR-0012) : gitleaks épinglé
  par version et empreintes par plateforme, bloquant en CI, signalant en
  local sans l'outil ; test mécanisé `tools/secrets-test.sh` ; cible
  `secrets` dans les façades, intégrée à `ci` et au hook pre-commit.
- Cadre de sécurité continue (req~securite-continue~1, méthode ch. 10) :
  STRIDE léger obligatoire pour les exigences de niveau S (reporté dans la
  Definition of Done), politique de vulnérabilités avec délais par sévérité
  et exceptions justifiées-datées-portées, SBOM en point d'extension de la
  release ; modèles bilingues threat-model et security-exception.
- Durcissement des façades CI : permissions minimales (contents: read) et
  persist-credentials: false sur le checkout GitHub.
- Scripts `tools/adr-new.sh` et `tools/bump.sh` (logique sortie des façades).
- Script d'instanciation `tools/init.sh` (req~instanciation-outillee~1) avec
  test mécanisé `tools/init-test.sh` câblé en CI : personnalise l'identité du
  projet, retire la spécification et les ADR du gabarit, laisse les portes
  vertes.
- Arbitrages d'instanciation : politique de mention de l'IA dans les commits
  (req~politique-attribution-agents~2, ADR-0011 remplaçant l'ADR-0008 — par
  défaut, déclaration obligatoire « IA: » avec responsable humain et relecture
  recommandée ; « autorisee » et « interdite » au choix) et langue du dépôt
  fr/en/fr-en (req~politique-langue~1, ADR-0009, bilingue par défaut) —
  appliqués mécaniquement par init.sh (blocs à marqueurs dans les portes).
- Portabilité des forges (req~portabilite-forges~1, ADR-0010) : façade CI
  GitLab `.gitlab-ci.yml` et modèles d'issues/MR `.gitlab/`, mêmes scripts que
  la façade GitHub ; périmètre de traçabilité filtrant les chemins absents.
- Nettoyage outillé du dépôt local (req~nettoyage-outille~1) :
  `tools/clean.sh` (chemins déclarés uniquement, point d'extension projet,
  cache purgé sur `--all` seulement, volume libéré affiché — motivé par
  l'incident des 500 Go de target/ sur ergonomia) et son test
  `tools/clean-test.sh` câblé dans les deux façades CI.
- Onboarding « Scripts to Rule Them All » (req~onboarding-outille~1) :
  `tools/setup.sh` (accueil après clone : bootstrap, hooks, portes,
  orientation) et `tools/bootstrap.sh` (socle + point d'extension où chaque
  projet installe son outillage en vérification de ses ADR), testés par
  `tools/setup-test.sh` câblé en CI.

## [0.1.0] - 2026-08-08

### Ajouté

- Méthode complète (`docs/methode/`, 9 chapitres) : expression du besoin,
  exigences EARS, ADR, traçabilité, tests mécanisés, questions ouvertes, revue
  et recette, versionnement, gouvernance des agents.
- Registre ADR avec six décisions fondatrices et charte du registre.
- Spécification auto-appliquée : 4 besoins, 14 exigences tracées.
- Traçabilité OpenFastTrace 4.9.0 (jar épinglé par SHA-256), hooks git,
  contrôles de cohérence et porte CI GitHub Actions.
- Modèles d'artefacts bilingues (`templates/fr/`, `templates/en/`) : ADR,
  besoin, exigence, question ouverte, relevé de décision, revue de code.
- Exemple multi-langages (Python, Rust, shell) exécutant la chaîne complète.
- Contrat d'agents AGENTS.md et adaptateur CLAUDE.md.
