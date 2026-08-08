# Exigences — domaine ingénierie des exigences

## Expression du besoin formalisée

`req~expression-du-besoin~1`

Le dépôt DOIT fournir un format d'expression de besoin (artefact de type feat)
qui capture le besoin, sa justification et son porteur, et que les exigences
référencent explicitement.

Critères d'acceptation :

- Étant donné un besoin exprimé, quand une exigence le décline, alors la
  relation besoin→exigence est déclarée dans l'exigence et vérifiée par l'outil
  de traçabilité.

Covers:
- feat~ingenierie-des-exigences~1

Needs: impl

## Rédaction selon EARS

`req~format-exigence-ears~1`

Chaque exigence DOIT être rédigée selon l'un des cinq motifs EARS (ubiquitaire,
événementiel, à état, comportement indésirable, fonctionnalité optionnelle),
porter un niveau normatif DOIT/DEVRAIT/PEUT et des critères d'acceptation en
forme Étant donné / Quand / Alors.

Rationale:
EARS contraint doucement la langue naturelle et élimine l'essentiel des
ambiguïtés sans imposer un formalisme lourd ; les critères d'acceptation
préparent directement les tests mécanisés.

Covers:
- feat~ingenierie-des-exigences~1

Needs: dsn, impl

## Cycle de vie des exigences

`req~cycle-de-vie-exigence~1`

Chaque exigence DOIT porter un statut de cycle de vie (brouillon → proposée →
approuvée → implémentée → vérifiée, ou rejetée/dépréciée), et seule la révision
de l'identifiant change quand le fond de l'exigence change.

Critères d'acceptation :

- Étant donné une exigence dont le texte normatif change, quand elle est
  republiée, alors sa révision est incrémentée et les couvertures pointant
  l'ancienne révision sont signalées obsolètes par l'outil de traçabilité.

Covers:
- feat~ingenierie-des-exigences~1

Needs: impl

## Questions ouvertes en cas de blocage

`req~questions-ouvertes~1`

Lorsqu'un contributeur (humain ou agent) est bloqué par une ambiguïté du besoin
ou un conflit de règles, il DOIT ouvrir une question ouverte structurée
(contexte, options, recommandation, décision, statut) plutôt que de trancher
seul ou de contourner la règle.

Rationale:
Protocole repris de wallos-rs : c'est le mécanisme qui permet de servir
« l'intention du besoin » sans inventer — l'agent propose, l'humain arbitre, la
décision est tracée.

Covers:
- feat~ingenierie-des-exigences~1

Needs: impl
