# Exigences — domaine coordination par les issues

## L'état, l'attente, l'acte

`req~issues-etat-attente-acte~1`

Sur une issue, les trois artefacts de coordination DOIVENT garder des rôles
distincts et jamais échangés : l'étiquette porte l'**état** (où en est
l'issue), l'assignation porte l'**attente** (de qui le prochain geste dépend),
le commentaire signé et daté porte l'**acte** (constat, lecture, validation,
décision) et fait seul foi. Aucune étiquette ne DOIT porter d'information
nominative, toute transition d'état DOIT être motivée par un commentaire, et
un automatisme ne DOIT que dériver l'état depuis un acte écrit — jamais
attester à la place de quelqu'un.

Rationale:
Une étiquette ne porte ni date, ni version, ni auteur : ce qu'elle affirme ne
se prouve pas. Leçon d'ergonomia : les étiquettes nominatives « Validé par … »
ont dû être remplacées par des commentaires de validation, seuls artefacts
signés, datés et citant la version.

Critères d'acceptation :

- Étant donné une validation de recette, quand elle est consignée, alors
  c'est un commentaire citant la version testée — jamais une étiquette
  nominative ni une case cochée seule.
- Étant donné une issue dont l'étiquette d'étape change, quand aucun
  commentaire ne motive la transition, alors la revue le signale comme défaut.
- Étant donné un automatisme de forge, quand il agit sur une issue, alors il
  pose ou retire étiquettes et assignations à partir d'un commentaire
  existant, sans jamais produire l'acte lui-même.

Covers:
- feat~coordination-issues~1

Needs: impl

## Trois flux, une taxonomie d'avancement

`req~issues-flux-avancement~1`

Le cycle de vie des issues DOIT distinguer trois flux — arbitrage d'une
spécification (`[Spec]`), arbitrage d'un document d'organisation (`[Orga]`),
réalisation d'une demande ou d'une anomalie (`[Feature]`/`[Bug]`) — partageant
une même taxonomie d'avancement scindée en **étapes** (une seule à la fois),
**entraves** (cumulables) et **sorties** (une seule, terminale). Toute fin de
vie autre que la livraison recettée DOIT être fermée « non planifiée » avec
son motif en commentaire, et une demande ventilée en exigences DOIT recevoir
l'étape correspondante au lieu de rester indéfiniment en discussion.

Rationale:
Mélanger étapes et entraves rend la règle « un seul état à la fois »
intenable ; ne pas distinguer les fins de vie (refus, doublon, abandon,
non-reproduction) oblige à relire chaque issue fermée pour savoir pourquoi.

Critères d'acceptation :

- Étant donné une issue ouverte, quand on lit ses étiquettes, alors elle
  porte au plus une étape, autant d'entraves que la réalité en impose, et
  aucune sortie.
- Étant donné une demande ventilée en exigences dans `spec/`, quand la
  ventilation est faite, alors l'issue quitte l'étape de discussion et un
  commentaire liste les identifiants créés.
- Étant donné une anomalie non reproduite, quand elle est fermée, alors la
  fermeture est « non planifiée » et le commentaire dit ce qui a été essayé
  et avec quelle version.
- Étant donné une régression, quand son correctif est recetté, alors un test
  de non-régression l'accompagne.

Covers:
- feat~coordination-issues~1

Needs: impl

## La gravité se constate, la priorité se décide

`req~issues-triage-priorites~1`

La gravité d'une anomalie DOIT être constatée par le déclarant dans le
formulaire (critique, gênant, mineur) ; la priorité DOIT être décidée au
triage, jamais demandée à la création, sur une échelle temporelle (P1 : avant
tout le reste ; P2 : ce jalon ou le suivant ; P3 : un jour) et bornée par une
limite d'issues en P1. Quand la limite est atteinte, poser un nouveau P1 DOIT
faire redescendre une autre issue, motif en commentaire.

Rationale:
Une priorité définie par le domaine (« sécurité, réglementaire ») finit par
tout qualifier et ne classe rien ; définie par le rang et bornée en nombre,
elle redevient un choix. Constat fondateur sur ergonomia : 21 issues sur 39
sans priorité, et du confort d'affichage en P1 pendant qu'un risque réel
dormait en P2.

Critères d'acceptation :

- Étant donné le formulaire d'anomalie, quand une anomalie est déclarée,
  alors la gravité est renseignée et aucune priorité n'est demandée au
  déclarant.
- Étant donné la limite de P1 atteinte, quand une issue supplémentaire doit
  passer en P1, alors une autre redescend et le commentaire dit laquelle et
  pourquoi.
- Étant donné un changement de priorité, quand il survient, alors son motif
  est écrit en commentaire.

Covers:
- feat~coordination-issues~1

Needs: impl
