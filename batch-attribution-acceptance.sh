#!/usr/bin/env bash
set -euo pipefail

# Config change selects every approved antibody in one guard request. Guard
# creates one adapter batch per target and attributes exact JUnit identities.
output="$(aegis guard --directory . --changed aegis.yaml)"
printf '%s\n' "$output"
grep -q 'Aegis guard: pass' <<<"$output"
