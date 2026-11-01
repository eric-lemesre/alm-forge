# ADR-0021 — Tolérer la conception avant la réalisation dans la traçabilité des items approuvés

**Statut** : Accepté
**Date** : 2026-11-01
**Décideur** : Éric Lemesre — seul, sur constat remonté d'un projet instancié (voir D-2026-11-02, registre des décisions)
**Portée** : durable — condition de réouverture : abandon du projet OpenFastTrace, ou changement du format de sortie qu'il rend à la vérification
**Remplace** : [ADR-0020](0020-tracer-les-seuls-items-approuves.md)

## Item de conception

`dsn~moteur-tracabilite~3`

La traçabilité besoin → exigence → conception → implémentation → test est
vérifiée par OpenFastTrace (jar autonome, épinglé en version et en empreinte
SHA-256 dans `tools/oft.sh`), sur les **seuls items approuvés** (option
`-w approved`). Un item non arbitré porte son statut OpenFastTrace sur la
ligne qui suit son identifiant ; `tools/statuts.sh` exige que ce statut
concorde avec le statut déclaré de l'exigence. Une exigence ou un item de
conception approuvés dont la **réalisation n'a pas commencé** — aucun type
de réalisation couvert (`impl`, `utest`, `itest`, `stest`, `mtest`), la
conception pouvant l'être — sont **à réaliser** : la porte les tolère et les
liste ; dès le premier tag de code ou de test, la couverture complète est
exigée.

Covers:
- req~tracabilite-outillee~3
- req~statut-trace-concordant~1

## Contexte

L'ADR-0020 a limité la trace aux items approuvés et toléré l'exigence
approuvée « sans aucun maillon aval (ni tag, ni item qui la couvre) ». À
l'adoption par un projet instancié, l'enchaînement normal d'une méthode
qui décide avant de coder s'est révélé bloqué : une exigence approuvée
couverte par l'item de conception d'un ADR, mais pas encore codée, a un
maillon entrant et sort de la tolérance ; l'item de conception, qui attend
son implémentation (`Needs: impl`), fait lui aussi échouer la porte. Le
projet n'a pu passer qu'en laissant en proposition des exigences pourtant
relues, ce que l'ADR-0020 voulait précisément éviter.

Vérifié sur OpenFastTrace 4.9.0 : le résumé d'un défaut liste entre
parenthèses tous les types requis, préfixés de « - » quand ils manquent —
`req~a~1 (dsn, -impl, -utest)` pour une exigence conçue et non codée,
`dsn~d~1 (-impl)` pour sa conception.

## Décision

L'ADR-0020 est repris tel quel — moteur OpenFastTrace aux conditions de
l'ADR-0002, filtre `approved`, statut collé sous l'identifiant et
concordance vérifiée, on ne réalise que l'approuvé, item de conception au
même `Status:` que les exigences proposées qu'il motive — à une règle
près, celle de la tolérance :

- **À réaliser** : une exigence (`req`) ou un item de conception (`dsn`)
  approuvés sont tolérés et listés quand aucun type de réalisation n'est
  couvert, que leurs maillons entrants sont tous sains, que leur lien amont
  est sain, et que leur seul défaut est l'absence de types requis. La
  conception (`dsn`) couverte ne compte pas comme réalisation.
- **Réalisation commencée** : au premier tag de code ou de test (y compris
  un test posé avant le code), la couverture complète est exigée.
- **Toujours bloquant** : couverture partielle d'une réalisation commencée,
  lien rompu, tag orphelin, révision périmée, besoin approuvé sans exigence
  approuvée.

## Alternatives écartées

Celles de l'ADR-0020 restent écartées pour les mêmes motifs. S'y ajoutent :

### Laisser en proposition les exigences conçues et non codées

C'est le contournement constaté : « proposée » ne dit plus que le porteur
n'a pas tranché, mais que le code manque — l'approbation se confond de
nouveau avec la réalisation.

### Ne pas déclarer `dsn` dans le `Needs:` de l'exigence, ni `impl` dans celui de l'item de conception

La porte passerait, mais l'exigence ne dirait plus qu'elle attend une
décision, ni la décision qu'elle attend son code : un `Needs:` tronqué, que
l'ADR-0020 a justement retiré.

### Tolérer aussi un test posé avant le code

Le test d'abord est une pratique saine, mais un test sans code est une
réalisation commencée et incomplète ; la tolérer rendrait la porte muette
sur un code oublié. On commite le test avec son code.

## Conséquences

- Ce que cela apporte : une exigence se conçoit (ADR) et s'approuve avant
  d'être codée, sans bloquer les commits ; la liste « à réaliser » comprend
  les décisions en attente de leur code.
- Ce que cela coûte : la porte interprète la liste des types du résumé
  OpenFastTrace 4.9.0 ; une montée de version doit être revérifiée par
  `tools/oft-test.sh`.
- Ce que cela ferme : le dépôt d'un test sans son code dans le même commit
  que rien d'autre.

## Vérification

- `tools/oft-test.sh` (dans `sh tools/ci.sh`) : une exigence conçue et non
  codée, et son item de conception, passent et sont listés ; un test sans
  code, un code sans test font échouer la porte ; la chaîne complète passe ;
  les cas de l'ADR-0020 (brouillons, couverture partielle, lien amont rompu,
  item écarté couvert, besoin sans exigence approuvée) restent joués. Les
  nouveaux cas échouent contre la porte de l'ADR-0020.
- `tools/statuts-test.sh` et `tools/socle-test.sh`, inchangés.

## Références

- ADR-0020, qu'il remplace ; ADR-0002 et ADR-0018.
- `req~tracabilite-outillee~3` (spec/02-exigences/tracabilite.md),
  `req~statut-trace-concordant~1` (spec/02-exigences/ingenierie-exigences.md).
- Méthode, ch. 2 (cycle de vie).
