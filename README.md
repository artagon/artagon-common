# Artagon Common

Shared infrastructure, scripts, configurations, and templates for all Artagon LLC projects.

## Overview

This repository serves as a centralized collection of common tooling used across the Artagon ecosystem. By consolidating these resources, we ensure consistency, reduce duplication, and simplify maintenance across all projects.

### What's Included

- **Scripts**: Automation for builds, deployments, CI/CD, and development workflows
- **Templates**: Standardized project files (.gitignore, README, etc.)
- **Configs**: Shared configuration files for code quality tools
- **Workflows**: Reusable GitHub Actions workflows

## Installation

### As a Git Submodule (Recommended)

The recommended way to use `artagon-common` is as a git submodule:

```bash
# Quick setup (installs to .common/artagon-common)
bash <(curl -fsSL https://raw.githubusercontent.com/artagon/artagon-common/main/scripts/setup-artagon-common.sh)

# Or manually
git submodule add git@github.com:artagon/artagon-common.git .common/artagon-common
git submodule update --init --recursive
```

### Direct Clone

If you prefer not to use submodules:

```bash
git clone git@github.com:artagon/artagon-common.git
```

## Repository Structure

```
artagon-common/
├── scripts/                      # Automation scripts
│   ├── auto_create_and_push.sh  # GitHub repository creation and setup
│   ├── setup-artagon-common.sh  # Bootstrap this repo into projects
│   ├── build/                   # Build-related scripts
│   ├── deploy/                  # Deployment automation
│   ├── ci/                      # CI/CD helpers
│   └── dev/                     # Development tools
├── templates/                    # Project templates
│   ├── .gitignore.template      # Standard .gitignore
│   ├── .editorconfig           # Code style settings
│   └── README.template.md       # Project README template
├── configs/                      # Shared configurations
│   ├── checkstyle.xml          # Java code style
│   ├── spotbugs.xml            # Bug detection
│   └── pmd.xml                 # Code analysis
├── .github/
│   └── workflows/               # Reusable GitHub Actions
├── .gitignore                   # Git ignore for this repo
└── README.md                    # This file
```

## Available Scripts

### Repository Management

#### `auto_create_and_push.sh`

Automated script to create GitHub repositories, initialize git, and push initial commit.

**Features:**
- Creates GitHub repo via `gh` CLI
- Supports both SSH and HTTPS protocols
- Handles public/private repositories
- Auto-renames `master` branch to `main`
- Configurable commit messages and descriptions

**Usage:**

```bash
# Basic usage
./scripts/auto_create_and_push.sh --repo my-project --public

# With description and custom message
./scripts/auto_create_and_push.sh \
  --repo api-server \
  --private \
  --description "REST API for Artagon platform" \
  --message "Initial commit"

# For organization
./scripts/auto_create_and_push.sh \
  --owner artagon \
  --repo new-service \
  --private
```

**Options:**
- `--repo <name>` - Repository name (required)
- `--owner <org|user>` - GitHub owner (default: current user)
- `--public` - Create public repository (default)
- `--private` - Create private repository
- `--ssh` - Use SSH protocol (default)
- `--https` - Use HTTPS protocol
- `--description <text>` - Repository description
- `--message <text>` - Initial commit message
- `--force` - Skip repo creation if exists
- `--no-prompt` - Non-interactive mode

#### `setup-artagon-common.sh`

Bootstrap script to add artagon-common as a submodule to any project.

**Usage:**

```bash
# Default installation (.common/artagon-common)
./scripts/setup-artagon-common.sh

# Custom path
./scripts/setup-artagon-common.sh tools/common

# Specific branch
./scripts/setup-artagon-common.sh .common/artagon-common develop
```

### Branch Protection

Protect your `main` branch across all repositories with one command. Three protection levels available:

#### `protect-main-branch.sh` - Solo Development ⭐
Basic protection for solo developers - blocks accidents but allows direct pushes.

```bash
./scripts/protect-main-branch.sh
```

**Protects against:**
- Force pushes
- Branch deletion

**Allows:**
- Direct pushes to main
- Admin overrides

#### `protect-main-branch-team.sh` - Team Collaboration ⭐
Balanced protection for teams - requires PR reviews but allows admin emergency access.

```bash
./scripts/protect-main-branch-team.sh
```

**Requires:**
- 1 PR approval before merging
- Conversation resolution

**Allows:**
- Admin direct push in emergencies
- Merge commits

#### `protect-main-branch-strict.sh` - Maximum Protection
Strict protection for compliance environments - enforced for everyone including admins.

```bash
./scripts/protect-main-branch-strict.sh
```

**Requires:**
- 1 PR approval
- Status checks (CI/CD)
- Linear history
- Enforced for admins

#### `check-branch-protection.sh` - Status Check
View current protection settings for all repositories.

```bash
./scripts/check-branch-protection.sh
```

#### `remove-branch-protection.sh` - Remove Protection
Remove all branch protection (use with caution).

```bash
./scripts/remove-branch-protection.sh
```

**📚 Full Documentation:** See [docs/BRANCH-PROTECTION.md](docs/BRANCH-PROTECTION.md) for detailed guide, comparison table, and workflows.

## Using in Your Projects

### Option 1: Submodule (Recommended)

Add as a submodule and reference scripts:

```bash
# Add submodule
git submodule add git@github.com:artagon/artagon-common.git .common/artagon-common

# Use scripts
.common/artagon-common/scripts/auto_create_and_push.sh --help

# Or symlink to project root
ln -s .common/artagon-common/scripts/auto_create_and_push.sh ./scripts/
```

### Option 2: Copy Scripts

Copy individual scripts to your project:

```bash
cp .common/artagon-common/scripts/auto_create_and_push.sh ./scripts/
```

### Option 3: Add to PATH

For personal use, symlink to your ~/bin:

```bash
ln -s ~/Projects/Artagon/artagon-common/scripts/auto_create_and_push.sh ~/bin/
```

## Updating

### Update Submodule to Latest

```bash
# From your project root
cd .common/artagon-common
git checkout main
git pull origin main
cd ../..
git add .common/artagon-common
git commit -m "Update artagon-common to latest"
```

### Or use git submodule command

```bash
git submodule update --remote .common/artagon-common
git add .common/artagon-common
git commit -m "Update artagon-common submodule"
```

### Automated Updates

Use the provided GitHub Actions workflow to automatically update submodules weekly:

```yaml
# .github/workflows/update-common.yml
name: Update Common Scripts

on:
  schedule:
    - cron: "0 6 * * 1"  # Weekly on Monday
  workflow_dispatch:

jobs:
  update:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          submodules: true

      - name: Update submodule
        run: |
          git config user.name "github-actions[bot]"
          git config user.email "github-actions[bot]@users.noreply.github.com"
          git submodule update --remote .common/artagon-common

      - name: Check for changes
        id: changes
        run: |
          if git diff --quiet; then
            echo "changed=false" >> $GITHUB_OUTPUT
          else
            echo "changed=true" >> $GITHUB_OUTPUT
          fi

      - name: Create Pull Request
        if: steps.changes.outputs.changed == 'true'
        uses: peter-evans/create-pull-request@v5
        with:
          commit-message: "Update artagon-common submodule"
          title: "Update artagon-common to latest"
          body: "Automated update of artagon-common submodule"
          branch: update-artagon-common
```

## Versioning

This repository follows semantic versioning:

- **Major versions**: Breaking changes to scripts or APIs
- **Minor versions**: New features, backward compatible
- **Patch versions**: Bug fixes

### Pinning to Specific Version

```bash
# Pin to specific tag
cd .common/artagon-common
git checkout v1.2.3
cd ../..
git add .common/artagon-common
git commit -m "Pin artagon-common to v1.2.3"
```

## Contributing

### Adding New Scripts

1. Create script in appropriate subdirectory (`scripts/build/`, `scripts/ci/`, etc.)
2. Make executable: `chmod +x scripts/your-script.sh`
3. Add documentation to this README
4. Test thoroughly
5. Submit pull request

### Script Guidelines

- Use `#!/usr/bin/env bash` shebang
- Include `set -euo pipefail` for safety
- Add help text and usage examples
- Handle errors gracefully
- Support `--help` flag
- Document all options and flags

### Example Script Template

```bash
#!/usr/bin/env bash
set -euo pipefail

# Script description
#
# Usage:
#   ./script-name.sh [options]
#
# Options:
#   --option1 <value>  Description
#   --option2          Description
#   -h, --help         Show help

# Help text
if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  cat << 'EOF'
Usage: script-name.sh [options]

Description of what this script does.

Options:
  --option1 <value>  Description
  --option2          Description
  -h, --help         Show this help
EOF
  exit 0
fi

# Script logic here
echo "Script running..."
```

## FAQ

### Q: Should I commit the submodule or just reference it?

**A:** Commit the submodule reference (the `.gitmodules` file and the submodule directory entry). This allows others to clone your repo and automatically get the common scripts.

### Q: How do I update to the latest version?

**A:** Run `git submodule update --remote .common/artagon-common` from your project root, then commit the change.

### Q: Can I use only specific scripts?

**A:** Yes! You can copy individual scripts to your project or symlink them. However, using as a submodule ensures you get updates easily.

### Q: What if I need a different version than other projects?

**A:** That's fine! Each project's submodule can point to different commits/tags. This is actually a feature of submodules.

### Q: How do I contribute improvements?

**A:** Fork this repo, make your changes, test them, and submit a pull request. See Contributing section above.

## Support

For questions or issues:

- **General inquiries**: info@artagon.com
- **Technical issues**: Create an issue in this repository
- **Security concerns**: security@artagon.com

## License

Copyright (C) 2025 Artagon LLC. All rights reserved.

See [LICENSE](LICENSE) for details.

---

**Related Repositories:**
- [artagon-license](https://github.com/artagon/artagon-license) - Dual licensing bundle
- [artagon-parent](https://github.com/artagon/artagon-parent) - Maven parent POM
- [artagon-bom](https://github.com/artagon/artagon-bom) - Bill of Materials

**Maintainers:**
- Artagon DevOps Team <devops@artagon.com>

---

Last updated: 2025-10-18
