#!/usr/bin/env bash
# Integration tests for CONTRIBUTING.md generation (gh_setup_contributing.sh)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
HELPERS="$SCRIPT_DIR/helpers/test-helpers.sh"

# Load test helpers
# shellcheck source=tests/integration/helpers/test-helpers.sh
source "$HELPERS"

SETUP_SCRIPT="$ROOT_DIR/scripts/gh_setup_contributing.sh"
TEMPLATE="$ROOT_DIR/templates/CONTRIBUTING.md.template"

echo "Testing CONTRIBUTING.md generation"
echo "==================================="

# Test 1: Template file exists
test_template_exists() {
  echo ""
  echo "Test: Template file exists and is readable"
  assert_file_exists "$TEMPLATE"
}

# Test 2: Basic variable substitution
test_basic_substitution() {
  echo ""
  echo "Test: Basic variable substitution"

  local test_dir
  test_dir="$(create_test_env)"
  cd "$test_dir"

  # Initialize minimal git repo
  git init -q
  git config user.email "test@test.com"
  git config user.name "Test"

  # Create minimal structure
  mkdir -p .common/artagon-common
  cp -r "$ROOT_DIR/templates" .common/artagon-common/
  cp -r "$ROOT_DIR/scripts" .common/artagon-common/

  # Run script with explicit parameters
  run_and_capture_exit "$SETUP_SCRIPT" \
      --repo-name "test-project" \
      --repo-owner "test-org" \
      --repo-desc "Test description" \
      --force 2>&1
  local exit_code=$?

  if [[ $exit_code -eq 0 ]]; then
    assert_file_exists "CONTRIBUTING.md"
    assert_file_contains "CONTRIBUTING.md" "test-project"
    assert_file_contains "CONTRIBUTING.md" "test-org"
    assert_file_contains "CONTRIBUTING.md" "Test description"

    # Verify template variables were replaced
    assert_file_not_contains "CONTRIBUTING.md" "{{ repository.name }}"
    assert_file_not_contains "CONTRIBUTING.md" "{{ repository.owner }}"
    assert_file_not_contains "CONTRIBUTING.md" "{{ repository.description }}"
  else
    echo "✗ Script execution failed with exit code: $exit_code"
    ((FAILED_TESTS++))
  fi

  cleanup_test_env "$test_dir"
}

# Test 3: Special characters in description
test_special_characters() {
  echo ""
  echo "Test: Special characters in description are properly escaped"

  local test_dir
  test_dir="$(create_test_env)"
  cd "$test_dir"

  git init -q
  git config user.email "test@test.com"
  git config user.name "Test"

  mkdir -p .common/artagon-common
  cp -r "$ROOT_DIR/templates" .common/artagon-common/
  cp -r "$ROOT_DIR/scripts" .common/artagon-common/

  # Test with special sed characters: & | / \
  local desc="Project with & ampersand | pipe / slash \\ backslash"

  if "$SETUP_SCRIPT" \
      --repo-name "test-project" \
      --repo-owner "test-org" \
      --repo-desc "$desc" \
      --force >/dev/null 2>&1; then

    assert_file_exists "CONTRIBUTING.md"
    # Check that the special characters are preserved
    assert_file_contains "CONTRIBUTING.md" "ampersand"
    assert_file_contains "CONTRIBUTING.md" "pipe"
    assert_file_contains "CONTRIBUTING.md" "slash"
  else
    echo "✗ Script failed with special characters"
    ((FAILED_TESTS++))
  fi

  cleanup_test_env "$test_dir"
}

# Test 4: Empty description
test_empty_description() {
  echo ""
  echo "Test: Empty description handling"

  local test_dir
  test_dir="$(create_test_env)"
  cd "$test_dir"

  git init -q
  git config user.email "test@test.com"
  git config user.name "Test"

  mkdir -p .common/artagon-common
  cp -r "$ROOT_DIR/templates" .common/artagon-common/
  cp -r "$ROOT_DIR/scripts" .common/artagon-common/

  if "$SETUP_SCRIPT" \
      --repo-name "test-project" \
      --repo-owner "test-org" \
      --repo-desc "" \
      --force >/dev/null 2>&1; then

    assert_file_exists "CONTRIBUTING.md"
    assert_file_contains "CONTRIBUTING.md" "test-project"
  else
    echo "✗ Script failed with empty description"
    ((FAILED_TESTS++))
  fi

  cleanup_test_env "$test_dir"
}

# Test 5: Idempotency - running twice doesn't break things
test_idempotency() {
  echo ""
  echo "Test: Script is idempotent"

  local test_dir
  test_dir="$(create_test_env)"
  cd "$test_dir"

  git init -q
  git config user.email "test@test.com"
  git config user.name "Test"

  mkdir -p .common/artagon-common
  cp -r "$ROOT_DIR/templates" .common/artagon-common/
  cp -r "$ROOT_DIR/scripts" .common/artagon-common/

  # Run twice
  "$SETUP_SCRIPT" \
      --repo-name "test-project" \
      --repo-owner "test-org" \
      --repo-desc "Test" \
      --force >/dev/null 2>&1

  local first_content
  first_content="$(cat CONTRIBUTING.md)"

  "$SETUP_SCRIPT" \
      --repo-name "test-project" \
      --repo-owner "test-org" \
      --repo-desc "Test" \
      --force >/dev/null 2>&1

  local second_content
  second_content="$(cat CONTRIBUTING.md)"

  if [[ "$first_content" == "$second_content" ]]; then
    echo "✓ Content unchanged after second run"
    ((PASSED_TESTS++))
  else
    echo "✗ Content changed after second run"
    ((FAILED_TESTS++))
  fi

  cleanup_test_env "$test_dir"
}

# Test 6: Command-line parameter validation
test_parameter_validation() {
  echo ""
  echo "Test: Parameter validation"

  local test_dir
  test_dir="$(create_test_env)"
  cd "$test_dir"

  git init -q
  git config user.email "test@test.com"
  git config user.name "Test"

  mkdir -p .common/artagon-common
  cp -r "$ROOT_DIR/templates" .common/artagon-common/
  cp -r "$ROOT_DIR/scripts" .common/artagon-common/

  # Should fail without required parameters
  if ! "$SETUP_SCRIPT" --force >/dev/null 2>&1; then
    echo "✓ Script rejects missing parameters"
    ((PASSED_TESTS++))
  else
    echo "✗ Script should reject missing parameters"
    ((FAILED_TESTS++))
  fi

  cleanup_test_env "$test_dir"
}

# Test 7: Git auto-detection
test_git_autodetection() {
  echo ""
  echo "Test: Git repository auto-detection"

  local test_dir
  test_dir="$(create_test_env)"
  cd "$test_dir"

  # Initialize git with remote
  git init -q
  git config user.email "test@test.com"
  git config user.name "Test"
  git remote add origin "https://github.com/auto-owner/auto-repo.git"

  mkdir -p .common/artagon-common
  cp -r "$ROOT_DIR/templates" .common/artagon-common/
  cp -r "$ROOT_DIR/scripts" .common/artagon-common/

  # Run without explicit owner/name - should detect from git
  if "$SETUP_SCRIPT" --force >/dev/null 2>&1; then
    assert_file_exists "CONTRIBUTING.md"
    assert_file_contains "CONTRIBUTING.md" "auto-repo"
    assert_file_contains "CONTRIBUTING.md" "auto-owner"
  else
    echo "✗ Auto-detection failed"
    ((FAILED_TESTS++))
  fi

  cleanup_test_env "$test_dir"
}

# Run all tests
main() {
  test_template_exists
  test_basic_substitution
  test_special_characters
  test_empty_description
  test_idempotency
  test_parameter_validation
  test_git_autodetection

  print_test_summary
}

main
