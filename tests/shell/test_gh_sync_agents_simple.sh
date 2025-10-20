#!/usr/bin/env bash
# Simplified test suite for scripts/gh_sync_agents.sh
# Focus on basic validation and critical functionality

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
SCRIPT_PATH="$ROOT_DIR/scripts/gh_sync_agents.sh"
FAILED=0

echo "Testing gh_sync_agents.sh"
echo "========================="

# Test 1: Script exists and is executable
if [[ -x "$SCRIPT_PATH" ]]; then
  echo "✓ Script is executable"
else
  echo "✗ Script not executable"
  ((FAILED++))
fi

# Test 2: Syntax check
if bash -n "$SCRIPT_PATH"; then
  echo "✓ Syntax is valid"
else
  echo "✗ Syntax errors found"
  ((FAILED++))
fi

# Test 3: Help output
if "$SCRIPT_PATH" --help 2>&1 | grep -q "Usage:"; then
  echo "✓ Help output works"
else
  echo "✗ Help output missing"
  ((FAILED++))
fi

# Test 4: Invalid option handling
if ! "$SCRIPT_PATH" --invalid-option >/dev/null 2>&1; then
  echo "✓ Invalid options rejected"
else
  echo "✗ Should reject invalid options"
  ((FAILED++))
fi

# Test 5: Dry-run mode basic test
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT
cd "$TMPDIR"
git init -q
git config user.email "test@test.com"
git config user.name "Test"
mkdir -p .agents-shared
echo "# Test" > .agents-shared/preferences.md
echo "# Test" > .agents-shared/project-context.md

set +e
OUTPUT=$(timeout 5 "$SCRIPT_PATH" --dry-run --models "claude" 2>&1)
set -e

if echo "$OUTPUT" | grep -q "\[DRY RUN\]"; then
  echo "✓ Dry-run mode works"
else
  echo "✗ Dry-run mode failed"
  echo "  Output: $OUTPUT"
  ((FAILED++))
fi

cd "$ROOT_DIR"

# Summary
echo "========================="
if [[ $FAILED -eq 0 ]]; then
  echo "All tests passed!"
  exit 0
else
  echo "$FAILED test(s) failed"
  exit 1
fi
