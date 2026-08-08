# alm-forge

**ALM template repository: from expressed need to mechanized tests,
language-agnostic and agent-agnostic.**

The normative documentation lives in French (see [README.md](README.md) and
`docs/methode/`); artefact templates are provided in both languages under
`templates/en/` and `templates/fr/`.

What you get when you instantiate this template:

- **Needs and requirements as code**: needs (feat items) declined into
  requirements written with the [EARS](https://alistairmavin.com/ears/) syntax,
  with normative levels and Given/When/Then acceptance criteria.
- **Architecture Decision Records**: a chartered ADR register derived from
  [MADR](https://adr.github.io/madr/), with a mandatory, mechanically checked
  Verification section — accepted ADRs are immutable.
- **Mechanized traceability**: the whole chain need → requirement → design →
  implementation → test is verified by
  [OpenFastTrace](https://github.com/itsallcode/openfasttrace) — coverage tags
  live in code comments of any language; a missing link fails the commit
  (git hooks) and the CI. No hand-maintained matrix.
- **Open-question protocol**: a blocked contributor (human or AI agent) stops
  and files a structured question (context, options, recommendation); a human
  arbitrates; the decision is traced to an ADR.
- **Agent governance**: a single authoritative AGENTS.md contract with
  numbered, tool-verified rules; per-agent adapter files contain no rules of
  their own.
- **A multi-language example** (Python, Rust, shell) running the full chain,
  scanned by the same gate as the rest of the repository.

Quick start: `just hooks && just ci` — prerequisites: git, just, bash, curl,
Java 17+. Licence: [MIT](LICENSE).
