# Audit — documentation vérifiée

Miroir de [`spec/02-exigences/documentation.md`](../../spec/02-exigences/documentation.md).

| Exigence | Verdict | Preuve / écart |
| --- | --- | --- |
| `req~integrite-liens~1` | conforme | `tools/liens.sh` (85 liens vérifiés) ; `tools/liens-test.sh` couvre quatre cas, dont le fichier présent mais non versionné |
| `req~feuille-de-route-outillee~1` | conforme | `tools/todo.sh`, index dérivé et protégé par `tools/derive.sh` ; méthode ch. 12 ; deux cas d'échec dans `tools/gouvernance-test.sh` |
| `req~suivi-constats-revue~1` | conforme | `tools/revues.sh` ; le refus des sévérités hautes non soldées mécanise la règle du ch. 7 ; le rejet motivé solde, cas éprouvé |
| `req~badges-autonomes~1` | conforme | `tools/badges.sh`, aucun appel réseau, sortie déterministe ; badges versionnés et protégés par l'anti-dérive ; cas d'échec dans `tools/gouvernance-test.sh` |
| `req~avancement-calcule~2` | conforme | `tools/avancement.sh` : une exigence due n'est tenue que si son `Needs:` est déclaré ET qu'une couverture est posée (étiquettes des fichiers suivis, items mtest/utest/itest/stest en `Covers:` ; un dsn ne compte pas), citations des fiches non soldées de `docs/todo/`, colonne protégée par `tools/derive.sh` ; `tools/gouvernance-test.sh` joue chaque état, dont « Needs déclaré sans couverture » qui échouait avec la révision 1 (« implémentée » au lieu de « planifiée » ou « à planifier »), et un domaine de deux exigences cité par une fiche (jamais reconnu « planifiée » avant correction de la lecture des identifiants) |

## Écarts ouverts

- Aucun.
