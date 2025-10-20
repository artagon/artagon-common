# Codex Preferences for Artagon Projects

## Attribution
- Do NOT include Codex or other AI attribution in commits or PRs.
- All commits must list the human author only (no "Co-Authored-By" AI metadata).

## Issue-Driven Development Workflow

**MANDATORY:** ALL development follows the issue-driven workflow with semantic commits.

### Workflow Overview

1. **Issue First**: Every change requires a GitHub issue
2. **Semantic Branch**: Create branch using `./scripts/gh_create_issue_branch.sh <issue>`
3. **Semantic Commits**: Format `<type>(<scope>): <subject>` with issue reference
4. **Pull Request**: Create PR using `./scripts/gh_create_pr.sh`
5. **Review & Merge**: All changes via PR, never direct to main

### Semantic Commit Format

```
<type>(<scope>): <subject>

<body>

Closes #<issue>
```

**Types:** feat, fix, docs, style, refactor, perf, test, build, ci, chore

**Branch Format:** `<type>/<issue>-<description>`

**Examples:**
- `feat/42-add-cpp26-support`
- `fix/38-workflow-matrix-bug`
- `docs/45-update-api-guide`

### Automation Tools

- `./scripts/gh_create_issue_branch.sh <issue>` - Create semantic branch from issue
- `./scripts/gh_create_pr.sh` - Create PR with auto-filled template
- `commit-msg` hook - Validates semantic commit format

### Validation

- PR validation workflow checks title, branch name, commits
- commit-msg hook validates locally before commit
- All commits must reference an issue

### Complete Workflow Example

```bash
# 1. Create/find issue
gh issue create --title "Add feature X" --label "enhancement"

# 2. Create branch
./scripts/gh_create_issue_branch.sh 42

# 3. Make changes and commit
git commit -m "feat(scope): add feature X

Detailed description.

Closes #42"

# 4. Push and create PR
git push -u origin feat/42-add-feature-x
./scripts/gh_create_pr.sh
```

**Documentation:**
- [docs/CONTRIBUTING.md](../../docs/CONTRIBUTING.md) - Full workflow guide
- [docs/SEMANTIC-COMMITS.md](../../docs/SEMANTIC-COMMITS.md) - Commit format reference
- [.github/ISSUE_TEMPLATE/](../../.github/ISSUE_TEMPLATE/) - Issue templates
- [.github/PULL_REQUEST_TEMPLATE.md](../../.github/PULL_REQUEST_TEMPLATE.md) - PR template

## Change Hygiene
- Update documentation, scripts, and templates whenever code behaviour changes.
- Keep Nix flakes, language templates, and automation scripts in sync with documentation in `README.md` and `docs/`.
- Prefer small, well-scoped commits with clear intent and context.
- All commits must follow semantic format and reference issues.
- Update CHANGELOG.md for significant changes.

## Coding Style
- Follow repository conventions defined in `configs/` and language-specific tooling (formatters, linters, etc.).
- Opt for clarity over clever optimisations; comment only when intent may be non-obvious.
- Scripts must use `#!/usr/bin/env bash` and `set -euo pipefail`.
- Pass shellcheck validation for all shell scripts.

## Tooling Expectations
- Run available formatters/lints/tests relevant to your changes.
- Add or update tests when fixing bugs or changing behaviour.
- Validate `scripts/repo_setup.sh` or other bootstrap scripts using a temporary repo when touched.
- Use automation scripts for branch/PR creation to ensure consistency.

## Context Memory
- Record meaningful repository patterns, workflows, or pitfalls in `project-context.md` after significant changes.
- Note structural shifts (new directories, renamed templates, etc.) so future sessions stay aligned.
- Document workflow changes and new automation tools.

## Quality Standards

- **Scripts**: Pass shellcheck, use proper error handling
- **Workflows**: Include Nix detection, proper matrix configuration, caching
- **Documentation**: Include examples, maintain cross-references
- **Tests**: All existing pass, add tests for new features
- **Security**: No secrets committed, proper input validation

## Guiding Principle

Treat Artagon repositories as professional, human-run projects. Automation assists delivery, but human accountability, thorough docs, and reproducible workflows take precedence.

**All development must follow the issue-driven workflow.** This ensures traceability, proper review process, and maintains project quality standards.
