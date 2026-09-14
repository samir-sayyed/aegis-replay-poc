#!/usr/bin/env bash
set -euo pipefail

base_ref="${GITHUB_BASE_REF:-main}"
git fetch origin "+refs/heads/$base_ref:refs/remotes/origin/$base_ref"
changed=()
while IFS= read -r path; do
  [ -n "$path" ] && changed+=("$path")
done < <(git diff --name-only "origin/$base_ref...HEAD" -- typescript-jest)

if [ "${#changed[@]}" -eq 0 ]; then
  echo "No web demo changes; skipping Aegis replay."
  exit 0
fi

arguments=(guard --directory .)
for path in "${changed[@]}"; do
  arguments+=(--changed "$path")
done

echo "Aegis selected: public catalog privacy antibody"
echo "Invariant: public catalog filtering must never expose internal products."
echo "Test: public product catalog / never exposes internal products in a public category"

set +e
output="$(aegis "${arguments[@]}")"
status=$?
set -e
printf '%s\n' "$output"

if [ "$status" -ne 0 ]; then
  message="Aegis blocked this PR: changed catalog code leaks an internal product. Restore the public visibility filter and push again."
  echo "::error title=Aegis regression caught::$message"
  if [ -n "${GITHUB_STEP_SUMMARY:-}" ]; then
    {
      echo "## Aegis blocked this PR"
      echo
      echo "$message"
      echo
      echo "- **Invariant:** Public catalog filtering never exposes internal products."
      echo "- **Selected test:** public product catalog / never exposes internal products in a public category"
      echo "- **Why this ran:** this PR changed `typescript-jest/src/filter.ts`."
    } >> "$GITHUB_STEP_SUMMARY"
  fi
  exit "$status"
fi
