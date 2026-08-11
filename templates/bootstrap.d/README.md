# Modules de bootstrap prêts à copier

Le bootstrap du gabarit est **modulaire** (ADR-0014) : chaque outil vit dans
son module `tools/bootstrap.d/NN-outil.sh`, et le point d'extension d'un
projet instancié est l'**ajout d'un module** — jamais l'édition de
l'orchestrateur. Ce répertoire fournit des modules **prêts à copier**, avec
l'outillage qu'ils installent. C'est du matériel **post-instanciation** : le
gabarit lui-même ne les exécute pas et n'en dépend pas.

Comme `templates/orchestrators/`, ce répertoire n'est pas scanné par la
traçabilité (`templates/` est exclu du périmètre, ADR-0002) : les fichiers
copiés se taguent **vers les exigences du projet instancié** (R2, R7).

## Kit lint Markdown (tableaux normalisés)

Porte `markdownlint-cli2` avec la règle **MD060** (tableaux GFM alignés,
pipes et séparateurs) et formateur `format-tables.mjs` fondé sur
`string-width` — la **même mesure de largeur que MD060** (emoji et
caractères larges compris), donc formateur et porte toujours d'accord.

| Fichier | Copier vers | Rôle |
| --- | --- | --- |
| `30-node.sh` | `tools/bootstrap.d/` | module bootstrap : Node.js 22+ |
| `40-markdown-npm.sh` | `tools/bootstrap.d/` | module bootstrap : dépendances npm du lint |
| `markdown/markdown.sh` | `tools/` | la porte : `lint` (gate) et `fix` (normalisation) |
| `markdown/format-tables.mjs` | `tools/` | formateur de tableaux (périmètre à adapter) |
| `markdown/markdownlint-cli2.jsonc` | `.markdownlint-cli2.jsonc` (racine) | configuration (globs à adapter) |
| `markdown/package.json` | `package.json` (racine, ou fusionner) | dépendances épinglées |

## Mise en place (projet instancié)

1. Copier les fichiers selon le tableau ci-dessus ; adapter les **globs** de
   la configuration et le **périmètre** de `format-tables.mjs` à votre
   arborescence.
2. `npm install --no-audit --no-fund` — versionner le `package-lock.json`
   produit (installations reproductibles) et ignorer `node_modules/`.
3. Câbler la porte (R7 : toute porte documentée est câblée) : une étape
   `sh tools/markdown.sh lint` dans la CI, une cible dans la façade
   d'orchestration, le hook pre-commit si souhaité — et **taguer**
   `markdown.sh` vers l'exigence de qualité documentaire du projet (R2).
   Prévoir le test du cas d'échec à la mise en place (R3).
4. Normaliser l'existant : `sh tools/markdown.sh fix` (idempotent), puis
   relancer la CI locale.

Prérequis : Node.js **22+** (`markdownlint-cli2` ≥ 0.23 l'exige) — vérifié
par le module `30-node.sh` et revérifié par la porte, qui échoue avec un
message explicite plutôt qu'une erreur cryptique.
