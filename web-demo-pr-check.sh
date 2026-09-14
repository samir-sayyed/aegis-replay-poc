#!/usr/bin/env bash
set -euo pipefail

base_ref="${GITHUB_BASE_REF:-main}"
git fetch origin "$base_ref" --depth=1
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
aegis "${arguments[@]}"
