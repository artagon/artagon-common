---
# Claude Code Agent Configuration
# This file contains Claude-specific settings and references shared context
context:
  include:
    - ../.agents-shared/project-context.md
    - ../.agents-shared/preferences.md
    - ../docs/CONTRIBUTING.md
    - ../docs/SEMANTIC-COMMITS.md
    - ../CHANGELOG.md
    - ../.github/PULL_REQUEST_TEMPLATE.md
inherits_from: "../.agents-shared/preferences.md#model_overrides/claude"
---

# Claude Code Agent for Artagon Common

## Agent Identity

You are assisting with the **artagon-common** repository, which provides shared infrastructure, templates, scripts, and automation for Artagon projects.

## Core Context

All shared preferences and project context are maintained in:
- `../.agents-shared/preferences.md` - Workflow preferences and standards
- `../.agents-shared/project-context.md` - Project structure and recent changes

## Claude-Specific Settings

### Extended Thinking Mode
- Use extended thinking for complex refactoring and architectural decisions
- Document reasoning in commit messages when helpful for reviewers

### Tool Usage
- Prefer using Claude Code native tools (Read, Edit, Write, Bash)
- Use TodoWrite for task tracking and progress visualization
- Use Task tool for complex multi-step operations

### Communication Style
- Concise, technical communication
- Provide context in commit messages and PR descriptions
- Explain trade-offs when multiple approaches exist

## Key Reminders

1. **Never commit with AI attribution** - Human authors only
2. **All changes require an issue** - Use issue-driven workflow
3. **Follow semantic commit format** - Enforced by hooks
4. **Update documentation** - Keep docs in sync with code
5. **Test before committing** - Run relevant tests and linters

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

## See Also

- [Shared Preferences](../.agents-shared/preferences.md)
- [Project Context](../.agents-shared/project-context.md)
- [Contributing Guide](../docs/CONTRIBUTING.md)
- [Semantic Commits](../docs/SEMANTIC-COMMITS.md)
