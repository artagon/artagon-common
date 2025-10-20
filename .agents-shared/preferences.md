---
# Shared Agent Preferences for Artagon Projects
# This file is the canonical source for both Claude and Codex agents
model_overrides:
  claude: "../.agents-claude/project.md"
  codex: "../.agents-codex/project.md"
---

# Agent Preferences for Artagon Projects

## Attribution Policy

**DO NOT** include AI attribution in commits or pull requests.

Specifically:
- ❌ Do NOT add "🤖 Generated with [Claude Code](https://claude.com/claude-code)"
- ❌ Do NOT add "Co-Authored-By: Claude <noreply@anthropic.com>"
- ❌ Do NOT add "Co-Authored-By: Copilot" or other AI metadata
- ❌ Do NOT add "Co-Authored-By: Gemini" or other AI metadata

All commits should show the human author only. These are professional open source projects where code contributions should be attributed to human authors only, not AI assistants.

## Issue-Driven Development Workflow

**MANDATORY:** ALL development must follow the issue-driven workflow.

### Workflow Steps

1. **Create or Find Issue**
   - Every change MUST start with a GitHub issue
   - Use `gh issue create` with appropriate labels
   - Issue templates available: feature_request, bug_report, chore
   - Label types map to commit types:
     - `enhancement` → feat
     - `bug` → fix
     - `documentation` → docs
     - `chore` → chore

2. **Create Semantic Branch**
   - Use automation: `./scripts/gh_create_issue_branch.sh <issue-number>`
   - Format: `<type>/<issue>-<short-description>`
   - Types: feat, fix, docs, style, refactor, perf, test, build, ci, chore
   - Examples:
     - `feat/42-add-cpp26-support`
     - `fix/38-workflow-matrix-bug`
     - `docs/45-update-api-guide`

3. **Make Changes with Semantic Commits**
   - Format: `<type>(<scope>): <subject>`
   - Always include issue reference: `Closes #42` or `Fixes #38`
   - Use imperative mood: "add" not "added"
   - Start subject with lowercase
   - No period at end
   - Subject <= 50 chars (72 max)
   - Commit message validated by `commit-msg` hook

4. **Push and Create PR**
   - Push: `git push -u origin <branch-name>`
   - Use automation: `./scripts/gh_create_pr.sh`
   - PR title must follow semantic format
   - Links to issue automatically

5. **Never Push to Main/Develop Directly**
   - All changes via feature branches
   - All changes via pull requests
   - All PRs require review

### Semantic Commit Format

**Structure:**
```
<type>(<scope>): <subject>

<body>

<footer>
```

**Required Types:**
- `feat` - New feature (MINOR semver)
- `fix` - Bug fix (PATCH semver)
- `docs` - Documentation only
- `style` - Formatting (no logic change)
- `refactor` - Code refactoring
- `perf` - Performance improvement
- `test` - Tests
- `build` - Build system/dependencies
- `ci` - CI/CD changes
- `chore` - Maintenance

**Optional Scopes:**
- `workflows`, `scripts`, `docs`, `bazel`, `cmake`, `maven`, `nix`, `ci`, `deploy`, `templates`, `hooks`

**Breaking Changes:**
- Add `!` after type/scope: `feat(api)!:`
- Include `BREAKING CHANGE:` in footer with migration guide

**Examples:**
```
feat(bazel): add C++26 standard support

Add C++26 compiler flags and feature detection.

Closes #42

---

fix(workflows): correct matrix generation

Changed from space to comma-separated format.

Fixes #38
```

### Branch Naming Convention

**Format:** `<type>/<issue>-<description>`

**Rules:**
- Lowercase only
- Hyphens (not underscores/spaces)
- Always include issue number
- 3-5 words max for description
- Match commit type

**Valid:**
- `feat/42-add-cpp26-support` ✓
- `fix/38-workflow-matrix` ✓
- `docs/45-api-examples` ✓

**Invalid:**
- `feature/42-add-cpp26` ✗ (wrong type)
- `feat-42-support` ✗ (wrong separator)
- `feat/add-support` ✗ (no issue number)

### Automation Scripts

Available tools:
- `./scripts/gh_create_issue_branch.sh <issue>` - Create semantic branch from issue
- `./scripts/gh_create_pr.sh` - Create PR with auto-filled template

### Commit Validation

The `commit-msg` hook validates:
- Semantic format compliance
- Valid commit type
- Subject length
- Imperative mood (warnings)
- Lowercase start (warnings)

Bypass only for emergencies:
```bash
git commit --no-verify
```

## Documentation and Script Maintenance

**ALWAYS** review and update documentation and scripts after making changes.

When making any code or configuration changes:
- ✅ Update relevant documentation files (README.md, docs/*.md, etc.)
- ✅ Update affected scripts in scripts/ directory
- ✅ Review related configuration files
- ✅ Check for outdated examples or instructions
- ✅ Ensure consistency across all documentation
- ✅ Update version numbers and dates where applicable
- ✅ Update CHANGELOG.md for significant changes

**Areas requiring review on changes:**
- README files (project root, subdirectories)
- Documentation in docs/ directory
- Script files in scripts/ directory
- Configuration templates in configs/ directory
- Nix templates and documentation
- Build configuration files (pom.xml, BUILD.bazel, etc.)
- Issue/PR templates in .github/
- Workflow files in .github/workflows/

**Workflow:**
1. Make code/config changes
2. Identify affected documentation
3. Update documentation to reflect changes
4. Review scripts for compatibility
5. Test updated scripts and examples
6. Follow semantic commit for all changes
7. Link commits to issues

## Context Memory

- Record meaningful repository patterns, workflows, or pitfalls in `project-context.md` after significant changes
- Note structural shifts (new directories, renamed templates, etc.) so future sessions stay aligned
- Document workflow changes and new automation tools

## Example Complete Workflow

```bash
# 1. Create issue
gh issue create \
  --title "Add C++26 support to Bazel" \
  --label "enhancement" \
  --body "..."
# Returns: Issue #42

# 2. Create branch
./scripts/gh_create_issue_branch.sh 42
# Creates: feat/42-add-cpp26-bazel-support
# Switches automatically

# 3. Make changes
vim configs/cpp/.bazelrc

# 4. Commit (semantic)
git add configs/cpp/.bazelrc
git commit -m "feat(bazel): add C++26 standard support

Add C++26 compiler flags and feature detection.

Closes #42"

# 5. Push
git push -u origin feat/42-add-cpp26-bazel-support

# 6. Create PR
./scripts/gh_create_pr.sh
# Auto-fills template, links to #42

# 7. Wait for review
# Issue closes on merge
```

## Coding Style

- Follow repository conventions defined in `configs/` and language-specific tooling (formatters, linters, etc.)
- Opt for clarity over clever optimizations; comment only when intent may be non-obvious
- Scripts must use `#!/usr/bin/env bash` and `set -euo pipefail`
- Pass shellcheck validation for all shell scripts
- Prefer small, well-scoped commits with clear intent and context

## Quality Standards

- **Scripts**: Must pass shellcheck, use `set -euo pipefail`, proper error handling
- **Workflows**: Nix detection, proper matrix configuration, caching
- **Documentation**: Examples, clear explanations, cross-references, maintain accuracy
- **Tests**: All existing pass, add tests for new functionality
- **Security**: No secrets committed, proper input validation, secure defaults

## Pull Request Reviews

### Code Review Process

1. **All PRs Require Review**: At least one approving review required before merge
2. **Conversation Resolution**: All review threads must be resolved before merging (enforced by branch protection)
3. **Address All Feedback**: Respond to all review comments with fixes or explanations

### GitHub Copilot Reviews

**Copilot automatically reviews all PRs** and provides feedback on:
- Security vulnerabilities
- Code quality issues
- Best practice violations
- Performance concerns

**Handling Copilot Feedback:**

1. **Address All Comments**: Fix issues or provide explanations for each comment
2. **Reply to Threads**: After fixing, reply to each comment explaining the fix
3. **Resolve Conversations**: Mark conversations as resolved after addressing
4. **Re-trigger Reviews**: Push new commits to trigger fresh Copilot review
   - Copilot re-reviews automatically on new commits
   - Review threads from outdated code are automatically marked as outdated

**Example Response:**
```
Fixed in commit abc1234. Removed eval usage and replaced with direct command execution.
```

### Branch Protection Rules

The `main` branch has protection rules enforcing:
- ✅ Required passing status checks (Shellcheck, Validate PR, build)
- ✅ At least 1 approving review required
- ✅ All conversations must be resolved before merge
- ✅ Branches must be up to date with base branch
- ✅ Force pushes and deletions blocked

**Impact**: PRs cannot be merged until:
1. All CI checks pass
2. All review conversations resolved
3. At least one approving review received

## Testing Requirements

**MANDATORY:** For each feature that changes shell scripts in this repository, integration tests MUST be added.

### When Tests Are Required

Tests are **REQUIRED** for:
- ✅ New shell scripts in `scripts/` directory
- ✅ Changes to existing scripts that modify behavior
- ✅ New functions or features in shell scripts
- ✅ Bug fixes that change script logic
- ✅ Template generation scripts
- ✅ Repository setup automation scripts

### Test Framework Location

All integration tests must be placed in:
```
tests/integration/
├── helpers/
│   └── test-helpers.sh          # Shared test utilities and assertions
├── fixtures/
│   └── expected-outputs/        # Expected test outputs
├── test_<feature>.sh            # Individual test suites
└── run_all_tests.sh            # Master test runner
```

### Test Requirements

Each test must:
1. **Use Test Helpers**: Source `tests/integration/helpers/test-helpers.sh`
2. **Be Isolated**: Use `create_test_env()` for temporary test directories
3. **Clean Up**: Use `cleanup_test_env()` or trap handlers
4. **Be Executable**: `chmod +x` for all test scripts
5. **Be Documented**: Add description and expected behavior
6. **Use Assertions**: Use helper functions (`assert_file_exists`, `assert_file_contains`, etc.)

### Example Test Structure

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$SCRIPT_DIR/helpers/test-helpers.sh"

test_my_script_feature() {
  echo ""
  echo "Test: My script feature works correctly"

  local test_dir
  test_dir="$(create_test_env)"
  cd "$test_dir"

  # Setup
  # ... test setup ...

  # Execute
  "$ROOT_DIR/scripts/my_script.sh" --param value

  # Assert
  assert_file_exists "expected-output.txt"
  assert_file_contains "expected-output.txt" "expected content"

  # Cleanup
  cleanup_test_env "$test_dir"
}

main() {
  test_my_script_feature
  print_test_summary
}

main
```

### Running Tests

```bash
# Run all integration tests
./tests/integration/run_all_tests.sh

# Run specific test suite
./tests/integration/test_<feature>.sh
```

### Test Coverage Expectations

For script changes, tests should cover:
- ✅ Basic functionality (happy path)
- ✅ Parameter validation
- ✅ Error handling
- ✅ Edge cases (empty values, special characters)
- ✅ Idempotency (if applicable)
- ✅ Integration points with other scripts

### Documentation

When adding tests:
1. Update `TESTING.md` with new test descriptions
2. Document any test limitations or prerequisites
3. Include examples of manual testing if needed

See [TESTING.md](../TESTING.md) for comprehensive testing guide.

## Tooling Expectations

- Run available formatters/linters/tests relevant to your changes
- Add or update tests when fixing bugs or changing behaviour
- Validate `scripts/repo_setup.sh` or other bootstrap scripts using a temporary repo when touched
- Use automation scripts for branch/PR creation to ensure consistency

## References

- **Full Guide**: [docs/CONTRIBUTING.md](../../docs/CONTRIBUTING.md)
- **Commit Format**: [docs/SEMANTIC-COMMITS.md](../../docs/SEMANTIC-COMMITS.md)
- **API Reference**: [docs/API.md](../../docs/API.md)
- **Troubleshooting**: [docs/TROUBLESHOOTING.md](../../docs/TROUBLESHOOTING.md)
- **Issue Templates**: [.github/ISSUE_TEMPLATE/](../../.github/ISSUE_TEMPLATE/)
- **PR Template**: [.github/PULL_REQUEST_TEMPLATE.md](../../.github/PULL_REQUEST_TEMPLATE.md)

## Guiding Principles

1. **Human Accountability**: Treat Artagon repositories as professional, human-run projects. Automation assists delivery, but human accountability, thorough docs, and reproducible workflows take precedence.

2. **Mandatory Issue-Driven Workflow**: All development must follow the issue-driven workflow with semantic commits. This is not optional. It ensures traceability, proper review process, and maintains project quality standards.

3. **Documentation Excellence**: Documentation must be kept accurate and up-to-date with every change to maintain project quality and usability.

4. **Quality First**: Prioritize code quality, testing, and maintainability over speed of delivery.
