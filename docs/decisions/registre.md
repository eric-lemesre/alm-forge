# Registre des décisions

Registre chronologique des décisions durables actées hors pull request (séance
ou consultation directe du décideur). Identifiant : D-AAAA-MM-NN. Chaque entrée
renvoie vers l'artefact qui la développe (ADR, relevé de séance). Les relevés
de séance sont archivés dans ce répertoire (modèle :
`templates/fr/decision-record.md`) et figés une fois actés.

| ID | Date | Décision | Développée dans |
| --- | --- | --- | --- |
| D-2026-08-01 | 2026-08-08 | alm-forge est un dépôt-gabarit instanciable (ni référentiel documentaire pur, ni framework publié) | [ADR-0001](../adr/0001-structurer-alm-forge-en-depot-gabarit.md) |
| D-2026-08-02 | 2026-08-08 | OpenFastTrace est le moteur de traçabilité | [ADR-0002](../adr/0002-tracer-les-exigences-avec-openfasttrace.md) |
| D-2026-08-03 | 2026-08-08 | Documentation normative en français, templates bilingues fr/en | [ADR-0005](../adr/0005-documentation-normative-francaise-templates-bilingues.md) |
| D-2026-08-04 | 2026-08-08 | Le dépôt est créé sous le nom alm-forge | — (décision d'intendance, pas d'ADR) |
| D-2026-08-05 | 2026-08-08 | Portes en scripts POSIX autonomes, orchestrateur en façade interchangeable (Task par défaut) | [ADR-0007](../adr/0007-orchestrateur-en-facade-interchangeable.md) |
| D-2026-08-06 | 2026-08-08 | L'attribution des agents dans les commits est à la discrétion de l'instanciateur (interdite par défaut) | [ADR-0008](../adr/0008-attribution-agents-arbitree-a-l-instanciation.md) |
| D-2026-08-07 | 2026-08-08 | La langue du dépôt (fr, en, fr-en) est à la discrétion de l'instanciateur (fr-en par défaut) | [ADR-0009](../adr/0009-langue-du-depot-arbitree-a-l-instanciation.md) |
| D-2026-08-08 | 2026-08-08 | Le gabarit fonctionne sur toute forge git : portes locales, CI en façades par forge (GitHub, GitLab fournies) | [ADR-0010](../adr/0010-ci-en-facades-par-forge.md) |
