#!/usr/bin/env bash
# Simple integration tests for repo_setup.sh components
#
# These tests verify the core components used by repo_setup.sh
# without actually creating GitHub repositories

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
HELPERS="$SCRIPT_DIR/helpers/test-helpers.sh"

# Load test helpers
# shellcheck source=tests/integration/helpers/test-helpers.sh
source "$HELPERS"

echo "Testing repo_setup.sh components"
echo "================================="

# Test 1: Check script exists and is executable
test_script_exists() {
  echo ""
  echo "Test: repo_setup.sh exists and is executable"
  assert_file_exists "$ROOT_DIR/scripts/repo_setup.sh"

  if [[ -x "$ROOT_DIR/scripts/repo_setup.sh" ]]; then
    echo "✓ Script is executable"
    ((PASSED_TESTS++))
  else
    echo "✗ Script is not executable"
    ((FAILED_TESTS++))
  fi
}

# Test 2: Help output works
test_help_output() {
  echo ""
  echo "Test: Help output displays"

  if "$ROOT_DIR/scripts/repo_setup.sh" --help 2>&1 | grep -q "Usage:"; then
    echo "✓ Help output works"
    ((PASSED_TESTS++))
  else
    echo "✗ Help output missing or broken"
    ((FAILED_TESTS++))
  fi
}

# Test 3: Syntax check
test_syntax() {
  echo ""
  echo "Test: Script syntax is valid"

  if bash -n "$ROOT_DIR/scripts/repo_setup.sh"; then
    echo "✓ Syntax is valid"
    ((PASSED_TESTS++))
  else
    echo "✗ Syntax errors found"
    ((FAILED_TESTS++))
  fi
}

# Test 4: Parameter validation
test_parameter_validation() {
  echo ""
  echo "Test: Parameter validation"

  # Should fail without required parameters
  if ! "$ROOT_DIR/scripts/repo_setup.sh" >/dev/null 2>&1; then
    echo "✓ Rejects missing parameters"
    ((PASSED_TESTS++))
  else
    echo "✗ Should reject missing parameters"
    ((FAILED_TESTS++))
  fi
}

# Test 5: Invalid project type rejection
test_invalid_type() {
  echo ""
  echo "Test: Invalid project type rejection"

  if ! "$ROOT_DIR/scripts/repo_setup.sh" --type invalid --name test 2>&1 | grep -q "Invalid project type"; then
    echo "✗ Should reject invalid project type"
    ((FAILED_TESTS++))
  else
    echo "✓ Rejects invalid project type"
    ((PASSED_TESTS++))
  fi
}

# Test 6: CONTRIBUTING.md integration exists
test_contributing_integration() {
  echo ""
  echo "Test: CONTRIBUTING.md setup integration exists"

  if grep -q "gh_setup_contributing" "$ROOT_DIR/scripts/repo_setup.sh"; then
    echo "✓ CONTRIBUTING.md setup is integrated"
    ((PASSED_TESTS++))
  else
    echo "✗ CONTRIBUTING.md setup not found in repo_setup.sh"
    ((FAILED_TESTS++))
  fi
}

# Run all tests
main() {
  test_script_exists
  test_help_output
  test_syntax
  test_parameter_validation
  test_invalid_type
  test_contributing_integration

  print_test_summary
}

main
