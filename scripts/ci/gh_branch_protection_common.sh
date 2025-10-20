#!/usr/bin/env bash
#
# Common functions for branch protection scripts
# Source this file in other scripts: source "$(dirname "$0")/gh_branch_protection_common.sh"
#

# Colors for output
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[1;33m'
export BLUE='\033[0;34m'
export CYAN='\033[0;36m'
export NC='\033[0m' # No Color

# Default values
export DEFAULT_OWNER="artagon"
export DEFAULT_BRANCH="main"
export DEFAULT_REPOS=(
    "artagon-common"
    "artagon-license"
    "artagon-bom"
    "artagon-parent"
)

# Parse command line arguments (common to all scripts)
parse_common_args() {
    local owner_var=$1
    local branch_var=$2
    local repos_var=$3
    local process_all_var=$4
    local force_var=$5

    shift 5  # Remove the variable names from args

    local -n _owner=$owner_var
    local -n _branch=$branch_var
    local -n _repos=$repos_var
    local -n _process_all=$process_all_var
    local -n _force=$force_var

    _owner=""
    _branch=""
    _repos=()
    _process_all=false
    _force=false

    while [[ $# -gt 0 ]]; do
        case $1 in
            -r|--repo)
                _repos+=("$2")
                shift 2
                ;;
            -o|--owner)
                _owner="$2"
                shift 2
                ;;
            -b|--branch)
                _branch="$2"
                shift 2
                ;;
            -a|--all)
                _process_all=true
                shift
                ;;
            -f|--force)
                _force=true
                shift
                ;;
            -h|--help)
                return 255  # Signal to show help
                ;;
            *)
                echo -e "${RED}Error: Unknown option: $1${NC}" >&2
                echo "Use --help for usage information" >&2
                return 1
                ;;
        esac
    done

    # Set defaults
    _owner=${_owner:-$DEFAULT_OWNER}
    _branch=${_branch:-$DEFAULT_BRANCH}

    # Determine which repos to process
    if [ "$_process_all" = true ]; then
        _repos=("${DEFAULT_REPOS[@]}")
    elif [ ${#_repos[@]} -eq 0 ]; then
        echo -e "${RED}Error: No repositories specified${NC}" >&2
        echo "Use --repo to specify repositories or --all for all default repos" >&2
        echo "Use --help for more information" >&2
        return 1
    fi

    return 0
}

# Show common usage examples
show_common_usage_examples() {
    cat << 'EOF'
EXAMPLES:
    # Protect a single repository
    $0 --repo artagon-common

    # Protect multiple repositories
    $0 --repo artagon-bom --repo artagon-parent

    # Protect repository in different organization
    $0 --repo my-project --owner myorg

    # Protect all default repositories
    $0 --all

    # Protect with custom branch
    $0 --repo artagon-common --branch develop

    # Skip confirmation prompt
    $0 --repo artagon-common --force

EOF
}

# Common OPTIONS section
show_common_options() {
    cat << EOF
OPTIONS:
    -r, --repo REPO         Repository name (can be specified multiple times)
    -o, --owner OWNER       GitHub owner/organization (default: ${DEFAULT_OWNER})
    -b, --branch BRANCH     Branch name to protect (default: ${DEFAULT_BRANCH})
    -a, --all               Process all default repositories
    -f, --force             Skip confirmation prompt
    -h, --help              Show this help message

EOF
}
