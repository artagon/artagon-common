#!/usr/bin/env bash
#
# Remove Branch Protection from GitHub Repositories
#
# Usage:
#   ./remove-branch-protection.sh --repo artagon-common
#   ./remove-branch-protection.sh --all --force
#

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Defaults
DEFAULT_OWNER="artagon"
DEFAULT_BRANCH="main"
DEFAULT_REPOS=("artagon-common" "artagon-license" "artagon-bom" "artagon-parent")

OWNER=""
BRANCH=""
REPOS=()
PROCESS_ALL=false
FORCE=false

usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Remove branch protection from GitHub repositories.

OPTIONS:
    -r, --repo REPO         Repository name (repeatable)
    -o, --owner OWNER       GitHub owner/org (default: ${DEFAULT_OWNER})
    -b, --branch BRANCH     Branch to unprotect (default: ${DEFAULT_BRANCH})
    -a, --all               Process all default repositories
    -f, --force             Skip confirmation
    -h, --help              Show help

⚠️  WARNING: This will remove ALL protection!

EXAMPLES:
    $0 --repo artagon-common
    $0 --all --force

EOF
    exit 0
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -r|--repo) REPOS+=("$2"); shift 2;;
            -o|--owner) OWNER="$2"; shift 2;;
            -b|--branch) BRANCH="$2"; shift 2;;
            -a|--all) PROCESS_ALL=true; shift;;
            -f|--force) FORCE=true; shift;;
            -h|--help) usage;;
            *) echo -e "${RED}Error: Unknown option: $1${NC}"; exit 1;;
        esac
    done
    OWNER=${OWNER:-$DEFAULT_OWNER}
    BRANCH=${BRANCH:-$DEFAULT_BRANCH}
    if [ "$PROCESS_ALL" = true ]; then
        REPOS=("${DEFAULT_REPOS[@]}")
    elif [ ${#REPOS[@]} -eq 0 ]; then
        echo -e "${RED}Error: No repositories specified${NC}"; exit 1
    fi
}

remove_protection() {
    local repo=$1 branch=$2
    echo -e "${YELLOW}Removing protection from '${branch}' in ${OWNER}/${repo}...${NC}"
    
    if gh api --method DELETE -H "Accept: application/vnd.github+json" \
        "/repos/${OWNER}/${repo}/branches/${branch}/protection" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Successfully removed protection from ${OWNER}/${repo}:${branch}${NC}"
        return 0
    else
        echo -e "${RED}✗ Failed to remove protection (may not exist)${NC}"
        return 1
    fi
}

main() {
    parse_args "$@"
    echo -e "${BLUE}======================================${NC}"
    echo -e "${BLUE}Remove Branch Protection${NC}"
    echo -e "${BLUE}======================================${NC}"
    echo ""
    echo -e "${RED}⚠️  WARNING: This will remove ALL protection!${NC}\n"
    for repo in "${REPOS[@]}"; do echo "  - ${OWNER}/${repo}:${BRANCH}"; done
    echo ""
    
    if [ "$FORCE" != true ]; then
        read -p "Are you sure? (y/n) " -r
        echo; [[ ! $REPLY =~ ^[Yy]$ ]] && exit 0
    fi
    
    success=0 fail=0
    for repo in "${REPOS[@]}"; do
        remove_protection "$repo" "$BRANCH" && ((success++)) || ((fail++))
        echo ""
    done
    
    echo -e "${BLUE}Summary: ${GREEN}Success: $success ${RED}Failed: $fail${NC}\n"
    [ $fail -eq 0 ] && exit 0 || exit 1
}

main "$@"
