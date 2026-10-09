# ADR-0020 — Tracer les seuls items approuvés

**Statut** : Accepté
**Date** : 2026-10-09
**Décideur** : Éric Lemesre — seul (arbitrage remonté du projet instancié LeadSage, OQ-013)
**Portée** : durable

## Item de conception

`dsn~statut-trace-concordant~1`

La porte de traçabilité appelle OpenFastTrace avec `-w approved` ; la porte
des statuts exige que le `Status:` collé sous l'identifiant d'une exigence
concorde avec son statut déclaré.

Covers:

- req~statut-trace-concordant~1

## Contexte

La méthode (ch. 2, 6 et 11) prévoit qu'une exigence non arbitrée, marquée
`Status: draft`, sorte du dénominateur de couverture. Mais `tools/oft.sh`
appelait OpenFastTrace sans filtre de statut : toute exigence rédigée et non
encore réalisée faisait échouer le hook pre-commit et la CI, si bien qu'une
spécification ne pouvait être versionnée qu'avec son code.

Constaté en outre le 2026-10-09 sur le projet instancié LeadSage : OpenFastTrace ne lit `Status:` que sur la
ligne qui suit immédiatement l'identifiant ; placé ailleurs, le mot-clé est
pris pour du texte et l'item reste « approved ».

## Décision

- `tools/oft.sh` ne trace que les items au statut OpenFastTrace `approved`
  (option `-w approved`), statut par défaut d'un item qui n'en déclare pas.
- Un besoin ou une exigence non arbitrés portent `Status: draft` (ou
  `proposed`, `rejected`) **sur la ligne qui suit l'identifiant**. Une
  exigence approuvée n'en porte pas.
- Concordance obligatoire, vérifiée par `tools/statuts.sh` (invariant 7) :
  brouillon ↔ `draft`, proposée ↔ `proposed`, rejetée et dépréciée ↔
  `rejected`, approuvée ↔ aucun `Status:`.
- Les modèles de besoin et d'exigence portent la ligne `Status: draft`.

## Alternatives écartées

### Ne versionner une exigence qu'avec son implémentation

Porte inchangée, mais la spécification reste hors du dépôt pendant toute sa
rédaction et son arbitrage : elle échappe à la revue, à l'historique et à la
consultation que la méthode organise justement sur le dépôt.

### Contourner le hook pendant la réalisation

`git commit --no-verify` rend la porte facultative : contraire à R3 et R7.

### Filtrer sans contrôle de concordance

Une exigence déclarée approuvée mais marquée `Status: draft` sortirait de la
traçabilité sans que rien ne le signale.

## Conséquences

- Ce que cela apporte : spécification versionnée dès sa rédaction ; porte
  inchangée en sévérité pour tout ce qui est approuvé.
- Ce que cela coûte : une ligne de plus par item non approuvé, à retirer à
  l'approbation ; un besoin laissé en `draft` sort de la porte — la revue
  d'approbation doit le lever en même temps que ses exigences.
- Ce que cela ferme : tout autre usage du mot-clé `Status:` d'OpenFastTrace.

## Vérification

- `tools/oft-test.sh` (dans `sh tools/ci.sh`) : des items en brouillon non
  réalisés passent ; une exigence approuvée non réalisée et un besoin approuvé
  couvert seulement par un brouillon font échouer la porte.
- `tools/statuts-test.sh` (dans `sh tools/ci.sh`) : chaque discordance de
  statut, et un `Status:` séparé de l'identifiant, font échouer la porte.
  Les deux tests échouent contre les versions antérieures des portes.

## Références

- `req~statut-trace-concordant~1` (spec/02-exigences/ingenierie-exigences.md).
- ADR-0018 (statut de cycle de vie porté par l'exigence).
- Projet LeadSage, OQ-013.
- docs/methode/02-exigences.md, cycle de vie.
- OpenFastTrace 4.9.0, option `--wanted-statuses`.
