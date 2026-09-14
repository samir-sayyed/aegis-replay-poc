#!/usr/bin/env bash
set -euo pipefail

known_bad="$(mktemp)"
alternate_bad="$(mktemp)"
trap 'rm -f "$known_bad" "$alternate_bad"' EXIT

sed -i.bak 's/Hello, {name}!/Broken, {name}!/' python-pytest/src/poc/greeting.py
rm python-pytest/src/poc/greeting.py.bak
git diff -- python-pytest/src/poc/greeting.py > "$known_bad"
sed -i.bak 's/Broken, {name}!/Alternate, {name}!/' python-pytest/src/poc/greeting.py
rm python-pytest/src/poc/greeting.py.bak
git diff -- python-pytest/src/poc/greeting.py > "$alternate_bad"
git checkout -- python-pytest/src/poc/greeting.py

if [ ! -f .aegis/antibodies/python-proof-demo.json ]; then
  aegis antibody create python-proof-demo \
  --directory . \
  --invariant 'Greeting preserves caller input case.' \
  --target python-pytest \
  --test 'tests.test_greeting#test_greeting_preserves_input_case' \
  --scope python-pytest/src \
    --proof-input source_revision=aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
  git add .aegis/antibodies
  git -c user.email=poc@example.invalid -c user.name='Aegis POC' commit -m 'record pytest POC antibody'
fi

aegis prove python-proof-demo --directory . --known-bad "$known_bad" --alternate-bad "$alternate_bad" --control 'tests.test_greeting#test_greeting_rejects_empty_name'
python - <<'PY'
import json
import subprocess
from pathlib import Path

head = subprocess.check_output(["git", "rev-parse", "HEAD"], text=True).strip()
Path(".aegis/python-review.json").write_text(json.dumps({"pull_request": {"head": {"sha": head}}, "reviews": [{"user": {"login": "poc-owner"}, "state": "APPROVED", "dismissed_at": None, "commit_id": head}]}))
PY
aegis approve python-proof-demo --directory . --github-fixture .aegis/python-review.json --required-owner poc-owner
git checkout -- .aegis/python-review.json
aegis guard --directory . --changed python-pytest/src/poc/greeting.py
git add .aegis/approvals .aegis/proofs .aegis/proof-inputs
git diff --cached --quiet || git -c user.email=poc@example.invalid -c user.name='Aegis POC' commit -m 'prove pytest POC invariant'
