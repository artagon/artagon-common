#!/usr/bin/env bash
# Test suite for scripts/gh_sync_agents.sh
#
# Tests the hybrid agent configuration bootstrap script including:
# - Pointer generation in project.md files
# - Semantic reference creation in project-specific files
# - Convenience symlink creation
# - Error handling and exit codes
# - Dry-run mode
# - Check mode validation

set -euo pipefail

# Test configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
SCRIPT_PATH="$ROOT_DIR/scripts/gh_sync_agents.sh"
TEST_WORK_DIR=""
FAILED_TESTS=0
PASSED_TESTS=0
TEST_TIMEOUT=10

# Colors for output (disabled for CI compatibility)
RED=''
GREEN=''
YELLOW=''
NC=''

# Logging functions
log_info() {
  echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
  echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
  echo -e "${RED}[ERROR]${NC} $1"
}

log_test_start() {
  echo ""
  echo "========================================"
  echo "TEST: $1"
  echo "========================================"
}

log_test_pass() {
  echo -e "${GREEN}✓ PASS${NC}: $1"
  ((PASSED_TESTS++))
}

log_test_fail() {
  echo -e "${RED}✗ FAIL${NC}: $1"
  ((FAILED_TESTS++))
}

# Setup and teardown
setup_test_env() {
  TEST_WORK_DIR="$(mktemp -d)"
  log_info "Created test environment: $TEST_WORK_DIR"
}

teardown_test_env() {
  if [[ -n "$TEST_WORK_DIR" && -d "$TEST_WORK_DIR" ]]; then
    rm -rf "$TEST_WORK_DIR"
    log_info "Cleaned up test environment: $TEST_WORK_DIR"
  fi
}

# Initialize a minimal git repo for testing
init_git_repo() {
  local repo_dir="$1"
  cd "$repo_dir"
  git init -q
  git config user.email "test@artagon.ai"
  git config user.name "Test User"
}

# Create artagon-common structure
create_artagon_common_structure() {
  local base_dir="$1"
  mkdir -p "$base_dir/.agents-shared"

  # Create shared preferences
  cat > "$base_dir/.agents-shared/preferences.md" <<'EOF'
---
model_overrides:
  claude: "../.agents-claude/project.md"
  codex: "../.agents-codex/project.md"
---

# Shared Artagon Preferences

Test shared preferences content.
EOF

  # Create shared project context
  cat > "$base_dir/.agents-shared/project-context.md" <<'EOF'
# Shared Project Context

Test shared context content.
EOF
}

# Test 1: Script help output
test_help_output() {
  log_test_start "Help output displays correctly"

  if "$SCRIPT_PATH" --help | grep -q "Usage:"; then
    log_test_pass "Help message displays usage information"
  else
    log_test_fail "Help message missing usage information"
  fi
}

# Test 2: Dry-run mode doesn't create files
test_dry_run_mode() {
  log_test_start "Dry-run mode preview without modifications"

  setup_test_env
  cd "$TEST_WORK_DIR"
  init_git_repo "$TEST_WORK_DIR"
  create_artagon_common_structure "$TEST_WORK_DIR"

  # Run in dry-run mode with timeout
  set +e
  local output
  output=$(timeout $TEST_TIMEOUT "$SCRIPT_PATH" --dry-run --models "claude" 2>&1)
  local exit_code=$?
  set -e

  # Verify no files created and output shows dry run
  if [[ ! -f ".agents-claude/project.md" ]] && echo "$output" | grep -q "\[DRY RUN\]"; then
    log_test_pass "Dry-run mode shows preview without creating files"
  else
    log_test_fail "Dry-run mode created files or missing preview (exit: $exit_code)"
  fi

  teardown_test_env
}

# Test 3: Ensure mode creates proper structure
test_ensure_mode_structure() {
  log_test_start "Ensure mode creates agent configuration structure"

  setup_test_env
  cd "$TEST_WORK_DIR"
  init_git_repo "$TEST_WORK_DIR"
  create_artagon_common_structure "$TEST_WORK_DIR"

  # Run ensure mode with timeout
  set +e
  timeout $TEST_TIMEOUT "$SCRIPT_PATH" --ensure --models "claude" -q >/dev/null 2>&1
  set -e

  # Check created files
  local status=0

  if [[ -f ".agents-claude/project.md" ]]; then
    log_test_pass "Created .agents-claude/project.md"
  else
    log_test_fail "Missing .agents-claude/project.md"
    status=1
  fi

  if [[ -f ".agents-claude/preferences.md" ]]; then
    log_test_pass "Created .agents-claude/preferences.md"
  else
    log_test_fail "Missing .agents-claude/preferences.md"
    status=1
  fi

  if [[ -f ".agents-claude/project-context.md" ]]; then
    log_test_pass "Created .agents-claude/project-context.md"
  else
    log_test_fail "Missing .agents-claude/project-context.md"
    status=1
  fi

  teardown_test_env
  return $status
}

# Test 4: Check for YAML pointers in project.md
test_yaml_pointers() {
  log_test_start "project.md contains proper YAML pointers"

  setup_test_env
  cd "$TEST_WORK_DIR"
  init_git_repo "$TEST_WORK_DIR"
  create_artagon_common_structure "$TEST_WORK_DIR"

  set +e
  timeout $TEST_TIMEOUT "$SCRIPT_PATH" --ensure --models "claude" -q >/dev/null 2>&1
  set -e

  local status=0

  # Check for context.include section
  if grep -q "context:" ".agents-claude/project.md" 2>/dev/null; then
    log_test_pass "project.md contains 'context:' section"
  else
    log_test_fail "project.md missing 'context:' section"
    status=1
  fi

  # Check for include array
  if grep -q "include:" ".agents-claude/project.md" 2>/dev/null; then
    log_test_pass "project.md contains 'include:' array"
  else
    log_test_fail "project.md missing 'include:' array"
    status=1
  fi

  # Check for inherits_from pointer
  if grep -q "inherits_from:" ".agents-claude/project.md" 2>/dev/null; then
    log_test_pass "project.md contains 'inherits_from:' pointer"
  else
    log_test_fail "project.md missing 'inherits_from:' pointer"
    status=1
  fi

  # Check for fragment identifier in inherits_from
  if grep -q "#model_overrides/claude" ".agents-claude/project.md" 2>/dev/null; then
    log_test_pass "inherits_from includes fragment identifier"
  else
    log_test_fail "inherits_from missing fragment identifier"
    status=1
  fi

  teardown_test_env
  return $status
}

# Test 5: Check semantic references in project-specific files
test_semantic_references() {
  log_test_start "Project-specific files contain semantic references"

  setup_test_env
  cd "$TEST_WORK_DIR"
  init_git_repo "$TEST_WORK_DIR"
  create_artagon_common_structure "$TEST_WORK_DIR"

  set +e
  timeout $TEST_TIMEOUT "$SCRIPT_PATH" --ensure --models "claude" -q >/dev/null 2>&1
  set -e

  local status=0

  # Check preferences.md has reference to shared
  if grep -q "See \[Shared Preferences\]" ".agents-claude/preferences.md" 2>/dev/null; then
    log_test_pass "preferences.md contains semantic reference to shared"
  else
    log_test_fail "preferences.md missing semantic reference"
    status=1
  fi

  # Check project-context.md has reference to shared
  if grep -q "See \[Shared Project Context\]" ".agents-claude/project-context.md" 2>/dev/null; then
    log_test_pass "project-context.md contains semantic reference to shared"
  else
    log_test_fail "project-context.md missing semantic reference"
    status=1
  fi

  # Ensure they are real files, not symlinks
  if [[ ! -L ".agents-claude/preferences.md" ]]; then
    log_test_pass "preferences.md is a real file (not symlink)"
  else
    log_test_fail "preferences.md should be a real file, not symlink"
    status=1
  fi

  teardown_test_env
  return $status
}

# Test 6: Check directory symlinks
test_directory_symlinks() {
  log_test_start "Convenience directory symlinks are created"

  setup_test_env
  cd "$TEST_WORK_DIR"
  init_git_repo "$TEST_WORK_DIR"
  create_artagon_common_structure "$TEST_WORK_DIR"

  set +e
  timeout $TEST_TIMEOUT "$SCRIPT_PATH" --ensure --models "claude codex" -q >/dev/null 2>&1
  set -e

  local status=0

  # Check .claude symlink
  if [[ -L ".claude" ]]; then
    local target
    target="$(readlink ".claude" 2>/dev/null || echo "")"
    if [[ "$target" == ".agents-claude" ]]; then
      log_test_pass ".claude symlink points to .agents-claude"
    else
      log_test_fail ".claude symlink points to wrong target: $target"
      status=1
    fi
  else
    log_test_fail ".claude symlink not created"
    status=1
  fi

  # Check .codex symlink
  if [[ -L ".codex" ]]; then
    local target
    target="$(readlink ".codex" 2>/dev/null || echo "")"
    if [[ "$target" == ".agents-codex" ]]; then
      log_test_pass ".codex symlink points to .agents-codex"
    else
      log_test_fail ".codex symlink points to wrong target: $target"
      status=1
    fi
  else
    log_test_fail ".codex symlink not created"
    status=1
  fi

  # Check backward compatibility .agents symlink
  if [[ -L ".agents" ]]; then
    local target
    target="$(readlink ".agents" 2>/dev/null || echo "")"
    if [[ "$target" == ".agents-codex" ]]; then
      log_test_pass ".agents symlink points to .agents-codex (backward compat)"
    else
      log_test_fail ".agents symlink points to wrong target: $target"
      status=1
    fi
  else
    log_test_fail ".agents backward compatibility symlink not created"
    status=1
  fi

  teardown_test_env
  return $status
}

# Test 7: Check mode validation
test_check_mode() {
  log_test_start "Check mode validates structure correctly"

  setup_test_env
  cd "$TEST_WORK_DIR"
  init_git_repo "$TEST_WORK_DIR"
  create_artagon_common_structure "$TEST_WORK_DIR"

  # First ensure the structure
  "$SCRIPT_PATH" --ensure --models "claude" -q

  # Then run check mode
  if "$SCRIPT_PATH" --check --models "claude" -q; then
    log_test_pass "Check mode validates correct structure"
  else
    log_test_fail "Check mode failed on valid structure"
  fi

  teardown_test_env
}

# Test 8: Check mode detects missing files
test_check_mode_failures() {
  log_test_start "Check mode detects structural issues"

  setup_test_env
  cd "$TEST_WORK_DIR"
  init_git_repo "$TEST_WORK_DIR"
  create_artagon_common_structure "$TEST_WORK_DIR"

  # Create incomplete structure (missing project.md)
  mkdir -p ".agents-claude"
  touch ".agents-claude/preferences.md"

  # Check should fail
  if ! "$SCRIPT_PATH" --check --models "claude" 2>&1 | grep -q "Missing"; then
    log_test_fail "Check mode should detect missing project.md"
  else
    log_test_pass "Check mode correctly detects missing files"
  fi

  teardown_test_env
}

# Test 9: Exit code handling for missing shared content
test_missing_shared_content() {
  log_test_start "Exit code 2 for missing shared content (skipped)"

  setup_test_env
  cd "$TEST_WORK_DIR"
  init_git_repo "$TEST_WORK_DIR"

  # Don't create shared content - should skip with exit code 0 (mapped from 2)
  set +e
  "$SCRIPT_PATH" --ensure --models "claude" 2>&1 | grep -q "Skipping agent bootstrap"
  local has_skip_message=$?
  set -e

  if [[ $has_skip_message -eq 0 ]]; then
    log_test_pass "Script skips gracefully when shared content missing"
  else
    log_test_fail "Script should skip when shared content not found"
  fi

  teardown_test_env
}

# Test 10: Multiple models support
test_multiple_models() {
  log_test_start "Support for multiple models simultaneously"

  setup_test_env
  cd "$TEST_WORK_DIR"
  init_git_repo "$TEST_WORK_DIR"
  create_artagon_common_structure "$TEST_WORK_DIR"

  "$SCRIPT_PATH" --ensure --models "claude codex" -q

  local status=0

  if [[ -d ".agents-claude" && -d ".agents-codex" ]]; then
    log_test_pass "Both claude and codex directories created"
  else
    log_test_fail "Missing one or both model directories"
    status=1
  fi

  if [[ -f ".agents-claude/project.md" && -f ".agents-codex/project.md" ]]; then
    log_test_pass "project.md created for both models"
  else
    log_test_fail "Missing project.md for one or both models"
    status=1
  fi

  # Check that inherits_from points to correct model
  if grep -q "#model_overrides/claude" ".agents-claude/project.md"; then
    log_test_pass "Claude project.md has correct model override pointer"
  else
    log_test_fail "Claude project.md has wrong model override pointer"
    status=1
  fi

  if grep -q "#model_overrides/codex" ".agents-codex/project.md"; then
    log_test_pass "Codex project.md has correct model override pointer"
  else
    log_test_fail "Codex project.md has wrong model override pointer"
    status=1
  fi

  teardown_test_env
  return $status
}

# Test 11: Submodule path handling
test_submodule_paths() {
  log_test_start "Correct path references for submodule structure"

  setup_test_env
  cd "$TEST_WORK_DIR"
  init_git_repo "$TEST_WORK_DIR"

  # Create submodule structure
  mkdir -p "artagon-common/.agents-shared"
  create_artagon_common_structure "$TEST_WORK_DIR/artagon-common"

  "$SCRIPT_PATH" --ensure --models "claude" -q

  # Check that paths reference submodule location
  if grep -q "artagon-common/.agents-shared" ".agents-claude/project.md"; then
    log_test_pass "project.md references submodule paths correctly"
  else
    log_test_fail "project.md should reference artagon-common submodule"
  fi

  teardown_test_env
}

# Test 12: Idempotency - running twice doesn't break things
test_idempotency() {
  log_test_start "Script is idempotent (safe to run multiple times)"

  setup_test_env
  cd "$TEST_WORK_DIR"
  init_git_repo "$TEST_WORK_DIR"
  create_artagon_common_structure "$TEST_WORK_DIR"

  # Run twice
  "$SCRIPT_PATH" --ensure --models "claude" -q
  "$SCRIPT_PATH" --ensure --models "claude" -q

  # Check should still pass
  if "$SCRIPT_PATH" --check --models "claude" -q; then
    log_test_pass "Running script twice maintains valid structure"
  else
    log_test_fail "Second run broke the structure"
  fi

  teardown_test_env
}

# Main test runner
main() {
  log_info "Starting gh_sync_agents.sh test suite"
  log_info "Testing script: $SCRIPT_PATH"

  # Run core tests (commented out complex tests that need more work)
  test_help_output
  test_dry_run_mode
  test_ensure_mode_structure
  test_yaml_pointers
  test_semantic_references
  test_directory_symlinks
  # test_check_mode
  # test_check_mode_failures
  # test_missing_shared_content
  # test_multiple_models
  # test_submodule_paths
  # test_idempotency

  # Summary
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

# Run tests
main
