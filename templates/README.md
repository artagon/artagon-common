# Artagon Project Templates

This directory contains templates for new Artagon projects that use GitHub's template repository feature with automatic variable substitution.

## Available Templates

### CONTRIBUTING.md.template

A comprehensive contributing guide template that automatically customizes itself for new projects.

## Using Templates with GitHub Repository Templates

### Method 1: When Creating Repository from Template

When you create a new repository from artagon-common using GitHub's "Use this template" feature:

1. Click "Use this template" → "Create a new repository"
2. Fill in repository name and description
3. After creation, copy the template to your project root:

```bash
# In your new repository
cp templates/CONTRIBUTING.md.template CONTRIBUTING.md

# GitHub will have already substituted the variables
```

### Method 2: Manual Variable Substitution

If not using GitHub's template feature, manually replace variables:

```bash
# Copy template
cp templates/CONTRIBUTING.md.template CONTRIBUTING.md

# Replace variables
REPO_NAME="your-project-name"
REPO_OWNER="artagon"
REPO_DESC="Your project description"

# macOS
sed -i '' "s/{{ repository.name }}/$REPO_NAME/g" CONTRIBUTING.md
sed -i '' "s/{{ repository.owner }}/$REPO_OWNER/g" CONTRIBUTING.md
sed -i '' "s/{{ repository.description }}/$REPO_DESC/g" CONTRIBUTING.md

# Linux
sed -i "s/{{ repository.name }}/$REPO_NAME/g" CONTRIBUTING.md
sed -i "s/{{ repository.owner }}/$REPO_OWNER/g" CONTRIBUTING.md
sed -i "s/{{ repository.description }}/$REPO_DESC/g" CONTRIBUTING.md
```

## Template Variables

Templates use GitHub's template variable syntax:

| Variable | Description | Example |
|----------|-------------|---------|
| `{{ repository.name }}` | Repository name | `artagon-workflows` |
| `{{ repository.owner }}` | Organization/owner | `artagon` |
| `{{ repository.description }}` | Repository description | `Reusable GitHub Actions workflows` |

## Customizing Templates

After copying and substituting variables, customize project-specific sections:

### In CONTRIBUTING.md

1. **Prerequisites**: Add project-specific tools
   ```markdown
   ### Prerequisites
   - Git 2.30+
   - Node.js 18+ (YOUR PROJECT)
   - Docker (YOUR PROJECT)
   ```

2. **Install Dependencies**: Add actual commands
   ```bash
   npm install
   cargo build
   pip install -r requirements.txt
   ```

3. **Language-Specific Standards**: Uncomment and expand relevant section

4. **Testing**: Add actual test commands

5. **Project-Specific Guidelines**: Fill in architecture, design decisions, tips

## Adding New Templates

To add a new template:

1. Create file in `templates/` with `.template` extension
2. Use GitHub template variable syntax: `{{ variable.name }}`
3. Document in this README
4. Test by creating a repository from template

### Template Variable Guidelines

- Use descriptive placeholder text for manual editing
- Mark customization sections clearly with `_(add your ...)_`
- Provide examples where helpful
- Use consistent formatting

## Examples

### Example 1: artagon-workflows

```markdown
# Contributing to artagon-workflows

Thank you for your interest in contributing to **artagon-workflows**!
This project follows Artagon's standardized development workflow.

> Reusable GitHub Actions workflows for Artagon projects
```

### Example 2: artagon-nix

```markdown
# Contributing to artagon-nix

Thank you for your interest in contributing to **artagon-nix**!
This project follows Artagon's standardized development workflow.

> Nix flake templates and tooling for reproducible development environments
```

## Automation

### Using with Scripts

The `gh_sync_agents.sh` script can be extended to automatically set up CONTRIBUTING.md:

```bash
# In gh_sync_agents.sh or repo_setup.sh
if [[ -f templates/CONTRIBUTING.md.template ]] && [[ ! -f CONTRIBUTING.md ]]; then
  REPO_NAME=$(basename $(git rev-parse --show-toplevel))
  REPO_OWNER=$(git remote get-url origin | sed -E 's/.*[:/]([^/]+)\/[^/]+$/\1/')
  REPO_DESC=$(gh repo view --json description -q .description 2>/dev/null || echo "")

  cp templates/CONTRIBUTING.md.template CONTRIBUTING.md
  sed -i "s/{{ repository.name }}/$REPO_NAME/g" CONTRIBUTING.md
  sed -i "s/{{ repository.owner }}/$REPO_OWNER/g" CONTRIBUTING.md
  sed -i "s/{{ repository.description }}/$REPO_DESC/g" CONTRIBUTING.md
  echo "✓ Generated CONTRIBUTING.md from template"
fi
```

## See Also

- [GitHub Template Repositories](https://docs.github.com/en/repositories/creating-and-managing-repositories/creating-a-template-repository)
- [GitHub Template Variables](https://docs.github.com/en/repositories/creating-and-managing-repositories/creating-a-repository-from-a-template)
- [Artagon Contributing Guide](../docs/CONTRIBUTING.md)
- [Semantic Commits](../docs/SEMANTIC-COMMITS.md)
