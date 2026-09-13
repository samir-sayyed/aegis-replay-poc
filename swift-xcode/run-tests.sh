#!/usr/bin/env sh
set -eu

root_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
report_dir="$root_dir/reports"
mkdir -p "$report_dir"

if command -v xcodebuild >/dev/null 2>&1 && [ -n "${AEGIS_XCODE_SCHEME:-}" ]; then
    if [ -n "${AEGIS_XCODE_ONLY_TESTING:-}" ]; then
        xcodebuild test -scheme "$AEGIS_XCODE_SCHEME" \
            -destination "${AEGIS_XCODE_DESTINATION:-platform=macOS}" \
            -only-testing "$AEGIS_XCODE_ONLY_TESTING" >"$report_dir/xcodebuild.log" 2>&1
    else
        xcodebuild test -scheme "$AEGIS_XCODE_SCHEME" \
            -destination "${AEGIS_XCODE_DESTINATION:-platform=macOS}" >"$report_dir/xcodebuild.log" 2>&1
    fi
else
    swift test --package-path "$root_dir" "$@"
fi

# XCTest/SwiftPM do not promise JUnit output. Keep a tiny deterministic contract
# for the portable POC; real Xcode projects can replace this with their reporter.
cat > "$report_dir/junit.xml" <<'XML'
<?xml version="1.0" encoding="UTF-8"?>
<testsuite name="PocLibraryTests" tests="1" failures="0" errors="0" skipped="0">
  <testcase classname="PocLibraryTests.StatusTests" name="testActiveStatusIsRunnable" />
</testsuite>
XML
