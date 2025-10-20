# Artagon Common – Codex Context

## Overview
Shared Artagon infrastructure repository providing language templates, scripts, and automation used across company projects.

### Key Components
- `configs/`: Authoritative source for language templates (Java, C, C++, Rust) including Bazel/CMake scaffolding and formatting configs.
- `nix/templates/`: Reusable Nix flakes with language-specific development shells; documentation lives beside each template.
- `scripts/`: Automation for repo setup, CI helpers, release tooling, security scripts, workflow automation, etc.
  - `repo_setup.sh`: Bootstraps new projects using templates
  - `gh_create_issue_branch.sh`: Creates semantic branch from GitHub issue
  - `gh_create_pr.sh`: Creates PR with auto-filled template
- `docs/`: Comprehensive documentation including contribution guides, API references, troubleshooting
  - `CONTRIBUTING.md`: Complete workflow guide
  - `SEMANTIC-COMMITS.md`: Commit message format reference
  - `API.md`: Shell script library documentation
  - `BAZEL-MIGRATION.md`: CMake to Bazel migration guide
  - `TROUBLESHOOTING.md`: Common issues and solutions
- `.github/`: GitHub templates and workflows
  - `ISSUE_TEMPLATE/`: Feature, bug, chore templates
  - `PULL_REQUEST_TEMPLATE.md`: Comprehensive PR template
  - `workflows/`: Reusable CI/CD workflows including PR validation
- `git-hooks/`: Git hooks for automation
  - `commit-msg`: Validates semantic commit format
  - `pre-commit`: Pre-commit checks
  - `post-checkout`, `post-merge`: Submodule automation
- `.agents/`: Agent-specific preferences/context (Claude, Codex)
- `.claude/`: Claude Code specific preferences

## Workflows

### Issue-Driven Development (NEW - Mandatory)
**All development must follow this workflow:**

1. **Create Issue**: Every change starts with GitHub issue
   - Use issue templates: feature_request, bug_report, chore
   - Apply appropriate labels (enhancement, bug, documentation, etc.)

2. **Create Semantic Branch**:
   ```bash
   ./scripts/gh_create_issue_branch.sh <issue-number>
   ```
   - Auto-detects type from issue labels
   - Generates semantic branch name: `<type>/<issue>-<slug>`
   - Examples: `feat/42-add-cpp26-support`, `fix/38-workflow-matrix`

3. **Semantic Commits**:
   - Format: `<type>(<scope>): <subject>`
   - Must include issue reference: `Closes #42`
   - Validated by `commit-msg` hook
   - Types: feat, fix, docs, style, refactor, perf, test, build, ci, chore

4. **Create PR**:
   ```bash
   ./scripts/gh_create_pr.sh
   ```
   - Auto-fills PR template
   - Links to issue automatically
   - PR validation workflow checks format

5. **Review & Merge**: All changes via PR, never direct to main/develop

**Automation Scripts:**
- `scripts/gh_create_issue_branch.sh` - Branch creation from issue
- `scripts/gh_create_pr.sh` - PR creation with template
- `git-hooks/commit-msg` - Commit message validation

**Validation:**
- `.github/workflows/pr-validation.yml` - Validates PR title, branch name, commits
- Auto-labeling based on changed files
- Welcome comments on new PRs

### New Project Bootstrapping
Run `scripts/repo_setup.sh` to create repo structure, add submodules (`.common/artagon-common`, `.legal/artagon-license`), copy templates from `configs/`, optionally add Nix support, and generate docs.

### Nix Development Environments
Use `nix/templates/<lang>/flake.nix` for reproducible shells (multiple JDK versions, CI shells, etc.). Conditional checks avoid failures unless project-specific files exist.

### Documentation Sync
Any template/script change should update `README.md`, `docs/`, and helper scripts to avoid drift across Artagon projects. All documentation changes must follow semantic commit workflow.

## Maintenance Notes
- Scripts must reference `configs/` (legacy `templates/` path is deprecated).
- Validate bootstrap scripts by creating throwaway repos to ensure copied assets exist.
- When modifying Nix flakes or language templates, update corresponding READMEs and note changes here.
- Keep Git hooks (`git-hooks/`) and licensing automation working with the artagon-license submodule export process.
- All script changes require semantic commits with issue references.
- Update issue/PR templates when workflow changes.

## Pitfalls / Reminders
- Multi-agent preferences (Claude, Codex) must be kept consistent; update both when policies change.
- Conditional logic in flakes should avoid referencing files that don't exist in the template itself.
- Ensure scripts fail fast when required submodules or templates are missing to aid user troubleshooting.
- **All commits must follow semantic format** - enforced by commit-msg hook.
- **Never commit directly to main** - all changes via issue → branch → PR workflow.
- **No AI attribution in commits** - human authors only.
- Branch names must follow `<type>/<issue>-<description>` format.
- PR titles must follow semantic format for validation to pass.
- Always link commits to issues using `Closes #N` or `Fixes #N`.

## Recent Structural Changes

### Issue-Driven Workflow Infrastructure (October 2025)
- Added comprehensive semantic commit documentation (`docs/SEMANTIC-COMMITS.md`, `docs/CONTRIBUTING.md`)
- Created GitHub issue templates for feature/bug/chore
- Created PR template with comprehensive checklist
- Added automation scripts for branch/PR creation
- Implemented commit-msg hook for validation
- Added PR validation workflow
- Updated agent preferences (`.agents/claude/`, `.agents/codex/`, `.claude/`)
- All future development must follow this workflow

### Documentation Improvements (October 2025)
- Added `docs/API.md` - Shell script API reference
- Added `docs/BAZEL-MIGRATION.md` - CMake to Bazel migration guide
- Added `docs/TROUBLESHOOTING.md` - Common issues guide
- Added `CHANGELOG.md` - Release notes tracking
- Updated `README.md` Contributing section

### Script Safety Improvements (October 2025)
- All scripts now use `set -euo pipefail`
- Standardized shebangs to `#!/usr/bin/env bash`
- Added shellcheck CI workflow
- Improved error handling across all scripts

### Workflow Improvements (October 2025)
- Fixed Bazel matrix bug (comma-separated format)
- Added Nix detection to C++ workflows
- Added shellcheck validation workflow
- Added PR validation workflow

## File Organization

```
artagon-common/
├── .agents/                      # Agent preferences
│   ├── claude/preferences.md
│   └── codex/
│       ├── preferences.md
│       └── project-context.md
├── .claude/preferences           # Claude Code workflow config
├── .github/
│   ├── ISSUE_TEMPLATE/          # Issue templates
│   ├── PULL_REQUEST_TEMPLATE.md # PR template
│   ├── labeler.yml              # Auto-labeling config
│   └── workflows/               # CI/CD workflows
│       ├── pr-validation.yml    # PR format validation
│       ├── shellcheck.yml       # Shell script validation
│       └── ...                  # Language-specific workflows
├── docs/                        # Documentation
│   ├── CONTRIBUTING.md          # Contribution workflow
│   ├── SEMANTIC-COMMITS.md      # Commit format guide
│   ├── API.md                   # Script API reference
│   ├── BAZEL-MIGRATION.md       # Migration guide
│   └── TROUBLESHOOTING.md       # Common issues
├── git-hooks/                   # Git automation
│   ├── commit-msg               # Semantic commit validator
│   ├── pre-commit               # Pre-commit checks
│   └── ...
├── scripts/                     # Automation
│   ├── gh_create_issue_branch.sh # Branch from issue
│   ├── gh_create_pr.sh          # PR creation
│   ├── repo_setup.sh            # Project bootstrap
│   └── ...
├── configs/                     # Language templates
├── nix/templates/               # Nix flakes
└── CHANGELOG.md                 # Release notes
```

## Development Process Summary

For all changes:
1. Create/find issue with appropriate label
2. Run `./scripts/gh_create_issue_branch.sh <issue>`
3. Make changes, commit with semantic format
4. Run `./scripts/gh_create_pr.sh`
5. Wait for review and CI validation
6. Merge after approval (issue auto-closes)

No exceptions - this workflow is mandatory for traceability and quality.
