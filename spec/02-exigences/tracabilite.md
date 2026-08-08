# Exigences — domaine traçabilité et vérification

## Traçabilité outillée de bout en bout

`req~tracabilite-outillee~1`

La chaîne besoin → exigence → conception → implémentation → test DOIT être
vérifiée par un outil indépendant du langage qui échoue (code retour non nul)
dès qu'un maillon manque : exigence sans couverture, couverture pointant un
identifiant inexistant ou une révision obsolète.

Critères d'acceptation :

- Étant donné une exigence approuvée sans implémentation taguée, quand la
  traçabilité s'exécute, alors elle échoue en nommant l'exigence orpheline.
- Étant donné un tag de couverture vers un identifiant inexistant, quand la
  traçabilité s'exécute, alors elle échoue (aucun tag fantôme possible).

Covers:
- feat~tracabilite-mecanisee~1

Needs: dsn, impl

## Porte d'intégration continue

`req~porte-ci~1`

Lorsqu'un commit est poussé ou qu'une pull request est ouverte, la CI DOIT
rejouer la traçabilité et les contrôles de cohérence, et DOIT échouer si l'un
d'eux échoue. Toute porte documentée DOIT être câblée dans la CI, ou marquée
explicitement « non câblée » avec sa raison et son échéance.

Rationale:
Contre-exemple observé sur wallos-rs : des portes déclarées dans le contrat de
gouvernance mais absentes du workflow créent une conformité illusoire.

Covers:
- feat~tracabilite-mecanisee~1

Needs: impl

## Garde-fous locaux

`req~garde-fous-locaux~1`

Le dépôt DOIT fournir des hooks git (pre-commit, commit-msg) reproduisant les
portes de la CI en local : traçabilité, contrôles de cohérence, format des
messages de commit, interdiction des mentions d'agent. Le contournement DOIT
être possible mais explicite et bruyant.

Critères d'acceptation :

- Étant donné les hooks installés, quand un commit casse la traçabilité, alors
  le commit est refusé avant d'atteindre le dépôt.
- Étant donné un message de commit non conventionnel ou portant une mention
  d'agent, quand le commit est validé, alors il est refusé avec le motif.

Covers:
- feat~tracabilite-mecanisee~1

Needs: impl

## Tests mécanisés reliés aux exigences

`req~tests-mecanises~1`

Chaque exigence testable DOIT être couverte par au moins un test automatisé
tagué avec son identifiant, au niveau approprié (unitaire, intégration,
système). Les exigences non automatisables DOIVENT être couvertes par une
procédure de vérification manuelle versionnée et taguée, jamais laissées sans
vérification déclarée.

Covers:
- feat~ingenierie-des-exigences~1
- feat~tracabilite-mecanisee~1

Needs: impl

## Exemple multi-langages

`req~exemple-multilangage~1`

Le dépôt DOIT contenir un exemple exécutant la chaîne complète (besoin,
exigences, décision, implémentations, tests tagués) dans au moins trois
langages différents, pour démontrer l'agnosticisme du dispositif et servir de
référence de mise en œuvre.

Covers:
- feat~gouvernance-agnostique~1

Needs: impl
