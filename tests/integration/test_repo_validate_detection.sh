#!/usr/bin/env bash
# Integration tests for repo_validate.sh project type detection

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
HELPERS="$SCRIPT_DIR/helpers/test-helpers.sh"

# Load test helpers
# shellcheck source=tests/integration/helpers/test-helpers.sh
source "$HELPERS"

echo "Testing repo_validate.sh project detection"
echo "=========================================="

# Test: C project detection tolerates missing source directories
test_c_detection_without_source_tree() {
  echo ""
  echo "Test: repo_validate.sh handles C projects without src/include directories"

  local test_dir
  test_dir="$(create_test_env)"

  pushd "$test_dir" >/dev/null

  git init >/dev/null 2>&1

  cat > CMakeLists.txt <<'EOF'
cmake_minimum_required(VERSION 3.26)
project(sample-c LANGUAGES C)
EOF

  local output_file exit_code
  output_file="$test_dir/validate.log"

  if run_without_errexit "$ROOT_DIR/scripts/repo_validate.sh" --check-only >"$output_file" 2>&1; then
    exit_code=0
  else
    exit_code=$?
  fi

  popd >/dev/null

  assert_file_contains "$output_file" "Auto-detected project type: c"

  if [[ $exit_code -eq 1 ]]; then
    echo "✓ repo_validate.sh exited with expected non-zero status (validation errors present)"
    PASSED_TESTS=$((PASSED_TESTS + 1))
  else
    echo "✗ repo_validate.sh exited with unexpected status: $exit_code (expected 1)"
    FAILED_TESTS=$((FAILED_TESTS + 1))
  fi

  cleanup_test_env "$test_dir"
}

main() {
  test_c_detection_without_source_tree
  print_test_summary
}

main
