#!/usr/bin/env bash
set -euo pipefail

# One guard request selects four portable target scopes. Guard creates one
# adapter batch per target and attributes exact JUnit identities.
for antibody in swift-proof-demo gradle-proof-demo python-proof-demo jest-proof-demo; do
  aegis antibody explain "$antibody" --directory .
done

set +e
output="$(aegis guard --directory . \
  --changed kotlin-gradle/src \
  --changed swift-xcode/Sources \
  --changed typescript-jest/src \
  --changed python-pytest/src)"
status=$?
set -e
printf '%s\n' "$output"
test "$status" -eq 0
grep -q 'Aegis guard: pass' <<<"$output"
