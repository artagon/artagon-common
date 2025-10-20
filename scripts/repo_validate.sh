#!/usr/bin/env bash
set -euo pipefail

# repo_validate.sh - Artagon Repository Validation and Update Script
#
# Validates that an existing project meets repo_setup.sh requirements
# and updates missing components to bring it into compliance.
#
# Usage:
#   ./repo_validate.sh [options]
#
# Options:
#   --check-only           Only validate, don't make changes (dry-run)
#   --fix                  Automatically fix missing components
#   --project-type <type>  Specify project type (java|c|cpp|rust)
#                         (auto-detected if not specified)
#   --force               Skip confirmation prompts
#   -h, --help            Show this help

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_COMMON_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
LIB_PATH="${SCRIPT_DIR}/lib/common.sh"

# shellcheck source=scripts/lib/common.sh
if [[ -f "${LIB_PATH}" ]]; then
    source "${LIB_PATH}"
fi

# Configuration
CHECK_ONLY="false"
FIX_MODE="false"
PROJECT_TYPE=""
FORCE="false"
VALIDATION_ERRORS=0
VALIDATION_WARNINGS=0

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Helper functions
error() {
    echo -e "${RED}✗ ERROR: $1${NC}" >&2
    ((VALIDATION_ERRORS++))
}

info() {
    echo -e "${BLUE}ℹ INFO: $1${NC}"
}

success() {
    echo -e "${GREEN}✓ SUCCESS: $1${NC}"
}

warn() {
    echo -e "${YELLOW}⚠ WARNING: $1${NC}"
    ((VALIDATION_WARNINGS++))
}

check_pass() {
    echo -e "${GREEN}✓ $1${NC}"
}

check_fail() {
    echo -e "${RED}✗ $1${NC}"
    ((VALIDATION_ERRORS++))
}

check_warn() {
    echo -e "${YELLOW}⚠ $1${NC}"
    ((VALIDATION_WARNINGS++))
}

show_help() {
    cat << 'EOF'
Artagon Repository Validation and Update Script

Validates that an existing project meets repo_setup.sh requirements
and updates missing components to bring it into compliance.

USAGE:
    ./repo_validate.sh [options]

OPTIONS:
    --check-only
            Only validate, don't make changes (dry-run mode)

    --fix
            Automatically fix missing components

    --project-type <java|c|cpp|rust>
            Specify project type (auto-detected if not specified)

    --force
            Skip confirmation prompts

    -h, --help
            Show this help message

EXAMPLES:
    # Check current project compliance
    ./repo_validate.sh --check-only

    # Fix issues in current project
    ./repo_validate.sh --fix

    # Fix issues for Java project
    ./repo_validate.sh --fix --project-type java --force

VALIDATION CHECKS:
    - Git repository initialization
    - artagon-common submodule presence and location
    - artagon-license submodule presence and location
    - License files exported from artagon-license
    - Git hooks configuration
    - CONTRIBUTING.md presence
    - GitHub configuration files (.github templates)
    - .editorconfig presence
    - Language-specific configurations
    - README.md structure

EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --check-only)
            CHECK_ONLY="true"
            shift
            ;;
        --fix)
            FIX_MODE="true"
            shift
            ;;
        --project-type)
            PROJECT_TYPE="$2"
            shift 2
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
            echo -e "${RED}ERROR: Unknown option: $1${NC}" >&2
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Detect project type if not specified
detect_project_type() {
    if [[ -f "pom.xml" ]]; then
        echo "java"
    elif [[ -f "Cargo.toml" ]]; then
        echo "rust"
    elif [[ -f "CMakeLists.txt" ]] || [[ -f "WORKSPACE.bazel" ]] || [[ -f "BUILD.bazel" ]]; then
        # Check for C vs C++ based on file extensions
        if find src include \( -name "*.cpp" -o -name "*.hpp" \) 2>/dev/null | grep -q .; then
            echo "cpp"
        else
            echo "c"
        fi
    else
        echo ""
    fi
}

# Auto-detect project type if not specified
if [[ -z "$PROJECT_TYPE" ]]; then
    PROJECT_TYPE=$(detect_project_type)
    if [[ -n "$PROJECT_TYPE" ]]; then
        info "Auto-detected project type: $PROJECT_TYPE"
    fi
fi

# Check if we're in a git repository
check_git_repo() {
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════${NC}"
    echo -e "${CYAN}  Git Repository Check${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════${NC}"

    if git rev-parse --git-dir > /dev/null 2>&1; then
        check_pass "Git repository initialized"
        return 0
    else
        check_fail "Not a git repository"
        return 1
    fi
}

# Check artagon-common submodule
check_artagon_common() {
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════${NC}"
    echo -e "${CYAN}  artagon-common Submodule Check${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════${NC}"

    local status=0

    if [[ -d ".common/artagon-common" ]]; then
        check_pass "artagon-common directory exists at .common/artagon-common"

        if [[ -f ".common/artagon-common/.git" ]] || [[ -d ".common/artagon-common/.git" ]]; then
            check_pass "artagon-common is a git submodule"
        else
            check_warn "artagon-common exists but is not a git submodule"
            status=1
        fi
    else
        check_fail "artagon-common submodule missing at .common/artagon-common"
        status=1
    fi

    return $status
}

# Check artagon-license submodule
check_artagon_license() {
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════${NC}"
    echo -e "${CYAN}  artagon-license Submodule Check${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════${NC}"

    local status=0

    if [[ -d ".legal/artagon-license" ]]; then
        check_pass "artagon-license directory exists at .legal/artagon-license"

        if [[ -f ".legal/artagon-license/.git" ]] || [[ -d ".legal/artagon-license/.git" ]]; then
            check_pass "artagon-license is a git submodule"
        else
            check_warn "artagon-license exists but is not a git submodule"
            status=1
        fi
    else
        check_fail "artagon-license submodule missing at .legal/artagon-license"
        status=1
    fi

    return $status
}

# Check license files
check_license_files() {
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════${NC}"
    echo -e "${CYAN}  License Files Check${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════${NC}"

    local status=0
    local required_files=(
        "LICENSE"
        "licenses/LICENSE-AGPL.txt"
        "licenses/LICENSE-COMMERCIAL.txt"
        "licenses/LICENSING.md"
    )

    for file in "${required_files[@]}"; do
        if [[ -f "$file" ]]; then
            check_pass "License file exists: $file"
        else
            check_fail "License file missing: $file"
            status=1
        fi
    done

    return $status
}

# Check git hooks configuration
check_git_hooks() {
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════${NC}"
    echo -e "${CYAN}  Git Hooks Configuration Check${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════${NC}"

    local status=0

    if [[ -d ".common/artagon-common/git-hooks" ]]; then
        check_pass "Git hooks directory exists in artagon-common"

        local hooks_path
        hooks_path=$(git config core.hooksPath || echo "")

        if [[ "$hooks_path" == ".common/artagon-common/git-hooks" ]]; then
            check_pass "Git hooks path configured correctly"
        else
            check_fail "Git hooks path not configured (expected: .common/artagon-common/git-hooks, got: ${hooks_path:-<not set>})"
            status=1
        fi
    else
        check_fail "Git hooks directory missing in artagon-common"
        status=1
    fi

    return $status
}

# Check CONTRIBUTING.md
check_contributing() {
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════${NC}"
    echo -e "${CYAN}  CONTRIBUTING.md Check${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════${NC}"

    if [[ -f "CONTRIBUTING.md" ]]; then
        check_pass "CONTRIBUTING.md exists"
        return 0
    else
        check_fail "CONTRIBUTING.md missing"
        return 1
    fi
}

# Check GitHub configuration files
check_github_config() {
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════${NC}"
    echo -e "${CYAN}  GitHub Configuration Check${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════${NC}"

    local status=0

    # Check .github directory
    if [[ -d ".github" ]]; then
        check_pass ".github directory exists"
    else
        check_fail ".github directory missing"
        status=1
    fi

    # Check PR template
    if [[ -L ".github/PULL_REQUEST_TEMPLATE.md" ]]; then
        check_pass "PR template symlink exists"
    elif [[ -f ".github/PULL_REQUEST_TEMPLATE.md" ]]; then
        check_warn "PR template exists but is not a symlink"
    else
        check_fail "PR template missing"
        status=1
    fi

    # Check labeler config
    if [[ -L ".github/labeler.yml" ]]; then
        check_pass "Labeler config symlink exists"
    elif [[ -f ".github/labeler.yml" ]]; then
        check_warn "Labeler config exists but is not a symlink"
    else
        check_fail "Labeler config missing"
        status=1
    fi

    # Check issue templates
    if [[ -d ".github/ISSUE_TEMPLATE" ]]; then
        check_pass "Issue templates directory exists"

        local template_count
        template_count=$(find .github/ISSUE_TEMPLATE -name "*.md" | wc -l)
        if [[ $template_count -gt 0 ]]; then
            check_pass "Found $template_count issue template(s)"
        else
            check_warn "Issue templates directory exists but is empty"
        fi
    else
        check_fail "Issue templates directory missing"
        status=1
    fi

    return $status
}

# Check .editorconfig
check_editorconfig() {
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════${NC}"
    echo -e "${CYAN}  .editorconfig Check${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════${NC}"

    if [[ -f ".editorconfig" ]]; then
        check_pass ".editorconfig exists"
        return 0
    else
        check_fail ".editorconfig missing"
        return 1
    fi
}

# Check language-specific configurations
check_language_config() {
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════${NC}"
    echo -e "${CYAN}  Language-Specific Configuration Check${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════${NC}"

    if [[ -z "$PROJECT_TYPE" ]]; then
        check_warn "Project type not detected or specified, skipping language-specific checks"
        return 0
    fi

    info "Checking $PROJECT_TYPE project configuration"

    local status=0

    case "$PROJECT_TYPE" in
        java)
            if [[ -f "pom.xml" ]]; then
                check_pass "pom.xml exists"
            else
                check_fail "pom.xml missing"
                status=1
            fi

            if [[ -d "src/main/java" ]]; then
                check_pass "Java source directory exists"
            else
                check_warn "Java source directory (src/main/java) missing"
            fi
            ;;

        c)
            if [[ -f "CMakeLists.txt" ]] || [[ -f "WORKSPACE.bazel" ]]; then
                check_pass "Build system configuration exists"
            else
                check_fail "No CMakeLists.txt or Bazel configuration found"
                status=1
            fi

            if [[ -f ".clang-format" ]]; then
                check_pass ".clang-format exists"
            else
                check_fail ".clang-format missing"
                status=1
            fi
            ;;

        cpp)
            if [[ -f "CMakeLists.txt" ]] || [[ -f "WORKSPACE.bazel" ]]; then
                check_pass "Build system configuration exists"
            else
                check_fail "No CMakeLists.txt or Bazel configuration found"
                status=1
            fi

            if [[ -f ".clang-format" ]]; then
                check_pass ".clang-format exists"
            else
                check_fail ".clang-format missing"
                status=1
            fi

            if [[ -f ".clang-tidy" ]]; then
                check_pass ".clang-tidy exists"
            else
                check_fail ".clang-tidy missing"
                status=1
            fi
            ;;

        rust)
            if [[ -f "Cargo.toml" ]]; then
                check_pass "Cargo.toml exists"
            else
                check_fail "Cargo.toml missing"
                status=1
            fi

            if [[ -f "rustfmt.toml" ]]; then
                check_pass "rustfmt.toml exists"
            else
                check_fail "rustfmt.toml missing"
                status=1
            fi

            if [[ -f "clippy.toml" ]]; then
                check_pass "clippy.toml exists"
            else
                check_fail "clippy.toml missing"
                status=1
            fi
            ;;
    esac

    return $status
}

# Check agent directories and symlinks
check_agent_symlinks() {
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════${NC}"
    echo -e "${CYAN}  Agent Directories and Symlinks Check${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════${NC}"

    local status=0

    # Check agent directories
    if [[ -d ".agents-claude" ]]; then
        check_pass ".agents-claude directory exists"
    else
        check_fail ".agents-claude directory missing"
        status=1
    fi

    if [[ -d ".agents-codex" ]]; then
        check_pass ".agents-codex directory exists"
    else
        check_fail ".agents-codex directory missing"
        status=1
    fi

    # Check for .agents-shared - can be local or in .common/artagon-common
    if [[ -d ".agents-shared" ]]; then
        check_pass ".agents-shared directory exists (local)"
    elif [[ -d ".common/artagon-common/.agents-shared" ]]; then
        check_pass ".agents-shared directory exists (via .common/artagon-common)"
    elif [[ -d "artagon-common/.agents-shared" ]]; then
        check_pass ".agents-shared directory exists (via artagon-common)"
    else
        check_fail ".agents-shared directory missing"
        status=1
    fi

    # Check symlinks
    if [[ -L ".agents" ]] && [[ "$(readlink .agents)" == ".agents-codex" ]]; then
        check_pass ".agents -> .agents-codex symlink correct"
    elif [[ -L ".agents" ]]; then
        check_fail ".agents symlink points to wrong target"
        status=1
    elif [[ -e ".agents" ]]; then
        check_fail ".agents exists but is not a symlink"
        status=1
    else
        check_fail ".agents -> .agents-codex symlink missing"
        status=1
    fi

    if [[ -L ".claude" ]] && [[ "$(readlink .claude)" == ".agents-claude" ]]; then
        check_pass ".claude -> .agents-claude symlink correct"
    elif [[ -L ".claude" ]]; then
        check_fail ".claude symlink points to wrong target"
        status=1
    elif [[ -e ".claude" ]]; then
        check_fail ".claude exists but is not a symlink"
        status=1
    else
        check_fail ".claude -> .agents-claude symlink missing"
        status=1
    fi

    if [[ -L ".codex" ]] && [[ "$(readlink .codex)" == ".agents-codex" ]]; then
        check_pass ".codex -> .agents-codex symlink correct"
    elif [[ -L ".codex" ]]; then
        check_fail ".codex symlink points to wrong target"
        status=1
    elif [[ -e ".codex" ]]; then
        check_fail ".codex exists but is not a symlink (should be symlink, not directory)"
        status=1
    else
        check_fail ".codex -> .agents-codex symlink missing"
        status=1
    fi

    return $status
}

# Check README.md
check_readme() {
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════${NC}"
    echo -e "${CYAN}  README.md Check${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════${NC}"

    local status=0

    if [[ -f "README.md" ]]; then
        check_pass "README.md exists"

        # Check for key sections
        if grep -q "## Building" README.md; then
            check_pass "README contains Building section"
        else
            check_warn "README missing Building section"
        fi

        if grep -q "## Licensing" README.md || grep -q "## License" README.md; then
            check_pass "README contains Licensing section"
        else
            check_warn "README missing Licensing section"
        fi
    else
        check_fail "README.md missing"
        status=1
    fi

    return $status
}

# Fix missing artagon-common submodule
fix_artagon_common() {
    info "Adding artagon-common submodule"

    if [[ ! -d ".common" ]]; then
        mkdir -p .common
    fi

    if git submodule add git@github.com:artagon/artagon-common.git .common/artagon-common 2>/dev/null || \
       git submodule add https://github.com/artagon/artagon-common.git .common/artagon-common; then
        git submodule update --init --recursive
        success "Added artagon-common submodule"
    else
        error "Failed to add artagon-common submodule"
        return 1
    fi
}

# Fix missing artagon-license submodule
fix_artagon_license() {
    info "Adding artagon-license submodule"

    if [[ ! -d ".legal" ]]; then
        mkdir -p .legal
    fi

    if git submodule add git@github.com:artagon/artagon-license.git .legal/artagon-license 2>/dev/null || \
       git submodule add https://github.com/artagon/artagon-license.git .legal/artagon-license; then
        git submodule update --init --recursive
        success "Added artagon-license submodule"
        return 0
    else
        error "Failed to add artagon-license submodule"
        return 1
    fi
}

# Fix missing license files
fix_license_files() {
    info "Exporting license files from artagon-license"

    if [[ -x ".legal/artagon-license/scripts/export-license-assets.sh" ]]; then
        .legal/artagon-license/scripts/export-license-assets.sh
        success "License files exported"
    else
        error "Cannot export license files: export script not found or not executable"
        return 1
    fi
}

# Fix git hooks configuration
fix_git_hooks() {
    info "Configuring git hooks"

    if [[ -d ".common/artagon-common/git-hooks" ]]; then
        git config core.hooksPath .common/artagon-common/git-hooks
        success "Git hooks configured"
    else
        error "Cannot configure git hooks: directory not found"
        return 1
    fi
}

# Fix missing CONTRIBUTING.md
fix_contributing() {
    info "Setting up CONTRIBUTING.md"

    local contributing_script=".common/artagon-common/scripts/gh_setup_contributing.sh"

    if [[ -x "$contributing_script" ]]; then
        "$contributing_script" --force
        success "CONTRIBUTING.md created"
    else
        error "Cannot create CONTRIBUTING.md: setup script not found"
        return 1
    fi
}

# Fix GitHub configuration files
fix_github_config() {
    info "Setting up GitHub configuration files"

    local github_templates_dir=".common/artagon-common/templates/.github"

    if [[ ! -d "$github_templates_dir" ]]; then
        error "GitHub templates directory not found in artagon-common"
        return 1
    fi

    # Create .github directory structure
    mkdir -p .github/ISSUE_TEMPLATE

    # Symlink PR template
    if [[ -f "$github_templates_dir/PULL_REQUEST_TEMPLATE.md" ]]; then
        ln -sf "../.common/artagon-common/templates/.github/PULL_REQUEST_TEMPLATE.md" \
            .github/PULL_REQUEST_TEMPLATE.md
        info "Linked PR template"
    fi

    # Symlink labeler config
    if [[ -f "$github_templates_dir/labeler.yml" ]]; then
        ln -sf "../.common/artagon-common/templates/.github/labeler.yml" \
            .github/labeler.yml
        info "Linked labeler configuration"
    fi

    # Symlink issue templates
    if [[ -d "$github_templates_dir/ISSUE_TEMPLATE" ]]; then
        for template in "$github_templates_dir/ISSUE_TEMPLATE"/*.md; do
            if [[ -f "$template" ]]; then
                template_name=$(basename "$template")
                ln -sf "../../.common/artagon-common/templates/.github/ISSUE_TEMPLATE/$template_name" \
                    ".github/ISSUE_TEMPLATE/$template_name"
            fi
        done
        info "Linked issue templates"
    fi

    success "GitHub configuration files installed"
}

# Fix missing .editorconfig
fix_editorconfig() {
    info "Copying .editorconfig"

    local editorconfig=".common/artagon-common/configs/.editorconfig"

    if [[ -f "$editorconfig" ]]; then
        cp "$editorconfig" .editorconfig
        success ".editorconfig copied"
    else
        error "Cannot copy .editorconfig: file not found in artagon-common"
        return 1
    fi
}

# Fix language-specific configuration
fix_language_config() {
    if [[ -z "$PROJECT_TYPE" ]]; then
        warn "Project type not specified, cannot fix language-specific configuration"
        return 1
    fi

    info "Fixing $PROJECT_TYPE project configuration"

    case "$PROJECT_TYPE" in
        c)
            if [[ ! -f ".clang-format" ]] && [[ -f ".common/artagon-common/configs/c/.clang-format" ]]; then
                cp .common/artagon-common/configs/c/.clang-format .
                success "Copied .clang-format"
            fi
            ;;

        cpp)
            if [[ ! -f ".clang-format" ]] && [[ -f ".common/artagon-common/configs/cpp/.clang-format" ]]; then
                cp .common/artagon-common/configs/cpp/.clang-format .
                success "Copied .clang-format"
            fi

            if [[ ! -f ".clang-tidy" ]] && [[ -f ".common/artagon-common/configs/cpp/.clang-tidy" ]]; then
                cp .common/artagon-common/configs/cpp/.clang-tidy .
                success "Copied .clang-tidy"
            fi
            ;;

        rust)
            if [[ ! -f "rustfmt.toml" ]] && [[ -f ".common/artagon-common/configs/rust/rustfmt.toml" ]]; then
                cp .common/artagon-common/configs/rust/rustfmt.toml .
                success "Copied rustfmt.toml"
            fi

            if [[ ! -f "clippy.toml" ]] && [[ -f ".common/artagon-common/configs/rust/clippy.toml" ]]; then
                cp .common/artagon-common/configs/rust/clippy.toml .
                success "Copied clippy.toml"
            fi
            ;;
    esac
}

# Fix agent directories and symlinks
fix_agent_symlinks() {
    info "Setting up agent directories and symlinks"

    local agents_sync_script=".common/artagon-common/scripts/gh_sync_agents.sh"

    if [[ -x "$agents_sync_script" ]]; then
        "$agents_sync_script" --ensure --quiet
        success "Agent directories and symlinks configured"
    else
        error "Cannot setup agents: sync script not found"
        return 1
    fi
}

# Run all validation checks
run_validation() {
    echo ""
    echo -e "${BLUE}╔═══════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║  Artagon Repository Validation Report    ║${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════╝${NC}"

    check_git_repo || true
    check_artagon_common || true
    check_artagon_license || true
    check_license_files || true
    check_git_hooks || true
    check_contributing || true
    check_github_config || true
    check_editorconfig || true
    check_agent_symlinks || true
    check_language_config || true
    check_readme || true
}

# Apply fixes
apply_fixes() {
    echo ""
    echo -e "${BLUE}╔═══════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║  Applying Fixes                           ║${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════╝${NC}"
    echo ""

    # Check artagon-common and fix if needed
    if ! check_artagon_common &>/dev/null; then
        fix_artagon_common || warn "Could not fix artagon-common"
    fi

    # Check artagon-license and fix if needed
    if ! check_artagon_license &>/dev/null; then
        fix_artagon_license || warn "Could not fix artagon-license"
    fi

    # Check license files and fix if needed
    if ! check_license_files &>/dev/null; then
        fix_license_files || warn "Could not fix license files"
    fi

    # Check git hooks and fix if needed
    if ! check_git_hooks &>/dev/null; then
        fix_git_hooks || warn "Could not fix git hooks"
    fi

    # Check CONTRIBUTING.md and fix if needed
    if ! check_contributing &>/dev/null; then
        fix_contributing || warn "Could not fix CONTRIBUTING.md"
    fi

    # Check GitHub config and fix if needed
    if ! check_github_config &>/dev/null; then
        fix_github_config || warn "Could not fix GitHub configuration"
    fi

    # Check .editorconfig and fix if needed
    if ! check_editorconfig &>/dev/null; then
        fix_editorconfig || warn "Could not fix .editorconfig"
    fi

    # Check agent symlinks and fix if needed
    if ! check_agent_symlinks &>/dev/null; then
        fix_agent_symlinks || warn "Could not fix agent directories and symlinks"
    fi

    # Check language config and fix if needed
    if ! check_language_config &>/dev/null; then
        fix_language_config || warn "Could not fix language-specific configuration"
    fi
}

# Main execution
main() {
    local project_dir
    project_dir=$(pwd)

    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════${NC}"
    echo -e "${BLUE}  Artagon Repository Validator${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════${NC}"
    echo -e "Directory: ${CYAN}$project_dir${NC}"
    if [[ -n "$PROJECT_TYPE" ]]; then
        echo -e "Project Type: ${CYAN}$PROJECT_TYPE${NC}"
    fi
    echo -e "Mode: ${CYAN}$([ "$CHECK_ONLY" == "true" ] && echo "Check Only" || echo "Fix Mode")${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════${NC}"

    # Check if we're in a git repository
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        error "Not a git repository. Please run this script from the root of a git repository."
        exit 1
    fi

    # Run validation
    run_validation

    # Print summary
    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════${NC}"
    echo -e "${BLUE}  Validation Summary${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════${NC}"
    echo -e "Errors: ${RED}$VALIDATION_ERRORS${NC}"
    echo -e "Warnings: ${YELLOW}$VALIDATION_WARNINGS${NC}"

    if [[ $VALIDATION_ERRORS -eq 0 ]] && [[ $VALIDATION_WARNINGS -eq 0 ]]; then
        echo ""
        success "All checks passed! Repository is fully compliant."
        exit 0
    fi

    if [[ "$CHECK_ONLY" == "true" ]]; then
        echo ""
        info "Check-only mode: No changes were made."
        info "Run with --fix to automatically fix issues."
        exit 1
    fi

    if [[ "$FIX_MODE" == "true" ]]; then
        if [[ "$FORCE" != "true" ]]; then
            echo ""
            read -p "Apply fixes to bring repository into compliance? (y/N) " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                info "Aborted by user"
                exit 0
            fi
        fi

        apply_fixes

        # Re-run validation to show improvements
        VALIDATION_ERRORS=0
        VALIDATION_WARNINGS=0

        echo ""
        echo -e "${BLUE}═══════════════════════════════════════════${NC}"
        echo -e "${BLUE}  Re-validation After Fixes${NC}"
        echo -e "${BLUE}═══════════════════════════════════════════${NC}"

        run_validation

        echo ""
        echo -e "${BLUE}═══════════════════════════════════════════${NC}"
        echo -e "${BLUE}  Final Summary${NC}"
        echo -e "${BLUE}═══════════════════════════════════════════${NC}"
        echo -e "Remaining Errors: ${RED}$VALIDATION_ERRORS${NC}"
        echo -e "Remaining Warnings: ${YELLOW}$VALIDATION_WARNINGS${NC}"

        if [[ $VALIDATION_ERRORS -eq 0 ]]; then
            echo ""
            success "Repository is now compliant!"

            # Check if there are changes to commit
            if ! git diff --quiet || ! git diff --cached --quiet || [ -n "$(git ls-files --others --exclude-standard)" ]; then
                echo ""
                info "Changes have been made to your repository."
                info "Review the changes and commit them:"
                echo ""
                echo "  git status"
                echo "  git add ."
                echo '  git commit -m "chore: update repository to meet artagon standards"'
            fi
        else
            echo ""
            warn "Some issues could not be automatically fixed."
            info "Please review the errors above and fix them manually."
            exit 1
        fi
    else
        echo ""
        info "Use --fix to automatically fix issues, or --check-only to just validate."
        exit 1
    fi
}

main
