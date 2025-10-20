# Semantic Commit Messages

This document defines the semantic commit message convention used in artagon-common and all related projects.

## Why Semantic Commits?

Semantic commits provide:
- **Clear history**: Understand changes at a glance
- **Automated changelogs**: Generate release notes automatically
- **Version management**: Semantic versioning based on commit types
- **Better collaboration**: Consistent communication across team
- **Automated CI/CD**: Trigger specific workflows based on commit type

## Commit Message Format

### Structure

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Components

**Type** (required): Category of change
**Scope** (optional): Area affected
**Subject** (required): Short description (50 chars or less)
**Body** (optional): Detailed explanation
**Footer** (optional): Issue references, breaking changes

### Rules

1. Use lowercase for type and scope
2. No period at end of subject
3. Use imperative mood ("add" not "added" or "adds")
4. Wrap body at 72 characters
5. Separate header from body with blank line
6. Reference issues in footer

## Commit Types

### Production Code Changes

#### feat
**Purpose:** New feature for the user
**Semver Impact:** MINOR version bump
**Examples:**
```
feat(bazel): add C++26 standard support
feat(workflows): add dependency caching for Maven builds
feat(nix): add Rust nightly toolchain option
```

#### fix
**Purpose:** Bug fix for the user
**Semver Impact:** PATCH version bump
**Examples:**
```
fix(workflows): correct matrix generation in bazel-ci.yml
fix(scripts): handle spaces in project names correctly
fix(bazel): resolve include path for header-only libraries
```

#### perf
**Purpose:** Performance improvement
**Semver Impact:** PATCH version bump
**Examples:**
```
perf(bazel): enable compilation database caching
perf(workflows): parallelize test execution
perf(scripts): optimize dependency resolution algorithm
```

### Non-Production Changes

#### docs
**Purpose:** Documentation only changes
**Semver Impact:** None (or PATCH in docs-only releases)
**Examples:**
```
docs(api): add examples for gh_repo_create function
docs: update BAZEL-MIGRATION.md with new patterns
docs(troubleshooting): add section for Nix build failures
```

#### style
**Purpose:** Code style/formatting (no logic change)
**Semver Impact:** None
**Examples:**
```
style(scripts): apply shellcheck recommendations
style(bazel): format BUILD files with buildifier
style: apply consistent indentation across configs
```

#### refactor
**Purpose:** Code change that neither fixes bug nor adds feature
**Semver Impact:** None (or PATCH if refactor includes minor fixes)
**Examples:**
```
refactor(scripts): extract common validation logic
refactor(workflows): consolidate Nix detection pattern
refactor: reorganize config templates by language
```

#### test
**Purpose:** Adding or updating tests
**Semver Impact:** None
**Examples:**
```
test(scripts): add unit tests for common.sh functions
test(bazel): add integration tests for C++ workflows
test: increase coverage for error handling paths
```

#### build
**Purpose:** Changes to build system or external dependencies
**Semver Impact:** PATCH version bump
**Examples:**
```
build(bazel): update rules_cc to v0.0.9
build(nix): pin nixpkgs to stable channel
build(maven): update parent POM to 2.0.0
```

#### ci
**Purpose:** Changes to CI/CD configuration
**Semver Impact:** None
**Examples:**
```
ci(workflows): add shellcheck validation step
ci: enable branch protection automation
ci(actions): update checkout action to v4
```

#### chore
**Purpose:** Maintenance tasks, dependency updates
**Semver Impact:** None
**Examples:**
```
chore: update .gitignore for IntelliJ IDEA
chore(deps): bump actions/cache from v3 to v4
chore: regenerate license checksums
```

#### revert
**Purpose:** Reverts a previous commit
**Semver Impact:** Depends on reverted commit
**Format:** `revert: <header of reverted commit>`
**Examples:**
```
revert: feat(bazel): add C++26 standard support

This reverts commit a1b2c3d4.
Reason: C++26 support is not stable in GCC 13
```

## Scopes

Scopes indicate the area of the codebase affected. Use consistent scope names across the project.

### Common Scopes

| Scope | Description | Example |
|-------|-------------|---------|
| `workflows` | GitHub Actions workflows | `ci(workflows): add linting` |
| `scripts` | Shell scripts | `fix(scripts): handle edge case` |
| `docs` | Documentation | `docs(docs): update guide` |
| `bazel` | Bazel configuration | `feat(bazel): add config` |
| `cmake` | CMake configuration | `fix(cmake): correct path` |
| `maven` | Maven configuration | `build(maven): update deps` |
| `nix` | Nix flakes | `feat(nix): add overlay` |
| `ci` | CI scripts | `refactor(ci): extract logic` |
| `deploy` | Deployment scripts | `fix(deploy): add validation` |
| `templates` | Project templates | `feat(templates): add Rust` |
| `hooks` | Git hooks | `chore(hooks): update format` |

### Scope Rules

1. Use singular form (`workflow` not `workflows` in scope)
2. Be specific but not too granular
3. Omit scope if change affects multiple areas equally
4. Create new scopes as needed, document in CONTRIBUTING.md

## Subject Line

### Guidelines

- **Imperative mood**: "add", "fix", "update" (not "added", "fixes", "updating")
- **No capitalization**: Start with lowercase letter
- **No period**: Don't end with `.`
- **Be concise**: 50 characters or less
- **Be specific**: Describe what, not how

### Examples

**Good:**
```
feat(bazel): add sanitizer support for TSAN
fix(workflows): correct branch name in checkout
docs: update installation instructions
```

**Bad:**
```
feat(bazel): Added TSAN support.  ← Capitalized, has period, wrong tense
fix(workflows): Fixes the problem    ← Wrong tense, not specific
docs: Updated docs                   ← Not specific enough
```

## Body

### When to Include

Include a body when:
- The subject doesn't fully explain the change
- Multiple changes are included
- Context or reasoning is important
- Breaking changes need explanation

### Format

- Wrap at 72 characters
- Use bullet points for multiple items
- Explain the "why" not the "what"
- Include relevant context

### Example

```
feat(bazel): add remote caching support

Enables remote caching for Bazel builds to improve CI performance.
Configuration uses environment variables for flexibility:

- BAZEL_REMOTE_CACHE_URL: Remote cache endpoint
- BAZEL_REMOTE_CACHE_TOKEN: Authentication token

This reduces average build time from 15 minutes to 5 minutes.
```

## Footer

### Issue References

Link commits to issues using keywords:

**Closes/Fixes** (closes issue on merge):
```
Closes #42
Fixes #38
Resolves #51
```

**References** (doesn't close issue):
```
Related to #45
See #50
Part of #48
```

**Multiple issues**:
```
Closes #42, #43
Fixes #38, closes #39
```

### Breaking Changes

Indicate breaking changes with `BREAKING CHANGE:` in footer:

```
feat(bazel)!: change config input format to comma-separated

BREAKING CHANGE: Bazel workflow input format changed from space-separated
to comma-separated values.

Old: bazel-configs: 'release debug asan'
New: bazel-configs: 'release,debug,asan'

Migration: Replace spaces with commas in all workflow calls.
```

**Note:** The `!` after type/scope also indicates breaking change.

## Complete Examples

### Feature with Body and Issue

```
feat(workflows): add automatic dependency updates

Add Dependabot configuration for automatic dependency updates
across all GitHub Actions workflows. Updates are grouped by
type and scheduled weekly.

Configuration includes:
- GitHub Actions updates
- Docker image updates
- npm dependencies (if present)

Closes #52
```

### Bug Fix with Context

```
fix(scripts): handle project names with spaces

Previously, project names containing spaces would cause the
script to fail with "command not found" errors due to improper
quoting in command substitution.

Added quotes around all variable expansions and tested with:
- "My Project"
- "test-project with spaces"
- "project_name"

Fixes #38
```

### Documentation Update

```
docs(api): add comprehensive examples for all functions

Add usage examples, error handling patterns, and best practices
for each function in scripts/lib/common.sh:

- require_commands: Show conditional usage
- generate_header_guard: Add edge cases
- gh_repo_create: Show all flag combinations
- clean_maven_dependency_line: Add pipeline examples

Related to #45
```

### Breaking Change

```
feat(bazel)!: migrate to Bzlmod for dependency management

BREAKING CHANGE: Migrate from WORKSPACE to MODULE.bazel (Bzlmod)
for dependency management. The legacy WORKSPACE file is deprecated.

Migration steps:
1. Run `bazel mod init` to create MODULE.bazel
2. Convert dependencies using `bazel mod tidy`
3. Test with `bazel build //...`
4. Remove WORKSPACE file

See docs/BAZEL-MIGRATION.md for detailed guide.

Closes #60
```

### Refactor with Explanation

```
refactor(scripts): extract validation logic to common library

Extract duplicated validation logic from multiple scripts into
shared functions in scripts/lib/common.sh:

- validate_repo_name()
- validate_branch_name()
- validate_semver()

This reduces code duplication by ~150 lines and makes validation
consistent across all scripts.

No functional changes to existing scripts.
```

### Revert

```
revert: feat(bazel): add remote caching support

This reverts commit 1234567.

Remote caching is causing authentication failures in CI
environment. Rolling back until credentials are properly
configured.

Related to #55
```

## Validation

### Commit Message Validation Hook

The repository includes a `commit-msg` hook that validates format:

```bash
# Valid commits pass silently
git commit -m "feat(bazel): add C++26 support"

# Invalid commits are rejected
git commit -m "Added C++26 support"
# Error: Commit message does not follow semantic format
```

### PR Title Validation

Pull request titles must also follow semantic format:

```
✓ feat(bazel): add C++26 support
✓ fix(workflows): correct matrix bug
✗ Add C++26 support (no type)
✗ FEAT: add support (wrong case)
```

## Tools and Automation

### Commitizen

Use commitizen for interactive commit creation:

```bash
npm install -g commitizen cz-conventional-changelog
git cz
```

### commitlint

Validate commits with commitlint:

```bash
npm install -g @commitlint/cli @commitlint/config-conventional
echo "feat(bazel): add support" | commitlint
```

### Conventional Changelog

Generate changelog from commits:

```bash
npm install -g conventional-changelog-cli
conventional-changelog -p angular -i CHANGELOG.md -s
```

## Best Practices

### Do's

✓ Write clear, descriptive subjects
✓ Use imperative mood consistently
✓ Reference issues in footer
✓ Include body for complex changes
✓ Mark breaking changes explicitly
✓ Keep commits atomic (one logical change)

### Don'ts

✗ Mix multiple unrelated changes
✗ Use vague subjects ("fix bug", "update code")
✗ Forget issue references
✗ Use past tense ("added", "fixed")
✗ Exceed character limits (50 for subject, 72 for body)
✗ Hide breaking changes

## Common Mistakes

### Mistake 1: Wrong Tense
```
✗ feat(bazel): added C++26 support
✓ feat(bazel): add C++26 support
```

### Mistake 2: Missing Type
```
✗ add C++26 support
✓ feat(bazel): add C++26 support
```

### Mistake 3: Vague Subject
```
✗ fix: fix bug
✓ fix(workflows): correct matrix generation syntax
```

### Mistake 4: Subject Too Long
```
✗ feat(bazel): add comprehensive support for C++26 standard including all new features
✓ feat(bazel): add C++26 standard support
```

### Mistake 5: Missing Issue Reference
```
✗ fix(scripts): handle spaces in names
✓ fix(scripts): handle spaces in names

Fixes #38
```

## References

- [Conventional Commits](https://www.conventionalcommits.org/)
- [Angular Commit Guidelines](https://github.com/angular/angular/blob/master/CONTRIBUTING.md#commit)
- [Semantic Versioning](https://semver.org/)
- [Keep a Changelog](https://keepachangelog.com/)

## See Also

- [CONTRIBUTING.md](./CONTRIBUTING.md) - Full contribution workflow
- [WORKFLOW.md](./WORKFLOW.md) - Issue-driven development process
- [Git Hooks](../git-hooks/) - Automated validation tools
