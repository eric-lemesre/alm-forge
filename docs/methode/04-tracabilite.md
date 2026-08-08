# 4. Traçabilité

La chaîne besoin → exigence → conception → implémentation → test est vérifiée
par [OpenFastTrace](https://github.com/itsallcode/openfasttrace) (décision :
[ADR-0002](../adr/0002-tracer-les-exigences-avec-openfasttrace.md)). L'outil
échoue si un maillon manque ; il n'y a pas de matrice tenue à la main.

## Types d'artefacts et chaîne

| Type | Artefact | Vit dans |
| --- | --- | --- |
| feat | expression de besoin | `spec/01-besoins/` |
| req | exigence | `spec/02-exigences/` |
| dsn | décision de conception | `docs/adr/` |
| impl | implémentation | code, scripts, docs selon le projet |
| utest / itest / stest | test unitaire / intégration / système | arborescence de tests |
| mtest | procédure de vérification manuelle | `docs/verification-manuelle/` |

Chaque item déclare ce qu'il attend en aval (`Needs: dsn, impl, utest`) ;
chaque artefact aval déclare ce qu'il couvre (mot-clé Covers pour les items,
tags pour le code).

## Définir un item (fichiers Markdown)

L'identifiant, entouré d'accents graves, **seul sur sa ligne** :

```markdown
`req~mon-exigence~1`

Texte de l'exigence.

Covers:
- feat~besoin-parent~1

Needs: impl, utest
```

Comportements vérifiés empiriquement (OpenFastTrace 4.9.0) :

- les blocs de code (comme ci-dessus) sont **ignorés** : la documentation peut
  citer la syntaxe sans créer d'items ;
- une mention d'identifiant à l'intérieur d'une phrase ne crée pas d'item ;
  éviter simplement de placer un identifiant entre accents graves seul en début
  de ligne hors définition volontaire.

## Taguer une couverture (tout langage)

Le tag `[type-aval->identifiant-couvert]` se place dans un commentaire,
n'importe quel langage à extension reconnue :

```python
# [impl->req~mon-exigence~1]
def ma_fonction():
    ...
```

```rust
// [utest->req~mon-exigence~1]
#[test]
fn verifie_mon_exigence() { ... }
```

Dans un document Markdown, le tag s'écrit dans un commentaire HTML en début de
ligne — `<!-- [impl->…] -->` ; voir les tags réels en tête des chapitres 2 et 5
de cette méthode.

**Pièges vérifiés** (OpenFastTrace 4.9.0) : l'importateur de tags ne respecte
pas les blocs de code pour les commentaires HTML des fichiers Markdown, et un
titre Markdown à l'intérieur d'un bloc de code réactive l'importateur d'items —
ne jamais placer un titre ni un tag HTML complet dans un exemple de code.

**Piège vérifié** : les fichiers **sans extension** (hooks git, justfile…) ne
sont pas scannés. Les tags doivent vivre dans des fichiers à extension reconnue
(.sh, .py, .rs, .js, .ts, .yml, .md…) — d'où les hooks minces qui délèguent à
des scripts `.sh` tagués dans `tools/`. C'est aussi une des raisons du choix
de `Taskfile.yml` comme façade par défaut : son extension le rend scannable
(ADR-0007).

## Exécution

| Commande | Effet |
| --- | --- |
| `task trace` (ou `sh tools/oft.sh trace`) | vérification complète, liste les défauts, code retour non nul si échec |
| `task report` (ou `sh tools/oft.sh report`) | rapport HTML navigable dans `build/tracabilite.html` |

Le périmètre scanné est défini une seule fois dans `tools/oft.sh` (hooks et CI
exécutent le même script). `templates/` en est exclu : les modèles contiennent
des exemples d'identifiants qui ne doivent pas devenir des items.

## Anti-patterns

- **Tag de complaisance** : taguer un fichier qui ne réalise pas réellement
  l'exigence pour faire passer la porte. La revue traque ce cas ; la
  traçabilité mesure la présence, la revue mesure la vérité.
- **Porte déclarée non câblée** : documenter un contrôle sans l'exécuter en CI.
  Interdit par l'exigence de porte CI — toute exception est marquée « non
  câblée » avec raison et échéance.
- **Contrôle no-op** : un contrôle de dérive qui compare un fichier jamais
  généré passe toujours. Vérifier le cas d'échec d'une porte fait partie de sa
  mise en place.
- **Outillage aveugle à son environnement** : un chemin d'artefact de build
  codé en dur (`./target`, `node_modules/.bin`…) dans une recette, un script
  ou une CI casse — ou pire, devient silencieusement sans effet — dès qu'un
  réglage de poste le déplace (répertoire Cargo partagé via
  CARGO_TARGET_DIR, store pnpm, ccache…). Résoudre les chemins via l'outil
  (`cargo metadata` donne `target_directory`), et re-tester les portes —
  nettoyage compris — après tout changement d'environnement : un nettoyage
  devenu no-op est un contrôle qui passe toujours. Attention aussi au sens
  inverse : avec un cache partagé, un `cargo clean` « local » purge le
  répertoire commun à tous les projets du poste. (Cas vécu à l'origine de
  cette règle : bascule d'un poste en target partagé, scripts de nettoyage
  devenus vides et recettes clean devenues globales le même jour.)
