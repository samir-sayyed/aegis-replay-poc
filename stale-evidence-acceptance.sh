#!/usr/bin/env bash
set -euo pipefail

expect_invalid() {
  local output
  set +e
  output="$(aegis guard --directory . --changed swift-xcode/Sources/PocLibrary/Status.swift)"
  local status=$?
  set -e
  test "$status" -ne 0
  printf '%s\n' "$output" | grep -q 'Aegis guard: invalid'
}

source_file=swift-xcode/Sources/PocLibrary/Status.swift
printf '\n// post-proof protected-source change\n' >> "$source_file"
expect_invalid
git checkout -- "$source_file"

jira_snapshot=.aegis/jira/POC-42.json
jira_backup="$(mktemp)"
trap 'cp "$jira_backup" "$jira_snapshot"; rm -f "$jira_backup"' EXIT
cp "$jira_snapshot" "$jira_backup"
sed -i.bak 's/Preserve active/Changed active/' "$jira_snapshot"
rm "$jira_snapshot.bak"
expect_invalid
