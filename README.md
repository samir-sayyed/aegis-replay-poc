# Aegis Replay public proof-of-concept

Licensed under [Apache-2.0](LICENSE). See [contributor guidance](CONTRIBUTING.md).

This directory is a small, public, polyglot project used to exercise Aegis Replay's
portable test contract. It intentionally keeps each sample independent: the
application code is tiny, the tests describe one stable behaviour, and every
target writes a JUnit XML report at the path declared in `../aegis.yaml`.

The samples are deliberately boring. Their job is to prove that Aegis can select
and run tests across different ecosystems, not to model a production application.

## Five-minute web demo

Use `typescript-jest/` for a lightweight judge demonstration. It models a public
product catalog containing one internal support dashboard. The protected rule is:
**a public category view must never expose internal products**.

The Jest acceptance script creates two isolated regressions: one drops visibility
filtering and leaks the dashboard; another ignores category filtering. Aegis proves
both fail, verifies fixed and control cases pass, records reviewer approval, then
replays only this focused web test when `typescript-jest/src/filter.ts` changes.

```bash
cd typescript-jest && npm ci && npm test
cd ..
./typescript-jest/run-acceptance.sh
aegis guard --directory . --changed typescript-jest/src/filter.ts
```

## Targets

| Target | Directory | Command | JUnit report |
| --- | --- | --- | --- |
| `kotlin-gradle` | `kotlin-gradle/` | `./gradlew test` | `kotlin-gradle/build/test-results/test/TEST-*.xml` |
| `swift-xcode` | `swift-xcode/` | `./run-tests.sh` | `swift-xcode/reports/junit.xml` |
| `typescript-jest` | `typescript-jest/` | `npm test` | `typescript-jest/reports/junit.xml` |
| `python-pytest` | `python-pytest/` | `python -m pytest` | `python-pytest/reports/junit.xml` |

Run one sample from its directory. The Kotlin, Swift, and Python samples use
only their standard toolchains. The Jest sample declares its reporter in
`package.json`; run `npm install` once before `npm test`.

Each test has a matching path and test name in the generated JUnit report. That
stable attribution is the contract consumed by Aegis Replay; a target that
cannot produce a report must be treated as invalid by the caller.

## Generic lifecycle

Linux CI runs `generic-command/run-acceptance.sh`: externally installed Aegis
creates an antibody, proves known-bad/fixed/alternate-bad states, approves a
recorded review fixture, then executes focused guard.

## Intentional mutation points

The fixtures contain one-line, reviewable behaviours that are useful for a
future antibody proof:

- return `true` for a healthy input;
- preserve the input's case when creating a greeting;
- reject an empty value;
- retain an item when filtering by its category.

The POC does not auto-generate mutations. A maintainer may create an isolated
known-bad or alternate-bad revision by changing one of those lines, then use
the normal Aegis proof workflow to verify the corresponding JUnit result.
