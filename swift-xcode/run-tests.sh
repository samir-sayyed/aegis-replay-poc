#!/usr/bin/env sh
set -eu

root_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
report_dir="$root_dir/reports"
report_path="$report_dir/junit.xml"
mkdir -p "$report_dir"
rm -f "$report_path"

if command -v xcodebuild >/dev/null 2>&1 && [ -n "${AEGIS_XCODE_SCHEME:-}" ]; then
    echo "Xcode schemes need a configured result-to-JUnit reporter; SwiftPM POC uses native xUnit output." >&2
    exit 2
elif command -v swift >/dev/null 2>&1; then
    swift test --package-path "$root_dir" --xunit-output "$report_path" "$@"
else
    echo "Swift toolchain is required to run Swift POC tests." >&2
    exit 2
fi

for _ in $(seq 1 20); do
    test -s "$report_path" && exit 0
    sleep 0.1
done

test -s "$report_path" || {
    echo "Swift test run completed without native xUnit report: $report_path" >&2
    exit 2
}
