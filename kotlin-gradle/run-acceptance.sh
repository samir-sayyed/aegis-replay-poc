#!/usr/bin/env bash
set -euo pipefail

known_bad="$(mktemp)"
alternate_bad="$(mktemp)"
trap 'rm -f "$known_bad" "$alternate_bad"' EXIT

sed -i.bak 's/status == "ok"/status == "healthy"/' kotlin-gradle/src/main/kotlin/poc/Health.kt
rm kotlin-gradle/src/main/kotlin/poc/Health.kt.bak
git diff -- kotlin-gradle/src/main/kotlin/poc/Health.kt > "$known_bad"
sed -i.bak 's/status == "healthy"/status == "okay"/' kotlin-gradle/src/main/kotlin/poc/Health.kt
rm kotlin-gradle/src/main/kotlin/poc/Health.kt.bak
git diff -- kotlin-gradle/src/main/kotlin/poc/Health.kt > "$alternate_bad"
git checkout -- kotlin-gradle/src/main/kotlin/poc/Health.kt

if [ ! -f .aegis/antibodies/gradle-proof-demo.json ]; then
  aegis antibody create gradle-proof-demo \
    --directory . \
    --invariant 'Only healthy status is accepted.' \
    --target kotlin-gradle \
    --test 'poc.HealthTest#healthyStatusIsAccepted()' \
    --scope kotlin-gradle/src \
    --proof-input source_revision=aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
  git add .aegis/antibodies
  git -c user.email=poc@example.invalid -c user.name='Aegis POC' commit -m 'record Gradle POC antibody'
fi

aegis prove gradle-proof-demo --directory . --known-bad "$known_bad" --alternate-bad "$alternate_bad" --control 'poc.HealthTest#otherStatusesAreRejected()'
python - <<'PY'
import json
from pathlib import Path

proof = json.loads(Path(".aegis/proofs/gradle-proof-demo.json").read_text())
source = proof["source_commit"]
Path(".aegis/gradle-review.json").write_text(json.dumps({"pull_request": {"head": {"sha": source}}, "reviews": [{"user": {"login": "poc-owner"}, "state": "APPROVED", "dismissed_at": None, "commit_id": source}]}))
PY
aegis approve gradle-proof-demo --directory . --github-fixture .aegis/gradle-review.json --required-owner poc-owner
aegis guard --directory . --changed kotlin-gradle/src/main/kotlin/poc/Health.kt
git add .aegis/approvals .aegis/proofs .aegis/proof-inputs
git diff --cached --quiet || git -c user.email=poc@example.invalid -c user.name='Aegis POC' commit -m 'prove Gradle POC invariant'
