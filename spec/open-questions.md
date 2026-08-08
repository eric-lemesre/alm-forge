# Questions ouvertes

<!-- [impl->req~questions-ouvertes~1] -->

Registre des blocages en attente d'arbitrage humain. Protocole complet :
[méthode, ch. 6](../docs/methode/06-questions-ouvertes.md). Modèle :
`templates/fr/open-question.md`.

Règle : un contributeur (humain ou agent) bloqué par une ambiguïté du besoin,
un conflit de règles ou une décision qui ne lui appartient pas **s'arrête et
ouvre une entrée ici** plutôt que de trancher seul. Une question résolue reste
dans le registre (statut `resolved`), avec sa décision et le renvoi vers l'ADR
ou le relevé qui l'acte.

---

Aucune question ouverte à ce jour : le registre n'a pas encore servi. La
première entrée suivra le format ci-dessous.

```markdown
## OQ-001 — Titre court

- **Bloque** : req~identifiant~1
- **Contexte** : ce qui rend la décision nécessaire, en deux phrases.
- **Options** :
  - A) …
  - B) …
- **Recommandation** : B, car …
- **Décision** : (laissée vide jusqu'à l'arbitrage ; renvoyer vers l'ADR)
- **Statut** : open | resolved
```
