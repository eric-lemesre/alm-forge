# 17. Journalisation

Règles de journalisation des projets Rust instanciés depuis le gabarit.
Décision : [ADR-0022](../adr/0022-journaliser-selon-des-regles-verifiees.md) ;
exigences du gabarit (domaine gouvernance) : `req~journalisation-verifiee~1`
et `req~journal-erreur-sans-debug~1`.

Le journal sert l'exploitation et la sécurité : savoir ce qui s'est passé,
pour qui, combien de temps, et pourquoi ça a échoué — sans jamais devenir une
fuite de secrets ni de données. Ce chapitre fait foi ; une compétence d'agent
qui le reprend est un adaptateur sans règle propre (ch. 9).

## Ce que la porte vérifie

`tools/journalisation.sh` (étape de `tools/ci.sh`) constate, sur les fichiers
`src/**/*.rs` suivis par git, les cinq règles qu'un outil juge sans
compiler :

| Règle | Constat qui fait échouer |
| --- | --- |
| A — règle 1 | une bibliothèque (paquet doté d'un `src/lib.rs`, hors `src/main.rs` et `src/bin/`) installe l'abonné : `set_global_default`, `.init()` d'un abonné `tracing_subscriber`, `env_logger` |
| B — règle 2 | un `#[instrument]` sans `skip_all` |
| C — règle 2 | un type qui dérive `Debug` porte un secret en `String` ou `Option<String>` (champ ou nouveau type dont le nom désigne un secret ; liste réglable par `JOURNAL_MOTS_SECRETS`) |
| D — règle 1 | une bibliothèque écrit par `println!`, `eprintln!`, `print!`, `eprint!` ou `dbg!` |
| E — règle 3 | un événement (`trace!` à `error!`) enregistre une erreur par son `Debug` : `?error`, `?err`, `?e`, `?cause`, ou `erreur = ?…` (binaires compris ; D-2026-11-04) |

Dérogation : `// journal: admis — <raison>` sur la ligne ou celle qui la
précède ; sans raison, elle ne compte pas. Limites assumées : lecture
textuelle, module de tests supposé en fin de fichier. Les autres règles
relèvent de la revue (ch. 7) et des tests du projet (règle 8).

## Règle 1 — `tracing`, structuré, initialisé par le seul binaire

- Écosystème : `tracing` (émission), `tracing-subscriber` (fonctions
  `env-filter`, `json`), `tracing-journald` pour systemd, `tower-http`
  (fonctions `trace`, `request-id`) pour un service HTTP. Versions
  épinglées par `Cargo.lock` ; vérifier la version courante avant ajout.
- Événements **structurés** : `info!(depot = %nom, duree_ms, "index reconstruit")`,
  jamais `info!("index {nom} reconstruit en {duree} ms")`. Le message est
  une constante ; les valeurs sont des champs.
- **Une bibliothèque émet, elle n'initialise jamais.** Aucun
  `tracing_subscriber::…::init()` ni `set_global_default` hors de `main.rs`
  (ou d'un module `journal` appelé par `main`). Une crate embarquée ne
  confisque pas le journal de son hôte.
- `println!` est réservé à la **sortie** d'une commande (le résultat que
  l'utilisateur ou un script consomme) ; tout diagnostic passe par
  `tracing`. `eprintln!` ne subsiste que pour l'erreur finale de `main`
  quand l'abonné n'a pas pu être installé.

## Règle 2 — les secrets sont écartés par le type

C'est le piège principal : `#[instrument]` enregistre par défaut **tous**
les arguments via `Debug`. Une fonction qui reçoit un jeton le fait fuir.

- Tout secret (jeton, mot de passe, clé, secret OAuth, DSN avec mot de
  passe) vit dans un type dont `Debug`/`Display` masquent la valeur :
  `secrecy::SecretString` ou un nouveau type maison
  (`impl fmt::Debug → "Jeton(***)"`). Jamais une `String` nue qui circule.
- Tout `#[instrument]` porte `skip_all` et liste ses champs :
  `#[instrument(skip_all, fields(depot = %depot))]`.
- Un `Debug` dérivé sur une structure de réglages qui contient un secret
  est interdit tant que le champ n'est pas d'un type masquant.
- Un message d'erreur ne cite jamais un secret (le tester : voir règle 8).

## Règle 3 — pas de contenu métier ni de donnée personnelle

- Ne jamais journaliser : corps de requête ou de réponse, question posée,
  texte de document, adresse électronique, nom, identifiant d'une personne,
  en-tête `Authorization`, cookie, paramètre d'URL brut.
- Journaliser des **mesures** à la place : longueur, nombre de résultats,
  date demandée, statut, durée.
- Un mode diagnostic qui journalise un contenu est une **option explicite,
  désactivée par défaut**, documentée, et signalée au démarrage par un
  `warn!`.
- **Erreurs des clients HTTP** : l'affichage d'une erreur `reqwest` reprend
  l'URL complète, paramètres compris (`?q=<saisie>`) — journaliser
  `erreur.without_url()`, jamais l'erreur brute. Même prudence avec le
  `Debug` d'une erreur de base de données (`sqlx`), qui peut citer des
  valeurs : journaliser le genre d'erreur, pas son `Debug`.
- Un motif de refus construit à partir d'une donnée reçue (adresse d'un
  expéditeur, identifiant saisi) est nettoyé AVANT d'être journalisé, comme
  il l'est avant d'être enregistré.
- Route : la **route générique** (`MatchedPath`, ex. `/depots/{nom}/recherche`),
  jamais le chemin brut (données dedans, injection de lignes).

## Règle 4 — un span par unité de travail, avec corrélation

- Service HTTP : chaque requête ouvre un span portant `id_requete`, méthode,
  route générique, et — une fois l'accès contrôlé — le client et la
  ressource. Tout événement émis pendant la requête, bibliothèque comprise,
  en hérite.
- **Identifiant de corrélation** : lire `X-Request-Id` entrant, sinon en
  générer un (UUID), le placer dans le span et le **renvoyer** dans la
  réponse (`tower_http::request_id::{SetRequestIdLayer, PropagateRequestIdLayer}`).
  Un client qui appelle un autre service **transmet** son identifiant.
- Tâche de fond, commande longue, reconstruction d'index : un span propre
  (`info_span!("reconstruction", depot = %nom)`), pour mesurer et relier.
- Fin de requête : un seul événement `info!` (statut, durée) par
  `TraceLayer`, réglé pour ne pas journaliser en-têtes ni corps.

## Règle 5 — niveaux et cibles

| Niveau | Usage |
| ------ | ----- |
| `error` | défaillance du service : 5xx, ressource indisponible, invariant rompu |
| `warn` | anomalie qui n'empêche pas de servir : refus d'accès, réglage douteux, mode diagnostic actif |
| `info` | cycle de vie (démarrage, arrêt, rechargement) et une ligne par requête |
| `debug` | détail utile au développement, jamais activé en production par défaut |
| `trace` | pas-à-pas ; jamais en production |

- Une 4xx du client est `info` (ou `debug`) — sauf refus d'accès, `warn`.
- **Cibles séparées** : les événements d'accès et de sécurité sous une
  cible dédiée (`target: "<crate>::acces"`), distincte du fonctionnement,
  pour les filtrer, conserver ou expédier à part.
- **Une erreur est journalisée une seule fois**, à la frontière (gestionnaire
  HTTP, `main`, boucle de tâche), avec sa chaîne de causes. Jamais « journaliser
  puis propager » : elle apparaîtrait deux fois.

## Règle 6 — réglage par l'environnement et par la configuration

- Filtre au format `EnvFilter` (`info,ma_crate::acces=warn`), lu dans une
  variable propre au projet (`<PROJET>_JOURNAL`), à défaut dans le fichier
  de configuration (`[journal] filtre = …`), à défaut `info`. Priorité :
  option de commande > environnement > fichier > défaut. `RUST_LOG` n'est
  lu qu'en repli, s'il est documenté.
- Format : `texte` (défaut interactif) ou `json` (collecteur), par
  `<PROJET>_JOURNAL_FORMAT` ou le fichier.
- Sortie : **la sortie d'erreur**. Pas de fichier de journal ni de rotation
  dans l'application : c'est le rôle de journald, du conteneur ou du
  collecteur.

## Règle 7 — journald natif sous systemd

journald ne connaît la gravité d'une ligne de la sortie d'erreur que par
un préfixe `<N>`, que `tracing-subscriber` n'écrit pas : sans précaution,
tout arrive au même niveau et `journalctl -p warning` ne filtre plus rien ;
journald horodate en plus, d'où des dates en double.

- Utiliser la couche `tracing-journald` (priorité et champs structurés
  transmis) seulement quand `JOURNAL_STREAM` désigne **la sortie
  d'erreur elle-même** : comparer son « périphérique:inode » à celui de
  la sortie d'erreur (`/proc/self/fd/2` sous Linux, `fstat(2)` ailleurs).
  Sa seule présence ne suffit pas : la variable est héritée par tout
  processus lancé depuis une session systemd, et un serveur dont la sortie
  d'erreur est redirigée écrirait alors à journald (constat : des tests
  d'intégration qui lisaient la sortie d'erreur du serveur restaient
  bloqués).
- Sinon, sortie d'erreur en texte ou JSON.
- Repli : si la couche journald ne s'ouvre pas, revenir à la sortie
  d'erreur et le dire par un `warn!`.

## Règle 8 — les tests prouvent l'absence de fuite

- Un test capture le journal (un `MakeWriter` vers un tampon partagé) d'un
  parcours sensible
  (requête refusée, requête réussie avec contenu) et vérifie que ni le
  jeton, ni le contenu, ni l'en-tête `Authorization` n'y figurent.
- **Capturer de façon déterministe.** Un abonné propre au fil
  (`set_default`, `with_default`) ou à la future (`with_subscriber`)
  dépend du cache d'intérêt de `tracing`, partagé entre les fils : quand
  d'autres tests du même binaire émettent en parallèle, des événements
  manquent au hasard (constat : test vert seul, rouge sous la couverture).
  Installer UN abonné global par binaire de test (`set_global_default`
  dans un `OnceLock`), et distinguer ses événements par une valeur propre
  au test ; ou, pour un service, lire la sortie d'erreur du processus
  lancé par le test, ou lancer chaque test dans son propre processus
  (nextest).
- Un test vérifie que l'identifiant de corrélation entrant ressort dans la
  réponse et dans le journal.
- Un test vérifie qu'aucune `Debug` d'un type de réglages ne contient le
  secret (`format!("{reglages:?}")`).

## Points d'attention

- **Adresse source derrière un mandataire** : `X-Forwarded-For` n'est lu
  que si les mandataires de confiance sont déclarés ; sinon l'adresse du
  pair fait foi (l'en-tête est falsifiable).
- **Inondation** : un refus d'accès répété (force brute) ne doit pas
  noyer le journal ; prévoir limitation de débit ou agrégation quand le
  service est exposé.
- **Métriques ≠ journal** : les durées dans la ligne de requête suffisent
  à petite échelle ; au-delà, des métriques (Prometheus, OpenTelemetry par
  `tracing-opentelemetry`) — décision à part.
- **Injection** : en format texte, ne jamais placer une chaîne venue du
  client dans le message ; en champ, elle est échappée par le formateur.

## Audit d'un dépôt existant

Pour chaque point, citer `fichier:ligne` (ou « absent ») :

1. Dépendances de journal et leur version ; abonné installé où ?
   (`rg "tracing_subscriber|set_global_default|env_logger|init\(\)"`)
2. Diagnostics hors `tracing` : `rg "println!|eprintln!|dbg!"` hors sortie
   de commande et tests.
3. Secrets : types qui les portent, `Debug` dérivés,
   `rg "#\[instrument"` sans `skip_all`.
4. Contenu métier ou personnel dans un événement ou un span.
5. Span par requête, identifiant de corrélation (entrant, sortant, transmis
   aux services appelés).
6. Niveaux, cible d'accès séparée, double journalisation des erreurs.
7. Réglage (variable, fichier, défaut) et format ; journald.
8. Tests de non-fuite.

Chaque écart reçoit une gravité (bloquant : fuite de secret ou de donnée ;
majeur : pas de corrélation, abonné dans une bibliothèque, pas de
journal ; mineur : niveaux, format, journald) et une correction proposée.
