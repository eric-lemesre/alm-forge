# 10. Sécurité continue

<!-- [impl->req~securite-continue~1] -->

La sécurité qui repose sur la vigilance échoue ; celle qui vit dans les
artefacts et les portes tient. Ce chapitre intègre trois pratiques du domaine
(shift-left) dans les mécanismes existants de la méthode — exigences, portes,
exceptions tracées.

## Modélisation légère des menaces (STRIDE)

Obligatoire pour toute exigence de **niveau d'enjeu S** et à chaque nouvelle
frontière de données (nouveau flux entrant, nouvelle intégration, nouveau
stockage). Format court — 30 à 60 minutes, l'équipe, pas un spécialiste seul
(modèle : `templates/fr/threat-model.md`) :

1. décrire le flux : composants, données échangées, limites de confiance ;
2. passer les six catégories sur chaque flux sensible :

| Lettre | Menace | Contrôle type |
| --- | --- | --- |
| S — Spoofing | usurpation d'identité | authentification forte |
| T — Tampering | altération de données | intégrité, signatures |
| R — Repudiation | actions non traçables | journalisation, audit |
| I — Information disclosure | exposition de données | chiffrement, moindre accès |
| D — Denial of service | indisponibilité | limitation de débit, garde-fous |
| E — Elevation of privilege | escalade de droits | moindre privilège, RBAC |

3. prioriser (critique/élevé/moyen/faible) ;
4. **reporter les menaces retenues en critères d'acceptation de l'exigence**
   — c'est le débouché obligatoire : une menace identifiée sans critère
   testable est un vœu. La Definition of Done le contrôle.

## Vulnérabilités : délais et exceptions

Politique par défaut du gabarit, adaptable par ADR du projet :

| Sévérité | Délai maximal de traitement |
| --- | --- |
| Critique | 24 heures |
| Haute | 72 heures |
| Moyenne | 2 semaines |
| Basse | le trimestre en cours |

- La **détection** est câblée en CI par le projet selon sa pile (audit de
  dépendances, scan d'images) — toute porte documentée est câblée ou marquée
  « non câblée » (R7). Prioriser au-delà du score de sévérité : probabilité
  d'exploitation et exposition réelle du composant.
- **Traiter** dans l'ordre : corriger (mise à jour), atténuer (contrôle
  compensatoire), ou **accepter explicitement** — jamais tacitement.
- Une acceptation est une **exception versionnée** (modèle :
  `templates/fr/security-exception.md`, ou le format natif de l'outil —
  ignore-list de l'auditeur de dépendances, `.gitleaks.toml`…) portant :
  justification, responsable nommé, échéance de réexamen. Une exception sans
  échéance est une dette invisible. Même patron que les waivers de
  traçabilité : l'exception se déclare, ne se contourne pas.

## Inventaire de composants (SBOM)

À chaque release, le projet DEVRAIT générer et archiver un inventaire de ses
composants (CycloneDX ou SPDX, selon l'outil de sa pile : cargo-cyclonedx,
syft, npm sbom…). C'est ce qui permet de répondre en minutes, pas en jours, à
« sommes-nous concernés ? » lors d'une vulnérabilité majeure. L'emplacement
est réservé dans la chaîne de release (chapitre 8, étape 4) ; l'outillage
concret relève de l'ADR technologique du projet, vérifié par sa présence en
CI de release.

## La porte anti-secrets

Un secret commité est compromis même supprimé ensuite : l'historique le
conserve. La porte gitleaks (ADR-0012) est bloquante en CI et exécutée par le
hook pre-commit quand l'outil est présent. Les faux positifs passent par une
entrée justifiée de `.gitleaks.toml`, jamais par la désactivation. En cas de
vrai secret déjà poussé : le **révoquer immédiatement** (la réécriture
d'historique ne « rattrape » rien — le secret a été exposé), puis nettoyer.

## Références

- STRIDE, pipeline sécurisé, gestion des vulnérabilités :
  <https://blog.stephane-robert.info/docs/devops/> (parcours DevSecOps).
- Épinglage et chaîne d'approvisionnement de l'outillage : ADR-0002 (jar
  OpenFastTrace), ADR-0012 (gitleaks), façades CI (actions par SHA).
