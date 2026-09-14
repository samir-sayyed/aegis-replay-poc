#!/usr/bin/env bash
set -euo pipefail

known_bad="$(mktemp)"
alternate_bad="$(mktemp)"
trap 'rm -f "$known_bad" "$alternate_bad"' EXIT

sed -i.bak 's/ && item.visibility === "public"//' typescript-jest/src/filter.ts
rm typescript-jest/src/filter.ts.bak
git diff -- typescript-jest/src/filter.ts > "$known_bad"
git checkout -- typescript-jest/src/filter.ts
sed -i.bak 's/item.category === category && //' typescript-jest/src/filter.ts
rm typescript-jest/src/filter.ts.bak
git diff -- typescript-jest/src/filter.ts > "$alternate_bad"
git checkout -- typescript-jest/src/filter.ts

if [ ! -f .aegis/antibodies/jest-proof-demo.json ]; then
  aegis antibody create jest-proof-demo \
  --directory . \
  --invariant 'Public catalog filtering never exposes internal products.' \
  --target typescript-jest \
  --test 'public product catalog#never exposes internal products in a public category' \
  --scope typescript-jest/src \
    --proof-input source_revision=aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
  git add .aegis/antibodies
  git -c user.email=poc@example.invalid -c user.name='Aegis POC' commit -m 'record Jest POC antibody'
fi

aegis prove jest-proof-demo --directory . --known-bad "$known_bad" --alternate-bad "$alternate_bad" --control 'public product catalog#returns an empty list when category is unknown'
python - <<'PY'
import json
from pathlib import Path

proof = json.loads(Path(".aegis/proofs/jest-proof-demo.json").read_text())
source = proof["source_commit"]
Path(".aegis/jest-review.json").write_text(json.dumps({"pull_request": {"head": {"sha": source}}, "reviews": [{"user": {"login": "poc-owner"}, "state": "APPROVED", "dismissed_at": None, "commit_id": source}]}))
PY
aegis approve jest-proof-demo --directory . --github-fixture .aegis/jest-review.json --required-owner poc-owner
git checkout -- .aegis/jest-review.json 2>/dev/null || rm -f .aegis/jest-review.json
aegis guard --directory . --changed typescript-jest/src/filter.ts
git add .aegis/approvals .aegis/proofs .aegis/proof-inputs
git diff --cached --quiet || git -c user.email=poc@example.invalid -c user.name='Aegis POC' commit -m 'prove Jest POC invariant'
