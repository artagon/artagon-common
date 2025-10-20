#!/usr/bin/env bash
# Test helper functions for integration tests

# Test assertion helpers
FAILED_TESTS=0
PASSED_TESTS=0

assert_file_exists() {
  local file="$1"
  if [[ -f "$file" ]]; then
    echo "✓ File exists: $file"
    ((PASSED_TESTS++))
    return 0
  else
    echo "✗ File does not exist: $file"
    ((FAILED_TESTS++))
    return 1
  fi
}

assert_file_contains() {
  local file="$1"
  local pattern="$2"
  if [[ ! -f "$file" ]]; then
    echo "✗ File does not exist: $file"
    ((FAILED_TESTS++))
    return 1
  fi

  if grep -q "$pattern" "$file"; then
    echo "✓ File contains pattern: $pattern"
    ((PASSED_TESTS++))
    return 0
  else
    echo "✗ File does not contain pattern: $pattern"
    echo "  File: $file"
    ((FAILED_TESTS++))
    return 1
  fi
}

assert_file_not_contains() {
  local file="$1"
  local pattern="$2"
  if [[ ! -f "$file" ]]; then
    echo "✗ File does not exist: $file"
    ((FAILED_TESTS++))
    return 1
  fi

  if ! grep -q "$pattern" "$file"; then
    echo "✓ File does not contain pattern: $pattern"
    ((PASSED_TESTS++))
    return 0
  else
    echo "✗ File contains pattern (should not): $pattern"
    echo "  File: $file"
    ((FAILED_TESTS++))
    return 1
  fi
}

assert_dir_exists() {
  local dir="$1"
  if [[ -d "$dir" ]]; then
    echo "✓ Directory exists: $dir"
    ((PASSED_TESTS++))
    return 0
  else
    echo "✗ Directory does not exist: $dir"
    ((FAILED_TESTS++))
    return 1
  fi
}

assert_symlink_exists() {
  local link="$1"
  if [[ -L "$link" ]]; then
    echo "✓ Symlink exists: $link"
    ((PASSED_TESTS++))
    return 0
  else
    echo "✗ Symlink does not exist: $link"
    ((FAILED_TESTS++))
    return 1
  fi
}

assert_symlink_points_to() {
  local link="$1"
  local target="$2"
  if [[ ! -L "$link" ]]; then
    echo "✗ Not a symlink: $link"
    ((FAILED_TESTS++))
    return 1
  fi

  local actual_target
  actual_target="$(readlink "$link")"
  if [[ "$actual_target" == "$target" ]]; then
    echo "✓ Symlink points to: $target"
    ((PASSED_TESTS++))
    return 0
  else
    echo "✗ Symlink points to wrong target: $actual_target (expected: $target)"
    ((FAILED_TESTS++))
    return 1
  fi
}

print_test_summary() {
  echo ""
  echo "========================================"
  echo "TEST SUMMARY"
  echo "========================================"
  echo "Passed: $PASSED_TESTS"
  echo "Failed: $FAILED_TESTS"

  if [[ $FAILED_TESTS -eq 0 ]]; then
    echo "All tests passed!"
    return 0
  else
    echo "Some tests failed."
    return 1
  fi
}

# Test environment helpers
create_test_env() {
  local test_dir
  test_dir="$(mktemp -d)"
  echo "$test_dir"
}

cleanup_test_env() {
  local test_dir="$1"
  if [[ -n "$test_dir" && -d "$test_dir" ]]; then
    rm -rf "$test_dir"
  fi
}

# Run command without errexit (set -e) enabled
# Usage: if run_without_errexit <command> [args...]; then ... fi
# This temporarily disables set -e to allow the command to fail without
# exiting the script. Use in conditionals to handle both success and failure.
run_without_errexit() {
  set +e
  "$@"
  local exit_code=$?
  set -e
  return $exit_code
}
