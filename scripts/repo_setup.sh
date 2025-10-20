#!/usr/bin/env bash
set -euo pipefail

# repo_setup.sh - Artagon Project Repository Setup Script
#
# Creates and configures a new project repository with language-specific
# templates, Nix integration, and GitHub configurations.
#
# Automatically sets up:
#   - GitHub PR and issue templates (symlinked from artagon-common)
#   - Auto-labeler configuration
#   - Git hooks for semantic commits and pre-commit checks
#   - .editorconfig for consistent editor settings
#   - CONTRIBUTING.md from template
#
# Usage:
#   ./repo_setup.sh --type <java|c|cpp|rust> --name <project-name> [options]
#
# Options:
#   --type <lang>          Project language: java, c, cpp, rust (required)
#   --name <name>          Project name (required)
#   --owner <org|user>     GitHub owner (default: artagon)
#   --description <text>   Project description
#   --private              Create private repository (default: public)
#   --public               Create public repository
#   --with-nix             Include Nix flake for reproducible builds
#   --branch-protection    Apply branch protection rules
#   --ssh                  Use SSH protocol (default)
#   --https                Use HTTPS protocol
#   --force                Skip confirmation prompts
#   -h, --help             Show this help

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_COMMON_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
LIB_PATH="${SCRIPT_DIR}/lib/common.sh"

# shellcheck source=scripts/lib/common.sh
source "${LIB_PATH}"

# Default values
PROJECT_TYPE=""
PROJECT_NAME=""
OWNER="artagon"
DESCRIPTION=""
VISIBILITY="public"
WITH_NIX="false"
BRANCH_PROTECTION="false"
PROTOCOL="ssh"
FORCE="false"
BUILD_SYSTEM="cmake"  # cmake or bazel

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
error() {
    echo -e "${RED}ERROR: $1${NC}" >&2
    exit 1
}

info() {
    echo -e "${BLUE}INFO: $1${NC}"
}

success() {
    echo -e "${GREEN}SUCCESS: $1${NC}"
}

warn() {
    echo -e "${YELLOW}WARNING: $1${NC}"
}

show_help() {
    cat << 'EOF'
Artagon Project Repository Setup Script

Creates and configures a new project repository with language-specific
templates, Nix integration, and GitHub configurations.

USAGE:
    ./repo_setup.sh --type <lang> --name <name> [options]

REQUIRED OPTIONS:
    --type <java|c|cpp|rust>
            Project language type

    --name <project-name>
            Name of the project/repository

OPTIONS:
    --owner <org|user>
            GitHub owner/organization (default: artagon)

    --description <text>
            Project description for README and GitHub

    --private
            Create private repository

    --public
            Create public repository (default)

    --with-nix
            Include Nix flake for reproducible builds

    --branch-protection
            Apply branch protection rules after creation

    --ssh
            Use SSH protocol for git operations (default)

    --https
            Use HTTPS protocol for git operations

    --force
            Skip confirmation prompts

    -h, --help
            Show this help message

EXAMPLES:
    # Create a Java project with Nix
    ./repo_setup.sh --type java --name my-api --with-nix

    # Create a private Rust project
    ./repo_setup.sh --type rust --name secret-tool --private

    # Create a C++ project with branch protection
    ./repo_setup.sh --type cpp --name graphics-engine --branch-protection

    # Create a C project for different organization
    ./repo_setup.sh --type c --name embedded-driver --owner myorg

SUPPORTED LANGUAGES:
    java   - Java project with Maven, JDK 25
    c      - C project with CMake, GCC/Clang
    cpp    - C++ project with CMake, C++23
    rust   - Rust project with Cargo

EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --type)
            PROJECT_TYPE="$2"
            shift 2
            ;;
        --name)
            PROJECT_NAME="$2"
            shift 2
            ;;
        --owner)
            OWNER="$2"
            shift 2
            ;;
        --description)
            DESCRIPTION="$2"
            shift 2
            ;;
        --private)
            VISIBILITY="private"
            shift
            ;;
        --public)
            VISIBILITY="public"
            shift
            ;;
        --with-nix)
            WITH_NIX="true"
            shift
            ;;
        --build-system)
            BUILD_SYSTEM="$2"
            shift 2
            ;;
        --branch-protection)
            BRANCH_PROTECTION="true"
            shift
            ;;
        --ssh)
            PROTOCOL="ssh"
            shift
            ;;
        --https)
            PROTOCOL="https"
            shift
            ;;
        --force)
            FORCE="true"
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            error "Unknown option: $1\nUse --help for usage information"
            ;;
    esac
done

# Validate required parameters
if [[ -z "$PROJECT_TYPE" ]]; then
    error "Project type is required. Use --type <java|c|cpp|rust>"
fi

if [[ -z "$PROJECT_NAME" ]]; then
    error "Project name is required. Use --name <project-name>"
fi

# Validate project type
case "$PROJECT_TYPE" in
    java|c|cpp|rust)
        ;;
    *)
        error "Invalid project type: $PROJECT_TYPE\nSupported types: java, c, cpp, rust"
        ;;
esac

# Validate build system
case "$BUILD_SYSTEM" in
    cmake|bazel)
        ;;
    *)
        error "Invalid build system: $BUILD_SYSTEM\nSupported systems: cmake, bazel"
        ;;
esac

# Check prerequisites
if ! command -v git &> /dev/null; then
    error "git is not installed"
fi

if ! command -v gh &> /dev/null; then
    error "GitHub CLI (gh) is not installed\nInstall: https://cli.github.com/"
fi

# Check gh authentication
if ! gh auth status &> /dev/null; then
    error "Not authenticated with GitHub CLI\nRun: gh auth login"
fi

# Display configuration
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🚀 Artagon Repository Setup"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Project Type:        $PROJECT_TYPE"
echo "Project Name:        $PROJECT_NAME"
echo "Owner:               $OWNER"
echo "Visibility:          $VISIBILITY"
echo "Description:         ${DESCRIPTION:-<none>}"
echo "Build System:        $BUILD_SYSTEM"
echo "With Nix:            $WITH_NIX"
echo "Branch Protection:   $BRANCH_PROTECTION"
echo "Protocol:            $PROTOCOL"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Confirm unless --force
if [[ "$FORCE" != "true" ]]; then
    read -p "Proceed with repository creation? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        info "Aborted by user"
        exit 0
    fi
fi

# Create repository
info "Creating GitHub repository: $OWNER/$PROJECT_NAME"

VISIBILITY_FLAG="--public"
if [[ "$VISIBILITY" == "private" ]]; then
    VISIBILITY_FLAG="--private"
fi

# Create GitHub repository
if ! gh_repo_create "$OWNER" "$PROJECT_NAME" "$VISIBILITY_FLAG" "$DESCRIPTION" --clone; then
    error "Failed to create GitHub repository via gh CLI"
fi

if [[ ! -d "$PROJECT_NAME" ]]; then
    error "Repository directory not created: $PROJECT_NAME"
fi

cd "$PROJECT_NAME"

# Add artagon-common as submodule
info "Adding artagon-common submodule"
git submodule add git@github.com:artagon/artagon-common.git .common/artagon-common || \
    git submodule add https://github.com/artagon/artagon-common.git .common/artagon-common
git submodule update --init --recursive

# Add artagon-license as submodule
info "Adding artagon-license submodule"
git submodule add git@github.com:artagon/artagon-license.git .legal/artagon-license || \
    git submodule add https://github.com/artagon/artagon-license.git .legal/artagon-license
git submodule update --init --recursive

# Export license files from artagon-license
info "Exporting license files from artagon-license"
.legal/artagon-license/scripts/export-license-assets.sh

# Configure git hooks to use shared hooks from artagon-common
info "Configuring git hooks"
git config core.hooksPath .common/artagon-common/git-hooks
success "Git hooks configured for automatic license management"

# Setup agent directories and symlinks (unified script)
AGENTS_SYNC_SCRIPT=".common/artagon-common/scripts/gh_sync_agents.sh"
if [[ -x "${AGENTS_SYNC_SCRIPT}" ]]; then
    info "Setting up agent directories and symlinks"
    if "${AGENTS_SYNC_SCRIPT}" --ensure --quiet; then
        success "Agent directories and symlinks configured"
    else
        warn "Agent sync script reported an issue"
    fi
else
    warn "Agent sync script not found; skipping agent setup"
fi

# Setup CONTRIBUTING.md from template
CONTRIBUTING_SETUP_SCRIPT=".common/artagon-common/scripts/gh_setup_contributing.sh"
if [[ -x "${CONTRIBUTING_SETUP_SCRIPT}" ]]; then
    info "Setting up CONTRIBUTING.md from template"
    if "${CONTRIBUTING_SETUP_SCRIPT}" --repo-name "$PROJECT_NAME" --repo-owner "$OWNER" --repo-desc "${DESCRIPTION:-Artagon ${PROJECT_TYPE} project}" --force; then
        success "CONTRIBUTING.md generated from template"
    else
        warn "Failed to generate CONTRIBUTING.md from template"
    fi
else
    warn "CONTRIBUTING.md setup script not found; skipping"
fi

# Setup GitHub configuration files
info "Setting up GitHub configuration files"
GITHUB_TEMPLATES_DIR=".common/artagon-common/templates/.github"
if [[ -d "$GITHUB_TEMPLATES_DIR" ]]; then
    # Create .github directory structure
    mkdir -p .github/ISSUE_TEMPLATE

    # Symlink PR template
    if [[ -f "$GITHUB_TEMPLATES_DIR/PULL_REQUEST_TEMPLATE.md" ]]; then
        ln -sf "../.common/artagon-common/templates/.github/PULL_REQUEST_TEMPLATE.md" \
            .github/PULL_REQUEST_TEMPLATE.md
        info "Linked PR template"
    fi

    # Symlink labeler config
    if [[ -f "$GITHUB_TEMPLATES_DIR/labeler.yml" ]]; then
        ln -sf "../.common/artagon-common/templates/.github/labeler.yml" \
            .github/labeler.yml
        info "Linked labeler configuration"
    fi

    # Symlink issue templates
    if [[ -d "$GITHUB_TEMPLATES_DIR/ISSUE_TEMPLATE" ]]; then
        for template in "$GITHUB_TEMPLATES_DIR/ISSUE_TEMPLATE"/*.md; do
            if [[ -f "$template" ]]; then
                template_name=$(basename "$template")
                ln -sf "../../.common/artagon-common/templates/.github/ISSUE_TEMPLATE/$template_name" \
                    ".github/ISSUE_TEMPLATE/$template_name"
            fi
        done
        info "Linked issue templates"
    fi

    success "GitHub configuration files installed"
else
    warn "GitHub templates not found at $GITHUB_TEMPLATES_DIR; skipping"
fi

# Copy .editorconfig
EDITORCONFIG=".common/artagon-common/configs/.editorconfig"
if [[ -f "$EDITORCONFIG" ]]; then
    cp "$EDITORCONFIG" .editorconfig
    info "Copied .editorconfig"
fi

# Install git hooks
GIT_HOOKS_DIR=".common/artagon-common/git-hooks"
if [[ -d "$GIT_HOOKS_DIR" && -d ".git/hooks" ]]; then
    info "Installing git hooks"
    for hook in "$GIT_HOOKS_DIR"/*; do
        if [[ -f "$hook" ]]; then
            hook_name=$(basename "$hook")
            cp "$hook" ".git/hooks/$hook_name"
            chmod +x ".git/hooks/$hook_name"
            info "Installed git hook: $hook_name"
        fi
    done
    success "Git hooks installed"
else
    warn "Git hooks directory not found; skipping git hooks installation"
fi

# Copy language-specific templates
info "Copying $PROJECT_TYPE templates"

case "$PROJECT_TYPE" in
    java)
        # Java project structure
        mkdir -p src/{main,test}/{java,resources}
        mkdir -p .github/workflows

        # Install reusable workflow wrappers for CI/CD
        WORKFLOW_TEMPLATE_DIR=".common/artagon-common/.github/workflows/examples"
        if [[ -d "$WORKFLOW_TEMPLATE_DIR" ]]; then
            info "Installing GitHub Actions workflows"
            cp "$WORKFLOW_TEMPLATE_DIR/ci.yml" .github/workflows/ci.yml
            cp "$WORKFLOW_TEMPLATE_DIR/release-branch.yml" .github/workflows/release-branch.yml
            cp "$WORKFLOW_TEMPLATE_DIR/release-tag.yml" .github/workflows/release-tag.yml
            cp "$WORKFLOW_TEMPLATE_DIR/release.yml" .github/workflows/release.yml
            cp "$WORKFLOW_TEMPLATE_DIR/snapshot-deploy.yml" .github/workflows/snapshot-deploy.yml
        else
            warn "Workflow templates not found at $WORKFLOW_TEMPLATE_DIR; skipping GitHub Actions setup"
        fi

        # Copy templates
        cp .common/artagon-common/configs/java/settings.xml .

        # Create basic pom.xml
        cat > pom.xml << EOF
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0
         http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>

    <groupId>com.artagon</groupId>
    <artifactId>${PROJECT_NAME}</artifactId>
    <version>0.1.0-SNAPSHOT</version>
    <packaging>jar</packaging>

    <name>${PROJECT_NAME}</name>
    <description>${DESCRIPTION:-Artagon ${PROJECT_TYPE} project}</description>

    <properties>
        <java.version>25</java.version>
        <maven.compiler.source>\${java.version}</maven.compiler.source>
        <maven.compiler.target>\${java.version}</maven.compiler.target>
        <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
    </properties>

    <dependencies>
        <!-- Add dependencies here -->
    </dependencies>

    <build>
        <plugins>
            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-compiler-plugin</artifactId>
                <version>3.13.0</version>
            </plugin>
        </plugins>
    </build>
</project>
EOF

        # Copy .gitignore
        if [[ -f .common/artagon-common/configs/java/.gitignore.template ]]; then
            cp .common/artagon-common/configs/java/.gitignore.template .gitignore
        elif [[ -f .common/artagon-common/configs/.gitignore.template ]]; then
            cp .common/artagon-common/configs/.gitignore.template .gitignore
        fi
        ;;

    c)
        # C project structure
        mkdir -p src include tests docs .github/workflows

        # Build system specific setup
        if [[ "$BUILD_SYSTEM" == "bazel" ]]; then
            # Copy Bazel templates
            cp .common/artagon-common/configs/c/bazel/.bazelversion .
            cp .common/artagon-common/configs/c/bazel/.bazelrc .
            cp .common/artagon-common/configs/c/bazel/MODULE.bazel .
            cp .common/artagon-common/configs/c/bazel/WORKSPACE.bazel .
            cp .common/artagon-common/configs/c/bazel/BUILD.bazel .
            sed -i.bak "s/PROJECT_NAME/${PROJECT_NAME}/g" MODULE.bazel WORKSPACE.bazel BUILD.bazel && \
                rm -f MODULE.bazel.bak WORKSPACE.bazel.bak BUILD.bazel.bak
        else
            # Copy CMake templates
            cp .common/artagon-common/configs/c/CMakeLists.txt.template CMakeLists.txt
            sed -i.bak "s/PROJECT_NAME/${PROJECT_NAME}/g" CMakeLists.txt && rm CMakeLists.txt.bak
        fi

        cp .common/artagon-common/configs/c/.clang-format .
        cp .common/artagon-common/configs/c/.gitignore.template .gitignore

        # Copy GitHub Actions workflows
        if [ -d .common/artagon-common/configs/c/.github-workflows-examples ]; then
            cp .common/artagon-common/configs/c/.github-workflows-examples/*.yml .github/workflows/
        fi

        # Create basic main.c
        cat > src/main.c << EOF
#include <stdio.h>

int main(int argc, char *argv[]) {
    printf("Hello from ${PROJECT_NAME}!\n");
    return 0;
}
EOF

        # Create basic header
        HEADER_GUARD="$(generate_header_guard "$PROJECT_NAME")"
        cat > include/${PROJECT_NAME}.h << EOF
#ifndef ${HEADER_GUARD}_H
#define ${HEADER_GUARD}_H

// Add your public API here

#endif // ${HEADER_GUARD}_H
EOF
        ;;

    cpp)
        # C++ project structure
        mkdir -p src include tests docs .github/workflows

        # Build system specific setup
        if [[ "$BUILD_SYSTEM" == "bazel" ]]; then
            # Copy Bazel templates
            cp .common/artagon-common/configs/cpp/bazel/.bazelversion .
            cp .common/artagon-common/configs/cpp/bazel/.bazelrc .
            cp .common/artagon-common/configs/cpp/bazel/MODULE.bazel .
            cp .common/artagon-common/configs/cpp/bazel/WORKSPACE.bazel .
            cp .common/artagon-common/configs/cpp/bazel/BUILD.bazel .
            sed -i.bak "s/PROJECT_NAME/${PROJECT_NAME}/g" MODULE.bazel WORKSPACE.bazel BUILD.bazel && \
                rm -f MODULE.bazel.bak WORKSPACE.bazel.bak BUILD.bazel.bak
        else
            # Copy CMake templates
            cp .common/artagon-common/configs/cpp/CMakeLists.txt.template CMakeLists.txt
            sed -i.bak "s/PROJECT_NAME/${PROJECT_NAME}/g" CMakeLists.txt && rm CMakeLists.txt.bak
        fi

        cp .common/artagon-common/configs/cpp/.clang-format .
        cp .common/artagon-common/configs/cpp/.clang-tidy .
        cp .common/artagon-common/configs/cpp/.gitignore.template .gitignore

        # Copy GitHub Actions workflows
        if [ -d .common/artagon-common/configs/cpp/.github-workflows-examples ]; then
            cp .common/artagon-common/configs/cpp/.github-workflows-examples/*.yml .github/workflows/
        fi

        # Create basic main.cpp
        cat > src/main.cpp << EOF
#include <iostream>

int main(int argc, char* argv[]) {
    std::cout << "Hello from ${PROJECT_NAME}!" << std::endl;
    return 0;
}
EOF

        # Create basic header
        HEADER_GUARD="$(generate_header_guard "$PROJECT_NAME")"
        cat > include/${PROJECT_NAME}.hpp << EOF
#ifndef ${HEADER_GUARD}_HPP
#define ${HEADER_GUARD}_HPP

#include <string>

namespace ${PROJECT_NAME//-/_} {

// Add your public API here

} // namespace ${PROJECT_NAME//-/_}

#endif // ${HEADER_GUARD}_HPP
EOF
        ;;

    rust)
        # Initialize Cargo project
        info "Initializing Rust project with Cargo"
        cargo init --name "${PROJECT_NAME}"

        # Copy templates
        cp .common/artagon-common/configs/rust/Cargo.toml.template Cargo.toml.new
        sed -i.bak "s/PROJECT_NAME/${PROJECT_NAME}/g" Cargo.toml.new && rm Cargo.toml.new.bak

        # Merge with generated Cargo.toml
        if [[ -f Cargo.toml ]]; then
            mv Cargo.toml Cargo.toml.orig
            mv Cargo.toml.new Cargo.toml
        fi

        cp .common/artagon-common/configs/rust/rustfmt.toml .
        cp .common/artagon-common/configs/rust/clippy.toml .
        cp -r .common/artagon-common/configs/rust/.cargo .
        cp .common/artagon-common/configs/rust/.gitignore.template .gitignore
        ;;
esac

# Add Nix development environment if requested
if [[ "$WITH_NIX" == "true" ]]; then
    info "Adding Nix development environment"

    # Add artagon-nix as submodule if not already present
    if [ ! -d ".nix/artagon-nix/.git" ] && ! grep -q '\.nix/artagon-nix' .gitmodules 2>/dev/null; then
        git submodule add "${GIT_PROTOCOL}github.com/${GITHUB_ORG}/artagon-nix.git" .nix/artagon-nix
    fi
    git submodule update --init --recursive

    # Checkout v1 tag for stability
    (cd .nix/artagon-nix && git checkout v1)
    git add .nix/artagon-nix

    # Create symlink to appropriate template
    if [[ -f .nix/artagon-nix/templates/${PROJECT_TYPE}/flake.nix ]]; then
        ln -sfn ".nix/artagon-nix/templates/${PROJECT_TYPE}/flake.nix" "./flake.nix"
        success "Nix flake symlink created"

        # Create .envrc for direnv integration (optional)
        cat > .envrc << 'EOF'
# Use Nix flake
use flake

# Or specify shell explicitly:
# use flake .#default
EOF

        info "Created .envrc for direnv integration"
        info "Run 'direnv allow' to activate (requires direnv)"
    else
        warn "No Nix template found for $PROJECT_TYPE in artagon-nix"
    fi
fi

# Create README
info "Creating README.md"
cat > README.md << EOF
# ${PROJECT_NAME}

${DESCRIPTION:-Artagon ${PROJECT_TYPE} project}

## Building

EOF

case "$PROJECT_TYPE" in
    java)
        cat >> README.md << 'EOF'
```bash
# Build
mvn clean install

# Run tests
mvn test

# Run
mvn exec:java
```

## Maven Setup

Copy \`settings.xml\` to \`~/.m2/settings.xml\` and configure your credentials.

EOF
        ;;
    c|cpp)
        if [[ "$BUILD_SYSTEM" == "bazel" ]]; then
            cat >> README.md << 'EOF'
```bash
# Build
bazel build //...

# Run tests
bazel test //...

# Run
bazel run //:main

# Build with specific config
bazel build --config=release //...
```

## Bazel Configurations

Available configs (see `.bazelrc`):
- `release` - Optimized release build
- `debug` - Debug build with symbols
- `asan` - Address sanitizer
- `ubsan` - Undefined behavior sanitizer
- `tsan` - Thread sanitizer
- `coverage` - Code coverage

EOF
        else
            cat >> README.md << 'EOF'
```bash
# Build
mkdir build && cd build
cmake ..
make

# Run tests
make test

# Run
./bin/PROJECT_NAME
```

EOF
        fi
        ;;
    rust)
        cat >> README.md << 'EOF'
```bash
# Build
cargo build

# Run tests
cargo test

# Run
cargo run
```

EOF
        ;;
esac

if [[ "$WITH_NIX" == "true" ]]; then
    cat >> README.md << 'EOF'
## Nix Development Shell

```bash
# Enter development environment
nix develop

# Or with direnv
direnv allow
```

EOF
fi

cat >> README.md << 'EOF'
## Shared Tooling via artagon-common

This project vendors `.common/artagon-common`, which provides shared automation and configuration:

- `codex/` exposes project overlays layered on top of shared Codex preferences in `codex/shared/`
- `.common/artagon-common/scripts/` offers setup, CI, release, and security tooling
- `.common/artagon-common/docs/` captures standards and reference material

See `.common/artagon-common/README.md` for the full capability catalog.

EOF

cat >> README.md << 'EOF'
## Licensing

This project uses a dual licensing model:

- **GNU Affero General Public License v3.0 (AGPL-3.0)** for open source
  use. See [`licenses/LICENSE-AGPL.txt`](licenses/LICENSE-AGPL.txt) for the full text.
- **Commercial License** for proprietary use, available from Artagon LLC
  with expanded rights, warranties, and support. Review
  [`licenses/LICENSE-COMMERCIAL.txt`](licenses/LICENSE-COMMERCIAL.txt) or
  contact `sales@artagon.com`.

Need help choosing? Read [`licenses/LICENSING.md`](licenses/LICENSING.md) for
a decision guide. Commercial pricing is available at
https://www.artagon.com/pricing.

EOF

# LICENSE file is already exported from artagon-license submodule
# No need to create it separately

# Initial commit
info "Creating initial commit"
git add .
git commit -m "Initial commit: ${PROJECT_TYPE} project setup

- Project structure initialized
- artagon-common submodule added
- artagon-license submodule added
- Dual licensing (AGPL-3.0 / Commercial) configured
- Git hooks enabled for automatic license management
- Build configuration added${WITH_NIX:+
- artagon-nix submodule added for reproducible development environment}"

# Push to GitHub
info "Pushing to GitHub"
git push -u origin main

# Apply branch protection if requested
if [[ "$BRANCH_PROTECTION" == "true" ]]; then
    info "Applying branch protection rules"
    TEAM_PROTECT_SCRIPT=".common/artagon-common/scripts/ci/gh_protect_main_team.sh"
    BASIC_PROTECT_SCRIPT=".common/artagon-common/scripts/ci/gh_protect_main.sh"

    if [[ -x "$TEAM_PROTECT_SCRIPT" ]]; then
        "$TEAM_PROTECT_SCRIPT" --repo "$PROJECT_NAME" --owner "$OWNER" --branch main --force
        success "Team branch protection applied to main"
    elif [[ -x "$BASIC_PROTECT_SCRIPT" ]]; then
        warn "Team branch protection script not found; falling back to basic protection"
        "$BASIC_PROTECT_SCRIPT" --repo "$PROJECT_NAME" --owner "$OWNER" --branch main --force
        success "Basic branch protection applied to main"
    else
        warn "Branch protection scripts not found in .common/artagon-common/scripts/ci"
    fi

    info "Reminder: once you cut a release-x.y.z branch, run gh_protect_main_team.sh for that branch to mirror the guardrails."
fi

# Summary
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
success "Repository setup complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Repository: https://github.com/$OWNER/$PROJECT_NAME"
echo "Local path: $(pwd)"
echo ""
echo "Next steps:"
case "$PROJECT_TYPE" in
    java)
        echo "  1. Configure Maven settings: cp settings.xml ~/.m2/"
        echo "  2. Build project: mvn clean install"
        ;;
    c|cpp)
        echo "  1. Build project: mkdir build && cd build && cmake .. && make"
        echo "  2. Format code: clang-format -i src/**/*"
        ;;
    rust)
        echo "  1. Build project: cargo build"
        echo "  2. Format code: cargo fmt"
        ;;
esac

if [[ "$WITH_NIX" == "true" ]]; then
    echo "  • Enter Nix shell: nix develop"
fi

echo ""
success "Happy coding! 🚀"
echo ""
