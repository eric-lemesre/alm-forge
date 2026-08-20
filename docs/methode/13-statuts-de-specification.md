# 13. Statuts de spécification

<!-- [impl->req~statut-specification~1] -->

Un statut de domaine n'est pas une décoration : c'est un **commutateur**. Il
décide si les exigences du domaine entrent au dénominateur des taux d'audit
(ch. 14) et de classification (ch. 2).

## Les trois statuts

| Statut | Ce qu'il dit | Effet sur les taux |
| --- | --- | --- |
| `PROPOSITION` | rédigé, pas encore arbitré | exigences **hors** dénominateur |
| `ACTIVE` | acté, opposable | exigences **au** dénominateur |
| `OBSOLÈTE` | remplacé ou abandonné | exigences hors dénominateur, fichier conservé |

Le vocabulaire vient du lexique (ADR-0015) : un dépôt anglophone lit
`PROPOSED`, `ACTIVE`, `OBSOLETE`.

## Où le statut se déclare

En tête du fichier de domaine, et dans l'index
[`spec/02-exigences/README.md`](../../spec/02-exigences/README.md) :

```markdown
**Statut : ACTIVE** — domaine acté le AAAA-MM-JJ (D-AAAA-MM-NN).
```

Les deux doivent dire la même chose. `tools/statuts.sh` refuse la divergence,
et c'est le contrôle qui compte le plus : l'index est ce qu'on lit, l'en-tête
est ce qui fait foi, et personne ne remarque qu'ils se contredisent.

## Passer un domaine en ACTIVE exige une décision

Un domaine `ACTIVE` doit être adossé à une entrée du registre des décisions
(ch. 3). Sans cette règle, un domaine passe `ACTIVE` d'un trait de plume :
la couverture affichée grimpe, sans que personne n'ait rien validé.

C'est la raison d'être du contrôle. Un statut qui ment ne se manifeste par
aucune erreur — il fausse un chiffre, et un chiffre faux inspire plus
confiance qu'une absence de chiffre.

## Cycle de vie

1. Rédaction → `PROPOSITION`. Les exigences existent, elles sont tracées, mais
   elles ne comptent pas encore : le taux d'audit ne récompense ni ne punit un
   domaine qu'on est en train d'écrire.
2. Consultation puis arbitrage (ch. 11, flux `[Spec]`) → décision consignée
   au registre → `ACTIVE`.
3. Remplacement → `OBSOLÈTE`, avec un renvoi vers le domaine qui prend la
   suite. On ne supprime pas : les décisions passées restent lisibles.

Un domaine `PROPOSITION` qui dort depuis longtemps est un signal — soit
l'arbitrage est bloqué et relève d'une question ouverte (ch. 6), soit le
domaine n'intéresse personne et devrait être `OBSOLÈTE`.
