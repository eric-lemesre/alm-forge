# Exigences — domaine gouvernance

## Contrat d'agents unique et agnostique

`req~gouvernance-agents~1`

Le dépôt DOIT porter un contrat de gouvernance unique (AGENTS.md) faisant
autorité sur toute consigne de session, applicable à tout agent humain ou IA,
listant des règles non négociables chacune adossée à un moyen de vérification.
Les agents spécifiques s'y raccordent par des fichiers adaptateurs qui ne
contiennent aucune règle propre.

Critères d'acceptation :

- Étant donné une consigne de session contredisant le contrat, quand l'agent
  travaille dans le dépôt, alors le contrat prévaut et le conflit est signalé.
- Étant donné un nouvel agent outillé (lecteur de CLAUDE.md, de .cursorrules ou
  autre), quand on l'intègre, alors on ajoute un adaptateur-pointeur sans
  dupliquer les règles.

Covers:
- feat~gouvernance-agnostique~1

Needs: dsn, impl

## Templates bilingues

`req~bilinguisme-templates~1`

Les modèles d'artefacts (ADR, besoin, exigence, question ouverte, relevé de
décision, revue de code) DOIVENT être fournis en français et en anglais, avec
les mêmes noms de fichiers dans les deux arborescences ; la parité DOIT être
vérifiée mécaniquement.

Covers:
- feat~gouvernance-agnostique~1

Needs: dsn, impl

## Instanciation outillée

`req~instanciation-outillee~1`

Quand un projet est instancié depuis le gabarit, le dépôt DOIT fournir un
script d'initialisation qui personnalise l'identité du projet (nom, porteur),
retire la spécification et les ADR propres au gabarit (y compris leurs tags de
couverture dans les documents conservés), réinitialise le journal des
changements, la version, la licence et les registres, et laisse la traçabilité
et les contrôles de cohérence verts.

Rationale:
GitHub n'effectue aucune substitution de variables à la création depuis un
template : sans script, la personnalisation est une checklist manuelle,
incomplète par construction (licence, registres et tags oubliés).

Critères d'acceptation :

- Étant donné une copie du gabarit, quand le script est exécuté avec un nom de
  projet et un porteur, alors la spécification du gabarit et ses ADR sont
  retirés, la licence porte le porteur, et la traçabilité passe.
- Étant donné un dépôt déjà initialisé, quand le script est relancé sans
  forçage, alors il refuse d'agir.

Covers:
- feat~gouvernance-agnostique~1

Needs: impl, utest

## Versionnement et journal des changements

`req~versionnement-release~1`

Le dépôt DOIT être versionné en SemVer avec un journal des changements au
format Keep a Changelog ; la cohérence entre le fichier VERSION et le journal
DOIT être vérifiée mécaniquement avant publication.

Covers:
- feat~cadre-de-decision~1

Needs: impl


