#!/usr/bin/env bash
# Integration tests for GitHub configuration files setup

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

PASSED=0
FAILED=0

echo "Testing GitHub configuration files setup"
echo "========================================"

# Test 1: Template files exist
echo ""
echo "Test: GitHub template files exist in templates/.github/"
if [[ -f "$ROOT_DIR/templates/.github/PULL_REQUEST_TEMPLATE.md" ]] && \
   [[ -f "$ROOT_DIR/templates/.github/labeler.yml" ]] && \
   [[ -f "$ROOT_DIR/templates/.github/ISSUE_TEMPLATE/bug_report.md" ]] && \
   [[ -f "$ROOT_DIR/templates/.github/ISSUE_TEMPLATE/chore.md" ]] && \
   [[ -f "$ROOT_DIR/templates/.github/ISSUE_TEMPLATE/feature_request.md" ]]; then
  echo "✓ All GitHub template files exist"
  ((PASSED++)) || true || true
else
  echo "✗ Some GitHub template files missing"
  ((FAILED++)) || true || true
fi

# Test 2: Symlinks exist in artagon-common
echo ""
echo "Test: Symlinks exist in artagon-common .github/"
if [[ -L "$ROOT_DIR/.github/PULL_REQUEST_TEMPLATE.md" ]] && \
   [[ -L "$ROOT_DIR/.github/labeler.yml" ]] && \
   [[ -L "$ROOT_DIR/.github/ISSUE_TEMPLATE/bug_report.md" ]] && \
   [[ -L "$ROOT_DIR/.github/ISSUE_TEMPLATE/chore.md" ]] && \
   [[ -L "$ROOT_DIR/.github/ISSUE_TEMPLATE/feature_request.md" ]]; then
  echo "✓ All symlinks exist"
  ((PASSED++)) || true
else
  echo "✗ Some symlinks missing"
  ((FAILED++)) || true
fi

# Test 3: Symlinks point to correct targets
echo ""
echo "Test: Symlinks point to correct template files"
PR_TARGET=$(readlink "$ROOT_DIR/.github/PULL_REQUEST_TEMPLATE.md")
LABELER_TARGET=$(readlink "$ROOT_DIR/.github/labeler.yml")
BUG_TARGET=$(readlink "$ROOT_DIR/.github/ISSUE_TEMPLATE/bug_report.md")

if [[ "$PR_TARGET" == "../templates/.github/PULL_REQUEST_TEMPLATE.md" ]] && \
   [[ "$LABELER_TARGET" == "../templates/.github/labeler.yml" ]] && \
   [[ "$BUG_TARGET" == "../../templates/.github/ISSUE_TEMPLATE/bug_report.md" ]]; then
  echo "✓ Symlinks point to correct targets"
  ((PASSED++)) || true
else
  echo "✗ Symlinks point to wrong targets"
  echo "  PR: $PR_TARGET"
  echo "  Labeler: $LABELER_TARGET"
  echo "  Bug: $BUG_TARGET"
  ((FAILED++)) || true
fi

# Test 4: Git hooks exist and are executable
echo ""
echo "Test: Git hooks exist and are executable"
if [[ -x "$ROOT_DIR/git-hooks/commit-msg" ]] && \
   [[ -x "$ROOT_DIR/git-hooks/pre-commit" ]] && \
   [[ -x "$ROOT_DIR/git-hooks/post-checkout" ]] && \
   [[ -x "$ROOT_DIR/git-hooks/post-merge" ]]; then
  echo "✓ All git hooks exist and are executable"
  ((PASSED++)) || true
else
  echo "✗ Some git hooks missing or not executable"
  ((FAILED++)) || true
fi

# Test 5: .editorconfig exists
echo ""
echo "Test: .editorconfig exists in configs/"
if [[ -f "$ROOT_DIR/configs/.editorconfig" ]]; then
  echo "✓ .editorconfig exists"
  ((PASSED++)) || true
else
  echo "✗ .editorconfig missing"
  ((FAILED++)) || true
fi

# Test 6: Template content validation
echo ""
echo "Test: Template files contain expected content"
if grep -q "Type of Change" "$ROOT_DIR/templates/.github/PULL_REQUEST_TEMPLATE.md" && \
   grep -q "Linked Issues" "$ROOT_DIR/templates/.github/PULL_REQUEST_TEMPLATE.md" && \
   grep -q "documentation" "$ROOT_DIR/templates/.github/labeler.yml" && \
   grep -q "workflows" "$ROOT_DIR/templates/.github/labeler.yml" && \
   grep -q "Bug Report" "$ROOT_DIR/templates/.github/ISSUE_TEMPLATE/bug_report.md"; then
  echo "✓ Template files contain expected content"
  ((PASSED++)) || true
else
  echo "✗ Template files missing expected content"
  ((FAILED++)) || true
fi

# Test 7: Symlinked files are accessible
echo ""
echo "Test: Symlinked files are readable"
if [[ -r "$ROOT_DIR/.github/PULL_REQUEST_TEMPLATE.md" ]] && \
   [[ -r "$ROOT_DIR/.github/labeler.yml" ]] && \
   [[ -r "$ROOT_DIR/.github/ISSUE_TEMPLATE/bug_report.md" ]]; then
  echo "✓ Symlinked files are readable"
  ((PASSED++)) || true
else
  echo "✗ Some symlinked files not readable"
  ((FAILED++)) || true
fi

# Summary
echo ""
echo "========================================"
echo "TEST SUMMARY"
echo "========================================"
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
