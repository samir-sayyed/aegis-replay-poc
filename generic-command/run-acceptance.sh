#!/usr/bin/env bash
set -euo pipefail

known_bad="$(mktemp)"
alternate_bad="$(mktemp)"
trap 'rm -f "$known_bad" "$alternate_bad"' EXIT

# CI target checks produce ignored reports and caches. Proof intentionally starts
# from a clean tracked workspace, so remove only ignored generated outputs.
git clean -fdX

printf 'known-bad\n' > generic-command/state.txt
git diff -- generic-command/state.txt > "$known_bad"
printf 'alternate-bad\n' > generic-command/state.txt
git diff -- generic-command/state.txt > "$alternate_bad"
git checkout -- generic-command/state.txt

aegis antibody create generic-proof-demo \
  --directory . \
  --invariant 'Generic invariant remains protected across replay states.' \
  --target generic-command \
  --test 'generic.InvariantTest#target_stays_fixed' \
  --scope generic-command/state.txt \
  --proof-input source_revision=aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
git add .aegis/antibodies
git -c user.email=poc@example.invalid -c user.name='Aegis POC' commit -m 'record generic POC antibody'

aegis prove generic-proof-demo --directory . --known-bad "$known_bad" --alternate-bad "$alternate_bad" --control 'generic.InvariantTest#control_confirms_fixed_state'
python generic-command/write_fixture.py
aegis approve generic-proof-demo --directory . --github-fixture .aegis/generic-review.json --required-owner poc-owner
aegis guard --directory . --changed generic-command/state.txt
