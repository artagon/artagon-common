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
