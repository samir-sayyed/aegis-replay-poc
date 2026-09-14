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
    log_path="$report_dir/swift-test.log"
    test_exit=0
    swift test --package-path "$root_dir" "$@" >"$log_path" 2>&1 || test_exit=$?
    cat "$log_path"
    testcase_count=$(sed -n \
        -e "s/.*Test Case '-\\[\\([^ ]*\\) \\([^]]*\\)\\]' passed.*/<testcase classname=\"\\1\" name=\"\\2\"\/>/p" \
        -e "s/.*Test Case '-\\[\\([^ ]*\\) \\([^]]*\\)\\]' failed.*/<testcase classname=\"\\1\" name=\"\\2\"><failure message=\"Swift test failed\"\/><\\/testcase>/p" \
        "$log_path" | wc -l | tr -d ' ')
    test "$testcase_count" -gt 0 || {
        echo "Swift test output did not contain any passed XCTest cases." >&2
        exit 2
    }
    {
        printf '%s\n' '<?xml version="1.0" encoding="UTF-8"?>'
        printf '<testsuite name="SwiftPM" tests="%s" failures="0" errors="0" skipped="0">\n' "$testcase_count"
        sed -n \
            -e "s/.*Test Case '-\\[\\([^ ]*\\) \\([^]]*\\)\\]' passed.*/  <testcase classname=\"\\1\" name=\"\\2\"\\/>/p" \
            -e "s/.*Test Case '-\\[\\([^ ]*\\) \\([^]]*\\)\\]' failed.*/  <testcase classname=\"\\1\" name=\"\\2\"><failure message=\"Swift test failed\"\\/><\\/testcase>/p" \
            "$log_path"
        printf '%s\n' '</testsuite>'
    } > "$report_path"
    test "$test_exit" -eq 0 || exit "$test_exit"
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
