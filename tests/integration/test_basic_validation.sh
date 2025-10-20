#!/usr/bin/env bash
# Basic validation tests for repository setup components

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
HELPERS="$SCRIPT_DIR/helpers/test-helpers.sh"

# Load test helpers
# shellcheck source=tests/integration/helpers/test-helpers.sh
source "$HELPERS"

echo "Basic Validation Tests"
echo "======================"

# Test 1: Template files exist
test_template_files() {
  echo ""
  echo "Test: Template files exist"
  assert_file_exists "$ROOT_DIR/templates/CONTRIBUTING.md.template"
  assert_file_exists "$ROOT_DIR/templates/README.md"
}

# Test 2: Setup scripts exist and are executable
test_scripts_exist() {
  echo ""
  echo "Test: Setup scripts exist and are executable"
  assert_file_exists "$ROOT_DIR/scripts/repo_setup.sh"
  assert_file_exists "$ROOT_DIR/scripts/gh_setup_contributing.sh"
  assert_file_exists "$ROOT_DIR/scripts/gh_sync_agents.sh"

  local scripts=(
    "$ROOT_DIR/scripts/repo_setup.sh"
    "$ROOT_DIR/scripts/gh_setup_contributing.sh"
    "$ROOT_DIR/scripts/gh_sync_agents.sh"
  )

  for script in "${scripts[@]}"; do
    if [[ -x "$script" ]]; then
      echo "✓ Executable: $(basename "$script")"
      ((PASSED_TESTS++))
    else
      echo "✗ Not executable: $(basename "$script")"
      ((FAILED_TESTS++))
    fi
  done
}

# Test 3: Script syntax validation
test_script_syntax() {
  echo ""
  echo "Test: Script syntax validation"

  local scripts=(
    "$ROOT_DIR/scripts/repo_setup.sh"
    "$ROOT_DIR/scripts/gh_setup_contributing.sh"
    "$ROOT_DIR/scripts/gh_sync_agents.sh"
  )

  for script in "${scripts[@]}"; do
    if bash -n "$script" 2>/dev/null; then
      echo "✓ Valid syntax: $(basename "$script")"
      ((PASSED_TESTS++))
    else
      echo "✗ Syntax error: $(basename "$script")"
      ((FAILED_TESTS++))
    fi
  done
}

# Test 4: Template contains variables
test_template_variables() {
  echo ""
  echo "Test: Template contains GitHub variables"
  assert_file_contains "$ROOT_DIR/templates/CONTRIBUTING.md.template" "{{ repository.name }}"
  assert_file_contains "$ROOT_DIR/templates/CONTRIBUTING.md.template" "{{ repository.owner }}"
  assert_file_contains "$ROOT_DIR/templates/CONTRIBUTING.md.template" "{{ repository.description }}"
}

# Test 5: repo_setup.sh contains CONTRIBUTING integration
test_contributing_integration() {
  echo ""
  echo "Test: repo_setup.sh integrates CONTRIBUTING.md setup"
  assert_file_contains "$ROOT_DIR/scripts/repo_setup.sh" "gh_setup_contributing"
  assert_file_contains "$ROOT_DIR/scripts/repo_setup.sh" "CONTRIBUTING_SETUP_SCRIPT"
}

# Test 6: Agent sync scripts exist
test_agent_scripts() {
  echo ""
  echo "Test: Agent configuration scripts exist"
  assert_file_exists "$ROOT_DIR/scripts/gh_sync_agents.sh"
  assert_file_exists "$ROOT_DIR/scripts/gh_sync_claude.sh"
}

# Run all tests
main() {
  test_template_files
  test_scripts_exist
  test_script_syntax
  test_template_variables
  test_contributing_integration
  test_agent_scripts

  print_test_summary
}

main
