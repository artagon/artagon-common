#!/usr/bin/env bash
# apply_github_configs.sh - Apply GitHub configurations to existing projects
#
# This script applies the new GitHub configuration setup to existing
# projects that already have artagon-common as a submodule.
#
# Usage:
#   cd <project-root>
#   ./.common/artagon-common/scripts/apply_github_configs.sh

set -euo pipefail

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

info() { echo -e "${GREEN}[INFO]${NC} $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; }

# Check if we're in a project root with artagon-common submodule
if [[ ! -d ".common/artagon-common" ]]; then
    error "Not in a project root with .common/artagon-common submodule"
    error "Run this script from the project root directory"
    exit 1
fi

COMMON_DIR=".common/artagon-common"
GITHUB_TEMPLATES="$COMMON_DIR/templates/.github"

if [[ ! -d "$GITHUB_TEMPLATES" ]]; then
    error "GitHub templates not found at $GITHUB_TEMPLATES"
    error "Make sure artagon-common submodule is up to date"
    exit 1
fi

info "Applying GitHub configurations..."

# Create .github directory if missing
mkdir -p .github/ISSUE_TEMPLATE

# Symlink PR template
if [[ -f "$GITHUB_TEMPLATES/PULL_REQUEST_TEMPLATE.md" ]]; then
    if [[ -e ".github/PULL_REQUEST_TEMPLATE.md" ]] && [[ ! -L ".github/PULL_REQUEST_TEMPLATE.md" ]]; then
        warn "Existing PULL_REQUEST_TEMPLATE.md is not a symlink, backing up..."
        mv .github/PULL_REQUEST_TEMPLATE.md .github/PULL_REQUEST_TEMPLATE.md.bak
    fi

    ln -sf "../$COMMON_DIR/templates/.github/PULL_REQUEST_TEMPLATE.md" \
        .github/PULL_REQUEST_TEMPLATE.md
    info "✓ Linked PR template"
fi

# Symlink labeler config
if [[ -f "$GITHUB_TEMPLATES/labeler.yml" ]]; then
    if [[ -e ".github/labeler.yml" ]] && [[ ! -L ".github/labeler.yml" ]]; then
        warn "Existing labeler.yml is not a symlink, backing up..."
        mv .github/labeler.yml .github/labeler.yml.bak
    fi

    ln -sf "../$COMMON_DIR/templates/.github/labeler.yml" \
        .github/labeler.yml
    info "✓ Linked labeler configuration"
fi

# Symlink issue templates
if [[ -d "$GITHUB_TEMPLATES/ISSUE_TEMPLATE" ]]; then
    for template in "$GITHUB_TEMPLATES/ISSUE_TEMPLATE"/*.md; do
        if [[ -f "$template" ]]; then
            template_name=$(basename "$template")
            target_path=".github/ISSUE_TEMPLATE/$template_name"

            if [[ -e "$target_path" ]] && [[ ! -L "$target_path" ]]; then
                warn "Existing $template_name is not a symlink, backing up..."
                mv "$target_path" "${target_path}.bak"
            fi

            ln -sf "../../$COMMON_DIR/templates/.github/ISSUE_TEMPLATE/$template_name" \
                "$target_path"
        fi
    done
    info "✓ Linked issue templates"
fi

# Copy .editorconfig if it doesn't exist
if [[ -f "$COMMON_DIR/configs/.editorconfig" ]] && [[ ! -f ".editorconfig" ]]; then
    cp "$COMMON_DIR/configs/.editorconfig" .editorconfig
    info "✓ Copied .editorconfig"
elif [[ -f ".editorconfig" ]]; then
    info "  .editorconfig already exists, skipping"
fi

# Install git hooks
if [[ -d "$COMMON_DIR/git-hooks" ]] && [[ -d ".git/hooks" ]]; then
    info "Installing git hooks..."
    for hook in "$COMMON_DIR/git-hooks"/*; do
        if [[ -f "$hook" ]]; then
            hook_name=$(basename "$hook")
            cp "$hook" ".git/hooks/$hook_name"
            chmod +x ".git/hooks/$hook_name"
            info "  ✓ Installed $hook_name"
        fi
    done
else
    warn "Git hooks directory not found, skipping"
fi

echo ""
info "GitHub configurations applied successfully!"
info ""
info "Changes made:"
info "  - Symlinked PR and issue templates"
info "  - Symlinked labeler configuration"
info "  - Copied .editorconfig (if missing)"
info "  - Installed git hooks"
info ""
info "Next steps:"
info "  1. Review the symlinks: ls -la .github/"
info "  2. Test git hooks: git commit (will validate semantic format)"
info "  3. Commit these changes to your project"
