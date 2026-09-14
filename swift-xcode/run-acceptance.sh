#!/usr/bin/env bash
set -euo pipefail

known_bad="$(mktemp)"
alternate_bad="$(mktemp)"
trap 'rm -f "$known_bad" "$alternate_bad"' EXIT

sed -i.bak 's/self == .active/self == .paused/' swift-xcode/Sources/PocLibrary/Status.swift
rm swift-xcode/Sources/PocLibrary/Status.swift.bak
git diff -- swift-xcode/Sources/PocLibrary/Status.swift > "$known_bad"
sed -i.bak 's/self == .paused/false/' swift-xcode/Sources/PocLibrary/Status.swift
rm swift-xcode/Sources/PocLibrary/Status.swift.bak
git diff -- swift-xcode/Sources/PocLibrary/Status.swift > "$alternate_bad"
git checkout -- swift-xcode/Sources/PocLibrary/Status.swift

if [ ! -f .aegis/antibodies/swift-proof-demo.json ]; then
  aegis antibody create swift-proof-demo \
    --directory . \
    --invariant 'Only active Swift status is runnable.' \
    --target swift-xcode \
    --test 'PocLibraryTests.StatusTests#testActiveStatusIsRunnable' \
    --scope swift-xcode/Sources \
    --proof-input source_revision=aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
  git add .aegis/antibodies
  git -c user.email=poc@example.invalid -c user.name='Aegis POC' commit -m 'record Swift POC antibody'
fi

aegis jira capture --directory . --key POC-42 --jira-fixture .aegis/fixtures/jira/POC-42.json --antibody swift-proof-demo >/dev/null
aegis prove swift-proof-demo --directory . --known-bad "$known_bad" --alternate-bad "$alternate_bad" --control 'PocLibraryTests.StatusTests#testPausedStatusIsNotRunnable'
python - <<'PY'
import json
from pathlib import Path

proof = json.loads(Path('.aegis/proofs/swift-proof-demo.json').read_text())
source = proof['source_commit']
Path('.aegis/swift-review.json').write_text(json.dumps({'pull_request': {'head': {'sha': source}}, 'reviews': [{'user': {'login': 'poc-owner'}, 'state': 'APPROVED', 'dismissed_at': None, 'commit_id': source}]}))
PY
aegis approve swift-proof-demo --directory . --github-fixture .aegis/swift-review.json --required-owner poc-owner
aegis guard --directory . --changed swift-xcode/Sources/PocLibrary/Status.swift
git add .aegis/approvals .aegis/proofs .aegis/proof-inputs
git diff --cached --quiet || git -c user.email=poc@example.invalid -c user.name='Aegis POC' commit -m 'prove Swift POC invariant'
