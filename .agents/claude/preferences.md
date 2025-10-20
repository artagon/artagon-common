# Claude Code Preferences for Artagon Projects

## Git Commit Attribution

**DO NOT** include Claude attribution in git commits.

Specifically:
- ❌ Do NOT add "🤖 Generated with [Claude Code](https://claude.com/claude-code)"
- ❌ Do NOT add "Co-Authored-By: Claude <noreply@anthropic.com>"

All commits should show only the human author only.

## Pull Request Attribution

**DO NOT** include Claude attribution in pull request descriptions.

## Issue-Driven Development Workflow

**MANDATORY:** ALL development must follow the issue-driven workflow.

### Workflow Steps

1. **Create or Find Issue**
   - Every change MUST start with a GitHub issue
   - Use `gh issue create` with appropriate labels
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
- `workflows`, `scripts`, `docs`, `bazel`, `cmake`, `maven`, `nix`, `ci`, `deploy`

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
- `./scripts/gh_create_issue_branch.sh <issue>` - Create semantic branch
- `./scripts/gh_create_pr.sh` - Create PR with template

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

## Quality Standards

- **Scripts**: Must pass shellcheck, use `set -euo pipefail`
- **Workflows**: Nix detection, proper matrix, caching
- **Documentation**: Examples, clear explanations, cross-references
- **Tests**: All existing pass, add tests for new functionality
- **Security**: No secrets, proper validation, secure defaults

## References

- **Full Guide**: [docs/CONTRIBUTING.md](../../docs/CONTRIBUTING.md)
- **Commit Format**: [docs/SEMANTIC-COMMITS.md](../../docs/SEMANTIC-COMMITS.md)
- **Troubleshooting**: [docs/TROUBLESHOOTING.md](../../docs/TROUBLESHOOTING.md)
- **Workflow Preferences**: [.claude/preferences](../../.claude/preferences)

## General Principle

These are professional open source projects. All code contributions should be attributed to human authors only, not AI assistants.

All development must follow the issue-driven workflow with semantic commits. This is not optional.

Documentation must be kept accurate and up-to-date with every change to maintain project quality and usability.
