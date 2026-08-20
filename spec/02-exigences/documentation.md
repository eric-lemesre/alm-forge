# Exigences — domaine documentation vérifiée

**Statut : ACTIVE** — domaine acté le 2026-08-20 (D-2026-08-16). Le statut commande
le dénominateur des taux d'audit et de classification (méthode, ch. 13).

Sur un projet qui trace ses décisions, la documentation n'est pas un
commentaire du produit : elle en fait partie. Les exigences de ce domaine la
soumettent au même régime que le code — des contrôles qui échouent.

## Intégrité des liens internes

`req~integrite-liens~1`

**Statut : approuvée**

Tout lien Markdown relatif de la documentation DOIT atteindre un fichier
suivi par le gestionnaire de versions, et toute ancre citée DOIT correspondre
à un titre existant du fichier visé. Le contrôle DOIT ignorer les liens
externes et les exemples placés dans des blocs de code.

Rationale:
Un lien mort ne casse aucun test : il envoie un lecteur dans le vide et lui
laisse croire qu'un document existe. Cas fondateur sur ergonomia : trois
documents de la branche principale ont renvoyé neuf jours durant vers une
spécification jamais versée, sans qu'aucune porte ne proteste. L'exigence de
suivi par le gestionnaire de versions — et non de simple présence sur le
disque — vient du symétrique : un fichier jamais ajouté satisfait un test
d'existence chez son auteur et reste mort pour tous les autres.

Critères d'acceptation :

- Étant donné un lien vers un fichier absent, quand la porte s'exécute, alors
  elle échoue en nommant le fichier source et sa ligne.
- Étant donné un lien vers un fichier présent sur le disque mais non
  versionné, quand la porte s'exécute, alors elle échoue.
- Étant donné un lien vers une ancre inexistante, quand la porte s'exécute,
  alors elle échoue.
- Étant donné un lien externe ou un exemple en bloc de code, quand la porte
  s'exécute, alors elle ne les signale pas.

Covers:
- feat~documentation-verifiee~1

Needs: impl, utest

## Feuille de route dérivée de ses fiches

`req~feuille-de-route-outillee~1`

**Statut : approuvée**

Chaque fiche de feuille de route DOIT porter une ligne de statut au
vocabulaire du lexique, et l'index des fiches DOIT être généré depuis
celles-ci plutôt que tenu à la main.

Rationale:
Un index tenu à la main finit toujours par mentir : sur ergonomia, sept
lignes annonçaient « à venir » ou « en cours » des jalons livrés depuis des
semaines. Générer l'index supprime la classe entière de défauts, et la porte
anti-dérive interdit de le retoucher.

Critères d'acceptation :

- Étant donné une fiche sans ligne de statut, quand la porte s'exécute, alors
  elle échoue.
- Étant donné un index modifié à la main, quand la porte s'exécute, alors
  elle échoue en indiquant la commande de régénération.

Covers:
- feat~documentation-verifiee~1

Needs: impl, utest

## Suivi consolidé des constats de revue

`req~suivi-constats-revue~1`

**Statut : approuvée**

Les constats des revues de code DOIVENT être consolidés en un tableau de bord
unique généré depuis les fiches, et aucun constat de sévérité haute NE DOIT
rester sans verdict — un rejet motivé valant réponse.

Rationale:
Les constats vivent dispersés, une fiche par branche ; passée la fusion,
personne ne les rouvre — « sans s'y pencher volontairement elles peuvent
mourir » (Éric Lemesre, ergonomia, 2026-08-18). Cette exigence mécanise en
outre la règle du chapitre 7, qui n'était jusqu'ici qu'une phrase de méthode.

Critères d'acceptation :

- Étant donné un constat de sévérité haute sans verdict, quand la porte
  s'exécute, alors elle échoue en citant la revue et le numéro du constat.
- Étant donné le même constat marqué rejeté avec un motif, quand la porte
  s'exécute, alors elle passe.
- Étant donné un tableau de bord périmé, quand la porte s'exécute, alors elle
  échoue.

Covers:
- feat~documentation-verifiee~1

Needs: impl, utest

## Badges autonomes, sans service tiers

`req~badges-autonomes~1`

**Statut : approuvée**

Les badges d'état affichés par la documentation DOIVENT être générés et
versionnés localement, sans appel réseau ni service tiers, et dériver de
sources de vérité du dépôt.

Rationale:
Un dépôt privé, hébergé sur une forge sans exécution de CI ou consulté hors
ligne, ne peut pas dépendre d'un service externe : les badges y restent gris
à jamais. Second motif, décisif en contexte de données de santé : chaque
lecteur du README transmet son adresse à un tiers hors de l'organisation.

Critères d'acceptation :

- Étant donné un dépôt sans accès réseau, quand les badges sont générés,
  alors la génération réussit.
- Étant donné un changement de version, quand la porte s'exécute sans que les
  badges aient été régénérés, alors elle échoue.

Covers:
- feat~documentation-verifiee~1

Needs: impl, utest
