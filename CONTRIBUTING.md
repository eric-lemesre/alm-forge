# Contribuer

Les règles complètes sont dans [AGENTS.md](AGENTS.md) (contrat faisant
autorité) et la méthode dans [docs/methode/](docs/methode/README.md). Résumé
opérationnel :

## Mise en place

```bash
just hooks   # installe pre-commit et commit-msg (indispensable)
just ci      # vérifie que le dépôt est sain avant de commencer
```

Prérequis : git, [just](https://github.com/casey/just), bash, curl, Java 17+
(pour OpenFastTrace, téléchargé automatiquement et vérifié par empreinte).

## Flux

1. Branche `type/sujet-court` depuis `main`.
2. Suivre la boucle de travail d'AGENTS.md §2 : exigence d'abord, tags de
   couverture, tests du niveau déclaré, `just ci` vert.
3. Commits conventionnels en français, l'identifiant d'exigence dans le sujet.
4. Pull request : la checklist du modèle est la Definition of Done.
5. Revue par un second regard ; chaque constat est soldé avant fusion.

## Ce qui bloque une contribution

- Une exigence orpheline ou un tag fantôme (`just trace` échoue).
- Un ADR accepté sans section Vérification (`just check` échoue).
- Un message de commit non conventionnel ou portant une mention d'agent.
- Un contrôle introduit sans démonstration de son cas d'échec (R3).
