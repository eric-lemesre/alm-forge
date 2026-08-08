# Requirements — {{ domain }} domain

<!-- Goes into spec/02-exigences/. One file per functional domain. -->

## {{ Readable requirement title }}

`req~kebab-name~1`

{{ EARS phrasing with SHALL / SHOULD / MAY normative level:
- Ubiquitous: The system SHALL …
- Event-driven: When <trigger>, the system SHALL …
- State-driven: While <state>, the system SHALL …
- Unwanted behaviour: If <unwanted condition>, then the system SHALL …
- Optional feature: Where <feature is present>, the system SHALL … }}

Rationale:
{{ Justification, when the motive is not obvious. }}

Acceptance criteria:

- Given {{ context }}, when {{ action }}, then {{ verifiable outcome }}.
- Given {{ adverse case }}, when {{ action }}, then {{ expected behaviour }}.

Covers:

- feat~parent-need~1

Needs: impl, utest

<!-- Needs according to the declared verification level: dsn when a design
     decision is expected; utest / itest / stest / mtest depending on the test
     level (method, ch. 5). -->
