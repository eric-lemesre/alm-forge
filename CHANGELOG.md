# Journal des changements

Format : [Keep a Changelog](https://keepachangelog.com/fr/1.1.0/) —
versionnement : [SemVer](https://semver.org/lang/fr/).

## [Non publié]

### Ajouté

- **Transposition des mécaniques ALM d'ergonomia** (D-2026-08-13 à
  D-2026-08-16), avec leur vocabulaire rendu bilingue. Seize mécaniques
  éprouvées sur un dépôt vivant et absentes de la fondation, chacune motivée
  par un défaut réellement constaté.

- **Lexique du vocabulaire outillé** (ADR-0015, req~lexique-outille~1) :
  `tools/lexique.sh` déclare en français et en anglais les 42 termes que les
  portes reconnaissent — statuts, niveaux normatifs, verdicts, gravités,
  étiquettes de forge, commandes de consultation. `tools/init.sh --langue`
  fige le jeu ; aucune porte n'écrit plus un de ces mots en dur. Referme
  l'écart laissé par l'ADR-0009, qui ne portait que sur les artefacts
  générés : une porte cherchant « ACTIVE » ou « conforme » devenait muette —
  sans erreur — dans un dépôt instancié en anglais.

- **Audit de réalisation** (ADR-0016, req~audit-de-realisation~1) : porte
  distincte de la traçabilité, qui pose la question que celle-ci ne pose
  jamais — le livré fait-il ce que l'exigence dit ? Une fiche par domaine dans
  `docs/audit/`, verdicts écrits à la main, tableau de bord généré, plafond
  d'exigences non examinées à 0. Le générateur compte, l'humain juge.

- **Périmètre de la porte constaté** (ADR-0017, req~perimetre-constate~1) :
  `tools/perimetre.sh` déduit la voie du changement réel — commits, index,
  arbre **et fichiers non suivis** — et impose la voie complète au moindre
  doute ; `tools/ci.sh` devient le point d'entrée unique dont les quatre
  façades (Task, just, GitHub, GitLab) ne font que déléguer.

- **Six portes documentaires** : intégrité des liens internes
  (req~integrite-liens~1), anti-dérive des artefacts générés — qui outille
  enfin la règle R8 (req~anti-derive-generes~1), statuts de domaine
  (req~statut-specification~1), relevés de séance et registre
  (req~releves-de-decision~1), journaux et intangibilité des sections
  publiées (req~journaux-depot-et-logiciel~1), classification des exigences
  (req~classification-exigences~1).

- **Feuille de route, suivi de revue et badges dérivés**
  (req~feuille-de-route-outillee~1, req~suivi-constats-revue~1,
  req~badges-autonomes~1) : trois artefacts générés au lieu d'être tenus à la
  main. Le suivi de revue mécanise au passage la règle du chapitre 7 —
  la porte refuse désormais un constat de sévérité haute sans verdict.

- **Coordination des issues outillée** : `tools/issues.sh` contrôle la
  conformité au cycle de vie, délibérément **hors porte** (réseau et session
  requis, req~conformite-issues~1) ; `templates/forge/` fournit les cinq
  automatismes prêts à câbler pour GitHub et GitLab, déclarés non câblés dans
  le gabarit avec leur raison (req~automatismes-forge~1).

- **Quatre chapitres de méthode** : 12 (feuille de route), 13 (statuts de
  spécification), 14 (audit de réalisation), 15 (cadrage des nouvelles
  fonctionnalités) ; compléments aux chapitres 4 (liste des portes,
  aiguillage, deux nouveaux anti-patterns), 7 (suivi consolidé) et 8 (NEWS ⟂
  CHANGELOG, sections closes, campagne de non-régression aux versions
  mineures).

- **Modèles bilingues** `roadmap-card.md` et `audit-sheet.md`.

### Corrigé

- **Deux angles morts de la porte des liens**, comblés d'après le retour
  d'ergonomia du même jour (FIX-#846) : les fichiers de forge
  (`.github/`, `.gitlab/`) n'étaient pas parcourus, et les URL
  `https://<forge>/<org>/<dépôt>/blob/<ref>/<chemin>` étaient rangées avec les
  liens externes alors qu'elles désignent un chemin du dépôt — seule forme de
  lien dont disposent les gabarits d'issue. Là-bas, un renommage de répertoire
  a tué seize renvois dont la regex d'un workflow, restée verte en ne filtrant
  plus rien. Cinq cas de test ajoutés, dont deux garde-fous contre les faux
  positifs (dépôt tiers, URL interpolée) et un contre la confusion
  commentaire YAML / titre Markdown.
- **Le filtre de retombée des lectures se prouve désormais**
  (`templates/forge/tools/automatismes.sh`) : écrit en chemins, il survivait
  syntaxiquement à un renommage tout en ne filtrant plus rien — et aurait vidé
  les positions de toutes les consultations ouvertes. `verifier_filtre` refuse
  de s'exécuter si un chemin exclu n'existe pas.

- **Revue de code par un relecteur tiers** (Kimi, kimi-cli 0.28.0), archivée
  dans `docs/revues/2026-08-20-transposition-alm.md` : **sept constats, tous
  corrigés, aucun rejeté**. Le plus important — le seul de sévérité haute —
  contredisait un critère d'acceptation : `tools/audit.sh` n'acceptait que le
  français en mode bilingue, qui est pourtant le défaut de l'instanciation.
  Le lexique gagne `lex_est` (reconnaissance selon la langue figée) et
  `lex_motif` (alternance parenthésée) ; la même classe de défaut touchait
  `todo.sh` et `statuts.sh`, où l'alternance insérée nue dans une regex
  produisait deux branches fausses. Le relecteur a également établi que le
  test bilingue existant ne prouvait rien sur le mode `fr-en` : le cas
  manquant est ajouté.
- Robustesse des portes, d'après la même revue : découpage des listes de
  chemins sur les seules fins de ligne (`IFS` + `set -f`, dix portes) — un
  fichier au nom espacé était ignoré **sans que rien ne le signale** ;
  extraction des liens à parenthèses équilibrées (`guide-(v2).md` n'est plus
  déclaré mort à tort) ; recherche de forge échappée ; fenêtre du contrôle
  des journaux surchargeable ; garde sur les clés du lexique.
- `templates/forge/` n'est plus supprimé à l'instanciation : le retirer
  privait le projet instancié de ce que `req~automatismes-forge~1` promet de
  lui fournir. Constat classé « basse » par le relecteur, en réalité une
  annulation d'exigence.
- Deux défauts trouvés **en corrigeant la revue**, dans la porte de
  consolidation elle-même : une barre verticale non échappée dans une cellule
  décalait les colonnes et faisait lire le verdict au mauvais endroit — un
  constat soldé s'affichait « ouvert », en silence ; et le code de retour
  d'`awk` se perdait dans un pipe vers `sort`. Les deux sont mécanisés, avec
  leurs cas de test.
- **Nouveau contrôle** `tools/checks.sh` : tout script du dépôt est analysable
  par `sh`. Ajouté après **trois** occurrences du même défaut — une apostrophe
  dans un commentaire de programme `awk` referme la quote qui l'entoure, et le
  shell se met à lire le programme comme du code. Le fichier paraît sain et
  casse à l'exécution, donc en CI, jamais en revue.

### Modifié

- **Dette révélée et résorbée.** La porte de classification a montré que 19
  exigences sur 25 étaient de niveau DOIT **sans aucune vérification
  déclarée** — dont les trois contrôles historiques de `tools/checks.sh`, qui
  n'avaient jamais été éprouvés sur leur cas d'échec (R3). Le taux passe de
  24 % à 100 % : `tools/checks-test.sh` et `tools/socle-test.sh` couvrent ce
  qui est mécanisable, `docs/verification-manuelle/` porte les douze
  procédures `mtest` de ce qui ne l'est pas.
- `tools/checks.sh` : trois contrôles ajoutés — complétude de l'index des ADR
  et sa réciproque, alignement des façades CI, complétude du lexique.
- Hook pre-commit : rejoue la voie documentaire complète (`tools/ci.sh
  --rapide`) au lieu de trois portes ; la voie complète reste due avant de
  proposer le travail.
- `tools/init.sh` : fige la langue du lexique, retire les procédures et fiches
  du gabarit, régénère et indexe les artefacts dérivés (12 étapes).
- Contrat d'agents : R8 outillée, deux règles ajoutées (R9 vocabulaire au
  lexique, R10 vérification déclarée pour tout DOIT), trois interdits
  explicites.
- Méthode, trois amendements repris d'ergonomia le même jour : une
  spécification validée **ne ferme pas** la demande — l'artefact n'est pas le
  besoin, et « quand la totalité de la pratique dément une règle écrite, c'est
  la règle qui est fausse » (ch. 11) ; un agrégat a **une** source, et un état
  d'avancement se calcule au lieu de se saisir (ch. 4, nouvel anti-pattern) ;
  la révision éditoriale d'une section publiée se déclare **après** la fusion,
  son SHA n'existant pas avant le squash (ch. 8).

### Connu

- **Écart d'audit ouvert** : `req~cycle-de-vie-exigence~1` réclame un statut
  par exigence (brouillon → proposée → … → vérifiée) ; le dépôt n'a jamais eu
  que le statut de **domaine**. Écart révélé par la mise en place de l'audit,
  présent depuis la fondation. À arbitrer — réviser l'exigence, ou outiller le
  statut par exigence — par consultation, pas par correction silencieuse.

### Modifié

- Bootstrap consenti, modulaire et auto-installant (ADR-0014,
  req~onboarding-outille~2) : `tools/bootstrap.sh` devient un orchestrateur —
  annonce → accord (`--oui`/`--verifie`) → vérifie → installe les seuls
  manquants via le gestionnaire natif (apt/dnf/brew/winget), échec nommant
  les outils restés absents. Chaque outil du socle vit dans son module
  `tools/bootstrap.d/NN-outil.sh` ; le point d'extension des projets
  instanciés devient l'ajout d'un module, jamais l'édition du script.
  Nouveaux scripts consentis `tools/install-git.sh` / `tools/install-git.ps1`
  pour le prérequis git (Windows compris, où `sh` n'existe qu'avec Git for
  Windows). Test mécanisé `tools/bootstrap-test.sh` câblé dans les deux CI.

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

- Modules de bootstrap **prêts à copier** (`templates/bootstrap.d/`, matériel
  post-instanciation hors traçabilité du gabarit, comme
  `templates/orchestrators/`) : kit **lint Markdown** — modules Node.js 22+
  et dépendances npm, porte `markdown.sh` (lint/fix, auto-suffisante via
  `npm ci`), formateur `format-tables.mjs` aligné sur la règle MD060 (même
  mesure `string-width`, emoji compris) et configuration `markdownlint-cli2`
  modèle. Le projet instancié copie, adapte les globs, tague vers ses
  exigences (R2) et câble la porte dans sa CI (R7).

- Cycle de vie des issues (feat~coordination-issues~1, méthode ch. 11),
  formalisé depuis le processus éprouvé sur ergonomia : règle état/attente/acte
  (req~issues-etat-attente-acte~2 — l'étiquette dit l'état, l'assignation dit
  qui est attendu, le commentaire trace l'acte et fait seul foi), trois flux
  [Spec]/[Orga]/réalisation avec avancement scindé en étapes, entraves et
  sorties et fins de vie motivées (req~issues-flux-avancement~2), triage où la
  gravité se constate et la priorité se décide — P1/P2/P3 par le « quand »,
  limite de P1 (req~issues-triage-priorites~2). Formulaires : gravité ajoutée
  à l'anomalie (GitHub et GitLab), nouveau formulaire [Orga], le formulaire
  [Spec] passe en `à-consulter`. Automatismes de forge documentés non câblés
  (R7) : à câbler à l'instanciation, testés sur leur cas d'échec.
- Arbitrage d'instanciation du cycle de vie des issues (ADR-0013,
  D-2026-08-11) : seul le socle état/attente/acte est invariant ; flux
  [Spec]/[Orga], jeu d'étiquettes, décideurs par domaine, valeurs (délais,
  limite de P1, cadences) et outillage des automatismes sont des défauts que
  l'instanciateur adopte, adapte ou réduit en le consignant au registre des
  décisions du projet. Exigences passées en révision 2, sites re-tagués.
- Arbitrage du cycle de vie outillé (amendement de l'ADR-0013, en conception
  de gabarit) : option `--cycle-issues complet|reduit` de `tools/init.sh` —
  le circuit réduit retire les formulaires de consultation [Spec]/[Orga]
  (questions ouvertes + ADR à la place), et l'arbitrage rendu, défaut
  compris, est consigné automatiquement au registre des décisions du projet
  instancié ; testé sur ses deux modes et sa valeur invalide
  (`tools/init-test.sh`). L'instanciation retire désormais aussi les tags de
  couverture des formulaires d'issues (ils pointaient vers des exigences
  supprimées et cassaient la traçabilité du projet instancié).
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
