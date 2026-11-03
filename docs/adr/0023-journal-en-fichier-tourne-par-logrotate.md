# ADR-0023 — Écrire le journal dans un fichier par défaut, tourné par logrotate

**Statut** : Accepté
**Date** : 2026-11-03
**Décideur** : Éric Lemesre — seul (voir D-2026-11-05, registre des décisions)
**Portée** : durable — condition de réouverture : un déploiement où aucun
fichier n'est inscriptible (conteneur en lecture seule) devient la norme

## Contexte

L'ADR-0022 et le chapitre 17 de la méthode (règle 6) envoyaient le journal
sur la sortie d'erreur, à charge pour journald, le conteneur ou le
collecteur de le conserver et de le faire tourner. En exploitation, le
porteur veut au contraire trouver le journal d'un service dans un fichier
connu, lisible sans `journalctl`, conservé et compressé selon une règle
écrite, et le même partout — poste, serveur sans systemd, conteneur doté
d'un volume.

## Décision

1. **Sortie par défaut : un fichier.** Un service écrit son journal dans
   un fichier désigné par `<PROJET>_JOURNAL_FICHIER` (ou la configuration),
   à défaut `/var/log/<projet>/<service>.log` en production et
   `target/journal/<service>.log` en développement (construction de mise
   au point). La sortie se règle par `<PROJET>_JOURNAL_SORTIE` :
   `fichier` (défaut), `erreur` (sortie d'erreur) ou `journald`.
2. **Rotation par logrotate.** L'application ne fait pas tourner ses
   fichiers : elle **rouvre** son fichier à la réception de `SIGHUP`. Le
   projet livre une configuration logrotate (quotidienne, quatorze
   générations, compressées, création en `0640`) dont le `postrotate`
   envoie `SIGHUP` au service.
3. **Repli annoncé.** Si le fichier ne s'ouvre pas au démarrage (dossier
   absent, droits), le journal va à la sortie d'erreur et le premier
   événement le dit (`warn!`) ; un échec de réouverture garde l'ancien
   descripteur et le dit de même.
4. **journald sur demande.** La couche `tracing-journald` (règle 7) ne sert
   plus que si la sortie `journald` est demandée, avec la même vérification
   de `JOURNAL_STREAM` quand la sortie d'erreur est choisie.
5. Les autres règles de l'ADR-0022 (secrets par le type, aucun contenu,
   corrélation, porte) sont inchangées ; le fichier porte exactement ce que
   la sortie d'erreur portait.

## Alternatives écartées

### Garder la sortie d'erreur et laisser journald conserver

C'était la règle de l'ADR-0022 : sans fichier, le journal dépend de la
configuration de journald (rétention, volatilité) et ne se lit qu'avec ses
outils ; hors systemd, il se perd si rien ne le recueille.

### Rotation par l'application (fichier par jour)

`tracing-appender` sait tourner ses fichiers, mais la rétention, la
compression et les droits deviennent du code à maintenir dans chaque projet,
alors que logrotate les tient déjà, de façon uniforme sur le serveur.

### logrotate avec `copytruncate`

Aucun signal à gérer, mais les lignes écrites entre la copie et la
troncature sont perdues, et le fichier tronqué sous un descripteur ouvert en
écriture simple laisse un trou ; la réouverture sur `SIGHUP` est le
mécanisme prévu pour cela.

## Conséquences

- Ce que cela apporte : un journal à un endroit connu, conservé et
  compressé selon une règle écrite, identique d'un déploiement à l'autre.
- Ce que cela coûte : un rédacteur qui sait se rouvrir et un gestionnaire
  de `SIGHUP` par service ; une configuration logrotate livrée ; un dossier
  `/var/log/<projet>` à créer avec les bons droits au déploiement.
- Ce que cela ferme : un journal perdu faute de collecteur ; une rétention
  décidée par défaut ailleurs que dans le projet.

## Vérification

- Tests du projet : la sortie par défaut est le fichier ; après
  renommage du fichier et réouverture, les lignes suivantes vont dans le
  nouveau fichier ; un fichier impossible à ouvrir renvoie à la sortie
  d'erreur avec un avertissement.
- La configuration logrotate livrée est validée par `logrotate -d` dans la
  CI du projet quand l'outil est présent.
- Revue (ch. 7) : la règle 6 du chapitre 17 fait foi.

## Références

- ADR-0022 (règles de journalisation vérifiées) ; méthode, chapitre 17,
  règles 6 et 7.
- `logrotate(8)` (`postrotate`, `sharedscripts`, `create`).
