#!/usr/bin/env bash
# Integration tests for agent layout verification

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
HELPERS="$SCRIPT_DIR/helpers/test-helpers.sh"

# shellcheck source=tests/integration/helpers/test-helpers.sh
source "$HELPERS"

echo "Testing agent layout"
echo "===================="

test_verify_agent_layout() {
  echo ""
  echo "Test: verify_agent_layout.sh confirms structure"

  local log_file="/tmp/verify-agent-layout.log"

  if "$ROOT_DIR/scripts/verify_agent_layout.sh" >"$log_file" 2>&1; then
    echo "✓ Agent layout verification passed"
    PASSED_TESTS=$((PASSED_TESTS + 1))
    rm -f "$log_file"
  else
    echo "✗ Agent layout verification failed"
    cat "$log_file"
    FAILED_TESTS=$((FAILED_TESTS + 1))
  fi
}

main() {
  test_verify_agent_layout
  print_test_summary
}

main "$@"
