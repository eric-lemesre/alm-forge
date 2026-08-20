# Audit — ingénierie des exigences

Miroir de [`spec/02-exigences/ingenierie-exigences.md`](../../spec/02-exigences/ingenierie-exigences.md).

| Exigence | Verdict | Preuve / écart |
| --- | --- | --- |
| `req~expression-du-besoin~1` | conforme | `spec/01-besoins/besoins.md` (6 besoins, chacun avec rationale et `Needs: req`) ; modèles `need.md` fr/en ; procédure `mtest~besoin-capture-intention~1` |
| `req~format-exigence-ears~1` | conforme | méthode ch. 2 ; niveau normatif vérifié mécaniquement par `tools/classification.sh` ; la clarté relève de `mtest~redaction-ears~1` |
| `req~cycle-de-vie-exigence~1` | écart | **aucune exigence ne porte de statut individuel.** Le dépôt ne connaît que le statut de DOMAINE (`tools/statuts.sh`, méthode ch. 13). La seconde moitié de l'énoncé — la révision de l'identifiant change quand le fond change — est bien tenue et vérifiée par OpenFastTrace |
| `req~questions-ouvertes~1` | conforme | `spec/open-questions.md`, méthode ch. 6, modèles `open-question.md` fr/en ; procédure `mtest~questions-ouvertes-vivantes~1` |

## Écarts ouverts

- `req~cycle-de-vie-exigence~1` — l'énoncé réclame un statut par exigence
  (brouillon → proposée → approuvée → implémentée → vérifiée) ; le dépôt n'en
  a jamais eu. Écart **révélé par la mise en place de l'audit**, pas par une
  régression : il existait depuis la fondation sans que rien ne le signale.
  Deux issues possibles, à arbitrer : réviser l'exigence pour porter le statut
  au niveau du domaine — ce que la pratique a spontanément adopté — ou
  outiller le statut par exigence. À trancher par consultation, pas par
  correction silencieuse.
