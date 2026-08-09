# ADR-0013 — Rendre le cycle de vie des issues arbitrable à l'instanciation

**Statut** : Accepté
**Date** : 2026-08-09
**Décideur** : Éric Lemesre — consultation directe (voir D-2026-08-11, registre
des décisions)
**Portée** : durable

## Item de conception

`dsn~cycle-issues-instanciation~1`

Le cycle de vie des issues (méthode, ch. 11) se décompose en deux couches :

- un **socle invariant**, qui ne dépend ni de l'équipe, ni du rythme, ni de la
  forge : l'étiquette dit l'état, l'assignation dit qui est attendu, le
  commentaire trace l'acte et fait seul foi ; rien de nominatif dans une
  étiquette ; aucune transition ni fin de vie sans motif écrit ;
- des **défauts arbitrables à l'instanciation** : flux d'arbitrage
  `[Spec]`/`[Orga]` (adoption, adaptation ou réduction), jeu d'étiquettes,
  décideurs par domaine, valeurs (délai de consultation, limite de P1,
  cadences), outillage des automatismes de forge.

L'instanciateur adopte, adapte ou réduit les défauts et **consigne son
arbitrage au registre des décisions du projet** ; sans choix explicite, le
défaut du chapitre 11 s'applique tel quel.

Covers:
- req~issues-etat-attente-acte~2
- req~issues-flux-avancement~2
- req~issues-triage-priorites~2

## Contexte

La première rédaction du chapitre 11 gravait dans la méthode des choix qui
supposent une équipe, un rythme et une forge donnés : circuit de consultation
à plusieurs intervenants, jeu d'étiquettes complet, délais et cadences. Le
porteur relève que ces choix reviennent à l'instanciateur : un porteur solo
n'a personne à consulter, une équipe de trois en a besoin ; un dépôt sans
forge n'a ni étiquettes ni assignations. Le gabarit a déjà tranché deux cas
analogues par le même patron « défaut + arbitrage d'instanciation » :
la politique d'attribution IA (ADR-0011) et la langue du dépôt (ADR-0009).

## Décision

Distinguer explicitement les deux couches, dans les exigences comme dans le
chapitre. Le socle reste invariant parce qu'il fonde l'opposabilité des actes
— une trace signée, datée, motivée — quel que soit le contexte du projet ;
tout le reste est un défaut que l'instanciateur arbitre, l'arbitrage étant
lui-même une décision consignée. Aucune option n'est ajoutée à `tools/init.sh` :
l'arbitrage est documentaire (registre du projet), pas outillé.

## Alternatives écartées

### Tout graver dans la méthode (première rédaction)

Imposerait à un porteur solo un circuit de consultation sans consultés, et à
tout projet un jeu d'étiquettes dimensionné pour une équipe de trois — la
cause exacte des étiquettes mortes que le processus source (ergonomia, ~400
issues) documente.

### Tout rendre arbitrable, socle compris

La règle état/attente/acte est le pendant « issues » des règles R du contrat :
un projet qui l'abandonne perd l'opposabilité de ses actes de coordination.
Ce ne serait plus une adaptation du cycle de vie mais une autre méthode —
hors de ce que le gabarit promet.

### Outiller l'arbitrage dans le script d'instanciation

Les artefacts arbitrés (étiquettes, formulaires, automatismes) vivent sur la
forge, hors de portée d'un script local ; une option `init.sh` donnerait
l'illusion d'un arbitrage appliqué. À rouvrir si les instanciations montrent
un besoin récurrent (par exemple générer les commandes de création
d'étiquettes).

## Conséquences

- Ce que cela apporte : un gabarit honnête sur ce qui relève de la méthode et
  ce qui relève du contexte ; un projet instancié qui sait ce qu'il peut
  adapter sans « casser » la méthode, et où consigner ce choix.
- Ce que cela coûte : les exigences passent en révision 2 et tous les sites
  tagués sont revisités — c'est le mécanisme voulu par le cycle de vie des
  exigences (méthode, ch. 2).
- Ce que cela ferme : rien — un projet peut durcir ses propres invariants par
  ADR local.

## Vérification

- La propagation des révisions est mécanique : `tools/oft.sh trace` échoue si
  un site tagué pointe une révision périmée des exigences couvertes.
- Le chapitre 11 sépare explicitement socle et défauts ; la revue
  d'instanciation vérifie que tout écart au défaut est consigné au registre
  des décisions du projet instancié. Aucune porte mécanique côté forge —
  non câblée (R7) : la coordination vit hors du dépôt ; échéance : rouvrir si
  l'expérience d'instanciation montre des dérives répétées.

## Références

- Registre des décisions : D-2026-08-11.
- Exigences : `spec/02-exigences/coordination-issues.md` (révision 2).
- Méthode : chapitre 11 (cycle de vie des issues).
- Patron suivi : [ADR-0009](0009-langue-du-depot-arbitree-a-l-instanciation.md),
  [ADR-0011](0011-declaration-ia-obligatoire-par-defaut.md).
