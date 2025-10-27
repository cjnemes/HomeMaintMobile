#!/bin/bash

# Coverage threshold check script for HomeMaint Mobile
# Ensures test coverage stays above 85%

set -e

echo "Checking code coverage threshold..."

# Run tests with coverage
xcodebuild test \
  -scheme HomeMaintMobile \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  -enableCodeCoverage YES \
  -resultBundlePath /tmp/TestResults.xcresult \
  -quiet

# Extract coverage percentage
COVERAGE=$(xcrun xccov view --report --json /tmp/TestResults.xcresult | \
  python3 -c "import sys, json; print(json.load(sys.stdin)['lineCoverage'])")

# Convert to percentage
COVERAGE_PERCENT=$(echo "$COVERAGE * 100" | bc)

echo "Current coverage: $COVERAGE_PERCENT%"

# Check threshold
THRESHOLD=85
if (( $(echo "$COVERAGE < 0.85" | bc -l) )); then
  echo "❌ FAILED: Coverage ($COVERAGE_PERCENT%) is below $THRESHOLD% threshold"
  echo "Please add tests to increase coverage before committing."
  exit 1
else
  echo "✅ PASSED: Coverage ($COVERAGE_PERCENT%) meets $THRESHOLD% threshold"
  exit 0
fi
