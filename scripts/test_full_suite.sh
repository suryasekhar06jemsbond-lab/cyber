#!/usr/bin/env sh
set -e

echo "Running full Nyx test suite..."

# Run the comprehensive language test
./nyx examples/comprehensive.ny

# Run standard test scripts if they exist
if [ -f "./scripts/test_v0.sh" ]; then ./scripts/test_v0.sh; fi
if [ -f "./scripts/test_v1.sh" ]; then ./scripts/test_v1.sh; fi
if [ -f "./scripts/test_v2.sh" ]; then ./scripts/test_v2.sh; fi
if [ -f "./scripts/test_v3_start.sh" ]; then ./scripts/test_v3_start.sh; fi
if [ -f "./scripts/test_production.sh" ]; then ./scripts/test_production.sh; fi

echo "Full test suite completed successfully."