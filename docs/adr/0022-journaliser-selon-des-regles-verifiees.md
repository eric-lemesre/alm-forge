# ADR-0022 — Journaliser selon des règles vérifiées dans les projets Rust

**Statut** : Accepté
**Date** : 2026-11-02
**Décideur** : Éric Lemesre — seul, après revue d'architecture de la journalisation d'un service instancié (voir D-2026-11-03, registre des décisions)
**Portée** : durable — condition de réouverture : abandon de l'écosystème `tracing` par la communauté Rust, ou porte qui juge le code compilé (lint maison) et rend la lecture textuelle superflue

## Item de conception

`dsn~journalisation-verifiee~1`

Les règles de journalisation des projets Rust sont écrites une fois, dans la
méthode (chapitre 17), indépendamment de l'agent qui produit le code. Les
quatre qu'un outil juge sans compiler — abonné installé par le seul binaire,
`#[instrument]` avec `skip_all`, aucun secret en chaîne nue dans un type qui
dérive `Debug`, aucun diagnostic par `println!` dans une bibliothèque — sont
constatées par une porte POSIX, `tools/journalisation.sh`, câblée dans
`tools/ci.sh`, sur les seuls fichiers suivis par git. Les autres règles
(corrélation, niveaux, journald, absence de contenu métier) relèvent de la
revue et des tests du projet, que le chapitre décrit.

Covers:

- req~journalisation-verifiee~1

## Contexte

La revue d'architecture de la journalisation d'un service Rust instancié a
fait apparaître des règles que tout projet Rust du poste de référence doit
suivre, et une faiblesse commune : les secrets n'étaient écartés du journal
que par la vigilance. `#[instrument]` enregistre par défaut tous les
arguments par leur `Debug` ; un `Debug` dérivé sur une structure de réglages
écrit le jeton qu'elle porte ; une bibliothèque qui installe l'abonné
confisque le journal de son hôte.

À la mise en place, la porte jouée sur six dépôts Rust a relevé 46 champs ou
types qui portent un mot de passe, un jeton ou une clé d'API en chaîne nue
dans un type qui dérive `Debug`, un abonné installé hors du binaire et quatre
diagnostics par `println!` ou `eprintln!` dans une bibliothèque ; deux dépôts
passaient sans constat. Aucune fuite effective par
ces voies, toutes à un `{:?}` près. Les audits manuels des mêmes dépôts ont
trouvé en plus une fuite réelle (adresse électronique journalisée) et des
manques de corrélation : ce qu'une porte textuelle ne voit pas.

Le contrat (règle méta, méthode ch. 9) exige qu'une règle désigne son
mécanisme de vérification : une règle de journal seulement écrite resterait
lettre morte.

## Décision

1. Le chapitre 17 de la méthode, « Journalisation », fait foi pour les
   règles. Une compétence d'agent qui les reprend (adaptateur) n'ajoute
   aucune règle propre.
2. `tools/journalisation.sh` constate les quatre règles mécanisables, sur
   les fichiers `src/**/*.rs` suivis par git de chaque paquet. Une
   bibliothèque est un paquet doté d'un `src/lib.rs`, hors `src/main.rs` et
   `src/bin/`.
3. Une dérogation s'écrit `journal: admis — <raison>` sur la ligne ou celle
   qui la précède ; la raison est obligatoire. La liste des mots qui
   désignent un secret se règle par `JOURNAL_MOTS_SECRETS`.
4. Sans manifeste Cargo à la racine, la porte le dit et passe. Un autre
   langage se traiterait par une porte sœur, sur le même patron.

## Alternatives écartées

### Un lint Clippy ou dylint maison

Il jugerait le code compilé (types réels, attributs résolus) et ne se
tromperait pas sur un alias ni sur une macro. Mais il impose une chaîne
nightly ou un outil de plus à chaque projet, contre l'interdit d'introduire
une dépendance d'outillage sans nécessité (le gabarit n'exige qu'un shell
POSIX), et son coût de maintenance dépasse celui de la porte textuelle pour
des règles qui se lisent sur une ligne. La condition de réouverture le garde
ouvert.

### Les règles dans la seule compétence d'agent

Elle ne lie que l'agent qui la charge, pas un contributeur humain ni un
autre agent, et n'échoue jamais : c'est une consigne, pas une porte.

### Un `Debug` interdit sur toute structure de réglages

Trop large : une structure sans secret a besoin de son `Debug`, et un secret
dans un type masquant le rend sûr. La règle vise le secret en chaîne nue, là
où la fuite naît.

## Conséquences

- Ce que cela apporte : une fuite de secret par le journal devient un échec
  de porte au lieu d'un incident ; les mêmes règles valent pour tous les
  projets Rust instanciés, quel que soit l'agent.
- Ce que cela coûte : une lecture textuelle, avec ses limites assumées et
  documentées dans la porte (module de tests supposé en fin de fichier,
  noms de secret reconnus par une liste) ; une mise en conformité des
  projets existants, dont les constats sont nommés fichier par fichier.
- Ce que cela ferme : l'installation de l'abonné ailleurs que dans le
  binaire, et le secret porté en chaîne nue par un type qui se formate.

## Vérification

- `tools/journalisation-test.sh` (dans `sh tools/ci.sh`, voie complète) joue
  chaque critère sur son cas d'échec et de passage : dépôt sans Cargo,
  paquet sain, abonné dans une bibliothèque (chaîne multiligne,
  `set_global_default`, `env_logger`) et hors bibliothèque, paquet d'espace
  de travail, `#[instrument]` nu, sans `skip_all` ou multiligne, secret en
  champ, en `Option`, en nouveau type, masqué ou sans `Debug`, mots réglables,
  diagnostics de bibliothèque et de binaire, commentaires et module de
  tests, dérogation avec et sans raison, dossier caché et fichier non suivi.
- `tools/journalisation.sh` est une étape de `tools/ci.sh` et des deux
  façades (Taskfile, justfile).

## Références

- Méthode, [chapitre 17 — Journalisation](../methode/17-journalisation.md).
- `req~journalisation-verifiee~1` (`spec/02-exigences/gouvernance.md`).
- Méthode, chapitre 9 (règles vérifiées) ; ADR-0012 (porte anti-secrets),
  qui protège le dépôt quand cette porte protège le journal.
