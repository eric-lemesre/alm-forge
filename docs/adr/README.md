# Registre des décisions d'architecture (ADR)

<!-- [impl->req~registre-adr~1] -->

Une décision d'architecture est un choix justifié qui répond à une exigence
fonctionnelle ou non fonctionnelle de portée structurante. Chaque décision est
consignée dans un ADR : un fichier, une décision, sa motivation, ses
alternatives écartées et son moyen de vérification.

## Quand écrire un ADR

- Le choix engage la structure, la sécurité, les données, l'outillage ou la
  méthode, et coûterait cher à défaire.
- Le choix tranche entre plusieurs options défendables : les alternatives
  écartées doivent survivre à la discussion.
- Le choix interprète un besoin ambigu : l'ADR matérialise le jugement rendu et
  renvoie à la question ouverte qui l'a soulevé.

Ce qui n'est **pas** un ADR : le contenu d'une spécification (il vit dans
`spec/`), la coordination d'un chantier (elle vit dans les issues), le
compte-rendu d'une séance (il vit dans `docs/decisions/`).

## Conventions

- Fichier `NNNN-titre-en-kebab-case.md`, numérotation continue, jamais
  réutilisée : un ADR rejeté consomme son numéro.
- Titre : la décision formulée à l'infinitif.
- Modèle : [`templates/fr/adr.md`](../../templates/fr/adr.md) (dérivé de MADR
  4.0, enrichi de la section Vérification).
- **Un ADR accepté ne se modifie pas.** On écrit un nouvel ADR qui le
  remplace ; l'ancien passe au statut « Remplacé par ADR-XXXX ».
- La section **Vérification** est obligatoire pour tout ADR accepté : une
  décision qu'aucun mécanisme ne protège dérivera. Ce point est contrôlé par
  les portes qualité (`task check`).
- Quand la décision répond à une exigence tracée, l'ADR porte un item de
  conception OpenFastTrace (type dsn) qui couvre l'exigence : la décision entre
  ainsi dans la matrice de traçabilité.

## Cycle de vie

```text
Proposé ──▶ Accepté ──▶ Déprécié
   │                       ▲
   └──▶ Rejeté             └── Remplacé par ADR-XXXX
```

## Niveaux d'enjeu et cérémonie

| Niveau | Nature | Circuit |
| --- | --- | --- |
| S — structurant | irréversible, sécurité, réglementaire, données | séance + relevé de décision, puis ADR |
| F — fonctionnel | arbitrage de conception courant | consultation asynchrone, décision du responsable de domaine |
| É — éditorial | reformulation, outillage mineur | simple pull request |

## Index

| ADR | Titre | Statut |
| --- | --- | --- |
| [0001](0001-structurer-alm-forge-en-depot-gabarit.md) | Structurer alm-forge en dépôt-gabarit instanciable | Accepté |
| [0002](0002-tracer-les-exigences-avec-openfasttrace.md) | Tracer les exigences avec OpenFastTrace | Accepté |
| [0003](0003-structurer-les-adr-sur-madr-avec-verification.md) | Structurer les ADR sur MADR avec section Vérification | Accepté |
| [0004](0004-rediger-les-exigences-selon-ears.md) | Rédiger les exigences selon la syntaxe EARS | Accepté |
| [0005](0005-documentation-normative-francaise-templates-bilingues.md) | Documentation normative en français, templates bilingues | Accepté |
| [0006](0006-contrat-agents-unique-avec-adaptateurs.md) | Un contrat d'agents unique, raccordé par adaptateurs | Accepté |
| [0007](0007-orchestrateur-en-facade-interchangeable.md) | Séparer les portes de l'orchestrateur, façade interchangeable | Accepté |
