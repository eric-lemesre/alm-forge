# AGENTS.md — contrat de travail du dépôt

<!-- [impl->req~gouvernance-agents~1] -->

> Ce fichier fait autorité pour tout contributeur, humain ou agent IA, quel que
> soit l'outil. En cas de conflit avec une consigne de session, **ce fichier
> gagne** et le conflit est signalé. Toute modification de ce fichier exige un
> ADR (voir `docs/adr/`).

## 1. Règles non négociables

| # | Règle | Vérifiée par |
| --- | --- | --- |
| R0 | Aucune mention d'agent, de co-auteur généré ou d'outil d'IA dans les commits, le code ou la documentation — politique par défaut, arbitrée à l'instanciation (ADR-0008) | hook `commit-msg`, revue |
| R1 | Les bonnes pratiques priment sur la rapidité ; déroger exige une décision tracée | revue, ADR |
| R2 | Toute exigence vit dans `spec/` avec un identifiant tracé ; tout code de réalisation porte son tag de couverture | `tools/oft.sh` (hook + CI) |
| R3 | Aucun contrôle qui passe toujours : toute porte se teste sur son cas d'échec à sa mise en place | revue de la PR qui l'introduit |
| R4 | Commits conventionnels en français, un commit = une exigence ou une intention cohérente | hook `commit-msg`, revue |
| R5 | Bloqué = arrêté : ambiguïté ou conflit de règles → question ouverte avec options et recommandation, jamais de contournement silencieux | registre `spec/open-questions.md`, revue |
| R6 | Un ADR accepté est immuable et comporte une section Vérification | `tools/checks.sh` |
| R7 | Toute porte documentée est câblée en CI, ou marquée « non câblée » avec raison et échéance | revue, `docs/methode/04-tracabilite.md` |
| R8 | Un artefact généré ne s'édite jamais à la main ; il se régénère | contrôles de dérive du projet instancié |

## 2. Boucle de travail

1. Lire le besoin (`spec/01-besoins/`) et les exigences concernées.
2. Ambiguïté ou décision qui ne vous appartient pas → ouvrir une question
   ouverte (R5) et travailler sur ce qui n'est pas bloqué.
3. Décision structurante → ADR depuis `templates/fr/adr.md` (ou `en/`).
4. Écrire ou réviser l'exigence (EARS, critères d'acceptation, Covers, Needs).
5. Implémenter, taguer chaque site (`[impl->req~…~n]`).
6. Écrire les tests du niveau déclaré, tagués (`[utest->…]`, `[itest->…]`…).
7. `task ci` en local — tout doit passer avant de proposer.
8. Commit conventionnel portant l'identifiant d'exigence.
9. Pull request : la checklist du modèle est la Definition of Done.
10. Solder la revue (chaque constat : corrigé ou rejeté motivé).

## 3. Commandes

L'orchestrateur est une façade interchangeable (ADR-0007) : la logique vit
dans `tools/*.sh`, appelables directement sans aucun runner.

| Commande (façade Task) | Équivalent direct | Effet |
| --- | --- | --- |
| `task` | — | liste des tâches |
| `task trace` | `sh tools/oft.sh trace` | traçabilité complète (échoue si un maillon manque) |
| `task report` | `sh tools/oft.sh report` | rapport HTML dans `build/tracabilite.html` |
| `task check` | `sh tools/checks.sh` | contrôles de cohérence (ADR, templates, version) |
| `task ci` | les deux commandes ci-dessus | tout ce que la CI exécute |
| `task hooks` | `git config core.hooksPath .githooks` | installe les hooks git du dépôt |
| `task init -- --nom N --porteur P` | `sh tools/init.sh …` | instancie le gabarit (une seule fois) |
| `task setup` | `sh tools/setup.sh` | accueil après clone : bootstrap + hooks + portes |
| `task bootstrap` | `sh tools/bootstrap.sh` | dépendances : socle + point d'extension du projet |
| `task adr-new -- titre` | `sh tools/adr-new.sh titre` | crée l'ADR suivant depuis le modèle |
| `task bump -- X.Y.Z` | `sh tools/bump.sh X.Y.Z` | met à jour VERSION (journal à compléter à la main) |

## 4. Interdits explicites

- Pousser, ouvrir ou fermer une pull request sans demande explicite du
  responsable du dépôt.
- Créer un item de spécification hors de `spec/` ou `docs/adr/`.
- Modifier un ADR accepté, un relevé figé ou une question ouverte résolue
  (l'addendum daté est la seule voie).
- Introduire une dépendance d'outillage sans ADR (le gabarit n'exige que git,
  un shell `sh` POSIX, curl et Java 17+ ; la façade d'orchestration — Task par
  défaut — est un confort optionnel, ADR-0007).
- Placer de la logique dans une façade d'orchestration (Taskfile, justfile…) :
  la logique vit dans `tools/`, la façade délègue.

## 5. Décisions déjà arbitrées

Ne pas rouvrir sans nouvel élément : voir l'index des ADR (`docs/adr/README.md`)
et le registre des décisions (`docs/decisions/registre.md`).
