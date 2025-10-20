# Contributing to Artagon Common

Thank you for your interest in contributing to artagon-common! This document outlines the development workflow, coding standards, and contribution process.

## Table of Contents

- [Getting Started](#getting-started)
- [Development Workflow](#development-workflow)
- [Semantic Commits](#semantic-commits)
- [Branch Naming](#branch-naming)
- [Pull Requests](#pull-requests)
- [Code Review](#code-review)
- [Testing](#testing)
- [Documentation](#documentation)
- [License](#license)

## Getting Started

### Prerequisites

- Git 2.30+
- GitHub CLI (`gh`)
- Bash 4.0+
- Optional: Nix (for reproducible development environment)

### Initial Setup

1. **Fork and Clone**

```bash
# Fork via GitHub UI or CLI
gh repo fork artagon/artagon-common --clone

cd artagon-common
```

2. **Run Setup Script**

```bash
# Installs git hooks, initializes submodules
./scripts/repo_add_artagon_common.sh
```

3. **Verify Installation**

```bash
# Check git hooks are installed
ls -la .git/hooks/

# Should see: commit-msg, pre-push
```

## Development Workflow

All development follows an **issue-driven workflow**:

```
Issue → Branch → Commits → PR → Review → Merge
```

### Step 1: Create or Find an Issue

**Create New Issue:**

```bash
gh issue create \
  --title "Add C++26 support to Bazel" \
  --label "enhancement" \
  --body "Detailed description..."
```

**Or find existing issue:**

```bash
gh issue list --label "good first issue"
```

### Step 2: Create Branch from Issue

```bash
# Automated script creates semantic branch name
./scripts/gh_create_issue_branch.sh <issue-number>

# Example:
./scripts/gh_create_issue_branch.sh 42
# Creates: feat/42-add-cpp26-bazel-support
# Switches to new branch automatically
```

**Manual branch creation:**

```bash
git checkout -b feat/42-add-cpp26-bazel-support
```

**Branch naming format:**
```
<type>/<issue-number>-<short-description>
```

See [Branch Naming](#branch-naming) for details.

### Step 3: Make Changes

**Development:**

```bash
# Make your changes
vim configs/cpp/.bazelrc

# Test your changes
bazel build //...
bazel test //...
```

**Commit with semantic message:**

```bash
git add configs/cpp/.bazelrc

# The commit-msg hook will validate your message
git commit
```

**Commit message format:**
```
feat(bazel): add C++26 standard support

Add C++26 compiler flags and feature detection.
Includes test matrix updates for new standard.

Closes #42
```

See [Semantic Commits](#semantic-commits) for details.

### Step 4: Push and Create Pull Request

```bash
# Push branch
git push -u origin feat/42-add-cpp26-bazel-support

# Create PR with automation script
./scripts/gh_create_pr.sh

# Or manually
gh pr create --fill
```

### Step 5: Code Review

- Address review comments
- Push additional commits to same branch
- Mark conversations as resolved
- Request re-review when ready

### Step 6: Merge

After approval and passing CI:

```bash
# Squash merge (preferred for feature branches)
gh pr merge --squash

# Or merge commit (for multi-commit features)
gh pr merge --merge

# Branch auto-deletes after merge
# Issue auto-closes on merge (if "Closes #N" in commits)
```

## Semantic Commits

### Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Commit Types

| Type | Purpose | Example |
|------|---------|---------|
| `feat` | New feature | `feat(bazel): add C++26 support` |
| `fix` | Bug fix | `fix(workflows): correct matrix syntax` |
| `docs` | Documentation | `docs: update API reference` |
| `style` | Formatting | `style(scripts): apply shellcheck` |
| `refactor` | Code refactoring | `refactor: extract validation logic` |
| `perf` | Performance | `perf(bazel): enable caching` |
| `test` | Tests | `test(scripts): add unit tests` |
| `build` | Build system | `build(nix): update dependencies` |
| `ci` | CI/CD | `ci(workflows): add validation step` |
| `chore` | Maintenance | `chore: update .gitignore` |
| `revert` | Revert commit | `revert: feat(bazel): add support` |

### Examples

**Feature:**
```
feat(workflows): add dependency caching

Add caching for Maven, npm, and Bazel dependencies
to reduce CI build time from 15 to 5 minutes.

Closes #52
```

**Bug Fix:**
```
fix(scripts): handle project names with spaces

Quote variable expansions to prevent word splitting
when project names contain spaces.

Fixes #38
```

**Breaking Change:**
```
feat(bazel)!: change config format to comma-separated

BREAKING CHANGE: Bazel workflow input changed from
space-separated to comma-separated format.

Old: bazel-configs: 'release debug'
New: bazel-configs: 'release,debug'

Closes #60
```

See [docs/SEMANTIC-COMMITS.md](./SEMANTIC-COMMITS.md) for complete guide.

## Branch Naming

### Format

```
<type>/<issue-number>-<short-description>
```

### Types

Use same types as semantic commits:
- `feat` - New feature
- `fix` - Bug fix
- `docs` - Documentation
- `refactor` - Code refactoring
- `test` - Tests
- `ci` - CI/CD changes
- `chore` - Maintenance

### Rules

1. **Lowercase only**: `feat/42-add-support` not `FEAT/42-Add-Support`
2. **Hyphens for spaces**: `feat/42-add-cpp26-support`
3. **Always include issue number**: `feat/42-...` not `feat/add-support`
4. **Be concise**: 3-5 words max for description
5. **Match commit type**: If commits will be `feat`, branch should be `feat/*`

### Examples

**Good:**
```
feat/42-add-cpp26-support
fix/38-workflow-matrix-bug
docs/45-api-examples
refactor/51-extract-validation
test/54-bazel-integration
ci/53-add-linting
```

**Bad:**
```
feature/42-add-cpp26  ← Wrong type name
feat-42-support       ← Wrong separator
feat/add-support      ← Missing issue number
feat/42-add-comprehensive-c++26-support-with-examples  ← Too long
```

### Automated Creation

```bash
# Script automatically generates correct branch name
./scripts/gh_create_issue_branch.sh 42

# Reads issue title: "Add C++26 support to Bazel"
# Detects type from labels: "enhancement" → feat
# Creates: feat/42-add-cpp26-bazel-support
```

## Pull Requests

### PR Title

PR title must follow semantic commit format:

```
feat(bazel): add C++26 support
fix(workflows): correct matrix generation
docs: update BAZEL-MIGRATION guide
```

### PR Description

Use the PR template (auto-filled by script):

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix (fix)
- [x] New feature (feat)
- [ ] Breaking change (feat!)
- [ ] Documentation (docs)

## Linked Issues
Closes #42

## Testing
- [x] Ran unit tests
- [x] Tested locally
- [x] Added new tests

## Checklist
- [x] Semantic commit messages
- [x] Documentation updated
- [x] Tests added/updated
- [x] CI passes
```

### PR Labels

Labels are auto-assigned based on type:
- `feat` → `enhancement`
- `fix` → `bug`
- `docs` → `documentation`
- `test` → `testing`

### Draft PRs

Use draft PRs for work-in-progress:

```bash
gh pr create --draft
# Or convert existing PR
gh pr ready --undo
```

## Code Review

### Review Process

1. **Automated Checks**
   - Shellcheck validation
   - Commit message format
   - Branch name validation
   - CI/CD pipelines

2. **Human Review**
   - Code quality and style
   - Test coverage
   - Documentation completeness
   - Architecture and design

### Addressing Feedback

**Make requested changes:**

```bash
# Make changes
vim file.sh

# Commit with semantic message
git commit -m "fix(scripts): address review feedback"

# Push to same branch
git push
```

**Respond to comments:**
- Mark conversations as resolved when addressed
- Explain your reasoning if disagreeing
- Ask clarifying questions

**Request re-review:**

```bash
gh pr review --request @reviewer
```

## Testing

### Local Testing

**Shell Scripts:**

```bash
# Syntax check
bash -n script.sh

# Shellcheck
shellcheck script.sh

# Run script
./script.sh --dry-run
```

**Bazel:**

```bash
# Build all targets
bazel build //...

# Run all tests
bazel test //...

# Test specific config
bazel test --config=asan //...
```

**Workflows:**

```bash
# Validate workflow syntax
gh workflow view cpp-ci.yml

# Trigger workflow manually
gh workflow run cpp-ci.yml
```

### Adding Tests

**For shell scripts:**

```bash
# Create test file
tests/test_common.sh

# Use framework like BATS
bats tests/test_common.sh
```

**For workflows:**

- Test with actual builds in CI
- Use matrix to test multiple configurations
- Add validation steps

### Test Coverage

Aim for:
- **Scripts**: 80%+ coverage of critical functions
- **Workflows**: All major configurations tested
- **Documentation**: All examples verified

## Documentation

### When to Update Documentation

Update docs when:
- Adding new features
- Changing public APIs
- Fixing bugs that affect documented behavior
- Adding new workflows or scripts

### Documentation Files

| File | Purpose |
|------|---------|
| `README.md` | Project overview, quick start |
| `docs/CONTRIBUTING.md` | This file |
| `docs/SEMANTIC-COMMITS.md` | Commit message guide |
| `docs/API.md` | Shell script API reference |
| `docs/BAZEL-MIGRATION.md` | Bazel migration guide |
| `docs/TROUBLESHOOTING.md` | Common issues |
| `CHANGELOG.md` | Release notes |

### Documentation Style

- Use clear, concise language
- Include code examples
- Add troubleshooting sections
- Link to related documents
- Keep examples up-to-date

### Updating README

Add new features to appropriate sections:

```markdown
## Features

- ✓ Existing feature
- ✓ Your new feature  ← Add here

## Usage

### Your New Feature  ← Add usage example

...
```

### Updating CHANGELOG

Changelog is updated during release, but you can add entry:

```markdown
## [Unreleased]

### Added
- Add C++26 support to Bazel configuration (#42)
```

## Code Style

### Shell Scripts

**Follow these conventions:**

```bash
#!/usr/bin/env bash
set -euo pipefail

# Use meaningful variable names
project_name="artagon-common"

# Quote variables
echo "$project_name"

# Use functions for reusability
validate_input() {
    local input="$1"
    # ...
}

# Proper error handling
if ! command -v git >/dev/null 2>&1; then
    echo "ERROR: git not found" >&2
    exit 1
fi
```

**Apply shellcheck:**

```bash
shellcheck --severity=warning script.sh
```

### Bazel

**Format with buildifier:**

```bash
buildifier -lint=fix BUILD.bazel
```

### Workflow Files

**Follow conventions:**

```yaml
# Clear naming
name: Descriptive Name

# Proper triggers
on:
  push:
    branches: [main]
  pull_request:

# Reusable patterns
jobs:
  build:
    uses: ./.github/workflows/cpp-ci.yml@main
    with:
      config: release
```

## Git Hooks

### Installed Hooks

**commit-msg**: Validates commit message format
**pre-push**: Warns about non-semantic branches

### Hook Behavior

```bash
# Valid commit accepted
git commit -m "feat(bazel): add support"
# ✓ Commit message valid

# Invalid commit rejected
git commit -m "Added support"
# ✗ Error: Commit message does not follow semantic format
#   Expected: <type>(<scope>): <subject>
#   Example: feat(bazel): add support
```

### Bypassing Hooks

**Only when absolutely necessary:**

```bash
git commit --no-verify
```

**Use sparingly:**
- Emergency hotfixes
- Reverting broken commits
- Working with legacy commits

## Common Workflows

### Feature Development

```bash
# 1. Create issue
gh issue create --title "Add feature X"

# 2. Create branch
./scripts/gh_create_issue_branch.sh 42

# 3. Develop
vim source.sh
git add source.sh
git commit -m "feat(scripts): add feature X"

# 4. Push and PR
git push -u origin feat/42-add-feature-x
./scripts/gh_create_pr.sh

# 5. Merge after review
gh pr merge --squash
```

### Bug Fix

```bash
# 1. Find/create bug report
gh issue create --title "Fix bug Y" --label bug

# 2. Create fix branch
./scripts/gh_create_issue_branch.sh 38

# 3. Fix bug
vim source.sh
git commit -m "fix(scripts): resolve bug Y

Added validation to prevent edge case.

Fixes #38"

# 4. Push and PR
git push -u origin fix/38-resolve-bug-y
./scripts/gh_create_pr.sh
```

### Documentation Update

```bash
# 1. Create/find docs issue
gh issue create --title "Update API docs"

# 2. Create branch
git checkout -b docs/45-update-api-docs

# 3. Update docs
vim docs/API.md
git commit -m "docs(api): add examples for new functions

Closes #45"

# 4. Create PR
git push -u origin docs/45-update-api-docs
gh pr create --fill
```

## License

By contributing, you agree to license your contributions under the same license as the project. See [licenses/CLA.md](../licenses/CLA.md) for details.

### Contributor License Agreement

For significant contributions, you may need to sign the CLA:

```bash
# Individual contributors
See licenses/CLA.md

# Corporate contributors
See licenses/CLA-CORPORATE.md
```

## Getting Help

### Resources

- **Documentation**: Check [docs/](../docs/) directory
- **Issues**: [GitHub Issues](https://github.com/artagon/artagon-common/issues)
- **Discussions**: [GitHub Discussions](https://github.com/artagon/artagon-common/discussions)

### Asking Questions

Before asking:
1. Check [TROUBLESHOOTING.md](./TROUBLESHOOTING.md)
2. Search existing issues
3. Review documentation

When asking:
- Provide clear description
- Include error messages
- Share relevant code/config
- Describe expected vs actual behavior

## Additional Guidelines

### Security

- Never commit secrets or credentials
- Use environment variables for sensitive data
- Report security issues privately

### Performance

- Profile before optimizing
- Document performance improvements
- Add benchmarks for critical paths

### Breaking Changes

- Mark clearly with `!` and `BREAKING CHANGE:`
- Provide migration guide
- Update major version number
- Announce in release notes

## Thank You!

Your contributions make artagon-common better for everyone. We appreciate your time and effort!

---

**Questions?** Open a [discussion](https://github.com/artagon/artagon-common/discussions) or reach out to maintainers.
