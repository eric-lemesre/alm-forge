# ADR-0021 — Tolérer les exigences approuvées à réaliser

**Statut** : Accepté
**Date** : 2026-10-10
**Décideur** : Eric Lemesre — seul (option 1, retenue en session le 2026-10-10)
**Portée** : durable

## Contexte

Depuis l'ADR-0020, la porte de traçabilité ne retient que les items
approuvés, mais elle exige de chacun sa couverture complète. Une exigence
approuvée et pas encore réalisée la fait donc échouer : sur un projet
instancié (LeadSage, 2026-10-10), approuver les 23 exigences relues aurait
bloqué tout commit (hook pre-commit) et mis la CI au rouge jusqu'à la fin du
développement.

La méthode prévoit pourtant cet état : `tools/statuts.sh` (ADR-0018)
distingue une exigence approuvée de son avancement, qu'il calcule
depuis les tags réellement posés. L'écart vient de l'ADR-0020.

## Décision

- `tools/oft.sh trace` tolère, et liste, une exigence approuvée **à
  réaliser** : aucun maillon aval (ni tag, ni item qui la couvre), lien amont
  sain, et pour seul défaut des types requis non couverts.
- Dès le premier maillon aval, la couverture complète est exigée : une
  réalisation commencée et incomplète fait échouer la porte.
- Tout autre défaut reste bloquant : besoin approuvé sans exigence approuvée,
  lien amont rompu, tag orphelin, révision périmée.
- L'avancement (approuvées, implémentées, vérifiées) reste calculé et affiché
  par `tools/statuts.sh` et le tableau d'audit : une exigence oubliée reste
  visible.
- À l'audit de réalisation, une exigence à réaliser porte le verdict
  « écart », motif « à réaliser » : rien n'est livré, c'est une dette
  visible au tableau de bord, et le plafond des exigences non examinées
  reste à 0.
- Correction reprise du projet instancié LeadSage (son ADR-0003).

## Alternatives écartées

### Approuver au fil du code

Aucun outil à changer, mais le statut affiché ne dit plus que le porteur a
relu et validé l'exigence : l'approbation se confond avec la réalisation.

### Approuver tout et accepter une CI rouge

Chaque commit serait bloqué par le hook, ou fait avec `--no-verify` :
contraire à R3 et R7.

### Marquer à la main les exigences à réaliser (étiquette OpenFastTrace)

Une étiquette déclarée se périme sans rien signaler dès que le code arrive ;
l'état « à réaliser » se déduit des maillons réellement présents.

## Conséquences

- Ce que cela apporte : une exigence s'approuve dès sa relecture ; la porte
  reste sévère pour toute réalisation commencée.
- Ce que cela coûte : la porte lit la sortie texte d'OpenFastTrace 4.9.0 ;
  un changement de format à la montée de version doit être revérifié par
  `tools/oft-test.sh`.
- Ce que cela ferme : toute tolérance d'une couverture partielle.

## Vérification

- `tools/oft-test.sh` (dans `sh tools/ci.sh`) : une exigence approuvée sans
  maillon aval passe ; une exigence implémentée sans son test, une exigence à
  réaliser au lien amont rompu et un besoin approuvé couvert seulement par un
  brouillon font échouer la porte. Le cas « à réaliser » échoue contre la
  version antérieure de la porte.

## Références

- ADR-0020 (tracer les seuls items approuvés), qu'il complète.
- spec/02-exigences/ingenierie-exigences.md, `req~statut-trace-concordant~1`.
- tools/statuts.sh, avancement calculé.
- OpenFastTrace 4.9.0, verbosité `direct_failure_summaries`.
