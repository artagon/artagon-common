#!/usr/bin/env bash
# Master test runner for integration tests
#
# Runs all integration test suites and reports results

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

PASSED=0
FAILED=0

echo "======================================"
echo "Integration Test Suite"
echo "======================================"
echo ""

# Test 1: Template files exist
echo "Test: Template files exist"
if [[ -f "$ROOT_DIR/templates/CONTRIBUTING.md.template" ]] && \
   [[ -f "$ROOT_DIR/templates/README.md" ]]; then
  echo "✓ Templates exist"
  ((PASSED++))
else
  echo "✗ Templates missing"
  ((FAILED++))
fi

# Test 2: Scripts exist and are executable
echo "Test: Setup scripts exist and are executable"
SCRIPTS=(
  "$ROOT_DIR/scripts/repo_setup.sh"
  "$ROOT_DIR/scripts/gh_setup_contributing.sh"
  "$ROOT_DIR/scripts/gh_sync_agents.sh"
)

ALL_EXEC=true
for script in "${SCRIPTS[@]}"; do
  if [[ ! -x "$script" ]]; then
    echo "✗ Not executable: $(basename "$script")"
    ALL_EXEC=false
    break
  fi
done

if $ALL_EXEC; then
  echo "✓ All scripts executable"
  ((PASSED++))
else
  ((FAILED++))
fi

# Test 3: Script syntax validation
echo "Test: Script syntax validation"
SYNTAX_OK=true
for script in "${SCRIPTS[@]}"; do
  if ! bash -n "$script" 2>/dev/null; then
    echo "✗ Syntax error: $(basename "$script")"
    SYNTAX_OK=false
    break
  fi
done

if $SYNTAX_OK; then
  echo "✓ All scripts have valid syntax"
  ((PASSED++))
else
  ((FAILED++))
fi

# Test 4: Template contains variables
echo "Test: Template contains required variables"
if grep -q "{{ repository.name }}" "$ROOT_DIR/templates/CONTRIBUTING.md.template" && \
   grep -q "{{ repository.owner }}" "$ROOT_DIR/templates/CONTRIBUTING.md.template" && \
   grep -q "{{ repository.description }}" "$ROOT_DIR/templates/CONTRIBUTING.md.template"; then
  echo "✓ Template variables present"
  ((PASSED++))
else
  echo "✗ Template variables missing"
  ((FAILED++))
fi

# Test 5: repo_setup.sh integrates CONTRIBUTING.md generation
echo "Test: repo_setup.sh integrates CONTRIBUTING.md setup"
if grep -q "gh_setup_contributing" "$ROOT_DIR/scripts/repo_setup.sh"; then
  echo "✓ CONTRIBUTING.md integration present"
  ((PASSED++))
else
  echo "✗ CONTRIBUTING.md integration missing"
  ((FAILED++))
fi

# Test 6: Agent sync scripts exist
echo "Test: Agent configuration scripts exist"
if [[ -x "$ROOT_DIR/scripts/gh_sync_agents.sh" ]] && \
   [[ -x "$ROOT_DIR/scripts/gh_sync_claude.sh" ]]; then
  echo "✓ Agent scripts exist"
  ((PASSED++))
else
  echo "✗ Agent scripts missing"
  ((FAILED++))
fi

# Test 7: Test helpers exist
echo "Test: Test helper utilities exist"
if [[ -f "$SCRIPT_DIR/helpers/test-helpers.sh" ]]; then
  echo "✓ Test helpers exist"
  ((PASSED++))
else
  echo "✗ Test helpers missing"
  ((FAILED++))
fi

# Test 8: Integration test documentation
echo "Test: Integration testing documentation exists"
if grep -q "Integration Testing" "$ROOT_DIR/TESTING.md"; then
  echo "✓ Documentation present"
  ((PASSED++))
else
  echo "✗ Documentation missing"
  ((FAILED++))
fi

# Summary
echo ""
echo "======================================"
echo "TEST SUMMARY"
echo "======================================"
echo "Passed: $PASSED"
echo "Failed: $FAILED"
echo ""

if [[ $FAILED -eq 0 ]]; then
  echo "All tests passed!"
  exit 0
else
  echo "Some tests failed."
  exit 1
fi
