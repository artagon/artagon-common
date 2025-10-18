#!/usr/bin/env bash
set -euo pipefail

# setup-repo.sh - Artagon Project Repository Setup Script
#
# Creates and configures a new project repository with language-specific
# templates, Nix integration, and GitHub configurations.
#
# Usage:
#   ./setup-repo.sh --type <java|c|cpp|rust> --name <project-name> [options]
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
COMMON_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

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
    ./setup-repo.sh --type <lang> --name <name> [options]

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
    ./setup-repo.sh --type java --name my-api --with-nix

    # Create a private Rust project
    ./setup-repo.sh --type rust --name secret-tool --private

    # Create a C++ project with branch protection
    ./setup-repo.sh --type cpp --name graphics-engine --branch-protection

    # Create a C project for different organization
    ./setup-repo.sh --type c --name embedded-driver --owner myorg

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

DESCRIPTION_FLAG=""
if [[ -n "$DESCRIPTION" ]]; then
    DESCRIPTION_FLAG="--description \"$DESCRIPTION\""
fi

# Create GitHub repository
eval gh repo create "$OWNER/$PROJECT_NAME" $VISIBILITY_FLAG $DESCRIPTION_FLAG --clone

if [[ ! -d "$PROJECT_NAME" ]]; then
    error "Repository directory not created: $PROJECT_NAME"
fi

cd "$PROJECT_NAME"

# Add artagon-common as submodule
info "Adding artagon-common submodule"
git submodule add git@github.com:artagon/artagon-common.git .common/artagon-common || \
    git submodule add https://github.com/artagon/artagon-common.git .common/artagon-common
git submodule update --init --recursive

# Copy language-specific templates
info "Copying $PROJECT_TYPE templates"

case "$PROJECT_TYPE" in
    java)
        # Java project structure
        mkdir -p src/{main,test}/{java,resources}
        mkdir -p .github/workflows

        # Copy templates
        cp .common/artagon-common/templates/settings.xml .

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
        if [[ -f .common/artagon-common/templates/java/.gitignore.template ]]; then
            cp .common/artagon-common/templates/java/.gitignore.template .gitignore
        fi
        ;;

    c)
        # C project structure
        mkdir -p src include tests docs

        # Copy templates
        cp .common/artagon-common/templates/c/CMakeLists.txt.template CMakeLists.txt
        sed -i.bak "s/PROJECT_NAME/${PROJECT_NAME}/g" CMakeLists.txt && rm CMakeLists.txt.bak

        cp .common/artagon-common/templates/c/.clang-format .
        cp .common/artagon-common/templates/c/.gitignore.template .gitignore

        # Create basic main.c
        cat > src/main.c << EOF
#include <stdio.h>

int main(int argc, char *argv[]) {
    printf("Hello from ${PROJECT_NAME}!\n");
    return 0;
}
EOF

        # Create basic header
        cat > include/${PROJECT_NAME}.h << EOF
#ifndef ${PROJECT_NAME^^}_H
#define ${PROJECT_NAME^^}_H

// Add your public API here

#endif // ${PROJECT_NAME^^}_H
EOF
        ;;

    cpp)
        # C++ project structure
        mkdir -p src include tests docs

        # Copy templates
        cp .common/artagon-common/templates/cpp/CMakeLists.txt.template CMakeLists.txt
        sed -i.bak "s/PROJECT_NAME/${PROJECT_NAME}/g" CMakeLists.txt && rm CMakeLists.txt.bak

        cp .common/artagon-common/templates/cpp/.clang-format .
        cp .common/artagon-common/templates/cpp/.clang-tidy .
        cp .common/artagon-common/templates/cpp/.gitignore.template .gitignore

        # Create basic main.cpp
        cat > src/main.cpp << EOF
#include <iostream>

int main(int argc, char* argv[]) {
    std::cout << "Hello from ${PROJECT_NAME}!" << std::endl;
    return 0;
}
EOF

        # Create basic header
        cat > include/${PROJECT_NAME}.hpp << EOF
#ifndef ${PROJECT_NAME^^}_HPP
#define ${PROJECT_NAME^^}_HPP

#include <string>

namespace ${PROJECT_NAME//-/_} {

// Add your public API here

} // namespace ${PROJECT_NAME//-/_}

#endif // ${PROJECT_NAME^^}_HPP
EOF
        ;;

    rust)
        # Initialize Cargo project
        info "Initializing Rust project with Cargo"
        cargo init --name "${PROJECT_NAME}"

        # Copy templates
        cp .common/artagon-common/templates/rust/Cargo.toml.template Cargo.toml.new
        sed -i.bak "s/PROJECT_NAME/${PROJECT_NAME}/g" Cargo.toml.new && rm Cargo.toml.new.bak

        # Merge with generated Cargo.toml
        if [[ -f Cargo.toml ]]; then
            mv Cargo.toml Cargo.toml.orig
            mv Cargo.toml.new Cargo.toml
        fi

        cp .common/artagon-common/templates/rust/rustfmt.toml .
        cp .common/artagon-common/templates/rust/clippy.toml .
        cp -r .common/artagon-common/templates/rust/.cargo .
        cp .common/artagon-common/templates/rust/.gitignore.template .gitignore
        ;;
esac

# Copy Nix flake if requested
if [[ "$WITH_NIX" == "true" ]]; then
    info "Adding Nix flake for reproducible builds"

    if [[ -f .common/artagon-common/nix/templates/${PROJECT_TYPE}/flake.nix ]]; then
        cp .common/artagon-common/nix/templates/${PROJECT_TYPE}/flake.nix .
        success "Nix flake added"

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
        warn "No Nix template found for $PROJECT_TYPE"
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
## License

Copyright (C) 2025 Artagon LLC. All rights reserved.

EOF

# Create LICENSE
if [[ "$VISIBILITY" == "public" ]]; then
    info "Creating LICENSE file"
    cat > LICENSE << 'EOF'
MIT License

Copyright (c) 2025 Artagon LLC

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
EOF
fi

# Initial commit
info "Creating initial commit"
git add .
git commit -m "Initial commit: ${PROJECT_TYPE} project setup

- Project structure initialized
- artagon-common submodule added
- Build configuration added${WITH_NIX:+
- Nix flake for reproducible builds}

🤖 Generated with Artagon setup-repo.sh"

# Push to GitHub
info "Pushing to GitHub"
git push -u origin main

# Apply branch protection if requested
if [[ "$BRANCH_PROTECTION" == "true" ]]; then
    info "Applying branch protection rules"

    if [[ -x .common/artagon-common/scripts/ci/protect-main-branch.sh ]]; then
        .common/artagon-common/scripts/ci/protect-main-branch.sh --repo "$PROJECT_NAME" --owner "$OWNER" --force
        success "Branch protection applied"
    else
        warn "Branch protection script not found"
    fi
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
