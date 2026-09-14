#!/usr/bin/env bash
set -euo pipefail

commit="$(git rev-parse HEAD)"
run_selection() {
  local changed="$1"
  local fixture="$2"
  local expected_fallback="$3"
  local output
  output="$(aegis select --directory . --changed "$changed" --semantic --commit "$commit" --semantic-response-file "$fixture" --manifest)"
  OUTPUT="$output" EXPECTED_FALLBACK="$expected_fallback" python - <<'PY'
import json
import os

result = json.loads(os.environ["OUTPUT"])
assert result["semantic"]["fallback"] is (os.environ["EXPECTED_FALLBACK"] == "true")
assert result["manifest"].startswith(".aegis/manifests/")
PY
}

# Direct TypeScript scope match plus recorded semantic addition.
run_selection typescript-jest/src/filter.ts .aegis/fixtures/semantic/additive.json false
# Moved behavior across Swift path: uncertainty must select all candidates.
run_selection swift-xcode/Sources/PocLibrary/Status.swift .aegis/fixtures/semantic/uncertain.json true
# Invalid recorded model response also fails safely to all candidates.
run_selection kotlin-gradle/src/main/kotlin/poc/Health.kt .aegis/fixtures/semantic/invalid.json true
