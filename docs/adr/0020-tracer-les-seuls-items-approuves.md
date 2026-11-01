# ADR-0020 — Tracer avec OpenFastTrace les seuls items approuvés, et tolérer l'exigence approuvée à réaliser

**Statut** : Accepté
**Date** : 2026-11-01
**Décideur** : Éric Lemesre — seul : option retenue en séance le 2026-10-10 (tolérance des exigences à réaliser), reprise sur la branche principale à sa demande le 2026-11-01 (voir D-2026-11-01, registre des décisions)
**Portée** : durable — condition de réouverture : abandon du projet OpenFastTrace, ou changement du format de sortie qu'il rend à la vérification
**Remplace** : [ADR-0002](0002-tracer-les-exigences-avec-openfasttrace.md)

## Item de conception

`dsn~moteur-tracabilite~2`

La traçabilité besoin → exigence → conception → implémentation → test est
vérifiée par OpenFastTrace (jar autonome, épinglé en version et en empreinte
SHA-256 dans `tools/oft.sh`), sur les **seuls items approuvés** (option
`-w approved`). Un item non arbitré porte son statut OpenFastTrace sur la
ligne qui suit son identifiant ; `tools/statuts.sh` exige que ce statut
concorde avec le statut déclaré de l'exigence. Une exigence approuvée sans
aucun maillon aval est **à réaliser** : la porte la tolère et la liste ; dès
le premier maillon, la couverture complète est exigée.

Covers:
- req~tracabilite-outillee~2
- req~statut-trace-concordant~1

## Contexte

L'ADR-0002 a retenu OpenFastTrace, appelé sans filtre de statut. La méthode
(ch. 2) prévoit pourtant qu'une exigence non arbitrée sorte du dénominateur :
sans filtre, toute exigence rédigée et non réalisée faisait échouer le hook
pre-commit et la CI, si bien qu'une spécification n'entrait au dépôt qu'avec
son code. Les projets instanciés contournaient en ne déclarant, sur une
exigence non réalisée, que la couverture déjà présente — un `Needs:`
tronqué qui ne dit plus ce que l'exigence attend.

Trois constats, sur des projets instanciés puis vérifiés sur OpenFastTrace
4.9.0 :

- l'outil ne lit `Status:` que sur la ligne qui suit immédiatement
  l'identifiant ; placé ailleurs, le mot-clé est du texte et l'item reste
  « approved » ;
- filtrer sur `approved` seul fait échouer une exigence approuvée et relue
  mais pas encore réalisée : approuver un lot d'exigences relues bloquait
  tout commit jusqu'à la fin du développement ;
- un item retenu qui couvre un item écarté (tag de code, item de conception
  d'un ADR) a un lien sortant rompu et fait échouer la porte.

L'ADR-0018 distingue déjà l'approbation (déclarée) de l'avancement
(calculé depuis les tags) : c'est la porte qui confondait les deux.

## Décision

- **Moteur** : OpenFastTrace reste le moteur unique, aux conditions de
  l'ADR-0002 (jar épinglé en version et en empreinte, même commande en local
  et en CI, tags dans les fichiers à extension reconnue). Les alternatives
  qu'il écarte restent écartées pour les mêmes motifs.
- **Filtre** : `tools/oft.sh` ne trace que les items au statut
  OpenFastTrace `approved`, statut par défaut d'un item qui n'en déclare pas.
- **Statut collé** : un besoin ou une exigence non approuvés portent
  `Status: draft` (brouillon), `proposed` (proposée) ou `rejected` (rejetée,
  dépréciée) **sur la ligne qui suit l'identifiant** ; une exigence
  approuvée n'en porte pas. `tools/statuts.sh` (invariant 7) refuse toute
  discordance.
- **À réaliser** : une exigence approuvée sans aucun maillon aval (ni tag,
  ni item qui la couvre), au lien amont sain, et dont le seul défaut est
  l'absence des types requis, est tolérée et listée. Dès le premier maillon
  aval, la couverture complète est exigée. Tout autre défaut reste
  bloquant : couverture partielle, lien amont rompu, tag orphelin, révision
  périmée, besoin approuvé sans exigence approuvée.
- **Ce qui couvre un item écarté** : un tag de code ne couvre qu'une
  exigence approuvée — on réalise ce qui est arbitré. Un item de conception
  qui motive des exigences encore en proposition porte le même `Status:`
  qu'elles, et le perd avec elles à leur approbation.
- **Avancement** : il reste calculé par `tools/statuts.sh` et le tableau
  d'audit ; une exigence à réaliser y reste visible.

## Alternatives écartées

### Ne versionner une exigence qu'avec son implémentation

Porte inchangée, mais la spécification reste hors du dépôt pendant sa
rédaction et son arbitrage : elle échappe à la revue et à l'historique que
la méthode organise sur le dépôt.

### Tronquer le `Needs:` des exigences non réalisées

C'est le contournement constaté : la porte passe, mais l'exigence ne dit
plus ce qu'elle attend, et rien ne rappelle de compléter le `Needs:` quand
le code arrive.

### Approuver au fil du code

Aucun outil à changer, mais « approuvée » ne dit plus que le porteur a relu
et validé l'exigence : l'approbation se confond avec la réalisation.

### Marquer à la main les exigences à réaliser

Une étiquette déclarée se périme sans rien signaler dès que le code arrive ;
l'état « à réaliser » se déduit des maillons réellement présents.

### Filtrer sans contrôle de concordance

Une exigence déclarée approuvée mais marquée `Status: draft` sortirait de la
traçabilité sans que rien ne le signale.

## Conséquences

- Ce que cela apporte : une spécification versionnée dès sa rédaction, avec
  son `Needs:` complet ; une exigence s'approuve dès sa relecture ; la porte
  reste sévère pour toute réalisation commencée.
- Ce que cela coûte : une ligne `Status:` par item non approuvé, à retirer à
  l'approbation ; la porte lit la sortie texte d'OpenFastTrace 4.9.0, qu'une
  montée de version doit revérifier par `tools/oft-test.sh`.
- Ce que cela ferme : tout autre usage du mot-clé `Status:` ; toute
  tolérance d'une couverture partielle ; la réalisation d'une exigence non
  approuvée.
- Pour un projet instancié qui adopte la révision : retirer le `Needs:`
  tronqué au profit du `Needs:` complet et d'un `Status:` collé, et porter
  le même `Status:` sur les items de conception qui couvrent ses exigences
  en proposition.

## Vérification

- `tools/oft-test.sh` (dans `sh tools/ci.sh`) : des items en brouillon non
  réalisés passent ; une exigence approuvée sans maillon aval passe et est
  listée ; une couverture partielle, un lien amont rompu, un besoin approuvé
  couvert par un seul brouillon, un tag de code ou un item de conception
  approuvé couvrant une exigence proposée font échouer la porte ; un item de
  conception au même `Status:` que l'exigence proposée qu'il couvre passe.
- `tools/statuts-test.sh` (dans `sh tools/ci.sh`) : chaque discordance de
  statut, et un `Status:` séparé de l'identifiant, font échouer la porte.
- `tools/socle-test.sh` : une exigence réalisée sans son test fait échouer
  la traçabilité ; posé, le test la ramène au vert.

## Références

- ADR-0002 (moteur de traçabilité), qu'il remplace ; ADR-0018 (statut porté
  par l'exigence).
- `req~tracabilite-outillee~2` (spec/02-exigences/tracabilite.md),
  `req~statut-trace-concordant~1` (spec/02-exigences/ingenierie-exigences.md).
- Méthode, ch. 2 (cycle de vie) et ch. 4 (traçabilité).
- OpenFastTrace 4.9.0 : options `--wanted-statuses`, verbosité
  `direct_failure_summaries`.
