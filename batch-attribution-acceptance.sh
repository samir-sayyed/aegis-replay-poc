#!/usr/bin/env bash
set -euo pipefail

# Config change selects every approved antibody in one guard request. Guard
# creates one adapter batch per target and attributes exact JUnit identities.
set +e
output="$(aegis guard --directory . --changed aegis.yaml)"
status=$?
set -e
printf '%s\n' "$output"
test "$status" -eq 0
grep -q 'Aegis guard: pass' <<<"$output"
