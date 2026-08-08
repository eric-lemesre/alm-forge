# Exigences — domaine décisions

Rédigées selon la syntaxe EARS (voir [méthode, ch. 2](../../docs/methode/02-exigences.md)).
Niveaux normatifs : DOIT / DEVRAIT / PEUT.

## Registre des décisions d'architecture

`req~registre-adr~1`

Le dépôt DOIT fournir un registre d'ADR : un répertoire dédié, une charte
(cycle de vie, numérotation continue, immuabilité des ADR acceptés) et un
modèle prêt à remplir.

Critères d'acceptation :

- Étant donné le gabarit instancié, quand un contributeur doit acter une
  décision, alors il trouve un modèle d'ADR et la procédure dans le registre.
- Étant donné un ADR accepté, quand la décision évolue, alors un nouvel ADR le
  remplace et l'ancien reçoit le statut « Remplacé », sans réécriture.

Covers:
- feat~cadre-de-decision~1

Needs: dsn, impl

## Section Vérification obligatoire

`req~adr-verification~1`

Lorsqu'un ADR passe au statut « Accepté », le dépôt DOIT vérifier mécaniquement
qu'il comporte une section « Vérification » décrivant comment on sait que la
décision est tenue.

Rationale:
Reprise du principe d'ergonomia : une décision qu'aucun mécanisme ne protège
dérivera. Le contrôle est outillé pour ne pas dépendre de la vigilance du
relecteur.

Critères d'acceptation :

- Étant donné un ADR au statut « Accepté » sans section « Vérification », quand
  les portes qualité s'exécutent, alors elles échouent en désignant le fichier.

Covers:
- feat~cadre-de-decision~1

Needs: impl
