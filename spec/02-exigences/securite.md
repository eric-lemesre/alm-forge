# Exigences — domaine sécurité

**Statut : ACTIVE** — domaine acté le 2026-08-20 (D-2026-08-16). Le statut commande
le dénominateur des taux d'audit et de classification (méthode, ch. 13).

## Détection des secrets dans les contributions

`req~detection-secrets~1`

**Statut : approuvée**

Si un secret (clé d'API, jeton, mot de passe, clé privée) est présent dans une
contribution, alors les portes DOIVENT le détecter et refuser la contribution
en CI ; le hook local DOIT effectuer la même détection sur les fichiers
indexés quand l'outil est disponible, et signaler bruyamment son absence sans
bloquer sinon. L'outil de détection DOIT être épinglé par version et par
empreinte, et les faux positifs DOIVENT passer par une exception justifiée
versionnée, jamais par la désactivation de la porte.

Rationale:
Un secret commité est compromis dès la première poussée, même supprimé
ensuite (l'historique le conserve). L'asymétrie local/CI est assumée et
documentée : bloquant là où l'environnement est maîtrisé (CI), signalant sur
les postes où l'outil peut manquer — un blocage local inconditionnel
pousserait au contournement global (ADR-0012).

Critères d'acceptation :

- Étant donné un fichier contenant un motif de secret connu, quand la porte
  s'exécute, alors elle échoue en désignant le fichier.
- Étant donné un dépôt sain, quand la porte s'exécute, alors elle passe.
- Étant donné un poste sans l'outil ni accès réseau, quand le hook local
  s'exécute, alors il avertit et laisse la CI trancher.

Covers:
- feat~tracabilite-mecanisee~1

Needs: dsn, impl, utest

## Cadre de sécurité continue

`req~securite-continue~1`

**Statut : approuvée**

Le dépôt DOIT fournir un cadre de sécurité continue documenté et outillable :
modélisation légère des menaces (STRIDE) exigée pour les exigences de niveau
d'enjeu S avec report des menaces retenues en critères d'acceptation, politique
de traitement des vulnérabilités avec délais par sévérité et exceptions
justifiées, datées et portées par un responsable, et emplacement déclaré pour
la génération d'inventaire de composants (SBOM) à la release.

Rationale:
La sécurité qui repose sur la vigilance échoue (shift-left) ; le cadre
transforme les pratiques du domaine en artefacts du dépôt : menaces → critères
testables, vulnérabilités → délais et exceptions tracées, composants →
inventaire versionné.

Critères d'acceptation :

- Étant donné une exigence de niveau S, quand elle est approuvée, alors ses
  menaces STRIDE examinées figurent dans ses critères d'acceptation (contrôlé
  en revue via la Definition of Done).
- Étant donné une vulnérabilité non corrigeable dans les délais, quand elle
  est acceptée, alors une exception versionnée porte la justification, le
  responsable et l'échéance.

Covers:
- feat~gouvernance-agnostique~1

Needs: impl, mtest
