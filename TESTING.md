# Testing Guide for Artagon Common

This document provides testing procedures for the artagon-common repository and its integration with downstream projects.

## Automated Workflow Testing

### Testing Submodule Updates

The automated update workflow runs weekly but can also be triggered manually to test the integration.

**Manual Trigger Steps:**
1. Navigate to the downstream repository (artagon-bom, artagon-parent, etc.)
2. Go to Actions > Update Common Scripts
3. Click "Run workflow" button
4. Select branch (usually `main`)
5. Click "Run workflow"

**Expected Behavior:**
- Workflow should complete successfully
- If updates are available, a PR should be created
- PR should include changelog of commits
- PR should be labeled with `dependencies` and `automated`

## Submodule Commands Testing

### Update Submodule Manually

```bash
# Navigate to project with submodule
cd ~/Projects/Artagon/artagon-bom

# Update submodule to latest
git submodule update --remote .common/artagon-common

# Check what changed
git diff .common/artagon-common

# Commit if there are changes
git add .common/artagon-common
git commit -m "Update artagon-common submodule"
git push
```

### Verify Submodule Status

```bash
# Check current commit
git submodule status

# View submodule details
cd .common/artagon-common
git log --oneline -5
cd ../..
```

## Script Testing

### Test gh_auto_create_and_push.sh

```bash
# From any project with the submodule
.common/artagon-common/scripts/gh_auto_create_and_push.sh --help

# Should display help text with all options
```

### Test repo_add_artagon_common.sh

```bash
# In a new test project
.common/artagon-common/scripts/repo_add_artagon_common.sh

# Should add submodule to current project
```

## Workflow File Validation

### Check Workflow Syntax

```bash
# Validate update-common.yml exists
cat .github/workflows/update-common.yml

# Verify it references the reusable workflow correctly
grep "artagon/artagon-common/.github/workflows" .github/workflows/update-common.yml
```

## Test Scenarios

### Scenario 1: New Script Added to artagon-common
1. Add new script to artagon-common/scripts/
2. Commit and push to artagon-common
3. Trigger update workflow in downstream projects
4. Verify new script appears in downstream submodule

### Scenario 2: Bug Fix in Existing Script
1. Fix bug in artagon-common script
2. Commit with clear message
3. Trigger updates
4. Verify fix propagates to all projects

### Scenario 3: Breaking Change
1. Make breaking change with major version bump
2. Create PR in downstream projects (don't auto-merge)
3. Review and test changes before merging
4. Update projects when ready

## Continuous Integration

### GitHub Actions Status

Monitor the following workflows:
- `.github/workflows/update-common.yml` - Should run weekly
- Check Actions tab for any failures
- Review PR descriptions for changelog accuracy

## Troubleshooting

### Submodule Not Updating
```bash
# Re-initialize submodule
git submodule update --init --recursive

# Force update
git submodule update --remote --force
```

### Workflow Not Triggering
- Check workflow file syntax
- Verify GITHUB_TOKEN has correct permissions
- Check repository settings for Actions enabled

### PR Not Created
- Verify peter-evans/create-pull-request action is accessible
- Check workflow logs for errors
- Ensure there are actual changes to commit

## Integration Testing

### Overview

Integration tests validate the repository setup automation and template generation features. These tests are located in `tests/integration/` and cover:

- CONTRIBUTING.md template generation
- Repository setup script components
- Agent configuration synchronization
- Template variable substitution

### Running Integration Tests

```bash
# Run all integration tests
./tests/integration/run_all_tests.sh

# Run specific test suites
./tests/integration/test_contributing_gen.sh
./tests/integration/test_basic_validation.sh
```

### Test Structure

```
tests/integration/
├── helpers/
│   └── test-helpers.sh          # Shared test utilities
├── fixtures/
│   └── expected-outputs/        # Expected test outputs
├── test_contributing_gen.sh     # CONTRIBUTING.md generation tests
├── test_basic_validation.sh     # Basic validation tests
└── run_all_tests.sh            # Master test runner
```

### Test Categories

#### 1. Template Validation Tests

Verify template files exist and contain required variables:

```bash
# Check template exists
test -f templates/CONTRIBUTING.md.template

# Verify variables present
grep "{{ repository.name }}" templates/CONTRIBUTING.md.template
grep "{{ repository.owner }}" templates/CONTRIBUTING.md.template
grep "{{ repository.description }}" templates/CONTRIBUTING.md.template
```

#### 2. CONTRIBUTING.md Generation Tests

Test the `gh_setup_contributing.sh` script:

**Test Cases:**
- Basic variable substitution
- Special character escaping (& | / \\)
- Empty description handling
- Idempotency (running twice)
- Parameter validation
- Git repository auto-detection

**Manual Test:**
```bash
# Create test environment
mkdir -p /tmp/test-contrib && cd /tmp/test-contrib
git init
git config user.email "test@test.com"
git config user.name "Test"

# Create structure
mkdir -p .common/artagon-common
cp -r /path/to/artagon-common/templates .common/artagon-common/
cp -r /path/to/artagon-common/scripts .common/artagon-common/

# Run generation
.common/artagon-common/scripts/gh_setup_contributing.sh \
  --repo-name "test-project" \
  --repo-owner "test-org" \
  --repo-desc "Test description" \
  --force

# Verify output
cat CONTRIBUTING.md | grep "test-project"
cat CONTRIBUTING.md | grep "test-org"
cat CONTRIBUTING.md | grep "Test description"

# Cleanup
cd / && rm -rf /tmp/test-contrib
```

#### 3. Repository Setup Tests

Test `repo_setup.sh` components:

**Validation Tests:**
- Script syntax validation
- Help output functionality
- Parameter validation
- Invalid input rejection
- CONTRIBUTING.md integration

**Note:** Full end-to-end testing of `repo_setup.sh` requires:
- GitHub CLI authentication
- GitHub repository creation permissions
- Submodule access
- Network connectivity

For full testing, use a test organization:

```bash
# Test with actual GitHub repository creation
./scripts/repo_setup.sh \
  --type java \
  --name test-repo-$(date +%s) \
  --owner test-org \
  --description "Integration test repository" \
  --force

# Verify created repository
gh repo view test-org/test-repo-<timestamp>

# Cleanup
gh repo delete test-org/test-repo-<timestamp> --yes
```

#### 4. Agent Configuration Tests

Test agent synchronization scripts:

```bash
# Test agent sync script
./scripts/gh_sync_agents.sh --dry-run --models "claude codex"

# Verify in test environment
mkdir -p /tmp/test-agents && cd /tmp/test-agents
git init
mkdir -p .agents-shared
echo "# Test" > .agents-shared/preferences.md
../scripts/gh_sync_agents.sh --ensure --models "claude"

# Check results
test -d .agents-claude
test -f .agents-claude/project.md
test -L .claude

# Cleanup
cd / && rm -rf /tmp/test-agents
```

### Edge Cases to Test

#### Special Characters in Descriptions

```bash
# Test with sed special characters
DESC="Project with & ampersand | pipe / slash \\ backslash"

./scripts/gh_setup_contributing.sh \
  --repo-name "test" \
  --repo-owner "test" \
  --repo-desc "$DESC" \
  --force

# Verify characters preserved
grep "ampersand" CONTRIBUTING.md
grep "pipe" CONTRIBUTING.md
```

#### Empty or Missing Parameters

```bash
# Should fail with clear error
./scripts/gh_setup_contributing.sh --force  # Missing required params

# Should handle empty description
./scripts/gh_setup_contributing.sh \
  --repo-name "test" \
  --repo-owner "test" \
  --repo-desc "" \
  --force
```

#### Idempotency

```bash
# Run twice, verify same output
./scripts/gh_setup_contributing.sh --force > /tmp/first.md
./scripts/gh_setup_contributing.sh --force > /tmp/second.md
diff /tmp/first.md /tmp/second.md  # Should be identical
```

### Writing New Tests

When adding new integration tests:

1. **Use Test Helpers**: Source `tests/integration/helpers/test-helpers.sh`
2. **Create Isolated Environments**: Use `mktemp -d` for test directories
3. **Clean Up**: Always remove test directories in cleanup or trap
4. **Document**: Add test description and expected behavior
5. **Use Assertions**: Use helper functions for consistent reporting

**Example Test Template:**

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$SCRIPT_DIR/helpers/test-helpers.sh"

test_my_feature() {
  echo ""
  echo "Test: My feature works correctly"

  local test_dir
  test_dir="$(create_test_env)"
  cd "$test_dir"

  # Setup
  # ... your test setup ...

  # Execute
  # ... run the feature ...

  # Assert
  assert_file_exists "expected-file.txt"
  assert_file_contains "expected-file.txt" "expected content"

  # Cleanup
  cleanup_test_env "$test_dir"
}

main() {
  test_my_feature
  print_test_summary
}

main
```

### CI/CD Integration

Integration tests run automatically in GitHub Actions:

- **Trigger**: On PR and push to main
- **Workflow**: `.github/workflows/tests.yml`
- **Coverage**: Template validation, syntax checks, basic integration
- **Artifacts**: Test results and logs

**Note:** Full repository creation tests are NOT run in CI due to GitHub API rate limits and resource constraints. These should be tested manually before major releases.

### Test Development Guidelines

1. **Mock External Dependencies**: Avoid requiring GitHub CLI or API calls in automated tests
2. **Use Fixtures**: Store expected outputs in `tests/integration/fixtures/`
3. **Test in Isolation**: Each test should be independent and not affect others
4. **Handle Cleanup**: Use traps to ensure cleanup even on failure
5. **Be Deterministic**: Tests should produce same results every time
6. **Document Limitations**: Note what cannot be tested automatically

### Known Limitations

- **GitHub API**: Full repo creation requires manual testing
- **Submodules**: Cannot fully test submodule operations without network
- **Authentication**: GitHub CLI authentication not available in CI
- **Rate Limits**: GitHub API rate limits affect extensive testing

For comprehensive testing of repository creation features, coordinate with DevOps team for test organization access.

---

**Last Updated:** 2025-10-20
**Version:** 1.1
**Maintainer:** Artagon DevOps Team
