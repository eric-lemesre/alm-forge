# Exigences — domaine traçabilité et vérification

**Statut : ACTIVE** — domaine acté le 2026-08-20 (D-2026-08-16). Le statut commande
le dénominateur des taux d'audit et de classification (méthode, ch. 13).

## Traçabilité outillée de bout en bout

`req~tracabilite-outillee~1`

**Statut : approuvée**

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

Needs: dsn, impl, utest

## Porte d'intégration continue

`req~porte-ci~1`

**Statut : approuvée**

Lorsqu'un commit est poussé ou qu'une pull request est ouverte, la CI DOIT
rejouer la traçabilité et les contrôles de cohérence, et DOIT échouer si l'un
d'eux échoue. Toute porte documentée DOIT être câblée dans la CI, ou marquée
explicitement « non câblée » avec sa raison et son échéance.

Rationale:
Contre-exemple observé sur wallos-rs : des portes déclarées dans le contrat de
gouvernance mais absentes du workflow créent une conformité illusoire.

Covers:
- feat~tracabilite-mecanisee~1

Needs: impl, mtest

## Garde-fous locaux

`req~garde-fous-locaux~1`

**Statut : approuvée**

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

Needs: impl, utest

## Tests mécanisés reliés aux exigences

`req~tests-mecanises~1`

**Statut : approuvée**

Chaque exigence testable DOIT être couverte par au moins un test automatisé
tagué avec son identifiant, au niveau approprié (unitaire, intégration,
système). Les exigences non automatisables DOIVENT être couvertes par une
procédure de vérification manuelle versionnée et taguée, jamais laissées sans
vérification déclarée.

Covers:
- feat~ingenierie-des-exigences~1
- feat~tracabilite-mecanisee~1

Needs: impl, mtest

## Exemple multi-langages

`req~exemple-multilangage~1`

**Statut : approuvée**

Le dépôt DOIT contenir un exemple exécutant la chaîne complète (besoin,
exigences, décision, implémentations, tests tagués) dans au moins trois
langages différents, pour démontrer l'agnosticisme du dispositif et servir de
référence de mise en œuvre.

Covers:
- feat~gouvernance-agnostique~1

Needs: impl, utest

## Périmètre de la porte constaté

`req~perimetre-constate~1`

**Statut : approuvée**

Le périmètre de vérification DOIT être déduit du changement réel — commits
depuis la base de fusion, index, arbre de travail et fichiers non suivis — et
non déclaré par le contributeur. En cas de doute — base de fusion introuvable,
empreinte vide, chemin non classé — la voie complète DOIT s'appliquer.

Rationale:
Une voie rapide choisie à la main est un contrôle qui passe toujours dès que
le jugement se trompe. La prise en compte des fichiers NON SUIVIS vient d'un
angle mort payé sur ergonomia : un nouveau script d'outillage, jamais ajouté à
l'index, échappait au classement et faisait passer un changement d'outillage
pour de la documentation.

Critères d'acceptation :

- Étant donné un changement purement documentaire, quand le périmètre est
  constaté, alors la voie rapide s'applique.
- Étant donné un fichier d'outillage non suivi, quand le périmètre est
  constaté, alors la voie complète s'applique.
- Étant donné une empreinte vide ou l'absence de base de fusion, quand le
  périmètre est constaté, alors la voie complète s'applique.

Covers:
- feat~tracabilite-mecanisee~1

Needs: dsn, impl, utest

## Anti-dérive des artefacts générés

`req~anti-derive-generes~1`

**Statut : approuvée**

Tout artefact généré DOIT être régénéré puis comparé à sa version versionnée
par une porte, et cette porte DOIT vérifier au préalable que l'artefact est
suivi par le gestionnaire de versions.

Rationale:
Sans le contrôle de suivi, la porte est un no-op : un généré non versionné ne
produit aucune différence, la comparaison passe toujours, et la règle R8
n'est vérifiée par rien. C'est l'anti-pattern « contrôle no-op » du chapitre 4,
constaté sur ergonomia avant d'être refermé par ce double contrôle.

Critères d'acceptation :

- Étant donné un artefact généré modifié à la main, quand la porte s'exécute,
  alors elle échoue en indiquant la commande de régénération.
- Étant donné un artefact généré non suivi par git, quand la porte s'exécute,
  alors elle échoue.
- Étant donné un générateur en erreur, quand la porte s'exécute, alors elle
  échoue.

Covers:
- feat~tracabilite-mecanisee~1

Needs: impl, utest

## Classification des exigences

`req~classification-exigences~1`

**Statut : approuvée**

Toute exigence DOIT porter un niveau normatif explicite dans son énoncé, et
toute exigence de niveau le plus contraignant DOIT déclarer un niveau de
vérification — mécanisé ou manuel assumé. Le niveau normatif DOIT être lu dans
le seul énoncé, à l'exclusion du rationale et des critères d'acceptation.

Rationale:
La traçabilité vérifie qu'un « Needs » déclaré est satisfait ; elle ne vérifie
jamais que ce « Needs » est à la hauteur de l'exigence. Une exigence qui dit
DOIT sans déclarer aucune vérification passe donc en silence — la plus
contraignante du dépôt peut n'être prouvée par rien. L'exclusion du rationale
répond au piège du niveau EMPRUNTÉ constaté sur ergonomia : un « DOIT » cité
dans une justification faisait classer en DOIT une exigence rédigée en
DEVRAIT.

Critères d'acceptation :

- Étant donné une exigence dont l'énoncé ne porte aucun niveau normatif, quand
  la porte s'exécute, alors elle échoue.
- Étant donné une exigence de niveau DOIT sans niveau de test déclaré, quand
  la porte s'exécute, alors elle échoue.
- Étant donné une exigence dont seul le rationale contient un niveau
  normatif, quand la porte s'exécute, alors elle échoue sans la classer au
  niveau emprunté.

Covers:
- feat~tracabilite-mecanisee~1

Needs: impl, utest

## Audit de réalisation

`req~audit-de-realisation~1`

**Statut : approuvée**

Le dépôt DOIT porter un audit de réalisation distinct de la traçabilité, où
chaque exigence d'un domaine actif reçoit un verdict écrit à la main —
conforme, écart, ou non examinée — assorti de sa preuve. La comptabilité de
cet audit DOIT être générée, et le nombre d'exigences non examinées DOIT
rester sous un plafond déclaré.

Rationale:
La traçabilité répond à « cette exigence a-t-elle du code et un test ? », une
question de présence qui se calcule. L'audit répond à « le livré fait-il ce
que l'exigence dit ? », une question de vérité qui se lit : un tag de
complaisance passe la première et échoue au second. Le partage du travail est
celui de la matrice — le générateur compte, l'humain juge — et le plafond
empêche la dette de s'installer sans être vue.

Critères d'acceptation :

- Étant donné une exigence sans ligne d'audit, quand la porte s'exécute,
  alors elle la compte comme non examinée et échoue si le plafond est
  dépassé.
- Étant donné un verdict hors du vocabulaire, quand la porte s'exécute, alors
  elle échoue.
- Étant donné une ligne d'audit visant une exigence supprimée, quand la porte
  s'exécute, alors elle échoue.

Covers:
- feat~tracabilite-mecanisee~1

Needs: dsn, impl, utest
