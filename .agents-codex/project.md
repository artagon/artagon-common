---
# Codex Agent Configuration
# This file contains Codex-specific settings and references shared context
context:
  include:
    - ../.agents-shared/project-context.md
    - ../.agents-shared/preferences.md
    - ../docs/CONTRIBUTING.md
    - ../docs/SEMANTIC-COMMITS.md
    - ../CHANGELOG.md
    - ../.github/PULL_REQUEST_TEMPLATE.md
inherits_from: "../.agents-shared/preferences.md#model_overrides/codex"
---

# Codex Agent for Artagon Common

## Agent Identity

You are assisting with the **artagon-common** repository, which provides shared infrastructure, templates, scripts, and automation for Artagon projects.

## Core Context

All shared preferences and project context are maintained in:
- `../.agents-shared/preferences.md` - Workflow preferences and standards
- `../.agents-shared/project-context.md` - Project structure and recent changes
- `../.agents-shared/CLAUDE.md` - Claude collaboration guidance kept aligned with model configs

## Key Reminders

1. **Never commit with AI attribution** - Human authors only.
2. **All changes require an issue** - Follow the issue-driven workflow.
3. **Follow semantic commit format** - Hooks enforce compliance.
4. **Update documentation** - Keep docs synchronized with code.
5. **Test before committing** - Run relevant tests and linters.

## Quick Reference

### Create Issue and Branch
```bash
# Create issue first
gh issue create --title "..." --label "enhancement"

# Create semantic branch
./scripts/gh_create_issue_branch.sh <issue-number>
```

### Semantic Commit
```bash
git commit -m "feat(scope): add feature

Detailed explanation.

Closes #<issue>"
```

### Create PR
```bash
./scripts/gh_create_pr.sh
```

## Quality Checklist

Before committing:
- [ ] Code follows repository conventions
- [ ] Scripts pass shellcheck (where applicable)
- [ ] Documentation updated
- [ ] Tests added/updated where needed
- [ ] Semantic commit format used
- [ ] Issue reference included

## See Also

- [Shared Preferences](../.agents-shared/preferences.md)
- [Project Context](../.agents-shared/project-context.md)
- [Contributing Guide](../docs/CONTRIBUTING.md)
- [Semantic Commits](../docs/SEMANTIC-COMMITS.md)

## Codex-Specific Settings

### Code Completion Focus
- Prioritize clean, idiomatic code
- Follow established patterns in the codebase
- Use type hints and documentation strings where applicable

### Shell Script Standards
- Always use `#!/usr/bin/env bash`
- Include `set -euo pipefail` at the start
- Pass shellcheck validation
- Provide clear error messages

### Multi-Language Support
- Respect language-specific conventions in `configs/`
- Follow formatter/linter configurations
- Maintain consistency with existing templates
