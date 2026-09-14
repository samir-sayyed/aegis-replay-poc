#!/usr/bin/env bash
set -euo pipefail

known_bad="$(mktemp)"
alternate_bad="$(mktemp)"
trap 'rm -f "$known_bad" "$alternate_bad"' EXIT

sed -i.bak 's/return items.filter/return [] as Item[];\/\/ return items.filter/' typescript-jest/src/filter.ts
rm typescript-jest/src/filter.ts.bak
git diff -- typescript-jest/src/filter.ts > "$known_bad"
sed -i.bak 's/return \[\] as Item\[\];\/\/ return items.filter/return items.slice(0, 0);\/\/ return items.filter/' typescript-jest/src/filter.ts
rm typescript-jest/src/filter.ts.bak
git diff -- typescript-jest/src/filter.ts > "$alternate_bad"
git checkout -- typescript-jest/src/filter.ts

aegis antibody create jest-proof-demo \
  --directory . \
  --invariant 'Category filtering retains matching item.' \
  --target typescript-jest \
  --test 'byCategory retains items in the requested category#byCategory retains items in the requested category' \
  --scope typescript-jest/src \
  --proof-input source_revision=aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
git add .aegis/antibodies
git -c user.email=poc@example.invalid -c user.name='Aegis POC' commit -m 'record Jest POC antibody'

aegis prove jest-proof-demo --directory . --known-bad "$known_bad" --alternate-bad "$alternate_bad" --control 'byCategory returns an empty list when category is unknown#byCategory returns an empty list when category is unknown'
python - <<'PY'
import json
from pathlib import Path

proof = json.loads(Path(".aegis/proofs/jest-proof-demo.json").read_text())
source = proof["source_commit"]
Path(".aegis/jest-review.json").write_text(json.dumps({"pull_request": {"head": {"sha": source}}, "reviews": [{"user": {"login": "poc-owner"}, "state": "APPROVED", "dismissed_at": None, "commit_id": source}]}))
PY
aegis approve jest-proof-demo --directory . --github-fixture .aegis/jest-review.json --required-owner poc-owner
aegis guard --directory . --changed typescript-jest/src/filter.ts
